#!/usr/bin/env python3
"""Two questions the slicer will not answer until it is too late:

  1. Is each exported word ONE solid body?  Script letters that only *look*
     joined come off the bed as loose strokes, and lining those up on a mirror
     by eye is miserable.  Checked on the meshes themselves.

  2. How thin does the lettering actually get?  Measured by eroding the 2D
     artwork: shrink it evenly and watch when a shape first snaps in two (a
     narrow neck) or disappears (a thin limb).  The radius at which that
     happens is half the narrowest stroke.

Usage: check.py export/template.svg export/*.stl
"""

import sys

import numpy as np
from scipy import ndimage

import svgpath

NOZZLE = 0.4           # mm -- what the stroke width is judged against
BED = (256.0, 256.0)   # mm -- Bambu X1/P1/A1
MARGIN = 4.0           # mm -- keep clear of the plate edge
SLIVER = 0.01          # mm3 -- below this a "body" is float32 noise, not a piece
PX_PER_MM = 8.0        # erosion raster; 0.125 mm per pixel
R_MAX = 4.0            # stop looking once strokes are comfortably thick


def min_stroke(svg):
    """Narrowest stroke in the artwork, in mm (None if nothing is that thin)."""
    cs = svgpath.contours(svg)
    mask, _ = svgpath.raster(cs, PX_PER_MM, pad_mm=2.0)

    # Distance from every solid pixel to the nearest edge. Eroding by r is then
    # just `dist > r * PX_PER_MM`, so the whole sweep is one transform.
    dist = ndimage.distance_transform_edt(mask)
    lab0, n0 = ndimage.label(mask)
    if n0 == 0:
        return None

    for r in np.arange(0.05, R_MAX, 0.05):
        eroded = dist > r * PX_PER_MM
        lab, _ = ndimage.label(eroded)
        for k in range(1, n0 + 1):
            piece = lab[lab0 == k]
            survivors = set(np.unique(piece)) - {0}
            if len(survivors) != 1:          # vanished (0) or split (>1)
                return round(2 * float(r), 2)
    return None


def bodies(stl):
    """(separate solid bodies, bounding box mm, best-rotated footprint mm, angle)."""
    import trimesh
    from scipy.spatial import ConvexHull

    m = trimesh.load(stl, force="mesh")
    size = m.bounds[1] - m.bounds[0]

    # Binary STL stores float32, which is coarse enough at 250 mm that the odd
    # triangle stops sharing a vertex with its neighbour and falls out as a
    # zero-volume shard. Slicers weld those straight back on; only bodies with
    # actual volume in them count as separate pieces.
    solids = [p for p in m.split(only_watertight=False) if abs(p.volume) > SLIVER]

    # A long word laid flat can be 250 mm across yet drop onto the plate happily
    # once it is turned. Spin the outline and keep the angle whose bounding
    # square is smallest -- that is the orientation to use in the slicer.
    pts = m.vertices[:, :2]
    pts = pts[ConvexHull(pts).vertices]
    best = (float("inf"), 0.0, None)
    for deg in np.arange(0, 90, 0.5):
        t = np.radians(deg)
        r = pts @ np.array([[np.cos(t), -np.sin(t)], [np.sin(t), np.cos(t)]])
        wh = r.max(axis=0) - r.min(axis=0)
        if max(wh) < best[0]:
            best = (max(wh), deg, wh)
    return len(solids), size, best[2], best[1]


def main(argv):
    svg, stls = argv[1], argv[2:]
    ok = True

    thin = min_stroke(svg)
    if thin is None:
        print(f"stroke   >= {2 * R_MAX:.1f} mm everywhere")
    else:
        walls = thin / NOZZLE
        flag = "" if walls >= 2.0 else "  <-- TOO THIN"
        print(f"stroke   narrowest {thin:.2f} mm ({walls:.1f} x {NOZZLE} nozzle){flag}")
        ok &= walls >= 2.0

    print(f"\nbed {BED[0]:.0f} x {BED[1]:.0f} mm, margin wanted {MARGIN:.0f} mm each side")
    for stl in stls:
        n, size, rot, deg = bodies(stl)
        name = stl.rsplit("/", 1)[-1]
        room = [BED[0] - 2 * MARGIN, BED[1] - 2 * MARGIN]
        flat = size[0] <= room[0] and size[1] <= room[1]
        turned = rot[0] <= room[0] and rot[1] <= room[1]

        how = ("flat" if flat else
               f"turned {deg:.0f} deg -> {rot[0]:.0f} x {rot[1]:.0f} mm" if turned else
               "WILL NOT FIT -- split it")
        note = "" if n == 1 else f"  <-- {n} LOOSE PIECES"
        print(f"{name:<12} {size[0]:6.1f} x {size[1]:5.1f} x {size[2]:4.1f} mm"
              f"   {n} body{'' if n == 1 else 'ies'}   {how}{note}")
        ok &= n == 1 and (flat or turned)

    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
