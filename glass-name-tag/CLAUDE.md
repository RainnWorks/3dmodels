# Glass name tags

A script name that clips over a wine glass rim. One file, `nametag.scad`, pure
OpenSCAD, selected with `-D style="..."` and `-D render_part="..."`, driven by
four small Python tools that **measure** rather than assume.

---

## The central idea

**A font's metrics are not a bound on where its ink goes, and a script font's
metrics are not even close.** Every defect in this design's ancestor, and every
design decision here, follows from that one fact.

```
        _   _
      _/ \ / \_          <- ink_rise above the baseline
 ----------------------  <- BASELINE, and the rail sits HERE
      \_/                <- ink_drop below it: 1.33mm for "Alice", 7.96 for "Jenny"
                            the font says 7.96 for both
 - - - - - - - - - - -   <- y = 0, THE GLASS FACE. nothing but the clip crosses this.
```

## The bug this model exists to avoid

The MakerWorld original places text with `valign="bottom"`, which pins the
font's **declared descent line**. Measured at 15mm, Great Vibes claims a
descent of 7.96mm for every string; the real ink reaches 7.96mm for `Jenny`
(whose `y` touches the descent line) and **1.33mm** for `Alice`. Pacifico is
worse: 9.48 claimed, 0.10 real for `Alice`.

So a tail-less name floats clear of the bar and prints as loose letters. The
reviews are full of the workaround — hand-tune the offset, "-3.0", "-5.5 to -7
depending on the letter" — and that workaround is the *other* complaint in the
same reviews, letters fouling the glass. Measured on the original file:
`txtYOffset=-3.0` puts ink at **y = -1.00**, `-5.5` at **y = -3.50**.

One missing measurement, two opposite symptoms, no offset that fixes both.

**The moral matches the ruffle-nozzle's:** a number taken from a font's own
description of itself, never checked against the geometry, is a guess. And
here, as there, the fix was to measure the real thing — `measure.py` renders
the letters through OpenSCAD and reads the extents off the exported mesh, so
the number comes from the same shaper that renders the final part.

## Every claim here is measured off the mesh

That is not a style preference, it is what kept catching real errors:

- **The style choice.** `lift` looked best in a render and was killed by
  `weld.py`: its weakest name is held on by **one 2.15mm joint** against
  `rail`'s 9.66mm across 9–11 joints. The user's instinct ("that would be
  extremely brittle, sometimes only the descenders of a p holding it") was
  right, and the number is what settled it in a minute rather than an argument.
- **The font thickening.** `bold = +0.15` is not taste. Eroding the letters
  until they broke into pieces put Great Vibes' narrowest stroke at **0.30mm**,
  below one 0.4mm extrusion. Pacifico survived 0.40mm of erosion intact.
- **The "just use a connected font" idea.** Sounded right, would have removed
  the bar entirely, and is not available: `Tom` is 2 pieces in Great Vibes and
  `Gabby` is 4, median gap **1.22mm**, and the same holds for Pacifico, Snell
  Roundhand, Savoye LET, Brush Script MT and Zapfino. Five minutes of measuring
  saved building on a false premise.
- **The clip was a hook.** The bend radius was picked as a free number (2.4mm)
  and *looked* fine. Intersecting it with the glass wall said it touched the
  rim over **2.6mm** — the curl was 4.8mm wide for a 2mm rim, so the rim never
  seated and only the arm's tip reached it. Deriving the curl from the rim
  (`glass_t/2`) took contact to **24.0mm**. The user spotted this by eye from a
  render before any measurement was taken; the measurement only confirmed it.
- **A regression the tests caught.** The first swish put its stroke's lower
  edge at **y = -0.10** — the centre was placed at `spine_w/2` when the stroke
  is `swish_w` wide. Invisible in a render; `empty_ink_clears_glass` failed
  immediately.

## The S in the swish is forced, not a bug

The rail is horizontal at the baseline. A hook that grips the rim must be
tangent to the glass face, so also horizontal, 8.5mm lower. **Any curve joining
two horizontal tangents at different heights reverses curvature.** That S is
what reads as "going against the flow of the text".

It cannot be removed by tuning the control points — only by giving up one of
the tangents. `swish_rise` sidesteps it instead: lifting the stroke off the
baseline before it dives makes the reversal read as a pen lifting into a
flourish rather than a ramp. Worth remembering before trying to "fix" it again.

## What went wrong on the way, and what it cost

- **Two contact sheets are not a test.** `flush` and `lift` both looked good on
  `Jenny` + `Alice` and both fell apart across the real 33 — `flush` amputating
  descenders mid-bowl, `lift` brittle. `grid.py` renders the whole set for
  exactly this reason. Judge a set on the set.
- **zsh does not word-split unquoted `$VAR`.** A shell loop passing
  `$CAM` (several OpenSCAD flags in one variable) silently produced no output
  at all — no error, no file. All command lines are built as Python lists now.
- **A boolean emptiness test needs a tolerance.** The bar and the clip both
  *touch* y=0 by design; CGAL returns a zero-volume shared face for that, which
  reads as "not empty" and failed every clearance test. `tests/lib.scad` offsets
  the half-space by `tol = 0.01`.
- **Stale exports are dangerous.** An early run packed onto 3 plates; a later
  one onto 2, leaving `plate3.3mf` behind, indistinguishable from a real plate
  at the slicer. `plate.py` now wipes `export/plate*` before writing.

## The packing is a bin-packing problem, and greedy is not enough

33 tags, 2589mm of total length, rows of 240mm, 6 rows a plate. Two plates
needs **94.5%** of every row filled. First-fit *and* best-fit decreasing both
stall at 13 rows; seeded random restarts find 12. `plate.py` does FFD then 4000
restarts from a fixed seed, so the same names always give the same plates.

Also: rows are packed first, then **distributed evenly** over plates. Total
print time does not depend on the plate count — it is the same parts — so the
only cost of an extra plate is the swap, and a plate holding one tag pays that
for nothing.

## Not for MakerWorld

Unlike the other models here, this one stays local. The design it follows is
under a Standard Digital File License that forbids sharing derivatives. Writing
the geometry from scratch and printing a set for a family wedding is fine;
publishing it is not.

## If this gets picked up again

- `names.txt` then `make plates` is the whole workflow.
- The caches (`ink.json`, `bridges.json`) are keyed by font, size, bold,
  spacing, style and the set baseline, so changing any of them invalidates the
  right entries on its own. `make clean` drops them.
- `set_drop` is what makes a set look like a set: every tag shares one baseline
  height, taken as the deepest ink across the whole list. A single tag rendered
  on its own uses its own ink and will sit at a slightly different height.
- Untested in the real world at time of writing: **the grip**. `glass_t = 2.0`
  came from the user's estimate of the rim, not calipers on the actual wedding
  glasses. Print one and check before committing to 33.
