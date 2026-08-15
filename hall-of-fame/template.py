#!/usr/bin/env python3
"""Turn the 2D export into a 1:1 paper template for placing the words on the
mirror.

A 300 mm sign is too big for one sheet, so the artwork is tiled across A4
landscape pages with an overlap to tape along. Each page carries a 100 mm
ruler -- if that measures 100 mm on the paper, the print came out at 100% and
everything else on the sheet is true size too.

Working method: tape the assembled sheets to the mirror, level them by the
centre lines, lay each printed word over its outline, tape a hinge across the
top of it, lift the paper away, then press the word down.

Usage: template.py export/template.svg export/template-a4.pdf
"""

import sys

from PIL import Image, ImageDraw, ImageFont

import svgpath

DPI = 300
A4 = (297.0, 210.0)     # landscape, mm
PAGE_MARGIN = 8.0       # printer dead zone, mm
OVERLAP = 12.0          # shared strip between neighbouring sheets, mm
ART_MARGIN = 12.0       # paper around the artwork, mm
RULER = 100.0           # length of the scale bar, mm

INK = (0, 0, 0)
GUIDE = (150, 150, 150)
CUT = (200, 60, 60)


def mm(v):
    return v * DPI / 25.4


def label_font(size_mm=3.2):
    """A legible label at 300 dpi -- PIL's built-in bitmap font is unreadable."""
    for path in ("/System/Library/Fonts/Supplemental/Arial.ttf",
                 "/System/Library/Fonts/Helvetica.ttc",
                 "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"):
        try:
            return ImageFont.truetype(path, int(mm(size_mm)))
        except OSError:
            continue
    return ImageFont.load_default()


def main(argv):
    src, dst = argv[1], argv[2]
    cs = svgpath.contours(src)
    x0, y0, x1, y1 = svgpath.bbox(cs)

    # the sheet of "paper" the artwork sits on, in mm
    ax0, ay0 = x0 - ART_MARGIN, y0 - ART_MARGIN
    art_w = (x1 - x0) + 2 * ART_MARGIN
    art_h = (y1 - y0) + 2 * ART_MARGIN

    tile_w = A4[0] - 2 * PAGE_MARGIN
    tile_h = A4[1] - 2 * PAGE_MARGIN
    step_x, step_y = tile_w - OVERLAP, tile_h - OVERLAP
    cols = max(1, -(-int(round((art_w - OVERLAP) * 100)) // int(step_x * 100)))
    rows = max(1, -(-int(round((art_h - OVERLAP) * 100)) // int(step_y * 100)))

    pw, ph = int(mm(A4[0])), int(mm(A4[1]))
    font = label_font()
    pages = []

    for r in range(rows):
        for c in range(cols):
            page = Image.new("RGB", (pw, ph), (255, 255, 255))
            d = ImageDraw.Draw(page)

            # mm -> px on this page: artwork point (x, y) lands at
            # (x - ax0 - c*step_x) + PAGE_MARGIN, same in y.
            ox = PAGE_MARGIN - (ax0 + c * step_x)
            oy = PAGE_MARGIN - (ay0 + r * step_y)
            P = lambda x, y: (mm(x + ox), mm(y + oy))

            # the letters, as outlines -- you need to see the mirror through
            # them and read the edge you are lining the print up against
            for cont in cs:
                d.line([P(x, y) for x, y in cont] + [P(*cont[0])],
                       fill=INK, width=max(1, int(mm(0.35))))

            # overall extent + centre cross, for levelling on the glass
            d.rectangle([P(x0, y0), P(x1, y1)], outline=GUIDE, width=1)
            cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
            d.line([P(cx, y0 - 8), P(cx, y1 + 8)], fill=GUIDE, width=1)
            d.line([P(x0 - 8, cy), P(x1 + 8, cy)], fill=GUIDE, width=1)

            # trim line: where this sheet butts up against the next one
            d.rectangle([mm(PAGE_MARGIN), mm(PAGE_MARGIN),
                         mm(PAGE_MARGIN + tile_w), mm(PAGE_MARGIN + tile_h)],
                        outline=CUT, width=1)

            # Labels sit on a white strip -- they land on top of the artwork
            # otherwise, and both become unreadable.
            def band(y_mm, h_mm):
                d.rectangle([mm(PAGE_MARGIN) + 1, mm(y_mm),
                             mm(PAGE_MARGIN + tile_w) - 1, mm(y_mm + h_mm)],
                            fill=(255, 255, 255))

            band(PAGE_MARGIN + 0.5, 8)
            d.text((mm(PAGE_MARGIN + 4), mm(PAGE_MARGIN + 2)),
                   f"Hall of Fame  -  1:1 placement template  -  "
                   f"sheet row {r + 1} of {rows}, col {c + 1} of {cols}  -  "
                   f"trim/overlap on the red line and tape",
                   fill=CUT, font=font)

            # scale bar, so a mis-scaled print is caught before anything sticks
            band(A4[1] - PAGE_MARGIN - 11, 10.5)
            bx, by = mm(PAGE_MARGIN + 6), mm(A4[1] - PAGE_MARGIN - 5)
            d.line([bx, by, bx + mm(RULER), by], fill=CUT, width=3)
            for t in (0, RULER):
                d.line([bx + mm(t), by - mm(2.5), bx + mm(t), by + mm(2.5)],
                       fill=CUT, width=3)
            d.text((bx + mm(RULER) + mm(5), by - mm(2.5)),
                   f"{RULER:.0f} mm  -  measure it. If it is not {RULER:.0f} mm, "
                   f"reprint at 100% / 'actual size', not 'fit to page'.",
                   fill=CUT, font=font)

            pages.append(page)

    pages[0].save(dst, "PDF", resolution=DPI, save_all=True,
                  append_images=pages[1:])
    print(f"{dst}: {cols} x {rows} A4 landscape sheets, "
          f"artwork {art_w:.0f} x {art_h:.0f} mm at 1:1")


if __name__ == "__main__":
    sys.exit(main(sys.argv))
