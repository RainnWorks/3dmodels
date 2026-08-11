#!/usr/bin/env python3
"""Geometry tests for nametag.scad.  Run with `make test`.

Same three handles the other models in this repo settled on:

  assert_*.scad   render must succeed. The file uses assert() on derived
                  values -- the arithmetic that is self-consistent but wrong.

  empty_*.scad    render must produce NO geometry. Boolean emptiness is how you
                  ask a solid modeller a yes/no question:
                      "A stays clear of B"  ->  intersection(A, B) is empty
                  Here that question is the whole point of the model: does any
                  letter reach past the glass face.

  mesh checks     properties of the exported STL that OpenSCAD will not report:
                  how many separate solids came out, and how far the body
                  reaches. A tag in two pieces renders perfectly and prints as
                  litter.

Every check runs over a WORD LIST, not one name, because every defect this
model was built to fix is name-dependent -- "Tom" and "Jenny" fail in opposite
directions, and a suite that tests one name proves nothing about a set of 30.
"""
import os
import struct
import subprocess
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import bridges          # noqa: E402
import measure          # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
MODEL = os.path.join(ROOT, "nametag.scad")
OPENSCAD = os.environ.get("OSCAD", "openscad")

GREEN, RED, DIM, OFF = "\033[32m", "\033[31m", "\033[2m", "\033[0m"

# Chosen so that between them they cover every way the placement can go wrong:
#   Alice       no descender at all      -- the metric overstates by ~6.6mm
#   Jenny       two deep tails           -- the metric is exactly right
#   Millie      two floating i-dots
#   Jai         i-dot AND a capital J tail
#   Christopher longest, and an i-dot
#   Tom         short -- clip_min_len drives the length, not the name
#   Zoe / Ava   very short, tail-less
NAMES = ["Alice", "Jenny", "Millie", "Jai", "Christopher", "Tom", "Zoe", "Ava",
         "Sophie", "Poppy", "Niamh", "George"]
FONTS = ["Great Vibes", "Pacifico"]
STYLES = ["lift", "rail", "solid"]
SIZE, BOLD = 15.0, 0.15


def run(args, out="/dev/null"):
    return subprocess.run(
        [OPENSCAD, "-o", out, "--export-format", "binstl",
         "--enable=textmetrics"] + args,
        capture_output=True, text=True)


def placed(name, font, style, set_drop, ic, bc):
    """The -D flags for a fully placed, fully bridged tag."""
    ink = measure.measure(name, font, SIZE, BOLD, cache=ic)
    st = bridges.bridges_for(name, ink, font, SIZE, style, set_drop, BOLD, cache=bc)
    args = (["-D", f'font="{font}"', "-D", f"txt_size={SIZE}", "-D", f"bold={BOLD}",
             "-D", f'style="{style}"', "-D", f"set_drop={set_drop}"]
            + measure.scad_args(name, ink))
    if st:
        import json
        args += ["-D", f"struts={json.dumps(st)}"]
    return args


def check_assert(scad, extra):
    r = run(extra + [scad])
    for line in r.stderr.splitlines():
        if "Assertion" in line or line.startswith("ERROR"):
            return False, line.strip()[:160]
    return True, ""


def check_empty(scad, extra):
    r = run(extra + [scad])
    if "Current top level object is empty" in r.stderr:
        return True, ""
    for line in r.stderr.splitlines():
        if "Assertion" in line or line.startswith("ERROR"):
            return False, line.strip()[:160]
    return False, "produced geometry -- something reaches past the glass face"


def mesh(name, font, style, set_drop, ic, bc, part="body"):
    out = os.path.join(HERE, ".t.stl")
    if os.path.exists(out):
        os.remove(out)
    r = run(placed(name, font, style, set_drop, ic, bc) + ["-D", f'render_part="{part}"',
            MODEL], out=out)
    if not os.path.exists(out):
        return None, r.stderr[-200:]
    tris = bridges.load_tris(out)
    roots, _ = bridges.components(tris)
    v = tris.reshape(-1, 3)
    res = {"shells": len(np.unique(roots)), "ymin": float(v[:, 1].min()),
           "ymax": float(v[:, 1].max()), "xlen": float(v[:, 0].max() - v[:, 0].min())}
    os.remove(out)
    return res, ""


def main():
    ic, bc = measure.load_cache(), bridges.load_cache()
    fails, total = [], 0

    def report(ok, label, why=""):
        nonlocal total
        total += 1
        if not ok:
            fails.append((label, why))
        print(f"  {GREEN + 'pass' + OFF if ok else RED + 'FAIL' + OFF}  {label}"
              + (f"\n        {DIM}{why}{OFF}" if why and not ok else ""))

    for font in FONTS:
        inks = {n: measure.measure(n, font, SIZE, BOLD, cache=ic) for n in NAMES}
        set_drop = max(v["drop"] for v in inks.values())
        print(f"\n{font}  size {SIZE:g}  bold +{BOLD}  set baseline {set_drop:.2f}mm")

        for style in STYLES:
            print(f"\n  --- style={style} ---")
            for scad in sorted(f for f in os.listdir(HERE) if f.endswith(".scad")
                               and f != "lib.scad" and not f.startswith("probe_")):
                path = os.path.join(HERE, scad)
                # the scad-level checks only need a couple of representative
                # names; the mesh checks below sweep the whole list
                for n in ["Alice", "Jenny"]:
                    extra = placed(n, font, style, set_drop, ic, bc)
                    fn = check_empty if scad.startswith("empty_") else check_assert
                    ok, why = fn(path, extra)
                    report(ok, f"{scad[:-5]:34} {n}", why)

            # --- mesh checks, every name -------------------------------------
            bad_shell, bad_y, errs = [], [], []
            for n in NAMES:
                m, err = mesh(n, font, style, set_drop, ic, bc)
                if m is None:
                    errs.append(f"{n}: {err}")
                    continue
                if m["shells"] != 1:
                    bad_shell.append(f"{n}={m['shells']}")
                if m["ymin"] < -1e-6:
                    bad_y.append(f"{n}={m['ymin']:.3f}")
            report(not errs, f"{'all names render':34} ({len(NAMES)} names)",
                   "; ".join(errs))
            report(not bad_shell, f"{'each tag is ONE body':34} ({len(NAMES)} names)",
                   "loose pieces: " + ", ".join(bad_shell))
            report(not bad_y, f"{'no ink past the glass face':34} ({len(NAMES)} names)",
                   "reaches into the glass: " + ", ".join(bad_y))

            # The clip must CLAMP, not hook. Measured as how far along the glass
            # it actually interferes: the first version of this clip touched
            # over 2.6mm -- a point -- because its curl was 4.8mm wide for a
            # 2mm rim, so the rim never seated and only the arm tip reached it.
            out = os.path.join(HERE, ".grip.stl")
            if os.path.exists(out):
                os.remove(out)
            run(placed("Grace", font, style, set_drop, ic, bc)
                + [os.path.join(HERE, "probe_grip.scad")], out=out)
            if not os.path.exists(out):
                report(False, f"{'clip clamps the rim':34}", "clip never touches the glass")
            else:
                gv = bridges.load_tris(out).reshape(-1, 3)
                contact = float(gv[:, 0].max() - gv[:, 0].min())
                os.remove(out)
                report(contact >= 10.0, f"{'clip clamps the rim':34} ({contact:.1f}mm contact)",
                       f"only {contact:.1f}mm of the clip meets the glass -- that is a "
                       f"hook, not a clip; check the curl is about a rim wide")

    measure.save_cache(ic)
    bridges.save_cache(bc)
    print(f"\n{'-'*60}")
    if fails:
        print(f"{RED}{len(fails)} of {total} checks FAILED{OFF}")
        for label, why in fails:
            print(f"  {label}: {why}")
        return 1
    print(f"{GREEN}all {total} checks passed{OFF}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
