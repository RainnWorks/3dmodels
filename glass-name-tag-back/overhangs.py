#!/usr/bin/env python3
"""Which way up does this print?  Run with `make overhangs`.

"No supports needed" is a claim about geometry, so measure it. This reads the
exported mesh, rolls it into each candidate print orientation, and reports what
each one asks of the printer.

Two numbers, and they are easy to confuse (the ruffle-nozzle README makes the
same point about its thread flanks):

  ANGLE      of a downward-facing face, from horizontal. 0 is a flat ceiling.
             On its own this is a poor statistic.

  UNSUPPORTED how much material in a layer has nothing under it. This is the
             one that decides. A 0 deg face 0.2mm wide bridges without noticing
             and never appears here; the same face 20mm wide is support.

The unsupported figure is computed the way a slicer would see it: rasterise the
solid on a `pitch` grid, and for each layer count the material that is not
within `reach` of the layer below. `reach` = layer height is the usual 45 deg
rule. The first layer sits on the bed and is supported by definition.

  python3 overhangs.py                 # the default name, every orientation
  python3 overhangs.py Marlow Tom      # other names
"""
import math
import os
import subprocess
import sys

import numpy as np

import place
from mesh import load_tris

HERE = os.path.dirname(os.path.abspath(__file__))
MODEL = place.MODEL
EXPDIR = os.path.join(HERE, "export")
OPENSCAD = os.environ.get("OSCAD", "openscad")

PITCH = 0.2        # raster cell, mm -- one Bambu 0.4mm nozzle layer
LAYER = 0.2        # layer height, mm
REACH = 0.2        # how far a layer may hang past the one below it (45 deg)
LEDGE_OK = 1.5     # how far it may reach out over air before it needs support

GREEN, RED, YELLOW, DIM, OFF = ("\033[32m", "\033[31m", "\033[33m",
                                "\033[2m", "\033[0m")


def rot(axis, deg):
    c, s = math.cos(math.radians(deg)), math.sin(math.radians(deg))
    if axis == "x":
        return np.array([[1, 0, 0], [0, c, -s], [0, s, c]])
    if axis == "y":
        return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])
    return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]])


# The model is built as worn: X up the glass (the name runs along it), Y along
# the rim, Z radial and out of the glass. The letters are a flat silhouette at
# z = 0..thick; only the clip leaves that plane.
#
# Only the first two keep the letters FLAT on the bed. The other three stand
# thin script strokes on edge, which is not an option here whatever the
# overhang numbers say -- they are measured so the comparison is on the record
# rather than asserted.
ORIENTS = [
    ("letters DOWN  faces on the bed, clip standing up", rot("x", 180)),
    ("letters UP    backs on the bed, clip underneath", np.eye(3)),
    ("as worn       on edge, name upright, clip on top", rot("y", -90)),
    ("inverted      on edge, name upside down", rot("y", 90)),
    ("on its side   on edge, bar's edge on the bed", rot("x", 90)),
]


# -----------------------------------------------------------------------------
#  Rasterise
# -----------------------------------------------------------------------------
def occupancy(tris, pitch, layer):
    """Solid occupancy as a boolean array [iz, iy, ix].

    Casts a ray along +x through the centre of every (y, z) cell and fills
    between crossings. Exact for a closed mesh, and about a second -- trimesh's
    voxeliser takes 75 on the same part, which is too slow to run five times.
    """
    lo = tris.reshape(-1, 3).min(0) - pitch
    hi = tris.reshape(-1, 3).max(0) + pitch
    nx = int(math.ceil((hi[0] - lo[0]) / pitch))
    ny = int(math.ceil((hi[1] - lo[1]) / pitch))
    nz = int(math.ceil((hi[2] - lo[2]) / layer))
    ys = lo[1] + (np.arange(ny) + 0.5) * pitch
    zs = lo[2] + (np.arange(nz) + 0.5) * layer

    # For every triangle, the (y, z) cell centres inside its YZ projection, and
    # the x where the ray pierces it.
    P = tris[:, :, [1, 2]]                       # project to (y, z)
    A, B, C = P[:, 0], P[:, 1], P[:, 2]
    d = ((B[:, 1] - C[:, 1]) * (A[:, 0] - C[:, 0])
         + (C[:, 0] - B[:, 0]) * (A[:, 1] - C[:, 1]))
    live = np.abs(d) > 1e-12                     # edge-on triangles pierce nothing

    hits_col, hits_x = [], []
    for t in np.nonzero(live)[0]:
        p = P[t]
        y0 = max(0, int((p[:, 0].min() - lo[1]) / pitch))
        y1 = min(ny, int((p[:, 0].max() - lo[1]) / pitch) + 2)
        z0 = max(0, int((p[:, 1].min() - lo[2]) / layer))
        z1 = min(nz, int((p[:, 1].max() - lo[2]) / layer) + 2)
        if y1 <= y0 or z1 <= z0:
            continue
        gy, gz = np.meshgrid(ys[y0:y1], zs[z0:z1])
        # barycentric, in the (y, z) projection
        l1 = ((p[1, 1] - p[2, 1]) * (gy - p[2, 0])
              + (p[2, 0] - p[1, 0]) * (gz - p[2, 1])) / d[t]
        l2 = ((p[2, 1] - p[0, 1]) * (gy - p[2, 0])
              + (p[0, 0] - p[2, 0]) * (gz - p[2, 1])) / d[t]
        l3 = 1.0 - l1 - l2
        inside = (l1 >= 0) & (l2 >= 0) & (l3 >= 0)
        if not inside.any():
            continue
        x = l1 * tris[t, 0, 0] + l2 * tris[t, 1, 0] + l3 * tris[t, 2, 0]
        iz, iy = np.nonzero(inside)
        hits_col.append((iz + z0) * ny + (iy + y0))
        hits_x.append(x[inside])

    occ = np.zeros((nz, ny, nx), dtype=bool)
    if not hits_col:
        return occ, pitch, layer
    col = np.concatenate(hits_col)
    xh = np.concatenate(hits_x)
    order = np.lexsort((xh, col))
    col, xh = col[order], xh[order]
    # crossings come in pairs: [enter, exit]
    flat = occ.reshape(-1, nx)
    starts = np.searchsorted(col, np.arange(ny * nz), "left")
    ends = np.searchsorted(col, np.arange(ny * nz), "right")
    for c in np.nonzero(ends > starts)[0]:
        xs = xh[starts[c]:ends[c]]
        for i in range(0, len(xs) - 1, 2):
            a = int(math.ceil((xs[i] - lo[0]) / pitch - 0.5))
            b = int(math.ceil((xs[i + 1] - lo[0]) / pitch - 0.5))
            if b > a:
                flat[c, max(0, a):b] = True
    return occ, pitch, layer


def unsupported(occ, pitch, layer, reach=REACH):
    """How much of each layer hangs past the one below, and how far out.

    Returns {area, worst_layer, worst_z, ledge, ledge_z, bed}.

    `ledge` is the one that decides. It is the furthest any unsupported cell
    sits from the nearest cell that IS supported -- i.e. how far the printer is
    being asked to reach out over air. Raised lettering on a vertical wall
    scores a nonzero AREA (every stroke's top edge is a `relief`-wide ledge)
    but a tiny LEDGE, and it bridges. A plate held up by nothing scores both.
    """
    from scipy import ndimage
    r = int(round(reach / pitch))
    k = np.ones((2 * r + 1, 2 * r + 1), bool) if r > 0 else np.ones((1, 1), bool)
    out = {"area": 0.0, "worst_layer": 0.0, "worst_z": 0.0,
           "ledge": 0.0, "ledge_z": 0.0, "bed": 0.0}
    # The first layer with anything in it IS the bed layer: supported by
    # definition, however wide it is.
    first = next((i for i in range(occ.shape[0]) if occ[i].any()), None)
    if first is None:
        return out
    out["bed"] = float(np.count_nonzero(occ[first])) * pitch * pitch
    prev = occ[first]
    for i in range(first + 1, occ.shape[0]):
        cur = occ[i]
        if not cur.any():
            prev = cur
            continue
        held = ndimage.binary_dilation(prev, k) if r else prev
        un = cur & ~held
        n = np.count_nonzero(un)
        if n:
            z = (i - first) * layer
            a = float(n) * pitch * pitch
            out["area"] += a
            if a > out["worst_layer"]:
                out["worst_layer"], out["worst_z"] = a, z
            # distance from each unheld cell to the nearest held one
            d = ndimage.distance_transform_edt(~held, sampling=pitch)
            far = float(d[un].max())
            if far > out["ledge"]:
                out["ledge"], out["ledge_z"] = far, z
        prev = cur
    return out


def facets(tris, nrm, zmin):
    """Downward-facing area by angle band, and the worst near-flat ledge."""
    down = nrm[:, 2] < -1e-6
    bands = {}
    widest = 0.0
    for i in np.nonzero(down)[0]:
        v = tris[i]
        if v[:, 2].max() <= zmin + 1e-3:          # the face lying on the bed
            continue
        u, w = v[1] - v[0], v[2] - v[0]
        area = 0.5 * np.linalg.norm(np.cross(u, w))
        if area < 1e-9:
            continue
        deg = math.degrees(math.asin(min(1.0, -nrm[i, 2] / max(1e-12, np.linalg.norm(nrm[i])))))
        bands[min(80, int(deg // 10) * 10)] = bands.get(min(80, int(deg // 10) * 10), 0) + area
        if deg >= 60:
            span = max(v[:, 0].max() - v[:, 0].min(), v[:, 1].max() - v[:, 1].min())
            widest = max(widest, span)
    return bands, widest


# -----------------------------------------------------------------------------
def export(args, out, part="tag"):
    r = subprocess.run(
        [OPENSCAD, "-o", out, "--export-format", "binstl", "--enable=textmetrics",
         "-D", f'part="{part}"'] + args + [MODEL], capture_output=True, text=True)
    if not os.path.exists(out):
        raise RuntimeError(f"export failed:\n{r.stderr[-800:]}")
    return out


def support(occ, pitch, layer, reach=REACH):
    """How much support material the unsupported bits would need, and where it
    lands.

    For every column that has something hanging in it, walk down from the
    lowest unsupported cell to the first solid beneath -- the bed, or the back
    of the part. That column of air is what the slicer has to fill.

    Returns {vol_mm3, on_bed_mm2, on_part_mm2}. `on_part` is the interesting
    one: support that lands on the tag leaves a mark, and it matters entirely
    WHICH face it marks.
    """
    from scipy import ndimage
    r = int(round(reach / pitch))
    k = np.ones((2 * r + 1, 2 * r + 1), bool) if r > 0 else np.ones((1, 1), bool)
    nz = occ.shape[0]
    first = next((i for i in range(nz) if occ[i].any()), None)
    if first is None:
        return {"vol_mm3": 0.0, "on_bed_mm2": 0.0, "on_part_mm2": 0.0}

    need = np.zeros_like(occ)
    prev = occ[first]
    for i in range(first + 1, nz):
        cur = occ[i]
        if cur.any():
            need[i] = cur & ~ndimage.binary_dilation(prev, k)
        prev = cur

    cells, on_bed, on_part = 0, 0, 0
    ys, xs = np.nonzero(need.any(axis=0))
    for y, x in zip(ys, xs):
        col_need, col_occ = need[:, y, x], occ[:, y, x]
        L = int(np.argmax(col_need))
        below = np.nonzero(col_occ[:L])[0]
        b = int(below[-1]) if len(below) else first - 1
        cells += max(0, L - 1 - b)
        if len(below):
            on_part += 1
        else:
            on_bed += 1
    return {"vol_mm3": cells * pitch * pitch * layer,
            "on_bed_mm2": on_bed * pitch * pitch,
            "on_part_mm2": on_part * pitch * pitch}


def study(name, args):
    os.makedirs(EXPDIR, exist_ok=True)
    stl = export(args, os.path.join(EXPDIR, f"{name}.stl"))
    tris0, nrm0 = load_tris(stl)

    print(f"\n{name}   {len(tris0)} facets, "
          f"{tris0.reshape(-1,3).max(0)[0]-tris0.reshape(-1,3).min(0)[0]:.1f}mm wide")
    print(f"  grid {PITCH}mm, layer {LAYER}mm, a layer may hang {REACH}mm "
          f"past the one below (45 deg)\n")
    print(f"  {'orientation':50} {'bed':>8} {'unsupported':>12} "
          f"{'reach':>8} {'support':>10}   letters")
    print("  " + "-" * 112)

    rows = []
    for label, R in ORIENTS:
        tris = tris0 @ R.T
        nrm = nrm0 @ R.T
        tris = tris - np.array([0, 0, tris[:, :, 2].min()])
        occ, p, l = occupancy(tris, PITCH, LAYER)
        u = unsupported(occ, p, l)
        u.update(support(occ, p, l))
        u["tall"] = float(tris[:, :, 2].max())
        u["bands"], u["facet_ledge"] = facets(tris, nrm, 0.0)
        u["label"] = label
        rows.append(u)
        ok = u["ledge"] <= LEDGE_OK
        col = GREEN if ok else RED
        flat = label.startswith("letters")
        print(f"  {label:50} {u['bed']:6.0f}mm2 {u['area']:9.1f}mm2 "
              f"{col}{u['ledge']:6.2f}mm{OFF} {u['vol_mm3']/1000:8.2f}cm3   "
              + (f"{GREEN}flat on the bed{OFF}" if flat
                 else f"{RED}on edge -- not an option{OFF}"))

    # Thin script strokes cannot be printed as vertical walls, so the choice is
    # only ever between the two flat ones; among those, least support wins.
    flat = [r for r in rows if r["label"].startswith("letters")]
    best = min(flat, key=lambda r: r["vol_mm3"])
    print(f"\n  {DIM}reach = how far the printer is asked to stick out over air. "
          f"Under {LEDGE_OK}mm it bridges.{OFF}")
    print(f"  {DIM}support = the volume of air a slicer would have to fill "
          f"(envelope, not the sparse material).{OFF}")
    print(f"  -> {GREEN}{best['label']}{OFF}   "
          f"{best['vol_mm3']/1000:.2f}cm3 of support envelope, landing on "
          f"{best['on_bed_mm2']:.0f}mm2 of bed and {best['on_part_mm2']:.0f}mm2 "
          f"of the part")

    print("\n  downward-facing surfaces in that orientation:")
    total = sum(best["bands"].values()) or 1
    for lo in sorted(best["bands"]):
        print(f"     {lo:2d}-{lo+10:2d} deg from horizontal  {best['bands'][lo]:7.1f} mm2  "
              + "#" * int(36 * best["bands"][lo] / total))
    print(f"     unsupported area {best['area']:.1f}mm2, worst single layer "
          f"{best['worst_layer']:.1f}mm2 at z={best['worst_z']:.1f}mm, "
          f"reaching {best['ledge']:.2f}mm")
    return rows


def trade(name, args, lens=(6, 10, 14, 18, 22, 26)):
    """What does the sprung arm cost?

    The arm is the whole of the unsupported area, and it is also the spring:
    variant 1 closes the jaw from `jaw_root` to `jaw` over `spring_len`, so a
    shorter arm has to converge faster and is stiffer. Both ends of that trade
    are measured here rather than argued.
    """
    print(f"\n{name}: what the sprung arm costs\n")
    print(f"  {'spring_len':>11} {'support':>10} {'unsupported':>12} "
          f"{'reach':>8} {'grip length':>12}")
    print("  " + "-" * 58)
    R = dict(ORIENTS)["letters DOWN  faces on the bed, clip standing up"]
    tmp = os.path.join(EXPDIR, ".trade.stl")
    for L in lens:
        extra = ["-D", f"spring_len={L}"]
        r = subprocess.run(
            [OPENSCAD, "-o", tmp, "--export-format", "binstl", "--enable=textmetrics",
             "-D", 'part="tag"'] + args + extra + [MODEL],
            capture_output=True, text=True)
        if not os.path.exists(tmp):
            bad = next((x for x in r.stderr.splitlines() if "Assertion" in x), "failed")
            print(f"  {L:9d}mm   {RED}{bad.strip()[:50]}{OFF}")
            continue
        tris, _ = load_tris(tmp)
        t = tris @ R.T
        t = t - np.array([0, 0, t[:, :, 2].min()])
        occ, p, l = occupancy(t, PITCH, LAYER)
        u = unsupported(occ, p, l)
        sup = support(occ, p, l)
        os.remove(tmp)
        subprocess.run(
            [OPENSCAD, "-o", tmp, "--export-format", "binstl", "--enable=textmetrics",
             "-D", 'part="bite"'] + args + extra + [MODEL], capture_output=True)
        grip = 0.0
        if os.path.exists(tmp):
            bt, _ = load_tris(tmp)
            if len(bt):
                v = bt.reshape(-1, 3)
                grip = float(v[:, 0].max() - v[:, 0].min())
            os.remove(tmp)
        print(f"  {L:9d}mm {sup['vol_mm3']/1000:8.2f}cm3 {u['area']:9.1f}mm2 "
              f"{u['ledge']:6.2f}mm {grip:10.1f}mm")


def main(argv):
    _, all_args = place.everything()
    want_trade = "--trade" in argv
    argv = [a for a in argv if not a.startswith("--")]
    for n in (argv or ["Justine"]):
        (trade if want_trade else study)(n, all_args[n])
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
