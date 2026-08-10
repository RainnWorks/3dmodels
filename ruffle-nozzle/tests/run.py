#!/usr/bin/env python3
"""Geometry tests for nozzle.scad.  Run with `make test`.

Three kinds of check, because OpenSCAD only exposes three useful handles --
the same three the playdoh-organiser settled on, for the same reasons:

  assert_*.scad   render must succeed.  The file uses assert() on derived
                  values.  Catches arithmetic that is self-consistent but
                  wrong.

  empty_*.scad    render must produce NO geometry.  Boolean emptiness is how
                  you ask a solid modeller a yes/no question:
                      "A fits inside B"   -> difference(A, B) is empty
                      "A and B miss"      -> intersection(A, B) is empty
                  This is the kind that matters here: the nozzle, the sleeve
                  and the ring are each obviously fine on their own, and the
                  only interesting question is whether they go together.

  mesh checks     properties of the exported STL that OpenSCAD will not report:
                  how many separate solids came out, and where the part sits.
                  The nozzle is the one to watch -- the aperture is a prism cut
                  clean through the cone, and if it ever reached the base wall
                  the part would fall into two petals.
"""
import glob
import os
import struct
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
MODEL = os.path.join(HERE, "..", "nozzle.scad")
OPENSCAD = os.environ.get("OSCAD", "openscad")

GREEN, RED, DIM, OFF = "\033[32m", "\033[31m", "\033[2m", "\033[0m"


# Both candidate base diameters. The design is normalised to base_d, but the
# walls, clearances and slot_grow are ABSOLUTE, so a O18 nozzle is not a scaled
# O23 one and its fits have to be proved separately.
SIZES = (23, 18)


def scad(path, out="/dev/null", extra=None):
    return subprocess.run(
        [OPENSCAD, "-o", out, "--export-format", "binstl"] + (extra or []) + [path],
        capture_output=True, text=True)


def check_assert(path, extra=None):
    r = scad(path, extra=extra)
    for line in r.stderr.splitlines():
        if "Assertion" in line or line.startswith("ERROR"):
            return False, line.strip()
    return True, ""


def check_empty(path, extra=None):
    r = scad(path, extra=extra)
    if "Current top level object is empty" in r.stderr:
        return True, ""
    for line in r.stderr.splitlines():
        if line.startswith("ERROR") or "Assertion" in line:
            return False, line.strip()
    tmp = "/tmp/_nozzletest.stl"
    scad(path, out=tmp, extra=extra)
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
    lo, hi = [float("inf")] * 3, [float("-inf")] * 3

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for tri in stl_triangles(path):
        keys = []
        for v in tri:
            for k in range(3):
                lo[k], hi[k] = min(lo[k], v[k]), max(hi[k], v[k])
            key = tuple(round(c, 3) for c in v)   # quantise: welds shared corners
            parent.setdefault(key, key)
            keys.append(key)
        tris.append(keys)
    for keys in tris:
        for k in keys[1:]:
            ra, rb = find(keys[0]), find(k)
            if ra != rb:
                parent[rb] = ra
    return len({find(k) for k in parent}), lo, hi


def check_mesh(args, want_components=None, want_min_z=None, want_max_z=None):
    out = "/tmp/_nozzlemesh.stl"
    r = scad(MODEL, out=out, extra=args)
    if not os.path.exists(out):
        return False, (r.stderr.strip().splitlines() or ["no output"])[-1]
    comps, lo, hi = components_and_bbox(out)
    os.remove(out)
    if want_components is not None and comps != want_components:
        return False, f"{comps} separate solids, expected {want_components}"
    if want_min_z is not None and abs(lo[2] - want_min_z) > 0.02:
        return False, f"sits at z={lo[2]:.2f}, expected {want_min_z}"
    if want_max_z is not None and abs(hi[2] - want_max_z) > 0.5:
        return False, f"tops out at z={hi[2]:.2f}, expected {want_max_z}"
    return True, f"{comps} solid(s), z {lo[2]:.2f}..{hi[2]:.2f}"


def main():
    results = []
    for d in SIZES:
        arg = ["-D", f"base_d={d}"]
        for path in sorted(glob.glob(os.path.join(HERE, "assert_*.scad"))):
            results.append((f"{os.path.basename(path)[:-5]}@O{d}",) + check_assert(path, arg))
        for path in sorted(glob.glob(os.path.join(HERE, "empty_*.scad"))):
            results.append((f"{os.path.basename(path)[:-5]}@O{d}",) + check_empty(path, arg))

    # The aperture is cut clean through the cone. Two petals joined only at the
    # base is ONE solid; if the cut ever reached the base wall it would be two.
    for part in ("nozzle", "sleeve", "ring"):
        results.append((f"mesh_{part}_is_one_piece",)
                       + check_mesh(["-D", f'render_part="{part}"'], want_components=1))
    # Nothing may hang below the build plate.
    for part in ("nozzle", "sleeve", "ring"):
        results.append((f"mesh_{part}_sits_on_plate",)
                       + check_mesh(["-D", f'render_part="{part}"'], want_min_z=0.0))

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
