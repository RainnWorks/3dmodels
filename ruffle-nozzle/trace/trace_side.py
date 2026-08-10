"""Trace the SIDE view: the cone's proportions, corrected for camera tilt.

The top-down view gave the aperture. This one gives height/diameter -- the
number that decides whether the nozzle is 50mm or 39mm tall, and the number
the published 1.8x1.8x3.5cm bounding box disagrees with.

Measuring it as "tallest row / widest row" is wrong: the camera looks slightly
DOWN at the nozzle, so the base circle projects to an ellipse and the near rim
dips below the base plane, padding the apparent height, while the axis itself
is foreshortened. Both are recoverable from the ellipse:

    major axis a  = D            (horizontal, unforeshortened)
    minor axis b  = D * sin(tilt)
    axis in image = H * cos(tilt)
"""
import os

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage
from skimage import measure

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, 'birkmann-122.png')
BASE_D_MM = 23.0

g = np.asarray(Image.open(SRC).convert('L')).astype(float)
side = g[0:760, :]
m = side < 238
lbl, n = ndimage.label(m)
m = lbl == (int(np.argmax(ndimage.sum(m, lbl, range(1, n + 1)))) + 1)
m = ndimage.binary_fill_holes(m)          # the slit is a hole; the silhouette is not

ys, xs = np.nonzero(m)
y_top, y_bot = ys.min(), ys.max()
widths = np.array([np.count_nonzero(m[y]) for y in range(y_top, y_bot + 1)])
a_px = widths.max()
y_wide = y_top + int(np.argmax(widths))   # the ellipse's major axis == base plane
b_px = 2 * (y_bot - y_wide)
print(f'silhouette y {y_top}..{y_bot}, widest {a_px}px at y={y_wide}')
print(f'base ellipse: major {a_px}px, minor {b_px}px')

tilt = np.degrees(np.arcsin(np.clip(b_px / a_px, 0, 1)))
print(f'camera tilt {tilt:.1f} deg above the base plane')

# --- fit the two flanks as straight lines, intersect for the virtual apex ----
rows = range(y_wide - int(0.75 * (y_wide - y_top)), y_wide - 10)
L = np.array([[np.nonzero(m[y])[0].min(), y] for y in rows], float)
R = np.array([[np.nonzero(m[y])[0].max(), y] for y in rows], float)
(lm, lc) = np.polyfit(L[:, 1], L[:, 0], 1)
(rm, rc) = np.polyfit(R[:, 1], R[:, 0], 1)
y_apex = (rc - lc) / (lm - rm)
x_apex = lm * y_apex + lc
print(f'virtual apex at ({x_apex:.1f}, {y_apex:.1f})  '
      f'[silhouette top is y={y_top}, so the tip is truncated]')

axis_px = y_wide - y_apex
H_px = axis_px / np.cos(np.radians(tilt))
print(f'\naxis in image {axis_px:.1f}px -> true {H_px:.1f}px after un-foreshortening')
print(f'  naive  h/d (tallest row / widest row) = {(y_bot-y_top)/a_px:.3f}')
print(f'  CORRECTED virtual-cone h/d            = {H_px/a_px:.3f}')

# truncated height: where the silhouette actually stops
trunc_px = (y_wide - y_top) / np.cos(np.radians(tilt))
tip_d_mm = BASE_D_MM * (1 - trunc_px / H_px)
print(f'  CORRECTED truncated  h/d              = {trunc_px/a_px:.3f}')
print(f'\nat base O{BASE_D_MM:.0f}: height {BASE_D_MM*trunc_px/a_px:.1f} mm, '
      f'tip O{tip_d_mm:.1f} mm')
print(f'at base O18: height {18*trunc_px/a_px:.1f} mm   '
      f'(published bounding box says 35mm -> h/d {35/18:.3f})')

# --- where does the photographed slit stop? ---------------------------------
# The slot reads DARK (you see shadowed interior through it), not bright -- a
# first attempt looked for bright pixels and dutifully found the specular
# highlights running down both flanks, plus the engraved lettering.
inner = ndimage.binary_erosion(m, iterations=6)      # stay off the rim shading
dark = inner & (side < 118)
dl, dn = ndimage.label(dark)
sl = np.zeros_like(m)
if dn:
    # the slit is the dark region that reaches the tip -- pick by topmost
    # pixel, not by area, or the shaded base rim and the engraving win.
    tops = ndimage.minimum(np.nonzero(dark)[0][:0].sum() * 0 +
                           np.indices(dark.shape)[0][dark], dl[dark],
                           range(1, dn + 1))
    sl = dl == (int(np.argmin(tops)) + 1)
    sy, sx = np.nonzero(sl)
    top = (y_wide - sy.min()) / np.cos(np.radians(tilt))
    bot = (y_wide - sy.max()) / np.cos(np.radians(tilt))
    print(f'\nphotographed slit spans {100*bot/trunc_px:.0f}%..{100*top/trunc_px:.0f}% '
          f'of the height -- the top {100*(1-bot/trunc_px):.0f}%')

# --- overlay ----------------------------------------------------------------
ov = Image.open(SRC).convert('RGB')
d = ImageDraw.Draw(ov)
for c in measure.find_contours(m.astype(float), 0.5):
    d.line([(x, y) for y, x in c], fill=(0, 200, 0), width=2)
for c in measure.find_contours(sl.astype(float), 0.5):
    d.line([(x, y) for y, x in c], fill=(255, 0, 255), width=2)
d.line([(lm*y_apex+lc, y_apex), (lm*(y_wide+40)+lc, y_wide+40)], fill=(255, 140, 0), width=1)
d.line([(rm*y_apex+rc, y_apex), (rm*(y_wide+40)+rc, y_wide+40)], fill=(255, 140, 0), width=1)
cx = xs.min() + a_px / 2
d.ellipse([cx - a_px/2, y_wide - b_px/2, cx + a_px/2, y_wide + b_px/2],
          outline=(0, 160, 255), width=2)
d.line([(cx, y_apex), (cx, y_wide)], fill=(255, 0, 0), width=2)
d.ellipse([x_apex-4, y_apex-4, x_apex+4, y_apex+4], fill=(255, 0, 0))
ov.crop((0, 0, 455, 780)).save(os.path.join(HERE, 'trace_side_check.png'))
print('\nwrote trace_side_check.png')
