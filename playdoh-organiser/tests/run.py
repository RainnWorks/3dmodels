#!/usr/bin/env python3
"""Geometry tests for organiser.scad.  Run with `make test`.

Three kinds of check, because OpenSCAD only exposes three useful handles:

  assert_*.scad   render must succeed.  The file uses assert() on derived values.
                  Catches arithmetic that is self-consistent but wrong -- e.g.
                  two legs that seat at the same depth but end at different
                  heights.

  empty_*.scad    render must produce NO geometry.  Boolean emptiness is how you
                  ask a solid modeller a yes/no question:
                      "A fits inside B"   -> difference(A, B) is empty
                      "A and B miss"      -> intersection(A, B) is empty
                  Catches shapes that are individually fine but don't mate. This
                  is what the hull() bug needed -- the plug and its hole were
                  each correct on their own.

  mesh checks     properties of the exported STL that OpenSCAD won't tell you:
                  how many separate solids came out, and where the part sits.
                  Catches a leg that is geometrically present but joined to
                  nothing.

Every case here is a bug that actually shipped, so they are regressions rather
than hypotheticals.
"""
import glob
import os
import struct
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
MODEL = os.path.join(HERE, "..", "organiser.scad")
OPENSCAD = os.environ.get("OSCAD", "openscad")

GREEN, RED, DIM, OFF = "\033[32m", "\033[31m", "\033[2m", "\033[0m"


def run(args):
    return subprocess.run([OPENSCAD] + args, capture_output=True, text=True)


def scad(path, out="/dev/null", extra=None):
    return run(["-o", out, "--export-format", "binstl"] + (extra or []) + [path])


# --- the three kinds of check ------------------------------------------------
def check_assert(path):
    r = scad(path)
    for line in r.stderr.splitlines():
        if "Assertion" in line or line.startswith("ERROR"):
            return False, line.strip()
    return True, ""


def check_empty(path):
    r = scad(path)
    if "Current top level object is empty" in r.stderr:
        return True, ""
    for line in r.stderr.splitlines():
        if line.startswith("ERROR") or "Assertion" in line:
            return False, line.strip()
    # geometry came out where none should have: report how much
    tmp = "/tmp/_scadtest.stl"
    scad(path, out=tmp)
    n = 0
    if os.path.exists(tmp):
        with open(tmp, "rb") as f:
            f.read(80)
            n = struct.unpack("<I", f.read(4))[0]
        os.remove(tmp)
    return False, f"expected no geometry, got {n} facets"


def stl_triangles(path):
    with open(path, "rb") as f:
        f.read(80)
        (n,) = struct.unpack("<I", f.read(4))
        for _ in range(n):
            d = struct.unpack("<12fH", f.read(50))
            yield d[3:6], d[6:9], d[9:12]


def components_and_bbox(path):
    """Count separate solids by union-find over triangles sharing a vertex."""
    parent, tris = {}, []
    lo = [float("inf")] * 3
    hi = [float("-inf")] * 3

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    def union(a, b):
        ra, rb = find(a), find(b)
        if ra != rb:
            parent[rb] = ra

    for i, tri in enumerate(stl_triangles(path)):
        keys = []
        for v in tri:
            for k in range(3):
                lo[k] = min(lo[k], v[k])
                hi[k] = max(hi[k], v[k])
            key = tuple(round(c, 3) for c in v)   # quantise: welds shared corners
            parent.setdefault(key, key)
            keys.append(key)
        tris.append(keys)
    for keys in tris:
        for k in keys[1:]:
            union(keys[0], k)
    roots = {find(k) for k in parent}
    return len(roots), lo, hi


def check_mesh(name, args, want_components=None, want_min_z=None):
    out = "/tmp/_scadmesh.stl"
    r = scad(MODEL, out=out, extra=args)
    if not os.path.exists(out):
        return False, (r.stderr.strip().splitlines() or ["no output"])[-1]
    comps, lo, hi = components_and_bbox(out)
    os.remove(out)
    if want_components is not None and comps != want_components:
        return False, f"{comps} separate solids, expected {want_components}"
    if want_min_z is not None and abs(lo[2] - want_min_z) > 0.02:
        return False, f"sits at z={lo[2]:.2f}, expected {want_min_z}"
    return True, f"{comps} solid(s), z {lo[2]:.2f}..{hi[2]:.2f}"


# --- run ---------------------------------------------------------------------
def main():
    results = []

    for path in sorted(glob.glob(os.path.join(HERE, "assert_*.scad"))):
        results.append((os.path.basename(path)[:-5],) + check_assert(path))
    for path in sorted(glob.glob(os.path.join(HERE, "empty_*.scad"))):
        results.append((os.path.basename(path)[:-5],) + check_empty(path))

    # A tray must come off the plate as ONE solid. Regression: inner legs at
    # inner_r=9 were islands floating in the interstitial void.
    results.append(("mesh_tray_is_one_piece",)
                   + check_mesh("tray", ['-D', 'render_part="tray"'], want_components=1))
    # Nothing may hang below the build plate.
    results.append(("mesh_tray_sits_on_plate",)
                   + check_mesh("tray", ['-D', 'render_part="tray"'], want_min_z=0.0))
    # A loaded tower must stand on the table, not float or sink.
    results.append(("mesh_tower_grounded",)
                   + check_mesh("stack", ['-D', 'render_part="stack"'], want_min_z=0.0))

    width = max(len(n) for n, _, _ in results)
    failed = 0
    for name, ok, note in results:
        if ok:
            print(f"  {GREEN}pass{OFF}  {name:<{width}}  {DIM}{note}{OFF}")
        else:
            failed += 1
            print(f"  {RED}FAIL{OFF}  {name:<{width}}  {note}")
    print(f"\n{len(results)} checks, {failed} failed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
