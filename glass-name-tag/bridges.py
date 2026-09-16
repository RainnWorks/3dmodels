#!/usr/bin/env python3
"""Weld a script font's floating islands -- the dots on i and j -- to the tag.

Every name with an "i" comes out of the text shaper as more than one body:
"Millie" is three. Printed flat, a loose dot is a 2mm disc sitting on the
build plate next to the tag. It prints beautifully and then falls off.

The obvious fix is the morphological close the cake-topper uses (dilate then
erode, bridging anything nearer than the radius). It does not survive here:
at 15mm the gap under a Great Vibes i-dot is wider than the counters of "e"
and "o", so any radius big enough to catch the dot fills the letters in.

So bridge each island explicitly and minimally instead. Find the components of
the real exported body, take the closest pair of points between each island and
the mainland, and emit a strut across exactly that gap -- typically under a
millimetre, tucked under the dot where it reads as part of the letter.

The struts are computed from the SAME mesh the printer gets, so this cannot
drift away from the geometry it is fixing. tests/run.py asserts the result is
one single body.
"""
import json
import os
import struct
import subprocess
import sys

import numpy as np

import measure

HERE = os.path.dirname(os.path.abspath(__file__))
MODEL = os.path.join(HERE, "nametag.scad")
CACHE = os.path.join(HERE, "bridges.json")
OPENSCAD = os.environ.get("OSCAD", "openscad")


def load_tris(path):
    with open(path, "rb") as fh:
        d = fh.read()
    n = struct.unpack("<I", d[80:84])[0]
    a = np.frombuffer(d[84:84 + n * 50],
                      dtype=np.dtype([("n", "<3f4"), ("v", "<9f4"), ("a", "<u2")]),
                      count=n)
    return a["v"].reshape(-1, 3, 3).astype(np.float64)


def components(tris):
    """Label each triangle with its connected component (shared vertices)."""
    q = np.round(tris.reshape(-1, 3), 4)
    _, idx = np.unique(q, axis=0, return_inverse=True)
    idx = idx.reshape(-1, 3)
    parent = list(range(idx.max() + 1))

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for tri in idx:
        a, b, c = (find(int(v)) for v in tri)
        if a != b:
            parent[a] = b
        if b != c:
            parent[b] = c
    roots = np.array([find(int(v)) for v in idx[:, 0]])
    return roots, idx


def island_struts(stl, min_gap=0.05):
    """[[x1,y1,x2,y2], ...] joining every island to the largest component."""
    tris = load_tris(stl)
    roots, _ = components(tris)
    labels = np.unique(roots)
    if len(labels) <= 1:
        return []

    # points of each component, flattened to 2D (the part is a flat extrusion)
    pts = {lab: np.unique(np.round(tris[roots == lab].reshape(-1, 3)[:, :2], 4), axis=0)
           for lab in labels}
    # mainland = the component with the largest bounding box area
    def extent(p):
        return (p[:, 0].max() - p[:, 0].min()) * (p[:, 1].max() - p[:, 1].min())
    main = max(labels, key=lambda l: extent(pts[l]))

    # Mainland EDGES, not mainland vertices. A hulled stroke or a plain bar has
    # vertices only where its segments end, so "nearest vertex" can be 12mm away
    # along a bar whose nearest POINT is directly beneath the dot -- which is
    # how an i-dot ended up tied to the far end of the bar by a line across the
    # whole name. Point-to-segment is exact and costs nothing here.
    seg = tris[roots == main][:, :, :2]
    A = np.concatenate([seg[:, 0], seg[:, 1], seg[:, 2]])
    B = np.concatenate([seg[:, 1], seg[:, 2], seg[:, 0]])
    keep = np.linalg.norm(B - A, axis=1) > 1e-9
    A, B = A[keep], B[keep]

    def closest_on_edges(P):
        """For each point in P, the nearest point lying on any mainland edge."""
        AB = B - A                                     # (E,2)
        L2 = np.einsum("ij,ij->i", AB, AB)             # (E,)
        AP = P[:, None, :] - A[None, :, :]             # (P,E,2)
        t = np.clip(np.einsum("pej,ej->pe", AP, AB) / L2, 0.0, 1.0)
        proj = A[None, :, :] + t[:, :, None] * AB[None, :, :]
        d = np.linalg.norm(P[:, None, :] - proj, axis=2)
        j = np.argmin(d, axis=1)
        i = np.arange(len(P))
        return proj[i, j], d[i, j]

    return mst_struts(tris, roots, labels, pts, min_gap)


def mst_struts(tris, roots, labels, pts, min_gap):
    """Join the pieces by a minimum spanning tree, not all to the mainland.

    "Justine" comes apart into three: the bar plus the capital J, the whole
    lowercase "ustine", and the dot over the i. Bridging every island to the
    MAINLAND sends that dot straight past its own stem -- which lives in a
    different island -- and ties it to the bar 14mm below, drawing a line down
    the middle of the name.

    An MST over the pieces gives each one its nearest neighbour instead: the
    dot lands on its stem, and "ustine" lands on the J beside it. Same
    guarantee (one connected body, n-1 struts for n pieces) at a fraction of
    the length.
    """
    def nearest(a, b):
        """Closest approach between pieces a and b: (point on a, point on b, d)."""
        seg = tris[roots == b][:, :, :2]
        A = np.concatenate([seg[:, 0], seg[:, 1], seg[:, 2]])
        B = np.concatenate([seg[:, 1], seg[:, 2], seg[:, 0]])
        keep = np.linalg.norm(B - A, axis=1) > 1e-9
        A, B = A[keep], B[keep]
        P = pts[a]
        AB = B - A
        L2 = np.einsum("ij,ij->i", AB, AB)
        AP = P[:, None, :] - A[None, :, :]
        t = np.clip(np.einsum("pej,ej->pe", AP, AB) / L2, 0.0, 1.0)
        proj = A[None, :, :] + t[:, :, None] * AB[None, :, :]
        d = np.linalg.norm(P[:, None, :] - proj, axis=2)
        j = np.argmin(d, axis=1)
        i = np.argmin(d[np.arange(len(P)), j])
        return P[i], proj[i, j[i]], float(d[i, j[i]])

    # Prim from the largest piece, so struts grow outward from the body.
    def extent(p):
        return (p[:, 0].max() - p[:, 0].min()) * (p[:, 1].max() - p[:, 1].min())
    inside = [max(labels, key=lambda l: extent(pts[l]))]
    outside = [l for l in labels if l != inside[0]]

    out = []
    while outside:
        best = None
        for a in outside:
            for b in inside:
                pa, pb, d = nearest(a, b)
                if best is None or d < best[0]:
                    best = (d, a, pa, pb)
        d, lab, pa, pb = best
        outside.remove(lab)
        inside.append(lab)
        # ALWAYS emit, however small the gap. There used to be a "close enough,
        # they must already be touching" shortcut here and it was simply wrong:
        # these pieces came back from the exporter as SEPARATE shells, which
        # means they do not overlap, however near they look. Skipping the strut
        # left "Corentin" in two pieces while every gap read as under 0.05mm.
        out.append([round(float(pa[0]), 3), round(float(pa[1]), 3),
                    round(float(pb[0]), 3), round(float(pb[1]), 3), round(d, 3)])
    return out


def bite():
    """The bite the struts were computed at -- it moves the letters, so it
    moves the struts."""
    return os.environ.get("BITE", "default")


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


def key(name, font, size, style, set_drop, bold):
    return f"{name}|{font}|{size}|{style}|{set_drop}|{bold}|{bite()}|{model_sig()}"


def render_body(out, name, ink, font, size, style, set_drop, bold, struts=None):
    cmd = ([OPENSCAD, "-o", out, "--export-format", "binstl", "--enable=textmetrics",
            "-D", f'render_part="body"', "-D", f'font="{font}"',
            "-D", f"txt_size={size}", "-D", f'style="{style}"',
            "-D", f"set_drop={set_drop}", "-D", f"bold={bold}"]
           + (["-D", f"bite={os.environ['BITE']}"] if "BITE" in os.environ else [])
           + measure.scad_args(name, ink)
           + (["-D", f"struts={json.dumps(struts)}"] if struts else [])
           + [MODEL])
    r = subprocess.run(cmd, capture_output=True, text=True)
    if not os.path.exists(out):
        raise RuntimeError(f"render failed for {name!r}:\n{r.stderr[-900:]}")
    return r


def bridges_for(name, ink, font, size, style, set_drop, bold=0.0, cache=None):
    """Struts (without the trailing gap value) that make this name one body."""
    k = key(name, font, size, style, set_drop, bold)
    if cache is not None and k in cache:
        return cache[k]
    tmp = os.path.join(HERE, f".b_{abs(hash(k))}.stl")
    render_body(tmp, name, ink, font, size, style, set_drop, bold)
    found = island_struts(tmp)
    os.remove(tmp)
    res = [s[:4] for s in found]
    if cache is not None:
        cache[k] = res
    return res


def load_cache():
    return json.load(open(CACHE)) if os.path.exists(CACHE) else {}


def save_cache(c):
    json.dump(c, open(CACHE, "w"), indent=1, sort_keys=True)


def main(argv):
    font = os.environ.get("FONT", "Great Vibes")
    size = float(os.environ.get("SIZE", 15))
    style = os.environ.get("STYLE", "flush")
    names = argv or ["Sophie", "Millie", "Jai", "Niamh", "Christopher", "Tom"]

    ic, bc = measure.load_cache(), load_cache()
    inks = {n: measure.measure(n, font, size, cache=ic) for n in names}
    sd = max(v["drop"] for v in inks.values())
    print(f"font={font!r} size={size} style={style!r} set baseline={sd:.2f}mm\n")
    print(f"{'name':14} {'islands':>8}  {'gaps bridged (mm)'}")
    print("-" * 52)
    for n in names:
        tmp = os.path.join(HERE, ".probe.stl")
        render_body(tmp, n, inks[n], font, size, style, sd, 0.0)
        found = island_struts(tmp)
        os.remove(tmp)
        bc[key(n, font, size, style, sd, 0.0)] = [s[:4] for s in found]
        gaps = ", ".join(f"{s[4]:.2f}" for s in found) or "-"
        print(f"{n:14} {len(found):8d}  {gaps}")
    measure.save_cache(ic)
    save_cache(bc)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
