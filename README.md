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
- **Cap** — flanged, closed-top accessory. Winter seal / blanking plate.
- **Widener** — flanged accessory that flares fast to a straight mouth the AC
  hose **inserts into**; internal helical tabs grip the hose's spiral (twist to
  engage), like a coarse interrupted thread. The "inlet" the duct connects to.

The accessories carry their own clamp flange, so screwing one down traps the door
between the body flange (outside) and the accessory flange (inside) — the
accessory *is* the clamp, no separate nut. Coarse trapezoidal thread does the
clamping; bore slop is non-structural.

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
(`body` | `cap` | `widener` | `test` | `assembly` | `section`):

```sh
openscad -o export/widener.stl -D 'render_part="widener"' bulkhead.scad
```

**Fit-test first:** `render_part="test"` is a short male thread coupon — print it
plus the `cap` in PLA and check the thread runs smoothly before committing to the
big parts. Tune `thread_clearance` if it's tight or sloppy.

Requires [BOSL2](https://github.com/BelfrySCAD/BOSL2) in the OpenSCAD library path.

### Deliverables in this repo

- `bulkhead.scad` — all parts + `render_part` selector. Print orientation and
  PLA/PETG settings are in the header comment.
- `Makefile` — regenerates everything below.
- `previews/` — body, cap, widener, test, assembly, and cross-section renders.
- `export/` — `body` / `cap` / `widener` / `test` as `.stl` and `.3mf`.
