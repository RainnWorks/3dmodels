#!/usr/bin/env python3
"""One place that knows how to place a name on this model.

Variant 2 shares variant 1's entire flat silhouette, so it shares variant 1's
measuring and bridging tools too -- not copies of them, the actual modules:

  ../glass-name-tag/measure.py   real ink extents, read off the exported mesh.
                                 The font's declared descent is not a bound on
                                 the ink in either direction -- at size 15
                                 Great Vibes claims 6.1mm for every string
                                 while "Justine" reaches 8.1mm and "Pascal"
                                 1.0mm -- and that is the bug both variants
                                 exist to avoid.
  ../glass-name-tag/bridges.py   the struts that weld the loose pieces. Great
                                 Vibes is not a connected script: "Tom" shapes
                                 as 2 pieces, "Justine" 3, "Gabby" 4. The
                                 solver is a minimum spanning TREE over the
                                 pieces using exact point-to-segment distance;
                                 both of those took two goes to get right in
                                 variant 1 and re-deriving them here would only
                                 mean re-learning them.

Because nametag_back.scad `include`s nametag.scad, the struts bridges.py
computes in variant 1's tag coordinates are already in ours -- the 2D is the
same 2D. That is the whole reason this file is four lines of plumbing rather
than a fork.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
V1 = os.path.join(os.path.dirname(HERE), "glass-name-tag")
MODEL = os.path.join(HERE, "nametag_back.scad")

if not os.path.isdir(V1):
    raise SystemExit(f"{V1} is missing -- variant 2 is variant 1 plus one "
                     "rotation and cannot be built without it")
sys.path.insert(0, V1)
import bridges          # noqa: E402  ../glass-name-tag/bridges.py
import measure          # noqa: E402  ../glass-name-tag/measure.py

# The shipping settings. `lift` is variant 1's default style: one thin bar at
# the bottom with the name lifted until its own deepest tail bites into it.
FONT, SIZE, BOLD, STYLE, SET_DROP = "Great Vibes", 15.0, 0.15, "lift", -1


def names(path=None):
    # Variant 1's list is the single source of truth. A local copy drifts:
    # renaming Vero/Seb/Hazz in variant 1 silently left this one exporting the
    # old three.
    return [l.strip() for l in open(path or os.path.join(
                os.path.dirname(HERE), "glass-name-tag", "names.txt"))
            if l.strip()]


def load():
    return measure.load_cache(), bridges.load_cache()


def save(ic, bc):
    measure.save_cache(ic)
    bridges.save_cache(bc)


def ink(name, ic, font=FONT, size=SIZE, bold=BOLD):
    return measure.measure(name, font, size, bold, cache=ic)


def struts(name, ink_, bc, font=FONT, size=SIZE, bold=BOLD, style=STYLE):
    return bridges.bridges_for(name, ink_, font, size, style, SET_DROP, bold,
                               cache=bc)


def args(name, ink_, st, font=FONT, size=SIZE, bold=BOLD, style=STYLE):
    """Every -D this model needs to build one placed, bridged tag."""
    return (["-D", f'font="{font}"', "-D", f"txt_size={size}",
             "-D", f"bold={bold}", "-D", f'style="{style}"',
             "-D", f"set_drop={SET_DROP}"]
            + measure.scad_args(name, ink_)
            + (["-D", f"struts={json.dumps(st)}"] if st else []))


def everything(font=FONT, size=SIZE, bold=BOLD, style=STYLE):
    """(names, {name: -D args}) for the whole list, measured and bridged."""
    ic, bc = load()
    ns = names()
    out = {}
    for n in ns:
        k = ink(n, ic, font, size, bold)
        out[n] = args(n, k, struts(n, k, bc, font, size, bold, style),
                      font, size, bold, style)
    save(ic, bc)
    return ns, out
