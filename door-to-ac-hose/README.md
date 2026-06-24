# 3dmodels

3D models for RainnWorks.

## bulkhead.scad — modular bulkhead fitting for a portable-AC hose

Parametric OpenSCAD model: a threaded port through a hole drilled in a door, with
**one thread spec used on both faces** so you can screw accessories in or out on
either side.

- **Body** — outside flange + a short externally-threaded *outboard collar*
  (outside port) + threaded *barrel* through the door (inside port). A flanged
  tube, threaded both ends. Drops through the hole from outside; the barrel is a
  deliberate loose fit in the bore.
There are **two accessory styles**, because the two faces of the door do
different jobs:

**Inside (geared)** — these clamp the door: a grip flange bears on the inside
face, so screwing one down traps the door between it and the body flange. The
accessory *is* the clamp (no separate nut).

- **Cap** — geared, closed top. Winter seal / blanking plate.
- **Widener** — geared, flares to a slotted **collet** mouth the AC hose pushes
  into; its base is externally threaded for the collet nut. The "inlet" the duct
  connects to.
- **Collet nut** — a separate **all-printed** clamp. Goes over the hose and screws
  onto the collet; its inner cone squeezes the fingers onto the hose as you
  tighten. Hand on/off, no hardware. Fixes the hose pulling out on door swing.

**Outside (plain)** — the body flange is already on the outside, so these are
compact threaded knobs (light knurl, **no clamp flange**) that screw onto the
outboard collar — no second gear stacked on the body flange.

- **Cap_out** — plain closed cap. Outside blank.
- **Net_out** — plain bug-mesh vent: air in/out, insects out. The mesh sits in a
  chamber above the collar tip so the core never protrudes through it.

### Parameters

Everything dimension-driving is in the parameter block at the top of
`bulkhead.scad`. The ones still needing a real measurement are marked `TODO`:
`bore_d` (default 86), `door_thickness` (default 40), and `duct_id` (default 145).

### Build

A `Makefile` drives the OpenSCAD CLI and only re-runs when `bulkhead.scad`
changes:

```sh
make            # all previews + all STL/3MF exports
make renders    # just the PNG previews
make exports    # just the STL + 3MF files
make body       # one part: its preview + STL + 3MF
make clean
```

Or call OpenSCAD directly, picking a part with `-D render_part="..."`
(`body` | `cap` | `cap_out` | `net_out` | `widener` | `test` | `assembly` | `section`):

```sh
openscad -o export/widener.stl -D 'render_part="widener"' bulkhead.scad
```

**Fit-test first:** `render_part="test"` is a short male thread coupon — print it
plus the `cap` in PLA and check the thread runs smoothly before committing to the
big parts. Tune `thread_clearance` if it's tight or sloppy.

Requires [BOSL2](https://github.com/BelfrySCAD/BOSL2) in the OpenSCAD library path.

### Publishing on MakerWorld (Parametric Model Maker / MakerLab)

`bulkhead.scad` is annotated for MakerWorld's OpenSCAD customizer so buyers can
dial in their own door/hose sizes and pick a part.

- **Upload the `.scad` itself** (not a 3MF) to get the "Customize" button.
- **BOSL2 is supported** — it's one of MakerLab's curated libraries, so the
  `include <BOSL2/...>` lines work there unchanged. (No fonts are used, so the
  macOS-font caveat from the cake topper doesn't apply here.)
- **Pick a part:** `render_part` is a **dropdown** — the functional parts
  (body, cap, widener, collet_nut, cap_out, net_out, test) are printable; the
  assembly/section/clampdemo options are preview-only. A buyer customizes once
  per part and downloads each.
- **Customizer UI:** parameters are grouped with `/* [Section] */`, use
  `// [min:step:max]` sliders, and internal vars (`$fa`, `$fs`) live under
  `/* [Hidden] */`. Derived values (e.g. `flange_od = bore + flange_margin`) are
  computed below the parameter block, so only the real inputs show in the UI.
- **OpenSCAD 2021:** MakerLab runs the 2021 release. If a thread call errors on
  upload, it's a BOSL2 version mismatch on their side — verify against the BOSL2
  version MakerLab ships.
- **Single colour:** each part prints in one filament; no multicolour setup
  needed (the `color()` calls are only for the assembly/section previews).

### Deliverables in this repo

- `bulkhead.scad` — all parts + `render_part` selector. Print orientation and
  PLA/PETG settings are in the header comment.
- `Makefile` — regenerates everything below.
- `previews/` — body, cap, widener, test, assembly, and cross-section renders.
- `export/` — `body` / `cap` / `widener` / `test` as `.stl` and `.3mf`.
