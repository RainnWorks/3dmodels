# Hall of Fame

A flat script "Hall of Fame" sign for sticking on a mirror, **300 mm wide**.
Two rows, nested, in a thin monoline script matched to the reference photo.

![layout](previews/layout.png)

The sign is **300 x 212 mm** overall. It prints as **three pieces** — `Hall`,
`of`, `Fame` — because 300 mm does not fit on a 256 mm bed and because a
mid-row break is invisible once the words are back in place. A 1:1 paper
template puts them back where they belong.

| piece | size | on the plate |
|---|---|---|
| `hall` | 230.8 x 100.2 x 4 mm | flat |
| `of`   |  69.2 x 152.2 x 4 mm | flat |
| `fame` | 255.8 x  95.6 x 4 mm | **turn it ~32°** — 194 x 194 mm rotated |

Narrowest stroke is **5.0 mm**, i.e. 12 lines wide on a 0.4 nozzle. Nothing
here is fragile.

## Build

Needs `openscad` (2026 build here) and Python with `numpy`, `scipy`,
`trimesh`, `pillow`.

```sh
make            # previews + per-word STL/3MF + the paper template
make renders    # just the PNGs
make exports    # just the STL + 3MF
make template   # just export/template.svg + export/template-a4.pdf
make check      # is every word one solid piece, how thin, does it fit the bed
make clean
```

The fonts are vendored in `fonts/` and the Makefile points
`OPENSCAD_FONT_PATH` at them, so this builds the same anywhere. It also passes
`--enable textmetrics` — the model measures the text to work backwards from
the 300 mm width, and will not run without it.

## Printing

- Flat on the bed, letters face **up**, no supports. The back face is what
  goes against the glass, so it wants to be the smooth bed side.
- 4 mm thick, 100% infill is fine at this size (it is nearly all perimeter
  anyway) — or 4 walls / 6 top+bottom layers and 15% infill.
- `fame.stl` needs turning about 32° on the plate. The slicer's auto-arrange
  finds this on its own; the check just confirms there is an angle that works.
- Gold PLA + a smooth PEI sheet gets closest to the reference photo. Silk gold
  reads brighter on glass.

## Sticking it on the mirror

`export/template-a4.pdf` is the artwork at 1:1 across **four A4 landscape
sheets**. Every sheet has a 100 mm ruler on it — measure it before you trust
anything. Print at 100% / "actual size", never "fit to page".

1. Overlap the sheets on the red trim lines and tape them into one sheet.
2. Tape it to the mirror. Level it using the grey centre cross and outer box,
   not the paper edge.
3. Lay each printed word over its outline. Run a strip of masking tape across
   the top of it as a hinge, so it can flip up and come back to the same spot.
4. Flip the word up, pull the template out, put the adhesive on, flip it back
   down and press.
5. Thin double-sided foam squares hold well and come off glass cleanly;
   solvent-free mirror adhesive is the permanent option.

## Changing it

Everything is in `HallOfFame.scad`. The sizing runs backwards from the width:
whichever row needs the most space is stretched to `Total_Width` and every
other row follows at the same font size, so the sign is exactly 300 mm across
whatever you type.

| param | notes |
|---|---|
| `Row1` `Row2` `Row3` | the rows; words split on spaces, one piece per word |
| `Row*_Scale` | make a row bigger or smaller than the others |
| `Row*_Nudge` | slide a row sideways, as a fraction of the total width |
| `Total_Width` | 300 mm — the whole composition, not one row |
| `Row_Gap` | mm between one row's lowest ink and the next row's highest. Negative nests them; **-40** here, which leaves 20 mm of real clearance |
| `Font` | `Sacramento` (the match), `Yellowtail`, `Allura`, `Parisienne`, `Great Vibes` |
| `Spacing` | **0.85**, not 1.0 — see below |
| `Boldness` | grows every stroke by this all round |
| `Connect` | fuses strokes that pass close, without fattening them |
| `Thickness` | 4 mm standoff from the glass |

Two settings are load-bearing and worth knowing about before you touch them:

- **`Spacing = 0.85`.** Sacramento's capitals do not reach the letter after
  them. At the font's own spacing there is a 10 mm gap, and `Hall` and `Fame`
  each come off the bed as two loose bits. Tightening to 0.85 pulls the H and
  F crossbars through the following letter — which is how the script wants to
  be set anyway, and matches the reference photo.
- **`Connect = 2.0`.** Even joined, the crossbars only graze. `Connect`
  dilates then erodes, which fuses anything passing within ~2x of it without
  fattening the strokes. At 0 the narrowest neck is 1.6 mm and one word still
  splits; at 2.0 it is a solid 5.0 mm.

After any change, run `make check`. It re-measures rather than assuming: it
splits each exported mesh to count loose bodies, and finds the narrowest
stroke by eroding the 2D artwork until a shape snaps or vanishes.

If you change the words, update `WORDS := 0:hall 1:of 2:fame` in the Makefile
to match the new pieces in reading order.

## Fonts

`fonts/` holds Sacramento, Yellowtail, Allura and Parisienne (SIL Open Font
License, licences alongside). Sacramento is the closest to the reference — a
thin monoline with the same slant. The others are heavier and have more
thick/thin contrast, and each needs its own `Spacing` to hold together —
`Yellowtail` and `Parisienne` join at 0.85, `Great Vibes` at its own 1.0.
`Allura` still comes apart at 0.70, where the letters are already piling into
each other, so it is not usable for this without a bigger `Connect`.
