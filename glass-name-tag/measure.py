#!/usr/bin/env python3
"""Measure where each name's INK actually is, and cache it.

The whole model turns on one number per name: how far the deepest glyph falls
below the baseline. The font will tell you its `descent` and that number is a
lie -- not conservatively, in both directions:

    Great Vibes, size 15, the font says descent = 6.1mm for every string.
    "Jenny"  really reaches 5.7mm below the baseline.
    "Tom"    really reaches 1.4mm.

Trust the metric and short names float clear of the spine and print as loose
letters; hand-tune an offset to fix that (which is what the original model's
users do, "-3.0", "-5.5 to -7") and the long descenders punch through the
spine into the glass. Both failures are the same missing measurement.

So measure it. The authority is OpenSCAD itself -- render the letters alone
and read the mesh's bounding box -- because that is the same text shaper that
will render the final part. A Python font library would be a second opinion
about a different engine's output.

Results are cached in ink.json, keyed by everything that can move the ink.
"""
import json
import os
import struct
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
MODEL = os.path.join(HERE, "nametag.scad")
CACHE = os.path.join(HERE, "ink.json")
OPENSCAD = os.environ.get("OSCAD", "openscad")

# nametag.scad places the text origin at x = clip_margin when ink_x0 = 0.
CLIP_MARGIN = 4.0


def stl_bbox(path):
    """(xmin, ymin, xmax, ymax) of a binary STL, or None if it has no facets."""
    with open(path, "rb") as fh:
        d = fh.read()
    if len(d) < 84:
        return None
    n = struct.unpack("<I", d[80:84])[0]
    if n == 0:
        return None
    xs, ys = [], []
    for i in range(n):
        off = 84 + i * 50 + 12
        for v in range(3):
            x, y, _ = struct.unpack("<3f", d[off + v * 12: off + v * 12 + 12])
            xs.append(x)
            ys.append(y)
    return min(xs), min(ys), max(xs), max(ys)


def model_sig():
    """Short hash of nametag.scad.

    The cached values are geometry -- ink extents, strut endpoints in tag
    coordinates -- so ANY change to the model can invalidate them. Keying on
    the file's contents over-invalidates and costs a few seconds; the
    alternative cost us struts that no longer reached their letters, which
    renders perfectly and prints as loose dots.
    """
    import hashlib
    with open(os.path.join(HERE, "nametag.scad"), "rb") as fh:
        return hashlib.sha1(fh.read()).hexdigest()[:10]


def key(name, font, size, bold, spacing):
    return f"{name}|{font}|{size}|{bold}|{spacing}|{model_sig()}"


def measure(name, font="Great Vibes", size=15, bold=0.0, spacing=1.0, cache=None):
    """Real ink extents relative to the baseline origin, in mm.

    Returns {"drop", "rise", "x0", "x1"} where `drop` is POSITIVE mm below the
    baseline. Renders with ink_drop=0 and glass_gap=0, which puts the baseline
    exactly on y=0, so the mesh bbox reads off directly.
    """
    k = key(name, font, size, bold, spacing)
    if cache is not None and k in cache:
        return cache[k]

    out = os.path.join(HERE, ".measure.stl")
    r = subprocess.run(
        [OPENSCAD, "-o", out, "--export-format", "binstl",
         "--enable=textmetrics",
         "-D", f'render_part="text"',
         "-D", f'name="{name}"',
         "-D", f'font="{font}"',
         "-D", f"txt_size={size}",
         "-D", f"bold={bold}",
         "-D", f"spacing={spacing}",
         "-D", "ink_drop=0", "-D", "glass_gap=0", "-D", "ink_x0=0",
         MODEL],
        capture_output=True, text=True)
    if not os.path.exists(out):
        raise RuntimeError(f"render failed for {name!r}:\n{r.stderr}")
    bb = stl_bbox(out)
    os.remove(out)
    if bb is None:
        raise RuntimeError(f"{name!r} rendered no geometry -- is font {font!r} installed?")
    xmin, ymin, xmax, ymax = bb

    res = {
        "drop": round(-ymin, 4),               # positive = below the baseline
        "rise": round(ymax, 4),
        "x0":   round(xmin - CLIP_MARGIN, 4),
        "x1":   round(xmax - CLIP_MARGIN, 4),
    }
    if cache is not None:
        cache[k] = res
    return res


def load_cache():
    if os.path.exists(CACHE):
        with open(CACHE) as fh:
            return json.load(fh)
    return {}


def save_cache(cache):
    with open(CACHE, "w") as fh:
        json.dump(cache, fh, indent=1, sort_keys=True)


def scad_args(name, ink):
    """The -D flags that place this name correctly."""
    return ["-D", f'name="{name}"',
            "-D", f"ink_drop={ink['drop']}",
            "-D", f"ink_x0={ink['x0']}",
            "-D", f"ink_x1={ink['x1']}"]


def main(argv):
    font = os.environ.get("FONT", "Great Vibes")
    size = float(os.environ.get("SIZE", 15))
    bold = float(os.environ.get("BOLD", 0.0))
    names = argv or ["Tom", "Alice", "Jenny", "Poppy", "Sophie", "George"]

    cache = load_cache()
    # What the font claims, once -- it is the same for every string.
    print(f"font={font!r} size={size} bold={bold}\n")
    print(f"{'name':14} {'ink drop':>9} {'ink rise':>9} {'ink width':>10}")
    print("-" * 46)
    drops = []
    for n in names:
        ink = measure(n, font, size, bold, cache=cache)
        drops.append(ink["drop"])
        print(f"{n:14} {ink['drop']:9.2f} {ink['rise']:9.2f} {ink['x1']-ink['x0']:10.2f}")
    save_cache(cache)
    print("-" * 46)
    print(f"{'spread':14} {min(drops):9.2f} .. {max(drops):.2f}"
          f"   ({max(drops)-min(drops):.2f}mm of variation the metric hides)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
