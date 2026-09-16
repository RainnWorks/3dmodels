#!/usr/bin/env python3
"""Contact sheets OpenSCAD cannot make on its own.  `make renders`.

  head.png      three names STRAIGHT ON, camera 0,0,0,0,0,0,0. This is the
                view that matters and it is first for a reason: every mistake
                this variant went through was invisible in an isometric render
                and obvious the moment the letter plane was seen face-on.
  all.png       every name in names.txt, all head-on.
  stack.png     the same tag from an angle, where the out-of-plane clip shows.
  print.png     the print orientation, letters face-down.
  section.png   the clip cut through, on a scale rim with a round end.
  onglass.png   the tag where it lives.
"""
import os
import subprocess
import sys

from PIL import Image, ImageDraw, ImageFont

import place

HERE = os.path.dirname(os.path.abspath(__file__))
PREV = os.path.join(HERE, "previews")
MODEL = place.MODEL
OPENSCAD = os.environ.get("OSCAD", "openscad")

COLS = 3
# The letters live in XY and the guest looks straight down -Z at them, so the
# head-on view is OpenSCAD's own default camera. Nothing is mirrored, nothing
# is foreshortened, and anything crossing the lettering shows immediately.
HEAD = "0,0,0,0,0,0,0"
ISO = "0,0,0,58,0,18,0"
SIDE = "0,0,0,90,0,0,0"
WORN = "0,0,0,66,0,20,0"


def render(png, part, args, cam, w, h, solid=True, extra=None):
    cmd = ([OPENSCAD, "-o", png] + (["--render"] if solid else [])
           + ["--colorscheme=Tomorrow", f"--camera={cam}", "--viewall",
              "--autocenter", f"--imgsize={w},{h}", "--enable=textmetrics",
              "-D", f'part="{part}"'] + (extra or []) + args + [MODEL])
    r = subprocess.run(cmd, capture_output=True, text=True)
    if not os.path.exists(png):
        raise RuntimeError(f"render failed: {part}\n{r.stderr[-800:]}")
    return png


def label_font(sz):
    for p in ("/System/Library/Fonts/Supplemental/Arial.ttf",
              "/System/Library/Fonts/Helvetica.ttc"):
        if os.path.exists(p):
            return ImageFont.truetype(p, sz)
    return ImageFont.load_default()


def caption(path, title, sub=""):
    im = Image.open(path).convert("RGB")
    hdr = 64 if sub else 44
    out = Image.new("RGB", (im.width, im.height + hdr), (24, 26, 30))
    out.paste(im, (0, hdr))
    d = ImageDraw.Draw(out)
    d.text((16, 12), title, font=label_font(24), fill=(240, 240, 240))
    if sub:
        d.text((16, 40), sub, font=label_font(17), fill=(150, 175, 205))
    out.save(path)
    return path


def stack(out, cells, title, sub, cols, cw=None, ch=None, labels=None):
    imgs = [Image.open(p) for p in cells]
    cw = cw or max(i.width for i in imgs)
    ch = ch or max(i.height for i in imgs)
    rows = (len(imgs) + cols - 1) // cols
    hdr = 68
    sh = Image.new("RGB", (cw * cols, hdr + ch * rows), (250, 250, 250))
    d = ImageDraw.Draw(sh)
    d.rectangle([0, 0, sh.width, hdr], fill=(24, 26, 30))
    d.text((16, 10), title, font=label_font(25), fill=(240, 240, 240))
    d.text((16, 41), sub, font=label_font(17), fill=(150, 175, 205))
    fl = label_font(21)
    for i, im in enumerate(imgs):
        r, c = divmod(i, cols)
        x, y = c * cw, hdr + r * ch
        sh.paste(im, (x, y))
        if labels:
            d.text((x + 12, y + 8), labels[i], font=fl, fill=(110, 135, 170))
        d.rectangle([x, y, x + cw - 1, y + ch - 1], outline=(226, 226, 226))
    sh.save(out)
    print(f"  {out}")
    return out


def main(argv):
    os.makedirs(PREV, exist_ok=True)
    names, args = place.everything()
    demo = argv[0] if argv else "Justine"

    print("rendering:")
    # 1. HEAD-ON, big, first.
    picks = [n for n in ("Justine", "Marlow", "Tom") if n in names] or names[:3]
    cells = [render(os.path.join(PREV, f"_h_{n}.png"), "tag", args[n],
                    HEAD, 1100, 420) for n in picks]
    stack(os.path.join(PREV, "head.png"), cells,
          "HEAD ON  --  camera 0,0,0,0,0,0,0",
          "the letter plane face-on: the clip is behind the bar and crosses no "
          "lettering. x runs UP the glass, so the name is read vertically.",
          1, labels=picks)

    for part, cam, w, h, solid, name, title, sub in [
        ("tag", ISO, 1000, 700, True, "stack",
         f"from an angle  --  \"{demo}\"",
         "the one change from variant 1: the clip curls BACKWARD out of the letter plane"),
        ("print", ISO, 1000, 700, True, "print",
         "print orientation  --  letters face-DOWN",
         "the whole flat part is a first layer; only the clip hangs. 0.08cm3 of support"),
        ("section", SIDE, 1000, 540, False, "section",
         "section through the clip, on the rim",
         "the rim SEATS in the curl (bend_r = glass_t/2) and the arm closes on it along its length"),
        ("onglass", WORN, 950, 720, False, "onglass",
         "on the glass",
         "the name faces the room, hanging down the front"),
    ]:
        p = render(os.path.join(PREV, f"{name}.png"), part, args[demo],
                   cam, w, h, solid)
        caption(p, title, sub)
        print(f"  {p}")

    # 2. the whole set, head-on
    cells = [render(os.path.join(PREV, f"_g_{n}.png"), "tag", args[n],
                    HEAD, 660, 300) for n in names]
    stack(os.path.join(PREV, "all.png"), cells,
          f"glass-name-tag-back  --  {place.FONT} {place.SIZE:g}mm  "
          f"bold +{place.BOLD}  style={place.STYLE}   {len(names)} names",
          "variant 1's flat part exactly, with the clip rotated 90 degrees out "
          "of the letter plane. All head-on.",
          COLS, labels=names)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
