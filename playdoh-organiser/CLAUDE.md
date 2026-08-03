# Play-Doh pot organiser

A **stackable tray** for Play-Doh pots. One file, `organiser.scad`, pure OpenSCAD
(no libraries). Selected with `-D render_part="..."`.

---

## The central idea

Use the two features the pots already have, and add nothing.

1. Every lid has a ~4mm **recess** its successor's base nests into — that's the
   stacking, and the tray must not get in its way.
2. The body flares out to a **lip** at the top, Ø49.1 over a Ø45.2 body — a
   downward-facing step on the pot itself, and the right thing to hang from.

Default `hang` cells use both: a Ø45.8 hole clears the body and the lip catches
on it, so pots hang by their own lips and a loaded tray can be picked up — while
the pot still nests 4mm into the lid below at exactly the same height. Two
supports in parallel, zero added height, 20 g a tray.

```
         | lid |            lid entirely clear, 3.4mm above the plate
   .-----'     '-----.
   |                 |   <- pot, base nested 4mm into the lid below
   '---.         .---'      lip flares 45.2 -> 49.1
  ======[       ]======  <- plate: body passes, LIP lands on top
        |       |            1.65mm of ledge, all the way round
```

## Geometry

- Pot: cone `pot_base_d` (38.6) → `pot_shoulder_d` (45.2) over `body_h = pot_h -
  lid_h` (50.1), then the lip (49.1) and lid (51.2, `lid_h` 7). `taper` ≈ 0.0659
  radial mm per mm of height; `pot_d(h)` gives the body diameter h above the base.
- `cell = pot_lid_d + pot_gap` — pitch set by the **widest** point, the lid.
- `nest` cell hole: a cone from `pot_d(lid_recess_h)` to
  `pot_d(lid_recess_h + deck_t)`, + `pot_clear`. Ø39.7 → Ø40.0. Asserted to be
  wider than `lid_recess_d` (or the pot can't drop through) and narrower than
  `pot_lid_d - 3` (or there's no lid rim left to bear on).
- `pitch` = `pot_h - lid_recess_h` (nest) or `pot_h + deck_t` (cup).
- `frustum_h = min(3.2, lid_recess_h - 0.8)` — must never bottom out in the
  recess, or the plate stops bearing on the rim.

## Parts (`render_part`)

**`tray` is the only printable part** — one per layer of pots. Plus `section`
(half cut), `slice` (thin cross-section), `stack`, `pot` for previews.

## Key options

- `cell_style` — `hang` (default, 20 g, retains pots), `nest` (27 g, spacer
  only, no retention) or `cup` (71 g, +6.4mm per layer, no retention). Only
  `hang` lets a loaded tray be lifted.
- `bottom_tray` — post/rail/wall styles only: lengthens the posts by
  `lid_recess_h`. Print one tray with it on for the bottom of the tower.
- `stack_style` — with `hang`: `posts` 60 g (default, includes inner legs) ·
  `pots` 20 g. `inner_legs` / `inner_r` control the mid-span legs.
- `leg_sweep` / `leg_t` / `leg_overlap` / `leg_min` / `leg_seat` / `leg_plug`
  shape the leg. With `hang` the "posts" are LEGS, below the plate;
  with `nest`/`cup` the same geometry stands above it.
  `rails`/`walls` reuse the `posts` corner geometry and add wall material
  between, so the peg interface is identical across all three.
- `deck_style` — `open` (frame + per-cell rings + ribs + corner braces) or
  `solid`. Rings must reach `pot_lid_d`; that rim is what the plate sits on.

## Design decisions & WHY

1. **Don't duplicate the pot's own guide.** The first version put an 8mm collar
   on every cell to cradle the pot base — and, because its deck sat on top of the
   lid, it *covered the recess it should have used*. Paying twice: 71 g instead
   of 27 g, and +6.4mm per layer. The user spotted it. `nest` cells make the
   plate a pure tie and let the lid do the guiding.
2. **The plate must clear the recess mouth, not overhang it.** The hole is Ø39.7
   against a Ø38.6 recess, so the plate bears on lid rim only and never fouls a
   pot dropping in. Both bounds are asserted.
3. **Cell holes follow the pot taper** so clearance is uniform rather than
   pinching at one band. Printable either way: the hole widens upward, so
   material only ever recedes.
4. **One part, not three.** `base` and `top` were both redundant: the bottom
   tray just lies on the table (its pots stand on the table and pass through it
   like any other plate) and a cap is only another tray laid on the top lids. The
   user asked why there were three; there was no good answer. Dropping them took
   a 3-layer tower from 160 g of plates to 81 g.
5. **The bottom tray is the only asymmetry**, and only for the post styles: its
   pots stand on the table instead of dropping `lid_recess_h` into a lid, so they
   sit that much higher and its posts must be that much longer — hence
   `bottom_tray`. `cup` trays have no such asymmetry (a cup seats its pot on its
   own deck at every level, bottom included), and `pots` stacking has no posts
   for the difference to matter to.
6. **`post_h = pitch - fh - deck_t`.** An earlier version omitted `fh`, which
   made posts foul the corner pads of the tray above and grow the stack ~3mm a
   layer.
7. **`hang` catches the LIP, not the lid.** First version caught under the lid
   rim (Ø49.7 hole between lip 49.1 and lid 51.2). The user pointed out the
   obvious problem: a lid is soft press-on plastic and hanging a pot off it
   indefinitely works it loose — and a lidless pot falls straight through.
   Catching the lip instead (Ø45.8, between body 45.2 and lip 49.1) is better on
   every axis: **1.65mm of ledge instead of 0.75mm**, load on rigid pot rather
   than soft lid, a 4.7mm plate ring instead of 2.75mm (so a stiffer tray), and
   pots stay put with their lids off. Costs 5 g of extra plate.
   There is no snap feature anywhere — the body tapers monotonically — so the lip
   step is the only thing on the pot worth catching.
8. **`hang` plates are referenced to their own layer, not the one below**, so
   every plate is identical — no bottom special case, no cap, and no
   `bottom_tray` flag needed. `nest` references the layer below, which is why it
   has the bottom-tray asymmetry.
9. **Inner legs, from print feedback.** The first printed tray flexed when
   carried loaded. Corner legs stiffen only the ends; a leg at each point where
   four cells meet is a 56mm-deep rib bonded to the middle of the plate, which is
   where it sags, and it carries the tray above at mid-span too.
   `inner_r` HAS A FLOOR and the first attempt was below it: at 9mm the leg was
   an island floating in the interstitial void, joined to nothing (must reach
   11.4mm to touch the deck rings). A circle that merely touches is still "barely
   attached" though -- at 16mm the pots cut into it and it becomes the four-lobed
   diamond that FILLS the gap, bonding to each ring along ~21mm of arc.
   It tapers on a CONE (prism INTERSECT cone), not by offsetting the outline:
   fat where it meets the rings, `inner_plug_r` where it plugs in. It is a rib
   first and an interlock second, so there is no reason for the plug to be as
   wide as the base. `inner_cone_h` is solved so its seat lands at exactly the
   same depth as a corner leg's -- otherwise only one of the two ever bears.
   It CANNOT use leg_stack: that lofts with hull(), which would convex-fill the
   diamond's concave sides and swallow the pots.
   `leg_loft`/`leg_stack`/`leg_section`/`leg_hole_2d` all take the outline as
   children() so corner and inner legs share one taper/plug/fit implementation.
10. **`hang` needs legs, and they point DOWN.** The plate sits 47.7mm up the pot,
   so an empty `hang` tray has nothing to stand on — it only self-supports once
   loaded, and you can't put it on a table to fill it. Legs fix that, and the
   length falls out as `pitch - deck_t` (50.7), the same number the posts already
   used. They must hang below the plate: pointing up would leave the bottom tray
   unsupported again.
   The part still **prints plate-down with the legs standing up** (a plate held
   50mm up on four legs would be all bridge) and is **turned over in use**. The
   plate is symmetric so nothing else changes. Legs carry ~4 N, so 9 x 9 x 1.6mm
   is ~4000x the buckling load; they were 14mm, which was 14000x and 24 g.
   No locating peg on a leg: the pots already tie every tray laterally, and a peg
   on the foot would leave the bottom tray rocking on four studs.
11. **The front scoop opens at the top.** An earlier ellipse cut arched over into
   an unprintable overhang. Now a U with a radiused floor, open to the top.

## hull() convexifies -- the corner legs are not what they look like

`leg_loft` lofts with `hull()`, which returns a CONVEX hull. The corner leg
outline is concave (it is cut against the pot ring), so the arc hugging the pot
becomes a straight CHORD and the leg is really a triangular tube, not the
crescent `leg_outline()` describes. Renders of the whole tray hide this -- the
deck pad underneath it is not hulled and does follow the ring, which is what you
see from above. Isolate `vertical()` to see the real shape.

Consequence: the chord's closest approach to a cell centre is
`(cell/2 - leg_overlap) * cos(leg_sweep/2)`. It must stay outside `hang_d/2`.
At the old default sweep of 60 it was 0.037mm INSIDE -- harmless in practice and
the reason a printed tray was fine, but accidental and with zero margin. Default
is now 56 (0.4mm clear) and an assert guards it.

Not "fixed", because the convex triangular tube is arguably stiffer than the
crescent and costs about the same. But the code and the comments claimed a shape
it was not producing. If the crescent is genuinely wanted, the loft has to become
a stack of thin offset prisms rather than a hull.

## Traps hit while building this

- **OpenSCAD hoists functions but NOT variables.** `pot_z0` referenced `hang_z`
  from a block further down the file and silently evaluated to `undef`, which
  propagated into every translate in `tower()` as a warning storm rather than an
  error. Keep derived values in dependency order.

## Preview cuts — two more

- **Cut on a cell centreline, not y = 0.** `cut_y = cy(rows - 1)`. With an even
  number of rows y = 0 falls in the *gap* between them, so the cut misses every
  pot and shows an unbroken plate over an apparently solid lid — which reads
  exactly like the nesting being broken.
- **`color(c) clipped() geom`, never `clipped() color(c) geom`, and only at the
  top level.** A CGAL boolean gives its cut faces the *default* colour, so
  clipping the whole assembly as a lump renders every cross-section flat teal.
  And `clip_solid()` called inside `at_cells()` picks up that cell's translate
  and wanders off the model. `tower()` therefore clips once per colour, in global
  coordinates.
- Prefer `slice` over `section` for reading a joint: a half-cut viewed straight
  on still shows what's *behind* it, so a cell hole reads as solid.

## Build / MakerWorld

`make` (previews + STL/3MF), `make weigh` (filament table), `make styles`.

Published as a MakerWorld customizer, so the parameter block is ordered for that
UI, not for the code: **Layout, Pot size, Options, Preview**, then four
`Advanced - ...` groups, then `/* [Hidden] */`.

- `pot_preset` resolves to the `POT` vector; `pot_h` and friends are DERIVED from
  it. So `-D pot_h=60` silently does nothing now -- use `-D pot_preset='"custom"'`
  with `-D custom_pot_h=60`. The Makefile only ever sets `render_part`,
  `cell_style`, `stack_style` and `leg_*`, so it is unaffected.
- Only ONE preset, and that is deliberate: the Play-Doh figures are measured.
  Inventing plausible dimensions for other pot sizes would be fabricating data
  the model then silently depends on.
- `open_d`, `cup_h` and `head_clear` are CLAMPED (`open_bore`, `cup_z`,
  `head_gap`) rather than asserted -- in a customizer an assert reads as a broken
  model rather than a hint. Only two asserts remain, both for combinations that
  cannot make a working part: a pot with no lip (Hang) and too shallow a lid
  recess (Cup). Each names the style to switch to.
- Checked across 36 grid/style combinations and pot sizes from a 28mm lid to a
  90mm one.

`weigh.py` integrates solid volume from the exported STL — OpenSCAD's
`--summary` reports facets and a bounding box but no volume, and filament cost
is a first-class comparison here, so it's a build target.

## Repo note

Lives in `playdoh-organiser/` within the `RainnWorks/3dmodels` repo, alongside
the unrelated `cake-topper/`, `door-to-ac-hose/` and `van-airfilter-cap/`.

## Open / TODO

- **`hang` is unproven against a real pot.** It depends on `pot_shoulder_d`
  (45.2) and `pot_lip_d` (49.1) being right to within a few tenths. Print ONE
  tray and try it before committing to a stack.
- `lip_h` (4mm) is ESTIMATED, not measured. It only moves `hang_seat` — how far
  up the pot the plate lands — and the pitch comes from the pots nesting, so it
  costs nothing structural. An assert catches it fouling the lid skirt.
- `lid_recess_d` assumed equal to `pot_base_d` (38.6) — not measured. Only
  affects `nest` and `cup`.
- `cup` assumes the **lid top is flat** outside the recess; `hang` doesn't care.
- Idea not built: a **single-cell modular ring** (one puck per pot, clipping to
  its neighbours) — any layout, lighter still, less rigid. Raised, not chosen.
