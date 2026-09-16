#!/usr/bin/env python3
"""Shape-aware plate packing: nest the real silhouettes, with rotation.

`plate.py` packs bounding boxes into shelves. For these tags that wastes most
of the plate, because a script name is mostly air -- its bounding box is 84 x
30mm and its ink covers maybe a third of that. Two tags turned 180 degrees to
each other interlock: the ascenders of one sit in the gaps above the bar of the
next. A rectangle packer cannot see that and never will.

So pack the actual outlines instead:

  1. rasterise each tag's footprint (all triangles projected to XY),
  2. keep a running "occupied" mask, dilated by the clearance,
  3. for every rotation, FFT-correlate the candidate against occupied -- that
     gives the overlap count for EVERY offset at once, and any zero is a legal
     placement. Take the lowest, then leftmost.

The FFT is what makes it tractable: testing offsets one at a time in Python is
~10^9 array operations per tag, correlating is one transform.

Clearance is enforced by dilating the occupied mask, not by trusting the
packer's arithmetic, and the result is re-checked against the raw masks at the
end -- an overlap here means two tags fused on the plate.
"""
import json
import math
import os
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy.signal import fftconvolve

import bridges

HERE = os.path.dirname(os.path.abspath(__file__))
OPENSCAD = os.environ.get("OSCAD", "openscad")

BED = float(os.environ.get("BED", 256))
MARGIN = float(os.environ.get("MARGIN", 8))
# 2.5mm. Flat parts with full bed contact need no thermal separation; this is
# purely so they snip apart cleanly and a stray blob cannot bridge two tags.
GAP = float(os.environ.get("GAP", 2.5))
PITCH = float(os.environ.get("PITCH", 0.6))    # raster cell, mm
# 45-degree increments, not 90. The extra four are what fit the 33rd tag: a
# name turned 45 slots into the triangular gap left between two turned 90.
ANGLES = [int(a) for a in os.environ.get(
    "ANGLES", "0,45,90,135,180,225,270,315").split(",")]


def footprint(path, angle, pitch=PITCH):
    """Binary mask of the tag's outline, rotated, snug to its bounding box.

    Returns (mask, x0, y0) where x0/y0 are the rotated geometry's bbox corner
    in mm -- what a translate() has to cancel to put the part where the packer
    decided.
    """
    tris = bridges.load_tris(path)[:, :, :2]
    if angle:
        c, s = math.cos(math.radians(angle)), math.sin(math.radians(angle))
        R = np.array([[c, -s], [s, c]])
        tris = tris @ R.T
    x0, y0 = tris.reshape(-1, 2).min(0)
    x1, y1 = tris.reshape(-1, 2).max(0)
    w = max(1, int(math.ceil((x1 - x0) / pitch)) + 1)
    h = max(1, int(math.ceil((y1 - y0) / pitch)) + 1)
    img = Image.new("1", (w, h), 0)
    d = ImageDraw.Draw(img)
    px = (tris - [x0, y0]) / pitch
    for t in px:
        d.polygon([tuple(p) for p in t], fill=1)
    return np.array(img, dtype=np.float32), float(x0), float(y0)


def disc(r_mm, pitch=PITCH):
    r = max(1, int(round(r_mm / pitch)))
    y, x = np.ogrid[-r:r + 1, -r:r + 1]
    return ((x * x + y * y) <= r * r).astype(np.float32)


def place(occupied, mask):
    """Lowest-then-leftmost offset where `mask` does not touch `occupied`."""
    if mask.shape[0] > occupied.shape[0] or mask.shape[1] > occupied.shape[1]:
        return None
    # correlation: overlap count at every offset, in one transform
    hits = fftconvolve(occupied, mask[::-1, ::-1], mode="valid")
    free = np.argwhere(hits < 0.5)
    if len(free) == 0:
        return None
    # np.argwhere gives (row, col) = (y, x); lowest y first, then lowest x
    order = np.lexsort((free[:, 1], free[:, 0]))
    return tuple(free[order[0]])


def pack(items, bed=BED, margin=MARGIN, gap=GAP, pitch=PITCH, angles=ANGLES):
    """items = [(name, stl_path)] -> [[(name, angle, x_mm, y_mm)], ...] per plate."""
    usable = bed - 2 * margin
    n = int(math.ceil(usable / pitch))
    grow = disc(gap, pitch)

    # pre-rasterise every rotation once
    shapes = {}
    for name, path in items:
        for a in angles:
            shapes[(name, a)] = footprint(path, a, pitch)
    area = {name: shapes[(name, angles[0])][0].sum() for name, _ in items}

    todo = sorted((nm for nm, _ in items), key=lambda nm: -area[nm])
    plates = []
    while todo:
        occupied = np.zeros((n, n), dtype=np.float32)
        placed, left = [], []
        for name in todo:
            best = None
            for a in angles:
                m, x0, y0 = shapes[(name, a)]
                pos = place(occupied, m)
                if pos is None:
                    continue
                # prefer the lowest placement; break ties by leftmost
                if best is None or (pos[0], pos[1]) < (best[0][0], best[0][1]):
                    best = (pos, a, m, x0, y0)
            if best is None:
                left.append(name)
                continue
            (r, c), a, m, x0, y0 = best
            # Dilate with mode="full", NOT "same". "same" crops the result to
            # the mask's own bounding box, so the grown halo is chopped off
            # exactly where it was supposed to hold the next tag away -- the
            # clearance silently became "somewhere under 2mm" instead of GAP.
            k = grow.shape[0] // 2
            halo = fftconvolve(m, grow, mode="full") > 0.5
            r0, c0 = r - k, c - k
            # clip against the plate edges
            sr, sc = max(0, -r0), max(0, -c0)
            er = min(halo.shape[0], occupied.shape[0] - r0)
            ec = min(halo.shape[1], occupied.shape[1] - c0)
            if er > sr and ec > sc:
                tgt = occupied[r0 + sr:r0 + er, c0 + sc:c0 + ec]
                np.maximum(tgt, halo[sr:er, sc:ec], out=tgt)
            placed.append((name, a, margin + c * pitch - x0, margin + r * pitch - y0))
        if not placed:
            raise SystemExit(f"cannot place: {left[:3]}")
        plates.append(placed)
        todo = left
    return plates


def verify(plates, items, gap=GAP, pitch=PITCH, bed=BED):
    """Re-check the finished layout against the raw outlines."""
    paths = dict(items)
    bad = []
    for pi, plate in enumerate(plates, 1):
        masks = []
        for name, a, x, y in plate:
            m, x0, y0 = footprint(paths[name], a, pitch)
            r = int(round((y + y0 - MARGIN) / pitch))
            c = int(round((x + x0 - MARGIN) / pitch))
            masks.append((name, m, r, c))
            if (x + x0 < -1e-6 or y + y0 < -1e-6
                    or x + x0 + m.shape[1] * pitch > bed
                    or y + y0 + m.shape[0] * pitch > bed):
                bad.append(f"plate{pi} {name} off the bed")
        for i in range(len(masks)):
            for j in range(i + 1, len(masks)):
                n1, m1, r1, c1 = masks[i]
                n2, m2, r2, c2 = masks[j]
                r0, cc0 = max(r1, r2), max(c1, c2)
                r9 = min(r1 + m1.shape[0], r2 + m2.shape[0])
                c9 = min(c1 + m1.shape[1], c2 + m2.shape[1])
                if r9 <= r0 or c9 <= cc0:
                    continue
                a1 = m1[r0 - r1:r9 - r1, cc0 - c1:c9 - c1]
                a2 = m2[r0 - r2:r9 - r2, cc0 - c2:c9 - c2]
                if np.any((a1 > 0) & (a2 > 0)):
                    bad.append(f"plate{pi} {n1} overlaps {n2}")
    return bad


def emit(plates, items, outdir, prefix, rel):
    """Write plateN.scad/3mf/png for the packed layout."""
    paths = dict(items)
    for pi, plate in enumerate(plates, 1):
        lines = [f"// {prefix} plate {pi} of {len(plates)} -- GENERATED by nest.py",
                 f"// {len(plate)} tags, shape-nested with rotation", ""]
        for name, a, x, y in plate:
            lines.append(f'translate([{x:.3f}, {y:.3f}, 0]) rotate([0, 0, {a}])'
                         f' import("{rel(name)}");')
        scad = os.path.join(outdir, f"{prefix}{pi}.scad")
        with open(scad, "w") as fh:
            fh.write("\n".join(lines) + "\n")
        subprocess.run([OPENSCAD, "-o", os.path.join(outdir, f"{prefix}{pi}.3mf"),
                        "--enable=lazy-union", scad], capture_output=True)
        subprocess.run([OPENSCAD, "-o", os.path.join(outdir, f"{prefix}{pi}.stl"),
                        "--export-format", "binstl", scad], capture_output=True)
        png = os.path.join(HERE, "previews", f"{prefix}{pi}.png")
        subprocess.run([OPENSCAD, "-o", png, "--camera=0,0,0,0,0,0,0", "--viewall",
                        "--autocenter", "--render", "--colorscheme=Tomorrow",
                        "--imgsize=1000,1000", scad], capture_output=True)


def main():
    src = os.environ.get("SRC", os.path.join(HERE, "export", "bite0.4"))
    out = os.environ.get("OUT", os.path.join(HERE, "export"))
    prefix = os.environ.get("PREFIX", "nest")
    # NAMES="A,B,C" packs just those, for a one-off plate
    names = ([n.strip() for n in os.environ["NAMES"].split(",") if n.strip()]
             if "NAMES" in os.environ
             else [l.strip() for l in open(os.path.join(HERE, "names.txt")) if l.strip()])
    items = [(n, os.path.join(src, f"{n}.stl")) for n in names]
    missing = [n for n, p in items if not os.path.exists(p)]
    if missing:
        raise SystemExit(f"missing exports: {missing[:5]}")

    print(f"nesting {len(items)} tags, bed {BED:g}mm, {GAP:g}mm clearance, "
          f"{PITCH:g}mm raster, rotations {ANGLES}")
    plates = pack(items)
    usable = BED - 2 * MARGIN
    for pi, plate in enumerate(plates, 1):
        turned = sum(1 for _, a, _, _ in plate if a)
        print(f"  plate {pi}: {len(plate):2d} tags ({turned} turned)")
    bad = verify(plates, items)
    print("  verify:", "; ".join(bad) if bad else "no overlaps, all on the bed")
    if bad:
        raise SystemExit(1)
    rel = os.path.relpath(src, out)
    emit(plates, items, out, prefix, lambda n: f"{rel}/{n}.stl")
    print(f"\nwrote {prefix}1..{len(plates)}.3mf in {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
