#!/usr/bin/env python3
"""Render every name in names.txt as a grid, so the whole set can be judged at
once. A style that looks fine on two names can still fall apart across thirty
-- which is exactly what happened to "flush" and "lift" here.

  python3 grid.py                 # default style, from names.txt
  STYLE=lift python3 grid.py      # any style
"""
import os
import sys

from PIL import Image, ImageDraw

import bridges
import compare
import measure

HERE = os.path.dirname(os.path.abspath(__file__))
COLS = 3


def main():
    font = os.environ.get("FONT", "Great Vibes")
    size = float(os.environ.get("SIZE", 15))
    bold = float(os.environ.get("BOLD", 0.15))
    style = os.environ.get("STYLE", "lift")
    extra = (["-D", f"bite={os.environ['BITE']}"] if "BITE" in os.environ else [])
    names = [l.strip() for l in open(os.path.join(HERE, "names.txt")) if l.strip()]

    ic, bc = measure.load_cache(), bridges.load_cache()
    inks = {n: measure.measure(n, font, size, bold, cache=ic) for n in names}
    set_drop = max(v["drop"] for v in inks.values())

    print(f"rendering {len(names)} names, {font} {size:g}mm style={style}")
    cells = []
    for n in names:
        p = os.path.join(compare.PREV, f"_g_{style}{os.environ.get('BITE','')}_{n}.png")
        compare.tag_png(p, n, font, size, style, set_drop, bold, ic, bc,
                        w=760, h=250, extra=extra)
        cells.append((n, p))

    imgs = [Image.open(p) for _, p in cells]
    cw, ch = max(i.width for i in imgs), max(i.height for i in imgs)
    rows = (len(imgs) + COLS - 1) // COLS
    hdr = 60
    sh = Image.new("RGB", (cw * COLS, hdr + ch * rows), (250, 250, 250))
    d = ImageDraw.Draw(sh)
    d.rectangle([0, 0, sh.width, hdr], fill=(24, 26, 30))
    d.text((16, 18), f"{font} {size:g}mm  bold +{bold}  style={style}"
                     f"{'  bite=' + os.environ['BITE'] + 'mm' if 'BITE' in os.environ else ''}   "
                     f"{len(names)} names, shared baseline {set_drop:.2f}mm",
           font=compare.label_font(26), fill=(240, 240, 240))
    fl = compare.label_font(20)
    for i, im in enumerate(imgs):
        r, c = divmod(i, COLS)
        x, y = c * cw, hdr + r * ch
        sh.paste(im, (x, y))
        d.text((x + 12, y + 8), cells[i][0], font=fl, fill=(120, 140, 170))
        d.rectangle([x, y, x + cw - 1, y + ch - 1], outline=(225, 225, 225))
    tagname = style + (f"_bite{os.environ['BITE']}" if "BITE" in os.environ else "")
    out = os.path.join(compare.PREV, f"all_{tagname}.png")
    sh.save(out)
    measure.save_cache(ic)
    bridges.save_cache(bc)
    print(f"  {out}")
    return out


if __name__ == "__main__":
    main()
