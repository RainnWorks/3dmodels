# Variant 2: what the measurements decided

## What this is

Variant 1's tag, with the clip rotated 90 degrees out of the letter plane.
That is not a description of the intent, it is a description of the FILE:
`nametag_back.scad` is 200 lines of which about twenty are geometry, and the
rest is a header explaining the rotation. It `include`s
`../glass-name-tag/nametag.scad` and uses that model's `body_2d()` and
`clip_2d()` unchanged. The one substantive line is:

```openscad
module clip3() {
    translate([0, cw, 0]) rotate([90, 0, 0]) linear_extrude(cw) clip_2d();
}
```

`rotate([90,0,0])` carries the clip drawing's y into z, so the curl still wraps
a slab lying under the glass face -- only now that face is the letter plane's
BACK rather than the tag's bottom edge. The determinant is +1, so it is a
rotation and not a mirror: the clip is the same hand as variant 1's.

Everything else -- the measured ink placement, `style="lift"` and the baseline
that rides on each name's own descent, the bar with its rounded end, the MST
struts, `bend_r = glass_t/2` so the rim seats in the curl -- is variant 1's, by
reference. `measure.py` and `bridges.py` are imported from that directory as
modules, not copied, and because the 2D is literally the same 2D, the strut
coordinates bridges.py computes are already in this model's frame.

Frame: **x up the glass** (the name runs along it and is read vertically, as in
variant 1), **y along the rim**, **z radial**. The letters are a flat
silhouette at `z = 0..thick`; the wall is `z = -glass_t..0` below the rim.

## Printability: it needs support, 0.08 cm3 of it

`make overhangs`, `Justine`, 16,888 facets, 0.2mm grid, 45 degree rule:

| orientation | bed | unsupported | worst reach | support | letters |
|---|---|---|---|---|---|
| **letters DOWN, faces on the bed** | **375 mm2** | 52.3 mm2 | 19.2 mm | **0.08 cm3** | flat |
| letters UP, backs on the bed | 2 mm2 | 425.2 mm2 | 64.6 mm | 1.60 cm3 | flat |
| as worn, on edge, clip on top | 2 mm2 | 145.7 mm2 | 15.0 mm | 0.60 cm3 | on edge |
| inverted, on edge | 4 mm2 | 155.2 mm2 | 10.0 mm | 0.73 cm3 | on edge |
| on its side, bar's edge down | 236 mm2 | 88.9 mm2 | 33.4 mm | 0.40 cm3 | on edge |

The bottom three stand thin script strokes on edge and are not an option
whatever the numbers say; they are measured so the comparison is on the record.
Between the two that keep the letters flat it is a factor of twenty:
**0.08 cm3 against 1.60**. Letters-up puts the clip's curl on the bed and
floats the entire name and bar 4.4mm in the air, which is the 64.6mm reach.

### What hangs, and where the support lands

Printed letters-down, everything in the letter plane is a first layer: the flat
part rasterises with **0.0 mm2** hanging. All 52.3 mm2 is the clip, and it is
in two parts:

- **the curl** is nearly free. It leaves the bar tangent to the bed and arcs
  up, so the first layers grow straight off the plate; only the last of the
  arch reaches out.
- **the sprung arm** is the bill: 2.4mm wide, running 18mm back along the tag
  at a fixed height with the jaw -- deliberately empty -- underneath it.

The support columns land on **3 mm2 of bed and 48 mm2 of the part**, and
printed letters-down every upward-facing surface is a BACK face. Those are the
faces that lie against the glass. **The letters' own faces are on the build
plate the whole time and are never touched.** Bambu tree supports at 0.2mm top
distance over 48 mm2 is a pad you pull off with a fingernail.

That is the honest verdict, and it cannot be designed away. The arm is on the
far side of the glass wall from the letters and the only way round a glass wall
is over the rim, so the arm is always a cantilever hanging off the curl.
Sharper: printed letters-down, moving the arm's face TOWARDS the letter plane
is moving it DOWN in the print, so **closing the jaw and being self-supporting
are the same axis in opposite directions**. An arm raked back far enough to
support itself is an arm that opens away from the wall and never grips.

### The only real lever

`make trade` sweeps the arm, which is both the support bill and the spring:

| `spring_len` | support | unsupported | reach | grip length |
|---|---|---|---|---|
| 6 mm | 0.03 cm3 | 24.5 mm2 | 7.6 mm | 10.6 mm |
| 10 mm | 0.05 cm3 | 33.6 mm2 | 11.4 mm | 13.9 mm |
| 14 mm | 0.06 cm3 | 42.7 mm2 | 15.4 mm | 17.7 mm |
| **18 mm** | **0.08 cm3** | **52.3 mm2** | **19.2 mm** | **21.6 mm** |
| 22 mm | 0.09 cm3 | 61.4 mm2 | 23.2 mm | 25.5 mm |
| 26 mm | 0.11 cm3 | 71.0 mm2 | 27.2 mm | 29.5 mm |

Linear in both directions, and cheap either way: halving the arm to 10mm saves
0.03 cm3 and gives up 8mm of the length over which the clip actually clamps.
Variant 1's 18mm is kept, because the number that matters is not the support --
it is that spreading 0.8mm of interference over 21.6mm is what makes this a
clip rather than a hook that touches at one point.

## The grip

Variant 1's clip, so variant 1's numbers -- but they are re-asserted here,
because variant 1 only checks them while IT is building a tag and from this
side it never is.

| | value | how |
|---|---|---|
| gap where the rim bottoms out | 2.00 mm | `jaw_root = glass_t`: the rim SEATS in the curl |
| bend radius | 1.00 mm | `glass_t/2`, which is what makes the seat concentric |
| gap at the end of the arm | 1.20 mm | **0.8mm of preload** |
| interference, measured off the mesh | **0.79 mm** deep over **20 mm** | `part="bite"` intersected with the wall |
| clip width along the rim | 2.4 mm | the bar's own depth |

**The wall had to be drawn properly before that number meant anything.**
Modelled as a square-ended slab, the wall's corner cuts across the curl and the
measured interference came out as **2.00mm -- the entire thickness of the glass
-- instead of 0.8mm of preload**, and the test failed. A fire-polished wine rim
is a half-round, and `bend_r = glass_t/2` exists precisely so the curl is
concentric with it. Giving the wall its round end made the seat exact and the
measurement fell straight onto the design intent. A test measuring the right
thing against the wrong model of the glass is worse than no test.

## Head-on is the view that matters

`previews/head.png` is rendered at camera `0,0,0,0,0,0,0` and is the first
thing `make renders` produces, because every wrong turn this variant took was
invisible in an isometric render and obvious face-on.

What it shows: the clip is **2.4mm wide, exactly the bar's depth, and sits in
the bar's own y band**, so head-on it is hidden behind the bar. It crosses no
lettering anywhere. That is not an observation about a render, it is
`tests/empty_clip_hides_behind_the_bar.scad`: flatten the real clip into the
letter plane, subtract the bar's band, and demand the result be empty. Sliding
the clip 2mm up out of the band fills it with geometry.

The arm does run back underneath the name's x range -- it has to, a U-clip's
return leg goes back the way it came -- but it does so *behind the bar*, in the
2.4mm band the bar already occupies, and on the far side of the glass.

## Where variant 2 stands against variant 1

Better:

- **The name faces the room** instead of being read edge-on. That is the whole
  point and it costs one rotation.
- Nothing else changed, so nothing else can have regressed.

Worse:

- **It needs support.** Variant 1 is a flat part and prints on a bare plate.
  0.08 cm3 and a mark on the faces that touch the glass is the whole price, but
  it is not zero.
- **The clip is 2.4mm wide along the rim** where variant 1's is 2.6mm deep in
  the same physical direction -- near enough identical, but it is now tied to
  `bar_w` rather than to `thick`, so anything that thins the bar thins the
  clip. `assert_clip_grips` holds it above 0.8mm.
- **The tag is a flat chord against a round glass.** The letters lie in one
  plane and the glass curves away from it; the longest name here is 75.3mm end
  to end, so only the middle touches. Variant 1 did not care, because its plane
  was radial.

## Tests

34 checks, `make test`. Four booleans, two assertion files, five mesh checks
over all 33 names, a measured grip, and the print rasterised layer by layer.

The print check pins a **decomposition** rather than a verdict: the flat part
must rasterise with 0.0 mm2 hanging and the clip accounts for the rest. Asking
it of the whole tag at once only bounds the total, and a defect in the letters
would hide inside the clip's allowance.

`make falsify` breaks the model eleven ways and all eleven are caught. Two of
those breaks are worth naming because they are the ones a reader would doubt:
sliding the clip out of the bar's band (the head-on invariant), and setting
`preload = 0` (the grip both as an assertion and as a measured solid).

`empty_body_clears_the_glass` is the cheapest check here and it is honest to
say so: the body is a `linear_extrude` from z = 0, so it holds by
construction. What it guards is the join -- unioning the clip into the body, or
extruding about z = 0 instead of from it, both look harmless and both put
letters inside the wall. Unioning the clip in takes it from empty to 1,004
facets.

## Open

- **Nothing has been printed.** The preload, the entry lip and the support pad
  are all waiting on a real glass and a real rim measurement.
- **The arm is straight over 18mm** while a wine glass bowl is not, below the
  rim. This is inherited from variant 1 unchanged, and unresolved there too.
- **The clip's width is the bar's depth.** If the lettering ever wants a
  slimmer bar, the clip goes with it and the grip narrows.
