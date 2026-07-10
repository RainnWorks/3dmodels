# Van air-filter cap

A **tapered press-fit weather cap** for a van air filter. One file,
`airfilter_cap.scad`, pure OpenSCAD (no libraries). Selected with
`-D render_part="..."`.

---

## How it works

The **big end clips onto the ~250mm housing rim** (a straight grip band presses
over it); the cone **tapers down to a ~160mm closed end** that covers the filter
element sitting ~140mm inside. It mounts **horizontally**: closed end out, and a
**vent field on the lower arc** lets air in while the solid top sheds rain.

```
   printed small-end-down (Z up):
                    ___________________     big end (clip) 250mm: grips the rim
                   /                   \
                  /   taper 250->160     \
       closed -> |______________________|  small end 160mm: over the filter,
       vented        mesh (lower arc)        closed; vents on the lower side
       end
```

## Geometry (all derived from a few measured numbers)

- `lip_od` (243) — housing rim OD the cap clips over. `big_d = lip_od +
  mouth_clear + 2*wall` ≈ 249.8 (assert keeps it ≤ `max_build` 250).
- `small_d` (160) — filter OD / small closed end.
- `taper_len` (140) — rim→filter distance = the cone length.
- `clip_len` (25) straight grip section; grip band = `grip_bore = lip_od -
  press_fit`, clearance bore elsewhere.
- Height = `small_len + taper_len + clip_len` ≈ 180.

## Parts (`render_part`)

`cap` (the part) · `section` (cut-away) · `profile` (vertical cut through the
vents, to read print overhangs) · `on_filter` / `inuse` (preview).

## Vents (`vent_style`)

- `grid` (default) — **diamond mesh**. Holes are `grid_h` tall × `grid_w` wide
  with `grid_h > grid_w`, so each hole points at the top: **no flat roof**, prints
  without support. Rows brick-offset; angular pitch recomputed per row for the
  taper. Biggest open area.
- `louver` — slanted slots swept with `rotate_extrude`; roof rises at
  `louver_angle` (≥45) from horizontal so the overhang self-supports.

Both live only on the lower `vent_arc` (≈160°) centred on `vent_center` (270 =
bottom), so openings face down in use → rain can't fall in.

## Design decisions & WHY

1. **Taper, printed small-end-down.** Closed end flat on the plate (no ceiling to
   bridge); the cone flares out ~18° off vertical → self-supporting. The other way
   up would need support under the closed end.
2. **Clip at the big end.** The cap grips the 250mm housing rim, not the 160mm
   filter (the filter just sits inside). Grip band is a short interference band;
   the rest of the bore is clearance so it slides on and only bites at the rim.
3. **Vents self-supporting, not just angled.** First attempt was horizontal
   louvers → flat overhangs, unprintable. Fixed by (a) slanting louver roofs ≥45°,
   then (b) preferring a **diamond grid** whose holes peak at the top — the user's
   call, and it prints cleaner with more airflow.
4. **Vents on the lower arc only.** A downward-facing opening can't collect
   falling rain, so the whole rain story is orientation + keeping the top solid.
5. **`--render` for previews.** The taper + swept/arrayed vents overflow the fast
   preview CSG normaliser (blank PNGs); full CGAL render fixes it. STL/3MF already
   use CGAL.

## Build / MakerWorld

`make` (previews + STL/3MF). Annotated for the MakerWorld customizer: upload the
`.scad`, `/* [Section] */` groups, `// [min:step:max]` sliders, `render_part` and
`vent_style` dropdowns, internals under `/* [Hidden] */`. Single-colour part.

## Repo note

Lives in `van-airfilter-cap/` within the `RainnWorks/3dmodels` repo, alongside the
unrelated `door-to-ac-hose/` and `cake-topper/` projects.

## Open / TODO

- Confirm `lip_od`, `small_d`, `taper_len` against the real filter + housing.
- Tune `press_fit` with a short test ring before printing the full 180mm part.
