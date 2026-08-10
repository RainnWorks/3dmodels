#!/usr/bin/env python3
"""What does each part ask of the printer?  Run with `make overhangs`.

Reads the exported meshes and reports every downward-facing surface, because
"no supports needed" is a claim about geometry and should be measured rather
than asserted. An earlier README said the thread flanks were "45 degrees or
shallower"; they are a 20 degree staircase, which this would have caught.

Two numbers matter and they are easy to confuse:

  ANGLE  from vertical. 0 is a vertical wall, 90 a flat ceiling. Steeper than
         ~50 usually wants support -- but only if it is also wide.

  WIDTH  how far the ledge sticks out past what is under it. A 90 degree face
         0.2mm wide bridges without noticing; the same face 3mm wide droops.
         The thread flanks here are 90 degree steps 0.167mm wide, which is why
         the angle alone is misleading.
"""
import collections
import math
import os
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
EXPDIR = os.path.join(HERE, "export")
FLAT_DEG = 60          # "near-horizontal" for the ledge-width pass
SUPPORT_DEG = 50       # beyond this, a WIDE face would want support


def triangles(path):
    with open(path, "rb") as f:
        f.read(80)
        (n,) = struct.unpack("<I", f.read(4))
        for _ in range(n):
            d = struct.unpack("<12fH", f.read(50))
            yield d[0:3], (d[3:6], d[6:9], d[9:12])


def area(a, b, c):
    u = [b[i] - a[i] for i in range(3)]
    v = [c[i] - a[i] for i in range(3)]
    x = (u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0])
    return 0.5 * math.sqrt(sum(t * t for t in x))


def report(name):
    path = os.path.join(EXPDIR, name)
    if not os.path.exists(path):
        print(f"{name}: not built")
        return True
    zmin = min(v[2] for _, vs in triangles(path) for v in vs)

    buckets = collections.Counter()
    ledges = []
    for nrm, vs in triangles(path):
        if nrm[2] >= -1e-6:                                    # not downward facing
            continue
        if max(v[2] for v in vs) <= zmin + 1e-3:               # the face on the plate
            continue
        deg = math.degrees(math.asin(min(1.0, -nrm[2])))
        buckets[min(80, int(deg // 10) * 10)] += area(*vs)
        if deg >= FLAT_DEG:
            rs = [math.hypot(v[0], v[1]) for v in vs]
            ledges.append((max(rs) - min(rs), sum(v[2] for v in vs) / 3.0))

    total = sum(buckets.values())
    if not total:
        print(f"\n{name}: no downward-facing surfaces at all")
        return True

    print(f"\n{name}")
    for lo in sorted(buckets):
        bar = "#" * int(40 * buckets[lo] / total)
        print(f"   {lo:2d}-{lo + 10:2d} deg  {buckets[lo]:7.1f} mm2  {bar}")

    if not ledges:
        print(f"   -> nothing steeper than {FLAT_DEG} deg; no supports")
        return True
    ledges.sort(reverse=True)
    widest, z = ledges[0]
    mean = sum(w for w, _ in ledges) / len(ledges)
    print(f"   -> {len(ledges)} near-flat faces, mean ledge {mean:.3f} mm, "
          f"widest {widest:.3f} mm at z={z:.1f}")
    # One extrusion width is the rule of thumb for a step that needs no thought.
    verdict = "fine, bridges" if widest < 1.5 else "WIDE -- check this one"
    print(f"      {verdict}")
    return widest < 1.5


def main():
    parts = sys.argv[1:] or ["nozzle.stl", "sleeve.stl", "ring.stl", "coupon.stl"]
    ok = all([report(p) for p in parts])
    print("\nall parts print unsupported" if ok else "\nsomething needs a second look")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
