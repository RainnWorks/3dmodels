#!/usr/bin/env python3
"""Solid volume of a binary STL, for comparing the filament cost of variants.

    python3 weigh.py <label> <file.stl>

OpenSCAD's --summary reports facets and a bounding box but no volume, so we
integrate the signed tetrahedron volume over the mesh ourselves.
"""
import struct
import sys

PLA_DENSITY = 1.24  # g/cm3


def volume_mm3(path):
    with open(path, "rb") as f:
        f.read(80)  # header
        (n,) = struct.unpack("<I", f.read(4))
        total = 0.0
        for _ in range(n):
            d = struct.unpack("<12fH", f.read(50))
            a, b, c = d[3:6], d[6:9], d[9:12]
            total += (
                a[0] * (b[1] * c[2] - b[2] * c[1])
                - a[1] * (b[0] * c[2] - b[2] * c[0])
                + a[2] * (b[0] * c[1] - b[1] * c[0])
            ) / 6.0
    return abs(total)


if __name__ == "__main__":
    label, path = sys.argv[1], sys.argv[2]
    cm3 = volume_mm3(path) / 1000.0
    print(f"{label:<22} {cm3:8.1f} cm3 {cm3 * PLA_DENSITY:6.0f} g")
