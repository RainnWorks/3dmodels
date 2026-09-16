#!/usr/bin/env python3
"""Break the model on purpose, and check the tests notice.  `make falsify`.

ruffle-nozzle's README puts it plainly: a test that cannot fail reads as
coverage and is worse than no test. So every check in tests/ has an entry here
that breaks the thing it is supposed to be watching -- by patching the model,
or by passing a parameter that undoes the design decision -- and this reports
whether the check flipped.

Nothing here touches the real files: the model and tests are copied into a
scratch directory first and the damage is done to the copy. Variant 1 is
symlinked rather than copied, because this variant IS variant 1 plus one
rotation and there is nothing to break in it from here.
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile

import numpy as np

import mesh
import place

HERE = os.path.dirname(os.path.abspath(__file__))
OPENSCAD = os.environ.get("OSCAD", "openscad")
GREEN, RED, DIM, OFF = "\033[32m", "\033[31m", "\033[2m", "\033[0m"

NAME = "Justine"     # 3 pieces before bridging, and the deepest descender

# (check, how it is broken, model patches, extra -D flags, drop the struts?)
BREAKS = [
    ("empty_body_clears_the_glass",
     "union the clip into the body, so the letters own its far side too",
     [(r"module body3\(\) \{ linear_extrude\(thick\) body_2d\(\); \}",
       "module body3() { union() { linear_extrude(thick) body_2d(); clip3(); } }")],
     [], False),

    ("empty_clip_hides_behind_the_bar",
     "slide the clip 2mm up out of the bar's band, into the lettering",
     [(r"translate\(\[0, cw, 0\]\) rotate\(\[90, 0, 0\]\)",
       "translate([0, cw + 2, 0]) rotate([90, 0, 0])")], [], False),

    ("empty_clip_stays_behind_the_letters",
     "a 4mm clip stroke on a 2.6mm letter plane: it stands proud",
     [], ["-D", "swish_w=4"], False),

    ("empty_the_arm_stays_over_the_bar",
     "a 90mm spring arm, running off the end of the bar it clamps against",
     [], ["-D", "spring_len=90"], False),

    ("assert_clip_grips",
     "preload = 0, so the jaw is exactly the rim and grips nothing",
     [], ["-D", "preload=0"], False),

    ("assert_clip_grips",
     "a 1mm spring arm: it cannot close the jaw without folding",
     [], ["-D", "spring_len=1"], False),

    ("assert_placement_is_measured",
     "no ink measurement: fall back to the font metric",
     [], ["-D", "ink_drop=-1"], False),

    ("assert_placement_is_measured",
     "style=rail: the baseline stops being this name's own descent",
     [], ["-D", 'style="rail"'], False),

    ("mesh:one body",
     "drop the struts, so the i-dot prints as a loose disc",
     [], [], True),

    ("mesh:the clip bites",
     "preload = 0: the arm runs parallel to the glass and touches nothing",
     [], ["-D", "preload=0"], False),

    ("mesh:nothing but the clip hangs",
     "an 8mm bend radius, which swings the whole arm further off the body",
     [], ["-D", "clip_rad=8"], False),
]


def scratch(patches):
    d = tempfile.mkdtemp(prefix="falsify_")
    for f in ("nametag_back.scad", "names.txt", "place.py", "mesh.py",
              "overhangs.py"):
        shutil.copy(os.path.join(HERE, f), d)
    shutil.copytree(os.path.join(HERE, "tests"), os.path.join(d, "tests"),
                    ignore=shutil.ignore_patterns("__pycache__", ".t_*"))
    p = os.path.join(d, "nametag_back.scad")
    src = open(p).read()
    # The copy has no sibling glass-name-tag/, so point its include at the real
    # one. Variant 1 is never patched here: this variant IS variant 1 plus one
    # rotation, and there is nothing to break in it from this side.
    src = src.replace("include <../glass-name-tag/nametag.scad>",
                      f"include <{os.path.join(os.path.dirname(HERE), 'glass-name-tag', 'nametag.scad')}>")
    for pat, rep in patches:
        new = re.sub(pat, rep, src)
        if new == src:
            raise RuntimeError(f"patch did not apply: {pat}")
        src = new
    open(p, "w").write(src)
    return d


def run(d, args, out="/dev/null"):
    return subprocess.run(
        [OPENSCAD, "-o", out, "--export-format", "binstl",
         "--enable=textmetrics"] + args, capture_output=True, text=True, cwd=d)


def mesh_check(d, what, args):
    out = os.path.join(d, "b.stl")
    p = "bite" if "bites" in what else "tag"
    run(d, args + ["-D", f'part="{p}"', "nametag_back.scad"], out=out)
    if not os.path.exists(out):
        return ("bites" in what), "no geometry at all"
    st = mesh.stats(out)
    if what == "one body":
        return st["shells"] != 1, f"exported in {st['shells']} pieces"
    if what == "the clip bites":
        return st is None or st["size"][2] < 0.05, \
            f"interference only {st['size'][2]:.3f}mm deep"
    if what == "nothing but the clip hangs":
        import overhangs
        tris, _ = mesh.load_tris(out)
        R = dict(overhangs.ORIENTS)["letters DOWN  faces on the bed, clip standing up"]
        t = tris @ R.T
        t = t - np.array([0, 0, t[:, :, 2].min()])
        occ, pp, l = overhangs.occupancy(t, overhangs.PITCH, overhangs.LAYER)
        u = overhangs.unsupported(occ, pp, l)
        return u["area"] > 90.0, f"{u['area']:.0f}mm2 hanging, against 52 as built"
    raise RuntimeError(what)


def main():
    ic, bc = place.load()
    k = place.ink(NAME, ic)
    st = place.struts(NAME, k, bc)
    place.save(ic, bc)
    base = place.args(NAME, k, st)
    nost = place.args(NAME, k, [])

    print(f"\nbreaking the model on purpose, name={NAME!r} "
          f"({len(st) + 1} pieces before bridging)\n")
    print(f"  {'check':40} {'broken by':58} result")
    print("  " + "-" * 118)
    bad = 0
    for label, how, patches, extra, nostruts in BREAKS:
        args = (nost if nostruts else base) + extra
        d = scratch(patches)
        try:
            if label.startswith("mesh:"):
                caught, detail = mesh_check(d, label[5:], args)
            elif label.startswith("empty_"):
                r = run(d, args + [f"tests/{label}.scad"])
                empty = "Current top level object is empty" in r.stderr
                fac = re.search(r"Facets:\s+(\d+)", r.stderr)
                caught = not empty
                detail = (f"{int(fac.group(1))} facets where there should be none"
                          if fac else "produced geometry")
                if empty:
                    detail = "still empty -- the test did NOT catch it"
            else:
                r = run(d, args + [f"tests/{label}.scad"])
                line = next((x for x in r.stderr.splitlines()
                             if "Assertion" in x or x.startswith("ERROR")), None)
                caught = line is not None
                detail = (line.split("failed:")[-1].strip()[:48]
                          if line else "no assertion fired -- NOT caught")
        finally:
            shutil.rmtree(d, ignore_errors=True)
        bad += 0 if caught else 1
        mark = f"{GREEN}caught{OFF}" if caught else f"{RED}MISSED{OFF}"
        print(f"  {label:40} {how[:58]:58} {mark}  {DIM}{detail}{OFF}")

    print()
    if bad:
        print(f"{RED}{bad} break(s) went unnoticed -- those tests cannot fail{OFF}")
        return 1
    print(f"{GREEN}every break was caught{OFF}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
