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

    out = []
    M = pts[main]
    for lab in labels:
        if lab == main:
            continue
        I = pts[lab]
        # closest pair between the island and the mainland
        d = np.linalg.norm(I[:, None, :] - M[None, :, :], axis=2)
        i, j = np.unravel_index(np.argmin(d), d.shape)
        gap = d[i, j]
        if gap < min_gap:      # already touching; nothing to bridge
            continue
        out.append([round(float(I[i, 0]), 3), round(float(I[i, 1]), 3),
                    round(float(M[j, 0]), 3), round(float(M[j, 1]), 3), round(float(gap), 3)])
    return out


def key(name, font, size, style, set_drop, bold):
    return f"{name}|{font}|{size}|{style}|{set_drop}|{bold}"


def render_body(out, name, ink, font, size, style, set_drop, bold, struts=None):
    cmd = ([OPENSCAD, "-o", out, "--export-format", "binstl", "--enable=textmetrics",
            "-D", f'render_part="body"', "-D", f'font="{font}"',
            "-D", f"txt_size={size}", "-D", f'style="{style}"',
            "-D", f"set_drop={set_drop}", "-D", f"bold={bold}"]
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
