#!/usr/bin/env python3
"""Reading properties back off an exported STL that OpenSCAD will not report.

A tag can render perfectly, pass every assertion, and still come off the plate
in three pieces, or with a letter reaching into the glass. Both are properties
of the exported mesh, so they are read off the exported mesh.
"""
import struct

import numpy as np


def load_tris(path):
    """(n, 3, 3) vertex array and (n, 3) facet normals from a binary STL."""
    with open(path, "rb") as fh:
        d = fh.read()
    n = struct.unpack("<I", d[80:84])[0]
    if n == 0:
        return np.zeros((0, 3, 3)), np.zeros((0, 3))
    a = np.frombuffer(d[84:84 + n * 50],
                      dtype=np.dtype([("n", "<3f4"), ("v", "<9f4"), ("a", "<u2")]),
                      count=n)
    return (a["v"].reshape(-1, 3, 3).astype(np.float64),
            a["n"].astype(np.float64))


def components(tris):
    """Label every triangle with its connected component (by shared vertex).

    This is the check that a tag is one printable object rather than a name in
    loose pieces. Great Vibes is not a connected script -- "Gabby" shapes as
    four separate bodies -- so variant 1 had to weld every floating island with
    a computed strut. Here the backing plate does it for free, and this is what
    proves that rather than assuming it.
    """
    q = np.round(tris.reshape(-1, 3), 4)
    _, idx = np.unique(q, axis=0, return_inverse=True)
    idx = idx.reshape(-1, 3)
    parent = list(range(int(idx.max()) + 1))

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
    return np.array([find(int(v)) for v in idx[:, 0]])


def centroid(tris):
    """Volume centroid of a closed mesh, by the divergence theorem.

    Used on the flat text extrusion, where the x component is exactly the ink's
    2D AREA centroid -- which is where the tag has to hang from if it is to
    hang level. The middle of the bounding box is a different point: a script
    capital with a big swash carries most of its area to one side of it.
    """
    a, b, c = tris[:, 0], tris[:, 1], tris[:, 2]
    v = np.einsum("ij,ij->i", a, np.cross(b, c)) / 6.0
    tot = v.sum()
    if abs(tot) < 1e-12:
        return None
    return ((v[:, None] * (a + b + c) / 4.0).sum(0)) / tot


def stats(path):
    """{shells, xmin.., xlen.., facets} for an exported part, or None if empty."""
    tris, _ = load_tris(path)
    if len(tris) == 0:
        return None
    v = tris.reshape(-1, 3)
    lo, hi = v.min(0), v.max(0)
    return {
        "facets": len(tris),
        "shells": int(len(np.unique(components(tris)))),
        "min": lo, "max": hi, "size": hi - lo,
    }
