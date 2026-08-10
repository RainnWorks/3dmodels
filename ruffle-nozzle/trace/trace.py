"""Trace the Birkmann #122 aperture out of the product photo.

Emits a NORMALISED outline (fraction of the base diameter) so the one
disputed number -- whether the base is O18 or O23 -- is a single scale
factor in the model, not a reason to re-trace.
"""
import os
import re

import numpy as np
from PIL import Image
from scipy import ndimage
from skimage import measure

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, 'birkmann-122.png')
MODEL = os.path.join(HERE, '..', 'nozzle.scad')
BASE_D_MM = 23.0        # only used to print mm; the emitted outline is normalised
mm_px = None            # set once the base circle is measured

g = np.asarray(Image.open(SRC).convert('L')).astype(float)

# ---- top-down view: the disc is the base circle, and sets the scale ---------
sub = g[780:1159, :]
disc = sub < 238
lbl, n = ndimage.label(disc)
disc = lbl == (int(np.argmax(ndimage.sum(disc, lbl, range(1, n + 1)))) + 1)
ys, xs = np.nonzero(disc)
d_px = ((xs.max() - xs.min() + 1) + (ys.max() - ys.min() + 1)) / 2.0
cx, cy = (xs.min() + xs.max()) / 2.0, (ys.min() + ys.max()) / 2.0
mm_px = BASE_D_MM / d_px
print(f'base circle {d_px:.1f} px = O{BASE_D_MM}mm, centre ({cx:.1f}, {cy:.1f})')

hole = ndimage.binary_fill_holes(disc) & ~disc
hl, hn = ndimage.label(hole)
hole = hl == (int(np.argmax(ndimage.sum(hole, hl, range(1, hn + 1)))) + 1)

# sub-pixel edge: contour the grayscale in a window round the hole, at the
# midpoint between the light coming through it and the metal around it.
hy, hx = np.nonzero(hole)
y0, y1 = hy.min() - 12, hy.max() + 13
x0, x1 = hx.min() - 12, hx.max() + 13
win, wmask = sub[y0:y1, x0:x1], hole[y0:y1, x0:x1]
ring = ndimage.binary_dilation(wmask, iterations=5) & ~ndimage.binary_dilation(wmask, iterations=2)
level = (np.median(win[wmask]) + np.median(win[ring])) / 2.0
print(f'hole {np.median(win[wmask]):.0f} / metal {np.median(win[ring]):.0f} -> level {level:.1f}')

cs = [c for c in measure.find_contours(win, level) if len(c) > 60]
c = max(cs, key=len)
print(f'{len(cs)} contour(s), longest {len(c)} pts')

# ---- close, resample uniformly, smooth periodically ------------------------
pts = c[:, ::-1] + [x0, y0]                      # (row,col) -> (x,y) in `sub`
if np.hypot(*(pts[0] - pts[-1])) > 1e-6:
    pts = np.vstack([pts, pts[0]])
s = np.concatenate([[0], np.cumsum(np.hypot(*np.diff(pts, axis=0).T))])
N = 240
u = np.linspace(0, s[-1], N, endpoint=False)
rs = np.column_stack([np.interp(u, s, pts[:, i]) for i in (0, 1)])
sm = np.column_stack([ndimage.gaussian_filter1d(rs[:, i], 3.0, mode='wrap') for i in (0, 1)])

# ---- anchor on the BULB, which is the tip mouth ----------------------------
# NOT the centroid. The traced S is a PROJECTION of two things: the round mouth
# at the tip (the bulb) and the slot running down one flank (the tail), which
# from directly above is foreshortened into the same outline. Only the mouth is
# on the axis. Anchoring on the centroid instead drags the tail across the axis,
# and a prism cut through that profile slices BOTH walls -- giving two free
# petals and a see-through tip, which the side photo flatly contradicts: the
# rim up there is a continuous unbroken oval.
#
# The bulb is found as the largest inscribed circle (max of the distance
# transform), which is exactly "where the shape is widest" and needs no
# threshold of its own.
dist = ndimage.distance_transform_edt(hole)
by, bx = np.unravel_index(np.argmax(dist), dist.shape)
bulb_r = dist[by, bx]
print(f'bulb (tip mouth) at ({bx}, {by}) px, radius {bulb_r*mm_px:.2f} mm '
      f'-> mouth O{2*bulb_r*mm_px:.2f} mm')
print(f'  it sits {(bx-cx)*mm_px:+.2f}, {-(by-cy)*mm_px:+.2f} mm off the disc centre '
      f'(parallax: the tip is ~2 base-D above the base plane)')

P = np.column_stack([(sm[:, 0] - bx) / d_px, -(sm[:, 1] - by) / d_px])

area = 0.5 * abs(np.dot(P[:, 0], np.roll(P[:, 1], -1)) - np.dot(np.roll(P[:, 0], -1), P[:, 1]))
print(f'\nNORMALISED (x base diameter): {np.ptp(P[:, 0]):.4f} wide, {np.ptp(P[:, 1]):.4f} long, '
      f'area {area:.5f}, max radius {np.hypot(P[:,0],P[:,1]).max():.4f}')
for d in (18.0, 23.0):
    print(f'  at base O{d:.0f}: {np.ptp(P[:, 0])*d:5.2f} x {np.ptp(P[:, 1])*d:5.2f} mm, '
          f'area {area*d*d:5.2f} mm^2, min wall-to-edge {(0.5-np.hypot(P[:,0],P[:,1]).max())*d:.2f} mm')

# --- how narrow does the slot get? -----------------------------------------
# This is the number that decides whether the thing prints at all: a channel
# under ~2 extrusion widths closes up, and the tail is much thinner than the
# bulb. Local width = 2x the distance transform along the shape's ridge.
from PIL import ImageDraw as _ID
_res = 0.002                                    # in units of base diameter
_lo, _hi = P.min(0) - 0.05, P.max(0) + 0.05
_w = int((_hi[0] - _lo[0]) / _res); _h = int((_hi[1] - _lo[1]) / _res)
_img = Image.new('L', (_w, _h), 0)
_ID.Draw(_img).polygon([tuple((q - _lo) / _res) for q in P], fill=255)
_dist = ndimage.distance_transform_edt(np.asarray(_img) > 0) * _res
_wid = np.array([2 * r.max() for r in _dist if r.max() > 0])
_wid = _wid[_wid > 0.005]                       # drop the rounded end caps
min_w, p5 = _wid.min(), np.percentile(_wid, 5)
print(f'slot width: narrowest {min_w*BASE_D_MM:.2f} mm, 5th pct {p5*BASE_D_MM:.2f} mm, '
      f'median {np.median(_wid)*BASE_D_MM:.2f} mm  (at O{BASE_D_MM:.0f})')

step = max(1, N // 96)
Q = P[::step]
block = ',\n'.join(f'  [{x: .5f}, {y: .5f}]' for x, y in Q)
open(os.path.join(HERE, 'aperture_pts.txt'), 'w').write(block)

# Rewrite the APERTURE block in the model. It is generated data, so the model
# is not the place it is authored -- but it is the place it has to live, since
# OpenSCAD cannot read a file.
src = open(MODEL).read()
new, n = re.subn(r'(APERTURE = \[\n).*?(\n\];)', lambda m: m.group(1) + block + m.group(2),
                 src, flags=re.S)
assert n == 1, f'expected exactly one APERTURE block, patched {n}'
# the bulb radius travels with the outline: it is what tells the model where the
# mouth ends and the one-sided tail begins.
new, nb = re.subn(r'APERTURE_BULB_R = [\d.]+;',
                  f'APERTURE_BULB_R = {bulb_r / d_px:.5f};', new)
assert nb == 1, f'expected exactly one APERTURE_BULB_R, patched {nb}'
new, nw = re.subn(r'APERTURE_MIN_W = [\d.]+;', f'APERTURE_MIN_W = {p5:.5f};', new)
assert nw == 1, f'expected exactly one APERTURE_MIN_W, patched {nw}'
open(MODEL, 'w').write(new)
print(f'\nwrote {len(Q)} normalised points -> aperture_pts.txt and nozzle.scad')

# ---- side view: the height/diameter ratio ----------------------------------
side = g[0:756, :] < 238
sl, sn = ndimage.label(side)
side = sl == (int(np.argmax(ndimage.sum(side, sl, range(1, sn + 1)))) + 1)
sy, _ = np.nonzero(side)
rows = np.array([np.count_nonzero(side[y]) for y in range(sy.min(), sy.max() + 1)])
base_px, h_px = rows.max(), len(rows)
print(f'\nside view: base {base_px} px, height {h_px} px -> h/d = {h_px/base_px:.3f}')
print(f'  => height {18*h_px/base_px:.1f} mm at O18   |   {23*h_px/base_px:.1f} mm at O23')
# where does the slit start, as a fraction of height? (widest gap in the flank)
print(f'  listed bounding box 18 x 18 x 35 mm implies h/d = {35/18:.3f}')

# ---- debug overlay: trace drawn back onto the photo ------------------------
from PIL import ImageDraw
ov = Image.open(SRC).convert('RGB')
dr = ImageDraw.Draw(ov)
back = [(x * d_px + bx, 780 + y * -d_px + by) for x, y in P]
dr.line(back + [back[0]], fill=(255, 0, 0), width=2)
dr.ellipse([cx - d_px/2, 780 + cy - d_px/2, cx + d_px/2, 780 + cy + d_px/2],
           outline=(0, 160, 255), width=2)
ov.save(os.path.join(HERE, 'trace_check.png'))
print('wrote trace_check.png')
