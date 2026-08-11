#!/usr/bin/env python3
"""Export every name as its own STL, at one or more `bite` settings.

  python3 tags.py               # the BITES below, each into its own folder
  BITES=3.0 python3 tags.py     # just one

Each name is measured, bridged and exported independently, and then CHECKED:
a tag that comes out as more than one body is litter, and a tag whose ink
reaches past the glass face will not sit flat. Both are verified here rather
than assumed, because these are the files that actually get printed.
"""
import json
import os
import subprocess
import sys

import numpy as np

import bridges
import measure

HERE = os.path.dirname(os.path.abspath(__file__))
EXPORT = os.path.join(HERE, "export")
MODEL = os.path.join(HERE, "nametag.scad")
OPENSCAD = os.environ.get("OSCAD", "openscad")

BITES = [b.strip() for b in os.environ.get("BITES", "0.4,3.0").split(",") if b.strip()]


def export_one(name, ink, struts, font, size, style, set_drop, bold, bite, out):
    cmd = ([OPENSCAD, "-o", out, "--export-format", "binstl", "--enable=textmetrics",
            "-D", 'render_part="tag"', "-D", f'font="{font}"', "-D", f"txt_size={size}",
            "-D", f'style="{style}"', "-D", f"set_drop={set_drop}", "-D", f"bold={bold}",
            "-D", f"bite={bite}"]
           + measure.scad_args(name, ink)
           + (["-D", f"struts={json.dumps(struts)}"] if struts else [])
           + [MODEL])
    r = subprocess.run(cmd, capture_output=True, text=True)
    if not os.path.exists(out):
        raise RuntimeError(f"export failed for {name} @ bite {bite}:\n{r.stderr[-600:]}")


def body_ok(name, ink, struts, font, size, style, set_drop, bold, bite):
    """(shells, ymin) of the BODY -- the part that must clear the glass."""
    out = os.path.join(HERE, ".chk.stl")
    if os.path.exists(out):
        os.remove(out)
    cmd = ([OPENSCAD, "-o", out, "--export-format", "binstl", "--enable=textmetrics",
            "-D", 'render_part="body"', "-D", f'font="{font}"', "-D", f"txt_size={size}",
            "-D", f'style="{style}"', "-D", f"set_drop={set_drop}", "-D", f"bold={bold}",
            "-D", f"bite={bite}"]
           + measure.scad_args(name, ink)
           + (["-D", f"struts={json.dumps(struts)}"] if struts else [])
           + [MODEL])
    subprocess.run(cmd, capture_output=True)
    t = bridges.load_tris(out)
    roots, _ = bridges.components(t)
    ymin = float(t.reshape(-1, 3)[:, 1].min())
    os.remove(out)
    return len(np.unique(roots)), ymin


def main():
    font = os.environ.get("FONT", "Great Vibes")
    size = float(os.environ.get("SIZE", 15))
    bold = float(os.environ.get("BOLD", 0.15))
    style = os.environ.get("STYLE", "lift")
    names = [l.strip() for l in open(os.path.join(HERE, "names.txt")) if l.strip()]

    for bite in BITES:
        # bridges.py keys its cache on BITE, because the bite moves the letters
        # and therefore moves the struts that weld their dots on.
        os.environ["BITE"] = bite
        ic, bc = measure.load_cache(), bridges.load_cache()
        inks = {n: measure.measure(n, font, size, bold, cache=ic) for n in names}
        set_drop = max(v["drop"] for v in inks.values())

        outdir = os.path.join(EXPORT, f"bite{bite}")
        os.makedirs(outdir, exist_ok=True)
        print(f"\nbite {bite}mm -> export/bite{bite}/   "
              f"({font} {size:g}mm bold+{bold} style={style})")

        loose, fouls, sizes = [], [], []
        for n in names:
            st = bridges.bridges_for(n, inks[n], font, size, style, set_drop, bold, cache=bc)
            out = os.path.join(outdir, f"{n}.stl")
            export_one(n, inks[n], st, font, size, style, set_drop, bold, bite, out)
            shells, ymin = body_ok(n, inks[n], st, font, size, style, set_drop, bold, bite)
            if shells != 1:
                loose.append(f"{n}={shells}")
            if ymin < -1e-6:
                fouls.append(f"{n}={ymin:.3f}")
            v = bridges.load_tris(out).reshape(-1, 3)
            sizes.append((n, v[:, 0].max() - v[:, 0].min(), v[:, 1].max() - v[:, 1].min()))

        ws = [s[1] for s in sizes]
        print(f"  {len(names)} STLs, {min(ws):.0f}-{max(ws):.0f}mm long, "
              f"{min(s[2] for s in sizes):.0f}-{max(s[2] for s in sizes):.0f}mm tall")
        print(f"  one body:        {'OK' if not loose else 'LOOSE PIECES: ' + ', '.join(loose)}")
        print(f"  clear of glass:  {'OK' if not fouls else 'FOULS: ' + ', '.join(fouls)}")
        measure.save_cache(ic)
        bridges.save_cache(bc)
    return 0


if __name__ == "__main__":
    sys.exit(main())
