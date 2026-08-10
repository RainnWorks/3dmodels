# Ruffle piping nozzle

A ruffle nozzle after the Birkmann #122, plus a two-part coupler. One file,
`nozzle.scad`, pure OpenSCAD (no libraries). Selected with `-D render_part="..."`.

---

## The central idea

The part is **a hollow cone with a round mouth at the tip and a wavy slot down
ONE flank**. Both come from a single constant-section prism run up the axis,
with the traced S as its profile — the bulb opens the mouth, the tail breaks
out through one flank.

```
    /\        near the tip: cone narrower than the BULB -> mouth
   /||\
  / |.\       lower: the TAIL sticks out past one flank -> slot, one side only
 /  | .\
/   |  .\     lower still: cone wider than the whole outline -> prism buried
'---------'   in the cavity, cutting nothing
```

**The outline is anchored on its BULB, and that is not cosmetic.** See below —
it is the difference between this part and a different, wrong one.

## The aperture is TRACED, not drawn

`trace/trace.py` finds the base circle in the manufacturer's top-down photo,
scales by the published Ø23mm, and sub-pixel contours the aperture out of the
grayscale (level = midpoint between the light through the hole and the metal
around it), then resamples and periodically smooths the closed curve.

This was not a nicety. The first pass hand-modelled the slot as a swept disc
along a sine centreline, sized by eye from the photo — **3× too large in area**
(45mm² against the real 16.1mm²), and `slot_len` was out by 40%. Eyeballing a
photo produces numbers that feel right and are not.

Output is **normalised to the base diameter**, which is what makes the model
robust to the one thing that is genuinely unresolved (below): `base_d` scales
the outline, the cone, the flange and the entire coupler together.

- `trace/trace_check.png` is the trace drawn back onto the source photo. Look
  at it before trusting a re-trace — it is the only real verification.
- The `APERTURE` block in `nozzle.scad` is generated. Do not hand-edit it.

## The side view needed a camera-tilt correction

`trace/trace_side.py`. The proportions were first taken as "tallest row /
widest row" = 2.111, which was never verified the way the aperture was — the
user caught that, and it was wrong twice over. The camera looks **19.6° down**
at the nozzle, so the axis is foreshortened *and* the base rim's near edge dips
below the base plane and pads the apparent height.

Both fall out of the base ellipse, because a circle viewed at tilt θ projects
with major axis `D` (horizontal, unforeshortened) and minor axis `D·sin θ`,
while the axis projects to `H·cos θ`. Corrected: **h/d = 2.063**, and fitting
the two flanks to straight lines and intersecting them for the virtual apex
gives the truncation as **tip Ø3.1mm** — a number that had been a guess.

The moral matches the aperture's: a measurement off a photo that has not been
drawn back onto the photo is not a measurement.

## The anchoring bug: the worst one in this model's history

The traced S was first anchored on its **centroid**. That produced a nozzle
whose tip was split into two free petals and which you could see straight
through, front to back. It rendered perfectly, passed every test, and was
wrong. The user spotted it in a preview and asked why the cutout appeared on
both sides.

**Why it happens.** The traced S is a *projection* of two features that are not
co-located: the round mouth at the tip, which IS on the axis, and the slot
running down one flank, which is not. For an S-shaped region the centroid sits
near the waist — and here it landed 0.2mm from the outline, so the axis was
essentially ON the boundary. Anchoring there dragged the tail across the axis,
and a prism cut through a profile that straddles the axis severs BOTH walls.

The topology of the whole part was hanging on a 0.2mm placement decision made
by an arbitrary convention.

**How it was settled** — not by argument, by looking. Zooming the tip in the
side photo shows a **continuous, unbroken oval rim** with the slot running down
one flank below it. Two free petals would show two prongs and a notch.

**The fix.** Anchor on the BULB, found as the largest inscribed circle (max of
the distance transform of the hole mask) — which is just "where the shape is
widest" and needs no threshold. `trace.py` emits `APERTURE_BULB_R` alongside
the outline, and the model derives `mouth_d` and `one_sided_r` from it.

**Corroboration, all of which had been quietly failing before:**

| | before (centroid) | after (bulb) | reality |
|---|---|---|---|
| anchor offset from disc centre | 0.8, 2.5mm | 0.8, 1.1mm | should be ~0, it is the axis |
| flank slot length | 35% of height | 67% | side photo: 72% |
| bulb diameter | (meaningless) | Ø2.55 | the tip mouth |

Note the middle row. Under the old model the slot came out at 35% against the
photo's 72% — a factor of two — and rather than treat that as the contradiction
it was, it got explained away as "the extra is a closed drawn seam". **A story
invented to reconcile a wrong model with the evidence.** The seam does not
exist; the 72% line is simply the slot. Distrust any explanation whose only job
is to absorb a discrepancy.

`tests/empty_slot_is_one_sided.scad` is the regression: beyond the mouth, the
outline must lie in one half-plane. Re-anchoring on the centroid takes it from
empty to 1,424 facets.

## The conflicting dimension, and why it is a parameter not a decision

Three published/derived numbers disagree:

| source | says |
|---|---|
| product copy (twice) | Ø 23 mm |
| spec table | 1.8 × 1.8 × 3.5 cm — cannot contain a Ø23 disc |
| the side photo, tilt-corrected | height/base = 2.063 -> 47.4mm at Ø23, 37.1mm at Ø18 |

The corrected ratio is new evidence and it does **not** favour the default:
Ø18 lands within 6% of the published 35mm and matches 1.8 × 1.8 exactly, while
Ø23 agrees with nothing but itself. Default is still Ø23, because it is the only
number explicitly labelled a diameter and the traced aperture is scaled to it —
but this is now a live question, not a settled one. Rather than pick a winner and bury it,
everything derives from `base_d`, so `-D base_d=18` rescales the whole system.
This is the same instinct as the organiser having exactly one measured pot
preset: do not fabricate data the model then silently depends on.

## Geometry

- Outer cone `r_o(z)`, cavity `r_i(z) = r_o(z) - wall(z)`. `wall(z)` is linear
  in z, so the cavity is a cone too and is one `cylinder(r1, r2)` — no lofting.
- `tip_wall_t` > `wall_t` deliberately: at the top the wall is two free petals,
  not a tube, and it needs the extra section.
- `petal_len` is DERIVED and echoed — the height at which `r_o(z)` drops below
  the aperture's reach, subtracted from the total. It is the main structural
  unknown in the part, so it is reported rather than hidden.
- `ap_area` is echoed too, by shoelace on the traced outline, against a #12
  round tip's 12.6mm². A nozzle you cannot squeeze is a failure mode that no
  dimension check catches.
- The clamp between ring and flange is a matching pair of **45° cones**, not a
  flat step (see decision 4).

## Parts (`render_part`)

`nozzle` is a complete tool on its own. `sleeve` + `ring` are the coupler and
are only needed to swap tips mid-bag. `coupon` is the top 16mm on a pad — the
aperture test print. Plus `assembly` / `section` / `all` / `aperture` for
previews.

## Design decisions & WHY

1. **The cone IS the retention feature.** The brief asked how to make it stay
   on any piping bag; the answer is that it already does. You drop the nozzle
   in and snip the bag 2–3mm under the base diameter, and the taper wedges in.
   That is why steel nozzles carry no thread, clip or flange. Nothing needed
   inventing here — only not breaking it.
2. **A base flange, which steel does not have.** Steel relies on friction
   alone; printed PETG is slicker and can push out through the snip under hand
   pressure. One ring of material makes that impossible, and it doubles as the
   coupler's clamping face.
3. **The nose follows the nozzle's bore, rather than plugging it.** A plain
   cylindrical nose sized to the base bore can only enter ~2.5mm before the
   taper stops it. Cutting the nose to `r_i(z) - 0.3` means it nests the full
   `nose_h` and *centres* the nozzle instead of merely filling it.
4. **The clamp is a 45° cone pair, not a flat step.** A flat step needed a
   1.95mm horizontal annular overhang in the ring — bridgeable but ugly. Making
   both faces 45° gives a self-centring conical seat, self-supporting on both
   parts, and it fell out for free because the flange chamfer and the ring
   relief happened to want the same angle.
5. **Our own thread, not a reverse-engineered Wilton.** We cannot measure
   theirs. A thread we define is a thread `make test` can prove.
6. **Every part is modelled in its assembly orientation and printed in it.**
   Nothing is flipped. This is not tidiness: flipping a part reverses thread
   handedness, and an external and an internal thread that disagree is a bug
   that only shows up on the printer. The ring is therefore modelled lip-up and
   printed lip-up.

## A helical thread is a TWISTED PRISM

At any height a thread rib occupies one angular sector, and that sector rotates
with height — which is exactly what `linear_extrude(twist=)` sweeps. So the rib
is `linear_extrude(h, twist = -360*h/lead)` of `circle ∩ wedge`. Sector width
is `360 * rib_thickness / lead`; multi-start is the same rib repeated at
`360/starts`; the twist is set by the **lead**, not the pitch.

One extrude gives a square thread. A trapezoid needs the sector to narrow as
the radius grows, which one extrude cannot do, so it is `thr_layers` nested
helices of decreasing angular width — the same staircase trick the
playdoh-organiser uses on its legs, for the same reason.

The sleeve's rib and the ring's groove come from **one module**, the groove
being the rib grown by `thr_rclear`/`thr_aclear`, so they cannot drift apart.

### `thread()` takes an ABSOLUTE z, and that is load-bearing

`linear_extrude(twist=)` sets phase from the *start of the extrude*. The ring's
groove has to span a taller range than the sleeve's rib (below), and starting
it 1mm lower silently rotates it by `360/lead` = 40° — the two would simply not
screw together. So `thread(z0, h)` pre-rotates its 2D shape by `360*z0/lead`
and phase is always referenced to z = 0.

`empty_ring_screws_onto_sleeve` is the regression: deleting that one `rotate()`
takes the test from empty to **39,660 facets** of interference.

## Coincident faces are not fits — three bugs, all the same bug

CGAL hands a zero-volume shell to every later boolean, so anything modelled to
abut *exactly* shows up as phantom interference and can also fragment a mesh.
All three came out as `z = a..a` with **0.000 mm³** of volume, which is the
signature to look for:

1. **Two threads ending on the same plane.** Both stopped at z = 0. Fixed with
   `thr_runout` (groove runs out past the rib) and `thr_top_gap` (rib stops
   short of the seat) — the runout deliberately goes *downward only*, because
   running it up past z = 0 cut through the ring's clamp cone and **sliced the
   lip off the body: 25 separate solids**, which `mesh_ring_is_one_piece`
   caught.
2. **The clamp cones modelled coincident.** Fixed with `clamp_relief` — the
   ring simply screws 0.2mm further down before it bites, and it has 9mm of
   thread to give.
3. **`ring()`'s own bore meeting its clamp cone** at the same z *and* the same
   diameter. Fixed by running the bore `2*eps` past the cone's start. This one
   was internal to a single module and still leaked into every fit test.

## Overhangs are measured, not claimed (`make overhangs`)

The README asserted the thread flanks were "45 deg or shallower". They are a
**20 deg staircase** -- `thread()` builds each flank as `thr_layers` nested
extrusions, so it is six 0.167mm steps, every one of them a 90 deg face.

Reading the exported meshes back settled it, and the lesson is that facet angle
alone is the wrong statistic. What decides whether a face needs support is the
LEDGE WIDTH -- how far it stands out past what is under it. 0.167mm bridges
without noticing; the same 90 deg face 3mm wide would droop. `overhangs.py`
reports both.

Result: the nozzle has nothing near-flat at all (worst 11 deg), and the coupler
halves are the thread staircase plus, originally, one ~1mm ledge each where the
rib started square out of the core.

`thr_lead_in` fixed the sleeve's: the rib is trimmed to an envelope that ramps
it out of the core over 1.5mm at each end, turning a full-depth horizontal
ledge into a 34 deg cone, and taking the worst ledge from 1.00mm to 0.19mm --
i.e. down to the staircase step, with no square run-out left. It also makes the
rib self-centring going into the ring, which is the bigger practical win.

The ring's groove deliberately does NOT get one and keeps its 0.73mm ledge: a
groove trimmed at its ends would be shallower exactly where the rib has to
enter, and would foul it. Only the male thread can take a lead-in.

Worth doing before believing any "no supports" claim about a new part.

## The test coupon was deleted, and why that is the interesting bit

There was a `coupon` part: the top 16mm of the nozzle on a pad, ~1/3 of the
layers, sold as a cheap way to check `slot_grow` before committing to a full
print. The user asked why you would bother. Measuring settled it:

| region | median slot width |
|---|---|
| in the coupon (z >= 31.4) | 1.79 mm |
| below it (z 15.6 .. 31.4)  | 0.86 mm |

The slot is 1.9mm at the mouth and tapers to 0.8mm and below down the tail.
Only the tail can close up -- and the coupon covered the wide half. It would
have printed cleanly every time while the at-risk region went untested, which
is worse than not printing it, because it manufactures confidence.

The nozzle is an hour and is itself the test, so the coupon is gone. What
replaced it is a NUMBER rather than a part: `trace.py` measures the slot's
local width (distance transform along its ridge) and emits `APERTURE_MIN_W`,
and the model echoes what that becomes after `slot_grow` in units of extrusion
width, warning under 2. Currently 0.96mm = 2.4 extrusions -- close to the floor.

The general lesson: a cheap test that does not cover the failure mode is not a
cheap test. Check what the sample actually spans before trusting it.

## Tests (`make test`, tests/run.py)

Same three kinds as the playdoh-organiser, for the same reason: checking that a
value is derived correctly is not the same as checking that two parts meet.

- `assert_*.scad` — render must succeed; asserts on derived values.
- `empty_*.scad` — render must produce NO geometry. `difference(A,B)` empty
  means A fits inside B; `intersection(A,B)` empty means they miss. This is the
  kind that matters: the nozzle, sleeve and ring are each obviously fine alone.
- mesh checks — component count and bounding box from the exported STL.
  `mesh_*_is_one_piece` catches fragmentation (the ring became 25 pieces once),
  but note what it did NOT catch: the two-free-petals bug left the nozzle a
  single connected solid, because the petals still met at the base. Connectivity
  is a weak invariant. `empty_slot_is_one_sided` is the one with teeth.

`tests/lib.scad` includes the model and sets `render_part = "none"` **after**
the include — OpenSCAD resolves a scope's assignments before evaluating
geometry and the last wins, so setting it first is silently overwritten.
`$fn = 240` so a fit cannot pass on tessellation alone.

`lib.scad`'s `nose()` is `sleeve() ∩ (z > 0)` — the REAL part — not a copy of
the cone in `sleeve()`. It was written as a copy first, which would have passed
whatever the model did; falsification is what exposed it.

**Every test was verified against a deliberately broken model:**

| test | broken by | result |
|---|---|---|
| `empty_ring_screws_onto_sleeve` | delete the phase `rotate()` | 39,660 facets |
| `empty_nose_enters_bore` | nose as a straight cylinder | 1,440 facets |
| `empty_ring_clears_nozzle` | `clamp_relief=-0.6` | geometry produced |
| `assert_fits` | `flange_over=3` | assert fires |
| `empty_aperture_inside_bore` | `slot_grow=6` | assert fires |
| `empty_slot_is_one_sided` | re-anchor outline on its centroid | 1,424 facets |

Do the same for any new test. A test that cannot fail reads as coverage and is
worse than no test.

## Traps

- **`ptp` is gone in numpy 2.x.** `arr.ptp()` is an AttributeError; use
  `np.ptp(arr)`. Bit the tracer.
- `cp` is aliased interactively here and will block on an overwrite prompt.
  Use `command cp -f` in scripts.

## Build

`make` (previews + STL/3MF), `make test`, `make coupon`, `make trace`.

`sleeve.stl` / `ring.stl` come out ~12MB — the thread is a stack of swept
helices at `slices = max(24, h*6)`. The 3MF is a tenth of the size. If the STL
size ever matters, `thr_layers` is the cheap knob.

## Repo note

Lives in `ruffle-nozzle/` within the `RainnWorks/3dmodels` repo, alongside the
unrelated `cake-topper/`, `door-to-ac-hose/`, `playdoh-organiser/` and
`van-airfilter-cap/`.

## base_d is settled at 23, and that dissolves the coupler question

The published numbers conflict (Ø23 stated twice, against a 1.8 x 1.8 x 3.5cm
bounding box, against a measured h/d of 2.063). Two size variants were shipped
for a while so a print could settle it -- and the coupler had to be exported
per diameter, because its thread, clamp and nose all derive from base_d.

The user asked the question that dissolved it: what is the Ø18 variant FOR? The
only thing that could have made the true diameter matter is fitting a
commercial coupler, and we print our own. Nothing downstream depends on it. So
it is a free choice, and Ø23 wins on flow area (16.1mm^2 vs 9.9, the latter
being below a plain #12 round tip) and on every feature being 22% larger and
thus more reliable at 0.4mm.

One diameter, one coupler, no suffixes. `make size D=20` covers the other case
and builds the WHOLE set, never a lone nozzle -- cross-fitting fails in both
directions at once (ring lip 2.8mm too wide to catch the smaller flange, nose
4.4mm too fat to enter the smaller bore).

The tests still run at BOTH 23 and 18. The reason changed: not because 18 ships,
but because it is the cheapest available proof that the parameterisation is real
rather than tuned to one number.

If the profile family in the TODO happens, all of it shares base_d = 23 and so
shares one coupler already. The standard-shank idea is only needed if different
profiles ever want different cone diameters, which is unlikely.

## Open / TODO## Open / TODO

- **Nothing has been printed.** `slot_grow` (does the aperture open to the
  traced size?) and the petals are both waiting on a print. Print `coupon`
  first.
- **`petal_len` is 17.5mm of free wall at 1.4mm.** Curved, so far stiffer than
  the numbers suggest, but if it splays the ruffle thickens under pressure.
  `height_ratio` down or `tip_wall_t` up.
- **The base diameter is unresolved** (Ø23 vs Ø18) and is being settled by
  printing both — `make sizes`. The test suite runs at both diameters, so
  either is a supported part, not a hopeful `-D`.
- The sleeve's nose bore steps from Ø15.4 to the nozzle's Ø18.2 — a small
  backward-facing step where icing can sit. Irrelevant to flow (both are >10×
  the aperture) but it is a cleaning nuisance; taper the nose thinner if it
  proves annoying.
- Ideas raised, not built: a **tip cap** so the slot does not crust between
  sessions; a **cleaning pick** shaped from the same `aperture_2d()` shrunk
  0.3mm (dried icing in a 1.6mm wavy slot is otherwise horrible); a
  **profile family** — the cone is entirely independent of the outline, so
  petal/star/round tips are a second `APERTURE` constant each.
