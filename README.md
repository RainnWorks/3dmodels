# 3dmodels

3D models for RainnWorks.

## bulkhead.scad — two-part bulkhead fan-duct fitting

Parametric OpenSCAD model that mounts a portable fan duct through a hole drilled
in a door. Two printed parts clamp the door between them:

- **Body** — flange + outer spigot + threaded barrel. Drops through the hole from
  the outside; flange seats on the outside face of the door.
- **Ring nut** — fluted hand-grip nut. Screws onto the barrel from the inside and
  clamps the door. The printed coarse trapezoidal thread does the clamping; the
  barrel is a deliberate loose fit in the bore, so bore slop is non-structural.

Duct connection is assumed push-fit over the outer spigot (trivial to change once
the duct dims are measured).

### Parameters

Everything dimension-driving is in the parameter block at the top of
`bulkhead.scad`. The ones still needing a real measurement are marked `TODO`:
`bore_d` (default 86), `door_thickness` (default 40), and the duct dims
(`spigot_od` / `spigot_len`).

### Render / export

Drive the OpenSCAD CLI directly; pick a part with `-D render_part="..."`
(`body` | `nut` | `assembly` | `section`):

```sh
# preview
openscad -o previews/body.png -D 'render_part="body"' \
  --camera=0,0,0,72,0,22,0 --viewall --autocenter bulkhead.scad

# export
openscad -o export/body.stl -D 'render_part="body"' bulkhead.scad
openscad -o export/nut.3mf  -D 'render_part="nut"'  bulkhead.scad
```

Requires [BOSL2](https://github.com/BelfrySCAD/BOSL2) in the OpenSCAD library path.

### Deliverables in this repo

- `bulkhead.scad` — both parts + `render_part` selector. Print orientation and
  PETG settings are documented in the header comment.
- `previews/` — body, nut, assembly, and cross-section renders.
- `export/` — `body.stl` / `nut.stl` and `.3mf` for each.
