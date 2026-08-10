# Ruffle piping nozzle

A printable ruffle nozzle after the Birkmann #122, plus a two-part coupler so
you can swap tips without emptying the bag.

One file, `nozzle.scad`, pure OpenSCAD (no libraries). Pick a part with
`-D render_part="..."`.

```
        /\          nozzle   -- the tool. Ø23 base, 47.4mm tall, 1.2->0.8mm wall.
       /||\         coupon   -- just the tip, for testing the aperture.
      / || \
     /  ||  \       sleeve   -- goes inside the bag, pokes out the snip.
    /   \/   \      ring     -- screws over the sleeve, clamps the nozzle.
   '----------'
```

## The aperture is traced, not drawn

The S-shaped opening is the whole part, and guessing at it does not work — a
first pass with a sine-wave slot came out nearly **3× too large**. So it is
measured instead: `trace/trace.py` finds the nozzle's base circle in the
manufacturer's top-down photo, uses the published Ø23mm to set the scale, and
sub-pixel contours the aperture out of the grayscale.

![traced outline over the source photo](trace/trace_check.png)

It comes out **3.7 × 9.7mm, 16.1mm² of flow area** — for comparison a plain #12
round tip is 12.6mm², so this pipes at about the pressure you would expect.

`trace/trace_side.py` does the same job on the **side** photo for the cone's
proportions. That one needs a correction: the camera looks **19.6° down** at the
nozzle, so reading "tallest row / widest row" off the image is wrong twice over
— the axis is foreshortened *and* the base rim's near edge pads the apparent
height. Both are recoverable from the base ellipse (major axis = true diameter,
minor axis = diameter × sin tilt), which takes h/d from a naive **2.111** to a
corrected **2.063**, and measures the truncated tip at **Ø3.1mm**.

![traced side view](trace/trace_side_check.png)

The outline is stored in `nozzle.scad` in **units of the base diameter**, so
`base_d` scales the whole design coherently and the one disputed number (see
*Which 23mm?* below) is a single parameter rather than a reason to re-trace.

## How the shape works

The nozzle is **a hollow cone with a small round mouth at the tip and a wavy
slot down one flank**. The slot is what ruffles: icing leaves as a ribbon,
thick at the mouth end and thinning along the tail.

The clever part is that both features come from **one** cut — a constant
cross-section prism running straight up the axis, with the traced S as its
profile:

- near the tip the cone is narrower than the bulb, so the bulb opens the mouth;
- further down the tail sticks out past the cone's flank on one side, and cuts
  the slot;
- lower still the cone is wider than the whole outline, so the prism sits
  buried in the cavity doing nothing.

One `difference()`.

**The anchoring is load-bearing.** The traced S is a *projection* of two
features that are not in the same place: the mouth is on the axis, the slot is
out on a flank. Only the bulb belongs on the axis. Anchor the outline on its
centroid instead — which for an S sits near the waist — and the tail is dragged
across the axis, so the prism cuts **both** walls: two free petals and a
see-through tip. The side photo rules that out; the tip rim is a continuous,
unbroken oval. `tests/empty_slot_is_one_sided.scad` is the regression.

Two independent measurements agree on the result: the flank slot runs **67%**
of the height by projected radius from the top-down view, against **72%**
measured off the side photo directly.

## Printing

The wall is **tapered on purpose**: 1.2mm at the base where you push it into
the bag, thinning to 0.8mm at the tip where the aperture is. That thickness
*is* the land the icing has to squeeze along before it separates, so thin means
sharp. Steel manages 0.5mm; 0.8 is as close as a 0.4mm nozzle gets while still
being two clean extrusions. `tip_wall_t = 0.45` is sharper again and much more
fragile — worth trying once you have a working print.

(An earlier version had this backwards, thickening *towards* the tip, from a
mistaken belief that the tip was two free petals needing extra section.)

### Slicer

| | |
|---|---|
| Nozzle | 0.4mm, hardened steel |
| Layer height | **0.1mm** — the aperture edge is the whole part |
| Wall loops | **999** |
| Wall extrusion width | **0.40mm** |
| Infill | 0 |
| Supports | none |
| Orientation | exactly as modelled; **no part may be flipped** (see below) |

**Why 999 loops.** The wall thickness varies continuously from 1.2 to 0.8mm, so
on the way up it passes through every fractional multiple of the line width. A
fixed loop count leaves voids wherever the wall does not divide evenly; 999
makes the slicer fill whatever is actually there, and the part comes out as one
continuous solid with no infill boundary anywhere. This is also why the two
ends are set to exact multiples of 0.40 (3 extrusions and 2) — the model echoes
those counts on render and warns if you pick a wall that is not a whole number
of extrusions.

**Orientation is not a free choice for the coupler.** Both halves are modelled
and printed axis-vertical, and flipping either one reverses the handedness of
its thread — an external and an internal thread that disagree is a bug you
only find on the printer. `tests/empty_ring_screws_onto_sleeve.scad` catches it
in CAD; nothing catches it in the slicer. Print them as exported.

**Supports: none, and that is measured.** `make overhangs` reads the exported
meshes back and reports every downward-facing face:

| part | worst | ledge width |
|---|---|---|
| nozzle | 11° from vertical | nothing near-flat at all |
| sleeve | 90° | mean 0.21mm, widest 1.00mm |
| ring | 90° | mean 0.19mm, widest 0.73mm |

The 90° faces are real but harmless, and the angle on its own is misleading.
They are the **thread flanks**, which are a staircase rather than a smooth
ramp: the helix is built as six nested extrusions, so each flank is six steps
of **0.167mm**. A 90° face 0.167mm wide bridges without noticing. The single
widest ledge on each part (~1mm) is where the thread run-out starts abruptly
out of the core.

(An earlier version of this table claimed the thread flanks were "45° or
shallower". They are a 20° staircase. Measuring is why that got caught.)

**Cooling.** Near the tip each layer is a thin ring of a few hundred mm², which
at 0.1mm goes by fast. Set a minimum layer time (~8–10s) or slow the top third,
or the last few millimetres will slump while soft.

Roughly 470 layers for the Ø23 nozzle. Budget an hour or so.

**Print `coupon` first.** It is the top 16mm on a thin pad — about a third of
the layers, so ~20 minutes against the nozzle's hour — and it tells you whether
`slot_grow` is right before you commit to the whole part.
FDM lays a narrow slot narrower than modelled; `slot_grow = 0.20` is the
compensation and it is the first number to tune.

### Food contact — read once

Layer lines hold residue that a smooth steel tip does not, so this is a
short-life tool, not an heirloom. Use PETG rather than PLA (the Birkmann's own
listing gives 40°C as its wash temperature, and PLA starts softening around
60°C — but PLA is the one that will also creep under hand pressure). Print with
a **hardened steel nozzle** if you would rather not think about brass and lead.
Hand wash, do not put it in the dishwasher, and retire it when the slot gets
scratched.

## Making it stay on the bag

**It already does, and this is the part most people get wrong.** A piping
nozzle is not clipped or threaded onto anything: you drop it inside the bag and
snip the tip **2–3mm smaller than the nozzle's base**, and the taper wedges
into the hole. The bag's own tension holds it. That is why steel nozzles are
bare cones — the taper *is* the retention feature — and it works on any
disposable bag.

Two things this design adds that steel does not have:

- **A base flange.** Steel relies purely on friction; a printed cone is
  slicker, and under real hand pressure it can push through the snip. The
  flange makes that impossible.
- **The coupler**, below.

### The coupler

```
   =====|     |=====   bag, snipped ~Ø26 and stretched over the thread
        |     |
   -----+-----+-----   sleeve body, inside the bag: flares to Ø34 so it
       /       \       cannot pull back through
      | ((thread)) |   thread pokes OUT through the snip
      |  \     /   |
       \  nozzle  /    nozzle drops over the sleeve's nose
        \  ring  /     ring screws on, clamps the nozzle's flange
```

1. Push the sleeve out through the snipped tip from inside the bag, threads
   first, until the bag sits on the neck behind them.
2. Drop the nozzle over the nose.
3. Screw the ring on. Three starts and a 9mm lead — one turn and it is tight.

To change tips: unscrew the ring, swap, screw back. The bag stays loaded.

The nose is **cut to follow the nozzle's own bore**, not made a plain plug, so
it centres the nozzle rather than merely filling it. The clamp is a matching
pair of **45° cones** rather than a flat step, so it self-centres and neither
part has an overhang to bridge.

The thread is **our own** — coarse, 3-start, 3mm pitch, 20° flank — not a
reverse-engineered Wilton. A thread we define is a thread we can test, and
`make test` does exactly that.

## Why Ø23

The published data conflicts: the product copy says **"Dimensions: Ø 23 mm"**
twice, the spec table says the item is **1.8 × 1.8 × 3.5 cm** (which cannot
contain a Ø23 disc), and the side photo's tilt-corrected height/base ratio of
**2.063** gives 47.4mm at Ø23 or 37.1mm at Ø18, matching neither cleanly.

**It does not matter, so it is settled at Ø23.** The only thing that could have
made the real diameter matter is fitting a commercial coupler — and we print
our own, so nothing downstream cares. Given a free choice, Ø23 is the better
one: **16.1mm² of flow area against Ø18's 9.9mm²** (which is below a plain #12
round tip, and would want a noticeably harder squeeze), and every feature —
tip rim, mouth, slot — is 22% larger and so prints more reliably at 0.4mm.

That also makes the coupler question disappear. There is one diameter, one
coupler, and no suffixed files to mix up.

`base_d` is still a parameter, and `make size D=20` builds the whole set at any
other diameter. It deliberately builds the **whole** set, because the coupler
is sized from `base_d`: a nozzle from one diameter will not clamp in a ring
from another. A Ø23 ring's lip bore is Ø23.6 against a Ø18 flange of Ø20.8, so
the flange drops straight through with no clamping ledge at all; and the Ø23
sleeve's nose is Ø20.0 against a Ø18 bore of Ø15.6, too fat to enter. Each
diameter gets a 1.10mm ledge with its own ring.

## Build

```
make            # previews + STL/3MF for all parts
make test       # the geometry tests
make coupon     # the aperture test print
make size D=20  # the whole set at some other base diameter
make compare    # the side-by-side previews (model vs the source photo)
make trace      # re-derive aperture AND proportions from the photos
```

## Honest comparison

Against a £3 steel tip, a printed one loses on edge sharpness and surface
finish, and it always will. What it wins on is shapes you cannot buy, a coupler
sized to your own bag, and the ability to change any of the above. That is the
reason to print it; "cheaper than steel" is not.

## Open

- **Unprinted.** Nothing here has been through a printer yet. Two numbers are
  waiting on that: `slot_grow` (whether the aperture opens to the traced size)
  and `tip_wall_t` (whether 0.8mm prints crisply and survives handling).
- **The slot edges are the structural unknown.** For the top 67% the cone is a
  C-section rather than a closed tube, so it can open slightly under pressure
  and thicken the ruffle. Far better than the two free petals an earlier
  version had, but still worth watching on the first print. `tip_wall_t` is the
  knob.
- **The tip is deliberately blunter than the original.** The real mouth is
  Ø2.55 in a Ø3.1 tip — a 0.28mm rim of steel, which FDM cannot lay. `tip_d`
  is opened to 4.4 for a ~0.7mm rim.
- `sleeve.stl` and `ring.stl` come out ~12MB because the thread is a stack of
  swept helices. The 3MF is a tenth of that; prefer it.
