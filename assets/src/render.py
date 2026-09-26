"""Rebuild the README images from the models' own preview renders.

    python3 assets/src/render.py

Needs Python 3 + Pillow and rsvg-convert (librsvg). Writes:

    assets/src/icon-1024.svg          -> assets/icon-1024.png
    assets/src/hero.svg               -> assets/hero.png        (the montage)
    <model>/assets/src/hero.svg       -> <model>/assets/hero.png

The renders themselves come from each model's `make renders`; nothing here
re-renders geometry. Each render is trimmed to its content, padded back out
on its own background and embedded in the SVG, because librsvg will not load
images from outside the SVG's own folder.
"""
from pathlib import Path
from io import BytesIO
from PIL import Image, ImageChops
import base64
import subprocess

SRC = Path(__file__).resolve().parent
REPO = SRC.parent.parent

CANVAS = '#eceef1'
INK = '#1d2126'
MUTED = '#5c6570'
FONT = "Helvetica Neue, Helvetica, Arial, Liberation Sans, sans-serif"

# Every render used, with what has to go before it is framed.
#   top/bottom: rows of caption bar to drop (drawn into the render itself)
#   fixed:      the background is a gradient, so crop to this box and fill
#               the card instead of trimming to content
RENDERS = {
    'cake-topper/previews/topper.png': {},
    'cake-topper/previews/iso.png': {},
    'door-to-ac-hose/previews/assembly.png': {},
    'door-to-ac-hose/previews/widener.png': {},
    'door-to-ac-hose/previews/collet_nut.png': {},
    'glass-name-tag/previews/plate1.png': {},
    'glass-name-tag/previews/Gwen.png': {},
    'glass-name-tag/previews/section.png': {},
    'glass-name-tag-back/previews/stack.png': {'top': 64},
    'glass-name-tag-back/previews/onglass.png': {'top': 64},
    'glass-name-tag-back/previews/section.png': {'top': 64},
    'hall-of-fame/previews/layout.png': {},
    'hall-of-fame/previews/iso.png': {},
    'playdoh-organiser/previews/stack.png': {},
    'playdoh-organiser/previews/tray.png': {},
    'playdoh-organiser/previews/section.png': {},
    'ruffle-nozzle/previews/assembly.png': {},
    'ruffle-nozzle/previews/all.png': {},
    'ruffle-nozzle/previews/aperture.png': {},
    'van-airfilter-cap/previews/cap.png': {},
    'van-airfilter-cap/previews/on_filter.png': {},
    'van-airfilter-cap/previews/vents.png': {},
    'xiao-wio-velux-bridge/previews/assembly.png': {'fixed': (0, 40, 960, 656)},
    'xiao-wio-velux-bridge/previews/captive_usb_assembly.png': {'fixed': (0, 40, 960, 656)},
    'xiao-wio-velux-bridge/previews/closed.png': {'fixed': (0, 40, 960, 656)},
}

# name, folder, montage render, then the model hero: (render, caption) pairs,
# the first one large when there are three.
MODELS = [
    ('Cake topper', 'cake-topper', 'cake-topper/previews/iso.png', [
        ('previews/topper.png', 'Face-on, as it stands on the cake'),
        ('previews/iso.png', 'Angled, showing the raised layers'),
    ]),
    ('Portable-AC door bulkhead', 'door-to-ac-hose', 'door-to-ac-hose/previews/assembly.png', [
        ('previews/assembly.png', 'Assembled through the door'),
        ('previews/widener.png', 'Widener, the hose inlet'),
        ('previews/collet_nut.png', 'Collet nut, which locks the hose'),
    ]),
    ('Glass name tag', 'glass-name-tag', 'glass-name-tag/previews/plate1.png', [
        ('previews/plate1.png', 'A full build plate of names'),
        ('previews/Gwen.png', 'One tag'),
        ('previews/section.png', 'Section through the clip'),
    ]),
    ('Glass name tag, back clip', 'glass-name-tag-back', 'glass-name-tag-back/previews/stack.png', [
        ('previews/stack.png', 'From an angle'),
        ('previews/onglass.png', 'On the glass'),
        ('previews/section.png', 'Section through the clip'),
    ]),
    ('Hall of Fame sign', 'hall-of-fame', 'hall-of-fame/previews/layout.png', [
        ('previews/layout.png', 'Face-on, as it sits on the mirror'),
        ('previews/iso.png', 'Angled, standing off the glass'),
    ]),
    ('Play-Doh pot organiser', 'playdoh-organiser', 'playdoh-organiser/previews/stack.png', [
        ('previews/stack.png', 'A loaded stack of trays'),
        ('previews/tray.png', 'One tray, legs up as it prints'),
        ('previews/section.png', 'Section through the stack'),
    ]),
    ('Ruffle piping nozzle', 'ruffle-nozzle', 'ruffle-nozzle/previews/assembly.png', [
        ('previews/assembly.png', 'Nozzle on its coupler'),
        ('previews/all.png', 'Ring, nozzle and sleeve'),
        ('previews/aperture.png', 'The aperture'),
    ]),
    ('Van air-filter cap', 'van-airfilter-cap', 'van-airfilter-cap/previews/cap.png', [
        ('previews/cap.png', 'The cap'),
        ('previews/on_filter.png', 'Over the filter'),
        ('previews/vents.png', 'Vents on the lower side'),
    ]),
    ('XIAO + Wio-SX1262 enclosure', 'xiao-wio-velux-bridge', 'xiao-wio-velux-bridge/previews/assembly.png', [
        ('previews/assembly.png', 'Standard USB, exploded'),
        ('previews/captive_usb_assembly.png', 'Captive USB, exploded'),
        ('previews/closed.png', 'Closed'),
    ]),
]


def framed(rel, w, h):
    """The render trimmed to its content and centred on a w x h card of its
    own background colour. Returns (png data URI, background hex)."""
    opts = RENDERS[rel]
    im = Image.open(REPO / rel).convert('RGB')
    if 'fixed' in opts:
        im = im.crop(opts['fixed'])
        scale = max(w / im.width, h / im.height)
        im = im.resize((round(im.width * scale), round(im.height * scale)), Image.LANCZOS)
        left, top = (im.width - w) // 2, (im.height - h) // 2
        card = im.crop((left, top, left + w, top + h))
        bg = card.getpixel((2, 2))
    else:
        im = im.crop((0, opts.get('top', 0), im.width, im.height - opts.get('bottom', 0)))
        bg = im.getpixel((2, 2))
        diff = ImageChops.difference(im, Image.new('RGB', im.size, bg)).convert('L')
        box = diff.point(lambda v: 255 if v > 12 else 0).getbbox()
        im = im.crop(box)
        fill = 0.86
        scale = min(w * fill / im.width, h * fill / im.height)
        im = im.resize((max(1, round(im.width * scale)), max(1, round(im.height * scale))), Image.LANCZOS)
        card = Image.new('RGB', (w, h), bg)
        card.paste(im, ((w - im.width) // 2, (h - im.height) // 2))
    stream = BytesIO()
    card.save(stream, format='PNG', optimize=True)
    uri = 'data:image/png;base64,' + base64.b64encode(stream.getvalue()).decode()
    return uri, '#%02x%02x%02x' % bg


CLIPS = 0


def card(rel, x, y, w, h, caption=None, size=26):
    uri, bg = framed(rel, w, h)
    global CLIPS
    CLIPS += 1
    clip = f'clip{CLIPS}'
    out = (f'<clipPath id="{clip}"><rect x="{x}" y="{y}" width="{w}" height="{h}" rx="18"/></clipPath>'
           f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="18" fill="{bg}"/>'
           f'<image x="{x}" y="{y}" width="{w}" height="{h}" href="{uri}" clip-path="url(#{clip})"/>')
    if caption:
        out += f'<text x="{x + 4}" y="{y + h + size + 12}" font-size="{size}" fill="{MUTED}">{caption}</text>'
    return out


def document(w, h, content):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">\n'
            f'<rect width="100%" height="100%" fill="{CANVAS}"/>\n'
            f'<g font-family="{FONT}">\n{content}\n</g></svg>\n')


def write(svg, source, png):
    source.parent.mkdir(parents=True, exist_ok=True)
    source.write_text(svg)
    png.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(['rsvg-convert', str(source), '-o', str(png)], check=True)


# --- the montage: every model, one render each, 3 x 3 -----------------------
M, GAP, CW, CH, CAP = 48, 28, 485, 300, 52
montage = ''
for i, (name, _, rel, _) in enumerate(MODELS):
    x = M + (i % 3) * (CW + GAP)
    y = M + (i // 3) * (CH + CAP + GAP)
    montage += card(rel, x, y, CW, CH, name, 27)
W = 2 * M + 3 * CW + 2 * GAP
H = 2 * M + 3 * (CH + CAP) + 2 * GAP - 10
write(document(W, H, montage), SRC / 'hero.svg', REPO / 'assets' / 'hero.png')

# --- one hero per model -----------------------------------------------------
for name, folder, _, shots in MODELS:
    shots = [(f'{folder}/{rel}', caption) for rel, caption in shots]
    if len(shots) == 2:
        w, h = 740, 560
        body = card(shots[0][0], 40, 40, w, h, shots[0][1])
        body += card(shots[1][0], 40 + w + 40, 40, w, h, shots[1][1])
        W, H = 40 + 2 * w + 40 + 40, 40 + h + 60 + 30
    else:
        big_w, big_h, small_w = 960, 640, 520
        small_h = (big_h - 72) // 2
        body = card(shots[0][0], 40, 40, big_w, big_h, shots[0][1])
        body += card(shots[1][0], 40 + big_w + 40, 40, small_w, small_h, shots[1][1])
        body += card(shots[2][0], 40 + big_w + 40, 40 + small_h + 72, small_w, small_h, shots[2][1])
        W, H = 40 + big_w + 40 + small_w + 40, 40 + big_h + 60 + 30
    base = REPO / folder / 'assets'
    write(document(W, H, body), base / 'src' / 'hero.svg', base / 'hero.png')

# --- the icon ---------------------------------------------------------------
# Hand-written SVG: the RainnWorks monogram, sliced into print layers.
subprocess.run(['rsvg-convert', str(SRC / 'icon-1024.svg'), '-o', str(REPO / 'assets' / 'icon-1024.png')], check=True)
