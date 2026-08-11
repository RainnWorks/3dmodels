#!/usr/bin/env python3
"""How much material actually holds each name onto its bar.

With style="lift" the bar is thin and the name is raised until its own deepest
ink bites into it, so on a name like "Poppy" the only thing joining the letters
to the bar may be the tails of two p's. That is a real worry and it is not
settled by looking at a render -- so measure it.

The weld is the ink crossing the bar's top edge. Intersect the letters with a
thin strip there, take the area, divide by the strip height: that is the total
WIDTH of material in the joint. Multiply by the print thickness for the
cross-section that has to survive being handled.
"""
import os, subprocess, sys
import numpy as np
import bridges, measure

HERE = os.path.dirname(os.path.abspath(__file__))
PROBE = 0.2


def weld_width(name, ink, font, size, style, set_drop, bold):
    out = os.path.join(HERE, ".w.stl")
    if os.path.exists(out):
        os.remove(out)
    cmd = (["openscad", "-o", out, "--export-format", "binstl", "--enable=textmetrics",
            "-D", 'render_part="weld"', "-D", f'font="{font}"', "-D", f"txt_size={size}",
            "-D", f'style="{style}"', "-D", f"set_drop={set_drop}", "-D", f"bold={bold}",
            "-D", f"weld_probe={PROBE}"]
           + measure.scad_args(name, ink) + [os.path.join(HERE, "nametag.scad")])
    subprocess.run(cmd, capture_output=True, text=True)
    if not os.path.exists(out):
        return 0.0, 0
    t = bridges.load_tris(out)
    n = np.cross(t[:, 1] - t[:, 0], t[:, 2] - t[:, 0])
    top = n[:, 2] > 0
    area = np.abs(n[top, 2]).sum() / 2
    roots, _ = bridges.components(t)
    os.remove(out)
    return area / PROBE, len(np.unique(roots))


def main(argv):
    font = os.environ.get("FONT", "Great Vibes")
    size = float(os.environ.get("SIZE", 15))
    bold = float(os.environ.get("BOLD", 0.15))
    style = os.environ.get("STYLE", "lift")
    names = [l.strip() for l in open(os.path.join(HERE, "names.txt")) if l.strip()]
    ic = measure.load_cache()
    inks = {n: measure.measure(n, font, size, bold, cache=ic) for n in names}
    sd = max(v["drop"] for v in inks.values())
    thick = 2.0
    print(f"{font} {size:g}mm bold+{bold} style={style}\n")
    print(f"{'name':13} {'weld mm':>8} {'joints':>7} {'area mm2':>9}   bar")
    print("-" * 56)
    rows = []
    for n in names:
        w, j = weld_width(n, inks[n], font, size, style, sd, bold)
        rows.append((n, w, j))
    for n, w, j in sorted(rows, key=lambda r: r[1]):
        bar = "#" * max(1, int(w * 2))
        print(f"{n:13} {w:8.2f} {j:7d} {w*thick:9.2f}   {bar}")
    ws = [w for _, w, _ in rows]
    print("-" * 56)
    print(f"weakest {min(ws):.2f}mm  median {sorted(ws)[len(ws)//2]:.2f}mm  "
          f"strongest {max(ws):.2f}mm")
    measure.save_cache(ic)


if __name__ == "__main__":
    main(sys.argv[1:])
