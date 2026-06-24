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
6. The **hose** pushes into the widener's **collet** mouth, and a separate printed
   **`collet_nut`** screws over the hose and squeezes the collet onto it — an
   all-printed compression clamp, hand on/off.

```
   outside                     door                     inside
  [cap_out / net_out]        ===||===        [widener + collet_nut → hose]
        screws onto           body            geared accessory clamps the door;
        outboard collar     flange|barrel     collet_nut clamps the hose
```

---

## Parts (`render_part`)

`body` · `cap` · `widener` · `collet_nut` · `cap_out` · `net_out` · `test`
plus views: `assembly`, `section`, `section_zoom`, `clamp_section`.

`test` is a short male-thread coupon for a quick PLA fit-check against `cap`.

---

## Key parameters (top of `bulkhead.scad`)

| Param | Default | Notes |
|---|---|---|
| `bore_d` | 86 | TODO measure — drilled hole dia |
| `door_thickness` | 40 | TODO measure |
| `duct_od` | 135 | hose OD that pushes into the mouth — **tuned, see decisions** |
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
- **Thread flank angle 30 → 50.** At 30° the trapezoidal teeth had flat
  *undersides* (horizontal overhangs). At 50° the downward flank is a ~45° slope
  with no flat underside → self-supports. Symmetric, so male/female still mate.
- **45° cone under every flange** (`support_cones`) replaces the flat annular
  overhang ring. The body's outboard collar was *extended* so its thread survives
  below the cone.
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

**6. Hose connection — evolved through three designs.**
- **v1: internal helical tabs** (hose twists onto them). Problem: tabs protruded
  ~4mm so the 135 hose couldn't even push past them, and it pulled out on door
  swing.
- **v2: jubilee groove** (slotted mouth + a *bought metal* worm-drive clamp).
  Rejected: not all-printed, and there's no printed clamp part to see.
- **v3 (current): collet + printed cap-nut.** The mouth is a slotted **collet**
  with an externally-threaded base; the separate **`collet_nut`** goes over the
  hose and screws onto the collet — its inner **cone squeezes the fingers onto the
  hose**. All printed, hand on/off, no hardware. (This is what the user asked for:
  "goes over the hose and as I screw it, it tightens around the pipe.")

**7. Hose size = 135mm.**
The first print used `duct_od = 130` → bore 132 / mouth OD 138, which was
*slightly* too tight to insert. Research showed portable-AC/heat-pump hoses are a
universal **130 or 150**; the user measured and it was just over 132, so **+5mm →
135** (bore 137 / mouth OD 143). One param to change if the real hose differs.

**8. Clamp range & tolerance.**
At rest the bore is **137** (hose slides in with ~2mm spare). The nut's cone
squeezes the finger OD from 142 down to ~137, pulling the **bore from 137 → ~132**
— a **5mm diametral range**. Plenty for a ~135 hose, and a **semi-flexible hose is
the easy case**: it squishes to grip and tolerates size variation both ways. PETG
fingers flex more happily than PLA for the real part.

---

## Printing (Bambu X2D, 0.4 nozzle)

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
make clean
```

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
