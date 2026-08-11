#!/usr/bin/env python3
"""Pack the whole name set onto build plates, ready to slice.

The tags are long thin strips of very different lengths (61 to 94mm for this
set), so a fixed grid wastes most of the plate -- every short name would
reserve the longest name's width. Shelf packing instead: longest first, laid
into rows, closing a row when the next tag will not fit. For strips that share
one height that lands within a few percent of optimal and needs no search.

Each tag is exported once, then plates are composed by importing those meshes
at their packed positions. With lazy-union that gives a 3MF holding one object
PER TAG, so Bambu Studio can select, move or delete individual names rather
than treating the plate as a single lump.
"""
import json
import os
import random
import shutil
import subprocess
import sys

import bridges
import measure

HERE = os.path.dirname(os.path.abspath(__file__))
EXPORT = os.path.join(HERE, "export")
TAGS = os.path.join(EXPORT, "tags")
PREV = os.path.join(HERE, "previews")
MODEL = os.path.join(HERE, "nametag.scad")
OPENSCAD = os.environ.get("OSCAD", "openscad")

# Bambu 256x256. Usable area is smaller than the bed: the slicer keeps an
# exclusion margin and parts near the edge foul the wiper.
BED = float(os.environ.get("BED", 256))
MARGIN = float(os.environ.get("MARGIN", 8))
# 4mm. These are flat parts with their whole footprint on the bed, so they need
# no brim and no thermal separation; 4mm is purely so they are easy to snip
# apart and so a stray blob cannot bridge two tags. Dropping 6 -> 4 is what
# fits the set onto two plates instead of three.
GAP = float(os.environ.get("GAP", 4))


def export_tag(name, ink, struts, font, size, style, set_drop, bold):
    """Export one tag and return its footprint (x0, y0, x1, y1)."""
    out = os.path.join(TAGS, f"{name}.stl")
    cmd = ([OPENSCAD, "-o", out, "--export-format", "binstl", "--enable=textmetrics",
            "-D", 'render_part="tag"', "-D", f'font="{font}"', "-D", f"txt_size={size}",
            "-D", f'style="{style}"', "-D", f"set_drop={set_drop}", "-D", f"bold={bold}"]
           + measure.scad_args(name, ink)
           + (["-D", f"struts={json.dumps(struts)}"] if struts else [])
           + [MODEL])
    r = subprocess.run(cmd, capture_output=True, text=True)
    if not os.path.exists(out):
        raise RuntimeError(f"export failed for {name}:\n{r.stderr[-600:]}")
    v = bridges.load_tris(out).reshape(-1, 3)
    return (float(v[:, 0].min()), float(v[:, 1].min()),
            float(v[:, 0].max()), float(v[:, 1].max()))


def shelf_pack(items, w, h):
    """items = [(name, iw, ih)] -> [[(name, x, y)]] per plate.

    First-fit decreasing, but across ALL open rows rather than only the newest.
    Sorting longest-first and only ever appending to the current row groups the
    long names together, and two 93mm tags leave 47mm of a 240mm row dead --
    too narrow for any tag in the set. Letting a later short name drop back
    into that hole is the whole difference between three plates and two.
    """
    # Two separate problems, solved separately, because solving them together
    # is what produced a plate holding one tag:
    #   1. pack the tags into ROWS of the bed width  (first-fit decreasing)
    #   2. distribute those rows over plates, EVENLY
    # Step 2 matters: the total print time is the same whatever the plate count
    # -- it is the same parts either way -- so the only real cost of an extra
    # plate is the swap. A plate holding one tag pays that cost for nothing,
    # whereas three balanced plates cost two swaps and nothing else.
    row_h = max(ih for _, _, ih in items)
    per_plate = int((h + GAP) // (row_h + GAP))
    if per_plate < 1:
        raise SystemExit(f"a {row_h:.1f}mm tag will not fit a {h:.0f}mm bed")

    for name, iw, _ in items:
        if iw > w:
            raise SystemExit(f"{name} is {iw:.1f}mm -- wider than the {w:.0f}mm bed")

    def first_fit(order):
        rows = []
        for name, iw in order:
            for row in rows:
                add = iw if not row[0] else iw + GAP
                if row[1] + add <= w:
                    row[0].append((name, row[1] + (0 if not row[0] else GAP)))
                    row[1] += add
                    break
            else:
                rows.append([[(name, 0.0)], iw])
        return rows

    # First-fit decreasing, then seeded random restarts. This set needs 94.5%
    # of every row filled to reach the plate count its total length allows, and
    # both FFD and best-fit stall one row short of that -- restarts find it.
    # Seeded, so the same names always produce the same plates.
    widths = [(n, iw) for n, iw, _ in items]
    best = first_fit(sorted(widths, key=lambda i: -i[1]))
    rng = random.Random(20260811)
    for _ in range(int(os.environ.get("TRIES", 4000))):
        cand = first_fit(rng.sample(widths, len(widths)))
        if len(cand) < len(best):
            best = cand
    rows = best

    n_plates = -(-len(rows) // per_plate)        # ceil
    spread = -(-len(rows) // n_plates)           # rows per plate, balanced
    plates = [[] for _ in range(n_plates)]
    for ri, row in enumerate(rows):
        pi = ri // spread
        y = (ri % spread) * (row_h + GAP)
        for name, x in row[0]:
            plates[pi].append((name, x, y))
    return [p for p in plates if p]


def main():
    font = os.environ.get("FONT", "Great Vibes")
    size = float(os.environ.get("SIZE", 15))
    bold = float(os.environ.get("BOLD", 0.15))
    style = os.environ.get("STYLE", "rail")
    names = [l.strip() for l in open(os.path.join(HERE, "names.txt")) if l.strip()]

    # Wipe every previously generated plate first. A run that packs onto fewer
    # plates than the last one would otherwise leave a stale plateN behind, and
    # a stale plate is indistinguishable from a real one at the slicer.
    shutil.rmtree(TAGS, ignore_errors=True)
    for d, exts in ((EXPORT, ("3mf", "stl", "scad")), (PREV, ("png",))):
        for f in (os.listdir(d) if os.path.isdir(d) else []):
            if f.startswith("plate") and f.rsplit(".", 1)[-1] in exts:
                os.remove(os.path.join(d, f))
    os.makedirs(TAGS, exist_ok=True)
    os.makedirs(PREV, exist_ok=True)

    ic, bc = measure.load_cache(), bridges.load_cache()
    inks = {n: measure.measure(n, font, size, bold, cache=ic) for n in names}
    set_drop = max(v["drop"] for v in inks.values())

    print(f"{len(names)} names -- {font} {size:g}mm bold+{bold} style={style}")
    print(f"bed {BED:g}mm, {MARGIN:g}mm keep-out, {GAP:g}mm between tags\n")
    print("exporting tags...")
    boxes = {}
    for n in names:
        st = bridges.bridges_for(n, inks[n], font, size, style, set_drop, bold, cache=bc)
        boxes[n] = export_tag(n, inks[n], st, font, size, style, set_drop, bold)

    items = [(n, boxes[n][2] - boxes[n][0], boxes[n][3] - boxes[n][1]) for n in names]
    usable = BED - 2 * MARGIN
    plates = shelf_pack(items, usable, usable)
    dims = {n: (w, h) for n, w, h in items}

    print(f"\npacked onto {len(plates)} plate(s), {usable:g}x{usable:g}mm usable:")
    for pi, plate in enumerate(plates, 1):
        used = sum(dims[n][0] * dims[n][1] for n, _, _ in plate)
        span = max(y + dims[n][1] for n, _, y in plate)
        print(f"  plate {pi}: {len(plate):2d} tags, {span:5.1f}mm deep, "
              f"{100*used/(usable*usable):4.1f}% area")
        print(f"            {', '.join(n for n, _, _ in plate)}")

        lines = [f"// plate {pi} of {len(plates)} -- GENERATED by plate.py, do not edit",
                 f"// {len(plate)} tags, {font} {size:g}mm, style={style}", ""]
        for n, x, y in plate:
            bx0, by0, _, _ = boxes[n]
            lines.append(f'translate([{x - bx0 + MARGIN:.3f}, {y - by0 + MARGIN:.3f}, 0])'
                         f' import("tags/{n}.stl");')
        scad = os.path.join(EXPORT, f"plate{pi}.scad")
        with open(scad, "w") as fh:
            fh.write("\n".join(lines) + "\n")

        # lazy-union keeps one 3MF object per tag, so the slicer can arrange them
        subprocess.run([OPENSCAD, "-o", os.path.join(EXPORT, f"plate{pi}.3mf"),
                        "--enable=lazy-union", scad], capture_output=True)
        subprocess.run([OPENSCAD, "-o", os.path.join(EXPORT, f"plate{pi}.stl"),
                        "--export-format", "binstl", scad], capture_output=True)
        subprocess.run([OPENSCAD, "-o", os.path.join(PREV, f"plate{pi}.png"),
                        "--camera=0,0,0,0,0,0,0", "--viewall", "--autocenter",
                        "--render", "--colorscheme=Tomorrow", "--imgsize=1000,1000",
                        scad], capture_output=True)

    measure.save_cache(ic)
    bridges.save_cache(bc)
    made = [f"plate{i}" for i in range(1, len(plates) + 1)]
    print(f"\nwrote export/{{{','.join(made)}}}.3mf (+ .stl, .scad) "
          f"and previews/plate*.png")
    return 0


if __name__ == "__main__":
    sys.exit(main())
