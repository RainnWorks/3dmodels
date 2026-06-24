# Cake Topper Generator

A parametric (OpenSCAD) cake topper: three lines of text ("Happy / Birthday /
<name>", the name bigger) with a big **age number** behind them. The number is
cut into a white backing plate as a gold inlay with a black outline, and a
white outline always wraps the whole thing. Two posts push into the cake.

![topper](previews/topper.png)

## Build locally

Needs `openscad` (2026+ used here; the model itself is 2021-compatible).

```sh
make            # previews (PNG) + exports (STL + 3MF)
make renders    # just previews
make exports    # just STL + 3MF
make clean
```

- `export/topper.3mf` — **multicolour**: four separate objects (white / gold /
  black / red). This is the file to slice for an AMS print.
- `export/topper.stl` — single watertight solid (same outer shape, no colour),
  exported via `-D Solid=true`.

## Publishing on MakerWorld (Parametric Model Maker / MakerLab)

This file is written to work with MakerWorld's OpenSCAD-based customizer, so
buyers can type their own name/age and download a custom model.

- **Upload the `.scad` itself** (not the 3MF) to get the "Customize" button.
- **Fonts:** MakerLab only has its own library (≈Google Fonts). The defaults
  (`Great Vibes`, `Anton`) are from it, and `Text_Font` / `Age_Font` are tagged
  `// font` so they appear as font pickers. macOS-only fonts (Snell Roundhand,
  Arial Black, …) will **not** render there.
- **Multicolour:** MakerLab enables OpenSCAD "lazy-union" and exports colour to
  3MF. The model emits one top-level object per colour (`part_white/gold/black/
  red`), which is exactly what that needs — each colour maps to a filament.
- **OpenSCAD 2021:** MakerLab runs the 2021 release; this model uses nothing
  newer, and no external libraries (no BOSL2 etc.).
- The Customizer UI is grouped via `/* [Section] */` and uses
  `// [min:step:max]` sliders and `// [a, b, c]` dropdowns. `/* [Hidden] */`
  keeps internal knobs (`Solid`, `render_part`, `$fn`) out of the UI.

## Key parameters

| Param | Notes |
|---|---|
| `Line1/2/3`, `*_Size` | the three lines; line 3 is the name, bigger |
| `Age`, `Age_Font` | the background number + its font |
| `Age_Style` | `inlay` (default) · `engrave` · `deboss` · `raised` |
| `Age_Scale`, `Age_Boldness` | number size / stroke weight |
| `Number_Stroke` | black outline width around the number (0 = none) |
| `Outline_thickness` | white border width around the words |
| `Gap` | clear gap between number and letters |
| `Post_*` | the legs that push into the cake (0 spacing = none) |
| `col_*` | colour → filament assignment |
