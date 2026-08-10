#!/usr/bin/env python3
"""Composite previews that OpenSCAD cannot make on its own.  Run with `make compare`.

Three of the most useful pictures here are comparisons, and each needs two
images side by side at a common scale:

  compare_top  the model rendered in the same view as the product photo. This
               is the check that the traced aperture actually came out right,
               and it is the one to look at after any re-trace.
  rotate       front / edge-on / back. The slot must appear on ONE flank only;
               seeing it from behind is how the two-free-petals bug was caught.
  sizes        the two candidate base diameters, rescaled to a common mm/pixel
               so the difference is real and not an artefact of --viewall
               fitting each render to its own frame.

OpenSCAD renders each part; the compositing is here.
"""
import os
import subprocess

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
MODEL = os.path.join(HERE, "nozzle.scad")
PREV = os.path.join(HERE, "previews")
PHOTO = os.path.join(HERE, "trace", "birkmann-122.png")
OPENSCAD = os.environ.get("OSCAD", "openscad")

BG = (250, 250, 250)
INK = (30, 30, 30)
SIZES = (23, 18)


def render(out, camera, size, defs=()):
    args = [OPENSCAD, "-o", out, "--render", "--colorscheme=Tomorrow",
            f"--camera={camera}", "--viewall", "--autocenter",
            f"--imgsize={size[0]},{size[1]}"]
    for d in defs:
        args += ["-D", d]
    subprocess.run(args + [MODEL], capture_output=True, text=True, check=True)
    return Image.open(out).convert("RGB")


def strip(images, labels, pad=10, top=25):
    w = sum(i.width for i in images) + pad * (len(images) + 1)
    out = Image.new("RGB", (w, images[0].height + top + 5), BG)
    d = ImageDraw.Draw(out)
    x = pad
    for im, lab in zip(images, labels):
        out.paste(im, (x, top))
        d.text((x + 30, 8), lab, fill=INK)
        x += im.width + pad
    return out


def main():
    os.makedirs(PREV, exist_ok=True)

    # --- rotate: the slot must be on ONE flank ------------------------------
    views = [render(os.path.join(PREV, f"_v{a}.png"), f"0,0,0,78,0,{a},0", (300, 560))
             for a in (0, 90, 180)]
    strip(views, ["0deg - slot facing you", "90deg - edge-on", "180deg - the BACK"]) \
        .save(os.path.join(PREV, "rotate.png"))
    for a in (0, 90, 180):
        os.remove(os.path.join(PREV, f"_v{a}.png"))

    # --- compare_top: model vs the photo it was traced from -----------------
    # The photo's top-down view is the lower half of the source image; this
    # crop is the disc, matched to the tracer's own measurement of it.
    mine = render(os.path.join(PREV, "nozzle_top.png"), "0,0,25,0,0,0,0", (460, 460))
    photo = Image.open(PHOTO).convert("RGB").crop((55, 783, 425, 1153)) \
                 .resize((460, 460), Image.LANCZOS)
    strip([photo, mine], ["photo: real #122, top-down", "model, same view"]) \
        .save(os.path.join(PREV, "compare_top.png"))

    # --- sizes: the two candidates at a COMMON scale ------------------------
    heights, imgs = {}, {}
    for d in SIZES:
        r = subprocess.run([OPENSCAD, "-o", os.path.join(PREV, f"nozzle_d{d}.png"),
                            "--render", "--colorscheme=Tomorrow", "--camera=0,0,0,68,0,20,0",
                            "--viewall", "--autocenter", "--imgsize=420,700",
                            "-D", f"base_d={d}", "-D", 'render_part="nozzle"', MODEL],
                           capture_output=True, text=True, check=True)
        # take the height straight from the model's own echo, not a guess
        line = next(l for l in r.stderr.splitlines() if l.startswith('ECHO: "nozzle '))
        heights[d] = float(line.split(" x ")[1].split(" mm")[0])
        imgs[d] = Image.open(os.path.join(PREV, f"nozzle_d{d}.png")).convert("RGB")

    big = max(SIZES, key=lambda d: heights[d])
    small = [d for d in SIZES if d != big][0]
    k = heights[small] / heights[big]
    a, b = imgs[big], imgs[small]
    b = b.resize((max(1, int(b.width * k)), max(1, int(b.height * k))), Image.LANCZOS)

    out = Image.new("RGB", (a.width + b.width + 60, a.height + 40), BG)
    out.paste(a, (10, 40))
    out.paste(b, (a.width + 40, 40 + a.height - b.height))   # stand them on one line
    d = ImageDraw.Draw(out)
    d.text((90, 14), f"base {big}mm  -  {heights[big]:.1f}mm tall", fill=INK)
    d.text((a.width + 60, 14), f"base {small}mm  -  {heights[small]:.1f}mm tall", fill=INK)
    out.save(os.path.join(PREV, "sizes.png"))

    print("wrote rotate.png, compare_top.png, sizes.png, "
          + ", ".join(f"nozzle_d{d}.png" for d in SIZES))


if __name__ == "__main__":
    main()
