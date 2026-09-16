#!/usr/bin/env python3
"""Export a printable tag for every name in names.txt.  `make exports`.

Each name is measured, bridged and exported independently, then CHECKED: a tag
that comes out as more than one body is litter, and a tag whose letters reach
past the glass face will not sit flat. Both are verified here rather than
assumed, because these are the files that actually get printed.

Exported in the PRINT orientation -- letters face-down -- so the STL drops onto
the bed the right way up and nobody has to remember which way that was.

  python3 build.py                 # all of names.txt
  python3 build.py Tom Marlow      # just these
  FMT=3mf python3 build.py         # 3MF instead of STL
"""
import os
import subprocess
import sys

import mesh
import place

HERE = os.path.dirname(os.path.abspath(__file__))
EXPDIR = os.path.join(HERE, "export")
OPENSCAD = os.environ.get("OSCAD", "openscad")
FMT = os.environ.get("FMT", "stl")
PART = os.environ.get("PART", "print")


def export(name, args, fmt=FMT, part=PART):
    out = os.path.join(EXPDIR, f"{name}.{fmt}")
    cmd = ([OPENSCAD, "-o", out, "--enable=textmetrics", "-D", f'part="{part}"']
           + (["--export-format", "binstl"] if fmt == "stl" else [])
           + args + [place.MODEL])
    r = subprocess.run(cmd, capture_output=True, text=True)
    if not os.path.exists(out):
        raise RuntimeError(f"export failed for {name!r}:\n{r.stderr[-800:]}")
    return out


def check(name, args):
    """(shells, zmin) of the BODY -- the part that must clear the glass."""
    out = os.path.join(EXPDIR, ".chk.stl")
    subprocess.run([OPENSCAD, "-o", out, "--export-format", "binstl",
                    "--enable=textmetrics", "-D", 'part="body"']
                   + args + [place.MODEL], capture_output=True)
    st = mesh.stats(out)
    tris, _ = mesh.load_tris(out)
    zmin = float(tris.reshape(-1, 3)[:, 2].min())
    os.remove(out)
    return st["shells"], zmin


def main(argv):
    os.makedirs(EXPDIR, exist_ok=True)
    names, args = place.everything()
    todo = argv or names

    print(f"{place.FONT} {place.SIZE:g}mm bold +{place.BOLD} "
          f"style={place.STYLE}\n")
    print(f"  {'name':12} {'size (mm)':>18} {'bodies':>7} {'body zmin':>10}  file")
    print("  " + "-" * 66)
    longest, bad = 0.0, []
    for n in todo:
        path = export(n, args[n])
        st = mesh.stats(path)
        shells, zmin = check(n, args[n])
        if shells != 1:
            bad.append(f"{n}: {shells} pieces")
        if zmin < -1e-6:
            bad.append(f"{n}: body reaches {zmin:.3f} into the glass")
        longest = max(longest, st["size"][0])
        print(f"  {n:12} {st['size'][0]:6.1f} x {st['size'][1]:5.1f} x "
              f"{st['size'][2]:4.1f} {shells:7d} {zmin:9.3f}  "
              f"{os.path.relpath(path, HERE)}")
    print("  " + "-" * 66)
    print(f"  {len(todo)} tags, longest {longest:.1f}mm")
    if bad:
        raise SystemExit("\nREFUSING these: " + "; ".join(bad))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
