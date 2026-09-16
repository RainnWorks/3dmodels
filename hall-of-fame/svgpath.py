"""Read the contours out of an OpenSCAD 2D SVG export.

OpenSCAD polygonises everything before it writes the file, so the whole
drawing is one <path> made of straight `M x,y L x,y ... z` subpaths, in
millimetres, with SVG's y-down axis. That is easy enough to read directly and
saves pulling in an SVG library.
"""

import re

_NUM = r"-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?"
_PT = re.compile(rf"({_NUM}),({_NUM})")


def contours(svg_path):
    """[[(x, y), ...], ...] in millimetres, y still pointing down."""
    text = open(svg_path).read()
    out = []
    for d in re.findall(r'<path[^>]*\sd="([^"]*)"', text, re.S):
        for sub in d.split("M")[1:]:
            pts = [(float(a), float(b)) for a, b in _PT.findall(sub)]
            if len(pts) >= 3:
                out.append(pts)
    return out


def bbox(cs):
    """(xmin, ymin, xmax, ymax) over every contour."""
    xs = [x for c in cs for x, _ in c]
    ys = [y for c in cs for _, y in c]
    return min(xs), min(ys), max(xs), max(ys)


def raster(cs, px_per_mm, pad_mm=0.0):
    """Fill the contours with the even-odd rule -> (bool mask, origin_mm).

    Even-odd is just XOR, so each contour can be drawn on its own and
    accumulated; holes fall out for free and no nesting test is needed.
    """
    import numpy as np
    from PIL import Image, ImageDraw

    x0, y0, x1, y1 = bbox(cs)
    x0 -= pad_mm; y0 -= pad_mm; x1 += pad_mm; y1 += pad_mm
    w = max(1, int(round((x1 - x0) * px_per_mm)))
    h = max(1, int(round((y1 - y0) * px_per_mm)))

    acc = np.zeros((h, w), dtype=bool)
    for c in cs:
        img = Image.new("1", (w, h), 0)
        ImageDraw.Draw(img).polygon(
            [((x - x0) * px_per_mm, (y - y0) * px_per_mm) for x, y in c], fill=1
        )
        acc ^= np.array(img, dtype=bool)
    return acc, (x0, y0)
