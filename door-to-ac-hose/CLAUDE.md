# Door-to-AC-hose bulkhead fitting

A 3D-printable, parametric (OpenSCAD) fitting that takes a **portable air-con /
heat-pump exhaust hose through a hole drilled in a door**. Everything is one file
— `bulkhead.scad` — and each part is selected with `-D render_part="..."`.

Target printer: **Bambu Lab X2D, 0.4 nozzle, black PLA** for fit-tests (PETG for
the real one). Depends on **BOSL2** in the OpenSCAD library path.

---

## How the system works

1. A round hole (default **86mm**) is drilled through the door.
2. The **body** drops through from the **outside**: a flange seats on the outside
   face, and a threaded **barrel** passes through the bore. The barrel is a
   deliberate *loose* fit (bore − 1mm) — the **clamp**, not the bore, holds it, so
   bore slop is non-structural.
3. **One coarse thread spec is used on BOTH faces of the door**, so accessories
   screw on at either side.
4. **Inside (geared) accessories** *do the clamping*: their grip flange bears on
   the inside face, trapping the door between it and the body flange. The
   accessory **is** the clamp — there is no separate nut.
   - `widener` — the hose inlet
   - `cap` — winter seal / blank
5. **Outside (plain) accessories** just close/vent the **outboard collar**. The
   body flange already does the flange job outside, so these are compact knurled
   knobs with **no clamp flange** (don't stack a second gear on the body flange).
   - `cap_out` — plain blank
   - `net_out` — bug-mesh vent (mesh sits above the collar tip so the core never
     protrudes through it)
6. The **hose screws into** the widener's mouth: internal **grip rings** drop into
   the hose's rib valleys (form-lock, not friction). A separate printed
   **`collet_nut`** then screws over the mouth and squeezes the slotted fingers, so
   the flexible ribs can't spring back out — and so the hose can't unscrew itself.
   All printed, hand on/off, no hardware. See decision #6.

```
   outside                     door                     inside
  [cap_out / net_out]        ===||===        [widener + collet_nut → hose]
        screws onto           body            geared accessory clamps the door;
        outboard collar     flange|barrel     collet_nut clamps the hose
```

---

## Parts (`render_part`)

`body` · `cap` · `widener` · `collet_nut` · `cap_out` · `net_out` · `spanner` · `test`
plus views: `assembly`, `section`, `section_zoom`, `clamp_section`.

`test` is a short male-thread coupon for a quick PLA fit-check against `cap`.

---

## Key parameters (top of `bulkhead.scad`)

| Param | Default | Notes |
|---|---|---|
| `bore_d` | 86 | TODO measure — drilled hole dia |
| `door_thickness` | 40 | TODO measure |
| `duct_od` | 146 | hose OD **across the rib crests** — measured, see decision #7 |
| `ring_spacing` | 11 | grip-ring spacing — deliberately NOT the hose rib pitch |
| `ring_engage` | 1.35 | how far rings bite past the crest before the nut is tightened |
| `ring_count` | 3 | few and wide beats many and dense |
| `thread_pitch` | 5 | body/accessory clamp thread |
| `thread_angle` | 50 | flank angle — see decision #4 |
| `thread_clearance` | 0.45 | diametral, male↔female |
| `airway_d` | 74 | clear through-bore |
| `collet_pitch` | 6 | coarse external thread on the widener mouth (for the nut) |
| `collet_*`, `nut_*` | — | collet finger / cap-nut geometry |

Everything dimension-driving is in the parameter block; change a value and `make`.

---

## Design decisions & WHY (the important bit)

**1. Two-part clamp, not a tight bore fit.**
The barrel is `bore − 1mm` so it just drops into the hole. The clamp (body flange +
inside accessory) does all the holding. This makes the barrel trivial to print and
insert, and means hole-drilling accuracy doesn't matter.

**2. One thread spec on both faces of the door.**
Same coarse thread outside (outboard collar) and inside (barrel), so the *same*
accessories fit either side, and the thread is as large as possible → keeps the
airway wide open for an exhaust.

**3. Geared (inside) vs plain (outside) accessories.**
Originally every accessory had the big fluted clamp flange. But on the *outside*
the body flange is already there, so a geared accessory just stacks a second Ø114
gear on the first — pointless. So: **inside accessories are geared (they clamp);
outside accessories are compact knobs (they just close/vent).** (Spotted by the
user; the geared `net` was dropped, replaced by plain `cap_out`/`net_out`.)

**4. Self-supporting everything → print with SUPPORTS OFF.**
- **Thread flank angle 30 → 50 → 80.** `thread_angle` is the *INCLUDED* angle, and
  the printed flank lands at exactly **half** of it off the horizontal. This was
  got wrong twice:
  - The original note claimed 50 gives "a ~45° slope". It gives **25°** — below
    Bambu's 30° default, so the slicer demanded support on *every thread turn*
    (74cm² on the body). That wrong claim is why the threads were assumed fine
    and the support problem was misattributed to the flange cone for so long.
  - It was then written off as unfixable because the thread spec is shared by the
    whole kit. Also wrong — the kit was already being reprinted, so the cost was
    near zero. (Caught by the user, who was "99% sure the overhangs are over 45°
    for no reason". They were right.)

  **80 would give 40° flanks** and measured sub-30° overhang on the body drops
  **74.16cm² → 0.11cm²** — no support anywhere, no slicer workaround.
  **But it is HELD AT 50.** Changing it re-cuts BOTH male and female, and the two
  do not interchange: at the major diameter a 50° tooth crest is **1.33mm** wide
  against an 80° groove of **0.40mm**, so a 50° male jams ~0.9mm out of an 80°
  female. The body was already printed at 50, so going to 80 would scrap it plus
  `cap`/`cap_out`/`net_out`. **Adopt 80 the next time the whole kit is reprinted as
  a set** — until then the 20° support threshold covers it.
  Do NOT go past 90: flank axial run is `thread_depth * tan(angle/2)`, so at
  `thread_depth = pitch/2` the two flanks consume the whole pitch at 90 and the
  profile degenerates to a knife-edge V with no crest flat. 80 keeps ~0.8mm.
- **45° cone under every flange** (`support_cones`) replaces the flat annular
  overhang ring. The body's outboard collar was *extended* so its thread survives
  below the cone.
- **The cone lands on the thread ROOT, not the crest.** It used to start at
  `barrel_od` (the crest, Ø85) while the thread valleys sit at `barrel_minor`
  (Ø80) — so the cone base jutted `thread_depth` (2.5mm) out over thin air, a
  **dead-horizontal 7.06cm² shelf right around the part**. Flat is the worst
  possible overhang, and it was the real reason support was demanded at the lip —
  *not* the 45° slope, which is above threshold and never was the problem.
  Starting the cone at `barrel_minor` drops that to 0.60cm² (a thread-end
  artefact, harmless). `body_cone_h` tracks the new base diameter so the cone
  stays a true 45°; the body grows 2.5mm taller as a result.
- **Print orientations** chosen so the one unavoidable structural overhang faces
  up (see Printing).
- The body's flange↔barrel step **cannot** be ramped on the seating side — the
  barrel must neck to Ø85 to pass the door hole — so it's handled by orientation
  (collar-down), not geometry.

**5. Coarse trapezoidal thread via BOSL2.**
BOSL2 builds the thread as a real helical sweep of a defined profile (flat-ish
crests, straight flanks), *not* a `linear_extrude` + twist (which gives a wavy
cross-section and needs huge facet counts). Kept BOSL2 over a self-contained helix
for a correct profile + tunable resolution. It's the one external dependency.

**6. Hose connection — evolved through four designs.**
- **v1: internal helical tabs** (hose twists onto them). Problem: tabs protruded
  ~4mm so the 135 hose couldn't even push past them, and it pulled out on door
  swing.
- **v2: jubilee groove** (slotted mouth + a *bought metal* worm-drive clamp).
  Rejected: not all-printed, and there's no printed clamp part to see.
- **v3: collet + printed cap-nut.** Slotted collet mouth, nut squeezes the fingers
  onto the hose. **Failed in the field — the user had to superglue it.** Two
  reasons, and the second is the interesting one:
  1. It was sized for a 135 hose against a real **146** one. The mouth bore and
     the nut throat were both 137, and the nut's internal thread crests 142, so it
     fouled in three places at once.
  2. Even sized right, **friction alone cannot grip ribbed hose.** A smooth collet
     only touches the rib *crests* — a few thin helical lines of contact, on the
     stiffest part of the hose. Almost no contact area. It was always going to
     creep off under load.
- **v4 (current): internal grip RINGS + the same collet nut.** Form-lock replaces
  friction: circumferential barbs inside the mouth drop into the rib *valleys*, and
  the nut then squeezes the fingers so the ribs can't flex back out.
  **Deliberately plain rings, not a helical thread.** The OEM adapter that ships
  with these units uses plain rings and the hose still screws in fine, because the
  hose's helical rib flexes to ride over them. Rings are also much more forgiving:
  a helix accumulates phase error every turn, whereas each ring only has to land
  somewhere in the ~5.5mm valley. See #7.
  The nut earns its place twice — it also resists the hose slowly **unscrewing
  itself** as the door swings, which is a likelier failure than straight pull-out
  given a floppy hose can rotate.

**7. Hose size = 146mm. Ring spacing is deliberately NOT matched to the hose.**
`duct_od` is the OD **across the rib crests** — measured 146. (Earlier values of
130/135 were for a different hose and were simply wrong for this one.)

The rings were first cut at 6.3mm to *match* the hose rib pitch, derived from the
OEM adapter's 5.5mm rib gap. **That was the wrong instinct and the user killed it:**
matching the pitch makes the mouth behave like one continuous fine thread, so it is
all-or-nothing — get the pitch slightly wrong and *every* ring lands on a crest
together. Checked against a true 8mm pitch: 4 rings at 6.3 spacing engage ~1, while
3 rings at wide spacing still engage 2.

So `ring_spacing = 11` with `ring_count = 3` — **few, wide and shallow, like the
OEM adapter**, which grips with a handful of shallow ribs spread over ~60mm rather
than a thread. **The hose is flexible**: each ring independently either finds a
valley or squashes a rib slightly, and the nut's squeeze then locks whatever caught.
Nothing depends on knowing the rib pitch, so it never has to be measured.
`hose_rib_pitch` (6.3) survives for the PREVIEW hose stub only and drives no
printed geometry.

**The rib depth was never measured either** (the user could only say "1cm-ish,
maybe half that" — valley somewhere between 136 and 141). It didn't need to be
either; see #8.

**8. Shallow rings + a squeeze — because the rib depth is unknown.**
`ring_engage = 1.35` is deliberately shallow: the rings reach only 1.35mm past the
hose crest, and **the nut's squeeze supplies the rest**. That is what makes the
grip tolerant of the unmeasured rib depth:

| if the rib is | rings engage | squeeze still left |
|---|---|---|
| 2.5mm deep | 54% | 1.15mm |
| 5.0mm deep | 27% | 3.65mm |

Either way it grips and the nut still has travel. A fixed-depth thread would have
needed the number; a squeeze does not. Full nut travel gives `max_squeeze` = 5mm
diametral — hand-tighten to feel, don't crank it.
**This is an interference fit by design, not a clearance fit.** Straight rings vs a
helical rib means the hose must flex **1.36mm** at the worst point to screw in
(measured). That is the mechanism, not a defect — it is exactly what the OEM
adapter does. If it ever screws in too stiffly, `ring_engage` is the one knob.
PETG fingers flex more happily than PLA for the real part.

**9. The collet nut needs a TOOL, not a better grip.**
First attempt at the too-stiff nut was to add hand-grip lugs. **Wrong answer, and the
user called it: "you actually need a tool for it really."** The numbers back that up:
the nut is Ø167 — too wide to wrap a hand round, so you are down to fingertip
friction — and its knurl **cannot** be deepened, because `nut_wall` is 4mm and the
existing 2.6mm scallops already leave only 1.4mm. There is no grip to be had.

So there is a printed **`spanner`**: a 180° C-jaw with teeth matching the nut's
knurl, plus a 185mm lever. 180° is deliberate — the jaw has to go on **sideways**
(the widener's flare blocks axial entry one end, the hose the other), and a
half-circle's opening equals the full diameter, so it slides straight on without
flexing. Teeth sit on the middle 120° only, leaving the jaw mouth clear on the way
in. Prints flat with **0.00 cm² of overhang** — every wall is vertical.

Alongside it, `nut_cone` went **10 → 20mm**. Same squeeze, but the wedge drops from
31° to 17°, which is **2× the radial force for the same hand torque**. Tool plus
shallower wedge is what makes it actually closable.
Verified the jaw and nut mate: intersection volume is **empty**.

**10. Customer variants are export folders, not source forks.**
The model is parametric, so a customer with a different door gets `make customer
DOOR=n` → `export/customer-nmm/`, and `bulkhead.scad`'s defaults stay canonical
(`door_thickness = 40` is still the untested TODO placeholder, *not* anyone's
real door). First one shipped: **`customer-20mm`** — a 20mm door, barrel 60 → 40
(`barrel_len = door_thickness + inside_thread_len`), body 94 → 76.5mm tall. The
flange, outboard collar and all five accessories are byte-identical to stock;
only the barrel shortens. Bore stays 86; hose is now 146 (see #7).

---

## Printing (Bambu X2D, 0.4 nozzle)

**Set the support threshold to 20° (default is 30°) and leave supports OFF.**
At 30° the thread flanks (25°, see decision #4) fall below the line, so the
slicer blankets *every thread turn* on the body — 81cm² of it. Drop the threshold
to 20° and the flagged area falls to 0.6cm². This is a slicer setting, not a
model change: the threads have always printed fine bare. Don't just enable
supports to satisfy the warning — you get support inside the threads, which is
what made the body a pain to print.

**`widener` and `collet_nut` are exported ALREADY IN PRINT ORIENTATION** — drop the
file on the plate and it is right, no manual rotate. This bit us once: the widener
was exported flange-up (its modelling origin), so it landed flange-down by default,
which turns the grip rings' square biting faces into **31cm² of dead-flat ceiling**
and it bridged badly. Mouth-down that same area is **0.75cm²**. The flip is applied
in the render selector only, so `assembly`/`section` views are unaffected.

**Orientations** (all parts: thread axis vertical, **supports OFF**):
- `body` → outboard collar **down**, barrel up (seating face prints flat-up).
- `cap` → flange **down**, closed top up.
- `widener` → **mouth down** (collet ring on the plate, flange up; flare + flange
  cone self-support).
- `collet_nut` → **hole-end down** (the small hose-hole face on the plate, open
  threaded end up — like a cup the right way up). Its squeeze cone is then the
  inside-bottom (supported). Printed open-end-down the cone becomes a ceiling and
  the slicer asks for support → just flip it.
- `cap_out` / `net_out` → flat on the plate.
- `test` → base down.

**Fast settings:** 0.24mm layer (X2D max for 0.4 nozzle stock), 2 walls, 10% grid
infill, no supports. **Note:** these parts are *big* (Ø140–156, because the hose
is 135) with lots of thread detail, so they're **~4–5h each regardless** — the
size dominates, not the settings (0.20→0.24+fast saved only ~8 min). Print the
pair overnight, or print a short collet-stub + short nut first to confirm grip.

**Material:** PLA for fit-tests; **PETG for the real one** (collet fingers flex
without cracking).

---

## Build / slice

```sh
make            # all previews + STL/3MF
make widener    # one part: preview + STL + 3MF
make customer DOOR=20   # one customer's kit -> export/customer-20mm/
make clean
```

`make customer` exports the whole printable set (body, cap, widener, collet_nut,
cap_out, net_out) plus a body + section preview into its own folder, overriding
`door_thickness` on the CLI. See decision #9.

Slicing was done headlessly with the Bambu Studio CLI
(`/Applications/BambuStudio.app/Contents/MacOS/BambuStudio --slice ...`) using the
`Bambu Lab X2D 0.4 nozzle` machine + `0.20/0.24mm Standard @BBL X2D` process +
`Bambu PLA Basic @BBL X2D` filament, with `--rotate-x 180` for mouth-down /
hole-down parts. There is **no CLI "send to printer"** — the printer (X2D + AMS,
black PLA) is driven from the GUI / Bambu Handy / RDP. Screenshots live in
`previews/` and are viewable on GitHub.

---

## Open / TODO

- Measure and set `bore_d`, `door_thickness`, and confirm `duct_od` (hose OD).
- Tune `collet_*` / `nut_*` if the clamp grip needs more range (more slots, or
  squeeze the cone further).
- The widener + nut are big multi-hour prints — consider a short fit-test pair
  first.

## Repo note

This project lives in `door-to-ac-hose/` within the `RainnWorks/3dmodels` repo.
`cake-topper/` alongside it is a separate, unrelated project.
