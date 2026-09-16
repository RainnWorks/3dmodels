#!/usr/bin/env python3
"""Geometry tests for nametag_back.scad.  Run with `make test`.

Same three handles the rest of this repo settled on:

  assert_*.scad   render must succeed. The file uses assert() on derived
                  values -- the arithmetic that is self-consistent but wrong.

  empty_*.scad    render must produce NO geometry. Boolean emptiness is how you
                  ask a solid modeller a yes/no question:
                      "A stays clear of B"  ->  intersection(A, B) is empty
                      "A is inside B"       ->  difference(A, B) is empty

  mesh checks     properties of the exported STL that OpenSCAD will not report:
                  how many separate solids came out, how far the body reaches,
                  whether the clip really bites the rim, and -- rasterised
                  layer by layer -- exactly what the printer is left holding.

Every check runs over the WHOLE NAME LIST. Great Vibes is not a connected
script: "Tom" shapes as 2 pieces, "Justine" 3, "Gabby" 4, and one name proves
nothing about thirty-three.

Mesh checks compare against numbers read back OUT of the model
(tests/echo.scad), so they cannot quietly agree with a model that changed
underneath them.
"""
import ast
import os
import re
import subprocess
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import mesh          # noqa: E402
import overhangs     # noqa: E402
import place         # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
MODEL = place.MODEL
OPENSCAD = os.environ.get("OSCAD", "openscad")

GREEN, RED, DIM, OFF = "\033[32m", "\033[31m", "\033[2m", "\033[0m"

# The scad-level checks run on these: the widest ink in the set, and the one
# with the deepest descenders (which is what drives the lifted baseline).
PAIR = ["Marlow", "Justine"]
# The raster print check costs a couple of seconds a name.
PRINT_NAMES = ["Marlow", "Justine", "Tom", "Seb"]
# A second font, for the same reason ruffle-nozzle runs its tests at two base
# diameters: the cheapest available proof that the model is parameterised
# rather than tuned to one set of numbers.
SECOND_FONT, SECOND_NAMES = "Pacifico", ["Marlow", "Justine"]

VAL_NAMES = ("clip_len bar_w thick base_y drop txt_w jaw jaw_root glass_t "
             "bend_r cw rim_x spring_len spring_ang").split()


def run(args, out="/dev/null"):
    return subprocess.run(
        [OPENSCAD, "-o", out, "--export-format", "binstl",
         "--enable=textmetrics"] + args, capture_output=True, text=True)


def derived(args):
    r = run(args + [os.path.join(HERE, "echo.scad")])
    m = re.search(r"ECHO: vals = (\[.*?\])", r.stderr, re.S)
    if not m:
        raise RuntimeError(f"echo.scad said nothing:\n{r.stderr[-400:]}")
    return dict(zip(VAL_NAMES, ast.literal_eval(m.group(1))))


def check_assert(scad, extra):
    r = run(extra + [scad])
    for line in r.stderr.splitlines():
        if "Assertion" in line or line.startswith("ERROR"):
            return False, line.strip()[:170]
    return True, ""


def check_empty(scad, extra):
    r = run(extra + [scad])
    if "Current top level object is empty" in r.stderr:
        return True, ""
    for line in r.stderr.splitlines():
        if "Assertion" in line or line.startswith("ERROR"):
            return False, line.strip()[:170]
    return False, "produced geometry where there should be none"


def export(args, part):
    out = os.path.join(HERE, f".t_{part}.stl")
    if os.path.exists(out):
        os.remove(out)
    r = run(args + ["-D", f'part="{part}"', MODEL], out=out)
    if not os.path.exists(out):
        return None, None, r.stderr[-220:]
    st = mesh.stats(out)
    tris, _ = mesh.load_tris(out)
    os.remove(out)
    return st, tris.reshape(-1, 3), ""


def main():
    names, all_args = place.everything()

    fails, total = [], 0

    def report(ok, label, why=""):
        nonlocal total
        total += 1
        if not ok:
            fails.append((label, why))
        print(f"  {GREEN + 'pass' + OFF if ok else RED + 'FAIL' + OFF}  {label}"
              + (f"\n        {DIM}{why}{OFF}" if why and not ok else ""))

    scads = sorted(f for f in os.listdir(HERE)
                   if f.endswith(".scad") and f not in ("lib.scad", "echo.scad"))

    print(f"\n{place.FONT} {place.SIZE:g}mm bold +{place.BOLD} style={place.STYLE}"
          f"   {len(names)} names")

    print("\n  --- the model's own arithmetic, and the booleans ---")
    for scad in scads:
        path = os.path.join(HERE, scad)
        fn = check_empty if scad.startswith("empty_") else check_assert
        for n in PAIR:
            ok, why = fn(path, all_args[n])
            report(ok, f"{scad[:-5]:40} {n}", why)

    print(f"\n  --- {SECOND_FONT}: the same checks on a different set of numbers ---")
    ic, bc = place.load()
    for n in SECOND_NAMES:
        k = place.ink(n, ic, font=SECOND_FONT)
        a2 = place.args(n, k, place.struts(n, k, bc, font=SECOND_FONT),
                        font=SECOND_FONT)
        for scad in scads:
            path = os.path.join(HERE, scad)
            fn = check_empty if scad.startswith("empty_") else check_assert
            ok, why = fn(path, a2)
            report(ok, f"{scad[:-5]:40} {n}", why)
    place.save(ic, bc)

    # --- the exported mesh, every name ---------------------------------------
    print(f"\n  --- the exported mesh, all {len(names)} names ---")
    bad_shell, bad_glass, bad_band, bad_front, errs = [], [], [], [], []
    for n in names:
        args = all_args[n]
        d = derived(args)
        tag, _, err = export(args, "tag")
        body, bv, err2 = export(args, "body")
        clip, cv, err3 = export(args, "clip")
        if tag is None or body is None or clip is None:
            errs.append(f"{n}: {err or err2 or err3}")
            continue
        if tag["shells"] != 1:
            bad_shell.append(f"{n}={tag['shells']}")
        # nothing but the clip may cross the glass face
        if bv[:, 2].min() < -1e-6:
            bad_glass.append(f"{n}={bv[:, 2].min():.3f}")
        # the clip stays inside the bar's band, so it hides behind it head-on
        if cv[:, 1].min() < -1e-6 or cv[:, 1].max() > d["bar_w"] + 1e-6:
            bad_band.append(f"{n}={cv[:, 1].min():.2f}..{cv[:, 1].max():.2f}")
        # ...and never stands proud of the letters' front face
        if cv[:, 2].max() > d["thick"] + 1e-6:
            bad_front.append(f"{n}={cv[:, 2].max():.3f}")

    report(not errs, f"{'all names render and export':44} ({len(names)} names)",
           "; ".join(errs[:4]))
    report(not bad_shell, f"{'each tag is ONE connected body':44} ({len(names)} names)",
           "loose pieces: " + ", ".join(bad_shell))
    report(not bad_glass, f"{'nothing but the clip crosses z=0':44} ({len(names)} names)",
           "reaches into the glass: " + ", ".join(bad_glass))
    report(not bad_band, f"{'the clip hides behind the bar':44} ({len(names)} names)",
           "; ".join(bad_band[:4]))
    report(not bad_front, f"{'the clip never stands proud of the name':44} ({len(names)} names)",
           "; ".join(bad_front[:4]))

    # --- the grip, as a measured interference --------------------------------
    print("\n  --- the grip ---")
    got, bad = [], []
    for n in PRINT_NAMES:
        args = all_args[n]
        d = derived(args)
        bite, bvv, err = export(args, "bite")
        want = d["glass_t"] - d["jaw"]          # the preload, from the model
        if bite is None:
            bad.append(f"{n}: no interference at all -- {err}")
            continue
        got.append(f"{n} {bite['size'][2]:.2f}x{bite['size'][0]:.0f}mm")
        if abs(bite["size"][2] - want) > 0.06:
            bad.append(f"{n}: bites {bite['size'][2]:.3f} not {want:.3f}")
        if bite["size"][0] < d["spring_len"]:
            bad.append(f"{n}: grips over only {bite['size'][0]:.1f}mm")
    report(not bad, f"{'the clip bites the rim by the preload':44} "
                    f"({', '.join(got)})", "; ".join(bad))

    # --- what the printer is left holding up ---------------------------------
    print(f"\n  --- the print, rasterised layer by layer "
          f"({overhangs.PITCH}mm grid, 45 deg rule) ---")
    R = dict(overhangs.ORIENTS)["letters DOWN  faces on the bed, clip standing up"]

    def raster(args, part):
        stl = overhangs.export(args, os.path.join(HERE, f".t_r_{part}.stl"), part)
        t, _ = mesh.load_tris(stl)
        t = t @ R.T
        t = t - np.array([0, 0, t[:, :, 2].min()])
        occ, p, l = overhangs.occupancy(t, overhangs.PITCH, overhangs.LAYER)
        os.remove(stl)
        return (overhangs.unsupported(occ, p, l), overhangs.support(occ, p, l))

    for n in PRINT_NAMES:
        args = all_args[n]
        d = derived(args)
        u, sup = raster(args, "tag")
        # This model does NOT print unsupported and does not pretend to. What
        # is pinned instead is the DECOMPOSITION: the flat part must rasterise
        # with nothing hanging at all, and the clip accounts for the rest. Ask
        # it of the whole tag and a defect anywhere in the letters hides inside
        # the clip's allowance.
        fu, _ = raster(args, "body")
        cap = d["cw"] * (d["spring_len"] + 2 * d["bend_r"] + 3 * d["clip_len"] / 100)
        ok = fu["area"] <= 0.5 and 0 < u["area"] <= cap * 1.6
        report(ok, f"{'the clip is the ONLY thing that hangs':44} {n:9} "
                   f"body {fu['area']:.1f}mm2, clip {u['area']:5.1f}mm2, "
                   f"support {sup['vol_mm3']/1000:.2f}cm3",
               f"body hangs {fu['area']:.1f}mm2; tag hangs {u['area']:.1f}mm2")

    print(f"\n{'-' * 70}")
    if fails:
        print(f"{RED}{len(fails)} of {total} checks FAILED{OFF}")
        for label, why in fails:
            print(f"  {label}: {why}")
        return 1
    print(f"{GREEN}all {total} checks passed{OFF}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
