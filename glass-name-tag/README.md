# Glass name tags

A name in script that clips over the rim of a wine glass, so each guest's glass
is their own place setting. Built for a wedding: 33 names, two build plates.

![all names](previews/all_rail.png)

Printed **flat**. The whole part lives in XY and is extruded `thick` in Z, so
the plane of the print is the plane of the tag. `y = 0` is the plane of the
glass wall — **nothing but the clip may cross it**, and that single constraint
is what most of this project is about.

## Build

Needs `openscad` (2026 used here) and Python with `numpy` + `pillow`.

```sh
make            # the contact sheet + the build plates
make plates     # just export/plate1.3mf, plate2.3mf  <- the things you slice
make test       # geometry tests
make one N=Grace
```

`export/plate*.3mf` hold **one object per tag** (OpenSCAD lazy-union), so Bambu
Studio can move or delete individual names rather than treating a plate as a
single lump.

To change the guest list, edit `names.txt` and `make plates`.

## Why this is not the obvious model

The design this follows is a popular MakerWorld one whose reviews are full of
the same two complaints: letters that come out as loose pieces, and letters
that stick out past the bar and stop the tag sitting flat on the glass. Both
come from **one** mistake, and it is worth stating plainly because it is easy
to repeat.

That model places the text with `valign="bottom"`, which aligns the font's
**declared descent line**. The font's metrics are not a bound on where the ink
goes. Measured, at 15mm:

| | metric claims | Tom | Alice | Jenny | George |
|---|---|---|---|---|---|
| Great Vibes | 7.96 for *every* name | 1.98 | 1.33 | 7.96 | 7.83 |
| Pacifico | 9.48 for *every* name | 0.10 | 0.10 | 9.48 | 9.48 |

So the metric is exactly right for `Jenny` — whose `y` reaches the descent line
— and wrong by **9.4mm** for `Alice` in Pacifico. A name with no descender is
left floating clear of the bar and prints as loose letters. Nudge it down to
fix that, which is what that model's users do by hand ("-3.0", "-5.5 to -7,
depending on the letter"), and now the deep descenders punch through the bar
into the glass. Measured on the original: at `txtYOffset=-3.0` the ink reaches
**y = -1.00**; at `-5.5`, **y = -3.50**.

They are the same bug from two ends, and no offset fixes both.

**So measure the ink instead.** `measure.py` renders each name's letters alone
through OpenSCAD and reads the extents off the exported mesh — the same text
shaper that renders the final part, so the number cannot drift from the
geometry. Placement is derived from that, never from `textmetrics`.

## The parts of the solution

- **`measure.py`** — real ink extents per name, cached in `ink.json`.
- **`bridges.py`** — a script font's `i` and `j` dots are separate bodies;
  `Millie` exports as three. Printed flat, a loose dot is a 2mm disc that
  prints beautifully and falls off. The cake-topper's morphological close does
  not work here: at 15mm the gap under a Great Vibes i-dot is wider than the
  counters of `e` and `o`, so any radius that catches the dot fills the letters
  in. Each island is bridged individually instead, with a strut across the
  measured shortest gap.
- **`weld.py`** — the cross-section holding each name onto its bar.
- **`plate.py`** — packs the set onto build plates.
- **`tests/`** — assert / empty / mesh-check, over a word list rather than one
  name, because every defect here is name-dependent.

## Styles, and why `rail` won

`style` picks how the letters are carried. All of them were built and measured;
the losers are kept so the reasons stay visible.

| style | what happened |
|---|---|
| **`rail`** | thin bar **on the baseline**, where script letters already join each other. Tails hang below it in open air. **Chosen.** |
| `lift` | thin bar at the glass face, name raised until its own tail bites in. Tails stay visible, but the weld is **one joint, 2.15mm at worst** (`Beth`) — a 60mm word on a 2mm tab. Brittle. |
| `solid` | bar from the glass face to the baseline. Strongest, but to catch a tail-less name like `Alice` it must reach within 1.3mm of the baseline, which swallows `Jenny`'s `J` and `y` whole. |
| `flush` | letters on a thin spine, anything past the glass face trimmed. Amputates descenders mid-bowl — with tails 8mm deep and the trim at 1.8mm it cuts ~6mm off every one. |

Measured across all 33 names:

| | weakest weld | median | joints per name |
|---|---|---|---|
| `rail` | **9.66mm** | 19.75mm | 9–11 |
| `lift` | 2.15mm | 3.99mm | 1 |

### The swish

The rail has to get from the baseline down to the glass face to become the
clip. A straight ramp does it with a solid triangular wedge, which is the one
thing the shape must not look like. So a stroke is swept along a cubic instead.

Note that a curve joining two *horizontal* tangents at different heights must
reverse curvature — the rail is flat and a hook tangent to the glass is flat,
so an S is forced, and it reads as fighting the direction of the writing.
`swish_rise` is the fix: the stroke lifts off the baseline before it dives, so
it reads as a pen lifting into a flourish rather than a ramp going downhill.

## The font

`Great Vibes` at 15mm, thickened `bold = +0.15`. That is not decoration — the
narrowest strokes measure **0.30mm**, below a single 0.4mm extrusion, found by
eroding the letters until they broke into pieces. Pacifico needs no thickening
(min stroke >0.8mm, and 572mm² of material against Great Vibes' 262mm²) and is
the tougher choice if these ever get handled hard.

Both are Google fonts, so they render here and in MakerWorld's customiser.

**A connected script would remove the bar entirely** — but no off-the-shelf one
is connected in the geometric sense. Measured over the name set: Great Vibes
leaves `Tom` in 2 pieces and `Gabby` in 4, with a median gap of **1.22mm**
between them (its capitals stand clear of the lowercase by design), and 38 of
51 gaps are over 1mm, so struts would be plainly visible. Pacifico, Snell
Roundhand, Savoye LET, Brush Script MT and Zapfino are all likewise unjoined.
Fattening and tightening the letter spacing barely moves it.

## The clip

Sized for a wine glass rim, `glass_t = 2.0mm`.

The bend radius is **not** a free parameter. It was, at 2.4mm, which put the
two legs of the U 4.8mm apart for a 2mm rim: the rim could never seat in the
curl, and the only thing that reached it was the angled tip of the arm.
Measured by intersecting the clip with the glass wall, that version touched
over **2.6mm** — a point. It was a hook, not a clip.

So the curl is a rim wide (`bend_r = glass_t/2`), the rim seats right into it,
and the arm then runs nearly straight, closing from `glass_t` at the curl to
`glass_t - preload` at its end. That 0.8mm of interference is the grip, and
spreading it along the arm is the whole point:

| | contact length | interference |
|---|---|---|
| curl at 2.4mm radius | 2.6mm | 9.7mm³ |
| curl at rim width | **24.0mm** | 27.3mm³ |

The last of the arm flares back out (`lip_len`, `lip_ang`) so the rim slides up
it instead of catching on a square end.

`tests/assert_clip_grips.scad` checks the curl is about a rim wide in both
directions, that the arm converges gently enough to clamp rather than claw, and
that the lip actually flares past the arm. `tests/run.py` measures the contact
length off the mesh and fails below 10mm.

![clip on a rim](previews/section.png)

## Licence, and why this one is not published

The MakerWorld model this follows is under a Standard Digital File License,
which forbids sharing derivatives or remixes. The geometry here is written from
scratch and printing a set for a family wedding is fine, but unlike the other
models in this repo **this one should not be uploaded to MakerWorld**.
