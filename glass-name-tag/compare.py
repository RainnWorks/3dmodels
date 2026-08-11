#!/usr/bin/env python3
"""Contact sheets OpenSCAD cannot make on its own.

  styles.png  every style x font, for one name WITH deep tails and one with
              none, both placed on the SAME set baseline -- which is the only
              way to see whether a style still works across a mixed set.
  glass.png   the tag drawn against a scale slice of glass rim, so the clip's
              jaw and the glass face can be checked by eye rather than by
              trusting the numbers.
"""
import json
import os
import subprocess
import sys

from PIL import Image, ImageDraw, ImageFont

import bridges
import measure

HERE = os.path.dirname(os.path.abspath(__file__))
PREV = os.path.join(HERE, "previews")
MODEL = os.path.join(HERE, "nametag.scad")
OPENSCAD = os.environ.get("OSCAD", "openscad")

CAM = ["--camera=0,0,0,0,0,0,0", "--viewall", "--autocenter",
       "--render", "--colorscheme=Tomorrow"]

# A name with the deepest tails in the set, and one with effectively none.
# Every style has to hold up for BOTH at a shared baseline.
PAIR = ["Jenny", "Alice"]
STYLES = ["window", "solid", "flush"]
FONTS = ["Great Vibes", "Pacifico"]


def render(png, name, ink, set_drop, font, style, size=15, w=1000, h=420,
           extra=None, bold=0.0, struts=None):
    cmd = ([OPENSCAD, "-o", png] + CAM + [f"--imgsize={w},{h}",
           "--enable=textmetrics",
           "-D", f'font="{font}"', "-D", f"txt_size={size}",
           "-D", f'style="{style}"', "-D", f"set_drop={set_drop}",
           "-D", f"bold={bold}"]
           + measure.scad_args(name, ink)
           + (["-D", f"struts={json.dumps(struts)}"] if struts else [])
           + (extra or []) + [MODEL])
    r = subprocess.run(cmd, capture_output=True, text=True)
    if not os.path.exists(png):
        raise RuntimeError(f"render failed: {name}/{font}/{style}\n{r.stderr[-800:]}")
    return png


def tag_png(png, name, font, size, style, set_drop, bold, ic, bc, **kw):
    """A finished tag: measured, bridged, rendered."""
    ink = measure.measure(name, font, size, bold, cache=ic)
    st = bridges.bridges_for(name, ink, font, size, style, set_drop, bold, cache=bc)
    return render(png, name, ink, set_drop, font, style, size,
                  bold=bold, struts=st, **kw)


def label_font(sz):
    for p in ("/System/Library/Fonts/Supplemental/Arial.ttf",
              "/System/Library/Fonts/Helvetica.ttc"):
        if os.path.exists(p):
            return ImageFont.truetype(p, sz)
    return ImageFont.load_default()


def sheet(out, rows, title):
    """rows = [(label, [png, ...]), ...] laid out as a labelled grid."""
    imgs = [[Image.open(p) for p in ps] for _, ps in rows]
    cw = max(im.width for r in imgs for im in r)
    ch = max(im.height for r in imgs for im in r)
    lab_w, hdr = 210, 62
    W = lab_w + cw * len(imgs[0])
    H = hdr + ch * len(imgs)
    sh = Image.new("RGB", (W, H), (28, 30, 34))
    d = ImageDraw.Draw(sh)
    f_t, f_l = label_font(30), label_font(23)
    d.text((18, 16), title, font=f_t, fill=(240, 240, 240))
    for ri, (lab, _) in enumerate(rows):
        y = hdr + ri * ch
        d.text((18, y + ch // 2 - 14), lab, font=f_l, fill=(150, 200, 255))
        for ci, im in enumerate(imgs[ri]):
            sh.paste(im, (lab_w + ci * cw, y))
        d.line([(0, y), (W, y)], fill=(60, 63, 68))
    sh.save(out)
    print(f"  {out}")
    return out


def main():
    os.makedirs(PREV, exist_ok=True)
    cache = measure.load_cache()
    size = float(os.environ.get("SIZE", 15))
    print("rendering contact sheets:")

    for font in FONTS:
        ink = {n: measure.measure(n, font, size, cache=cache) for n in PAIR}
        # one shared baseline for the pair -- as a real set would have
        set_drop = max(v["drop"] for v in ink.values())
        rows = []
        for st in STYLES:
            ps = []
            for n in PAIR:
                p = os.path.join(PREV, f"_{font.replace(' ','')}_{n}_{st}.png")
                ps.append(render(p, n, ink[n], set_drop, font, st, size))
            rows.append((st, ps))
        tag = font.replace(" ", "").lower()
        sheet(os.path.join(PREV, f"styles_{tag}.png"), rows,
              f"{font} {size:g}mm  --  shared set baseline "
              f"(deepest tail {set_drop:.2f}mm)   left: Jenny (tails)   right: Alice (none)")

    measure.save_cache(cache)
    return 0


if __name__ == "__main__":
    sys.exit(main())
