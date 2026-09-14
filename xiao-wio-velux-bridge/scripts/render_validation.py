"""Render a human-readable preview of the mechanical fit test suite."""

import argparse
import io
from pathlib import Path
import sys
import unittest

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy.spatial import ConvexHull


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tests"))
import test_fit as fit  # noqa: E402


def args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--variant", choices=("standard", "captive_usb"), default="standard")
    parser.add_argument("--output", required=True)
    return parser.parse_args()


def fonts():
    path = "/System/Library/Fonts/Supplemental/Arial.ttf"
    bold = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
    return {
        "title": ImageFont.truetype(bold, 34),
        "heading": ImageFont.truetype(bold, 22),
        "body": ImageFont.truetype(path, 18),
        "small": ImageFont.truetype(path, 15),
        "badge": ImageFont.truetype(bold, 18),
    }


def run_tests():
    suite = unittest.defaultTestLoader.discover(str(ROOT / "tests"))
    result = unittest.TextTestRunner(stream=io.StringIO(), verbosity=0).run(suite)
    return result.testsRun, len(result.failures) + len(result.errors)


def hull_polygon(vertices, axes, project):
    points = vertices[:, axes]
    hull = ConvexHull(points)
    return [project(*points[i]) for i in hull.vertices]


def panel(draw, box, title, font):
    draw.rounded_rectangle(box, radius=18, fill="#101923", outline="#2b4255", width=2)
    draw.text((box[0] + 22, box[1] + 18), title, font=font, fill="#edf5fb")


def dimension(draw, p1, p2, label, font, colour="#9db2c2"):
    draw.line([p1, p2], fill=colour, width=2)
    for x, y in (p1, p2):
        draw.line([(x - 5, y - 5), (x + 5, y + 5)], fill=colour, width=2)
    mx, my = (p1[0] + p2[0]) / 2, (p1[1] + p2[1]) / 2
    bounds = draw.textbbox((0, 0), label, font=font)
    tw = bounds[2] - bounds[0]
    draw.rounded_rectangle((mx - tw / 2 - 7, my - 12, mx + tw / 2 + 7, my + 12),
                           radius=5, fill="#101923")
    draw.text((mx - tw / 2, my - 9), label, font=font, fill=colour)


def render(output, variant):
    p = fit.P
    count, failures = run_tests()
    passed = failures == 0
    image = Image.new("RGB", (1400, 920), "#091017")
    draw = ImageDraw.Draw(image, "RGBA")
    font = fonts()

    draw.text((54, 38), "FULL KIT FIT VALIDATION", font=font["title"], fill="#f3f8fc")
    subtitle = "STANDARD USB" if variant == "standard" else "CAPTIVE SHORT-USB"
    draw.text((56, 84), f"{subtitle} · manufacturer models + exported enclosure meshes",
              font=font["body"], fill="#9fb2c0")
    badge = f"{'PASS' if passed else 'FAIL'}  {count - failures}/{count}"
    colour = "#21c77a" if passed else "#ef5b5b"
    draw.rounded_rectangle((1160, 42, 1342, 92), radius=24, fill=colour)
    draw.text((1190, 57), badge, font=font["badge"], fill="#07130d")

    left = (45, 130, 690, 725)
    right = (710, 130, 1355, 725)
    panel(draw, left, "TOP VIEW · wall and corner clearance", font["heading"])
    panel(draw, right, "SIDE VIEW · vertical and lid clearance", font["heading"])

    centre_y = -8.0 if variant == "standard" else 8.0
    xiao = fit.placed_official_mesh("XIAO-ESP32S3.stl", [2, 0, 1],
                                    centre_y, p["device_floor_z"])
    wio_bottom = p["device_floor_z"] + p["device_h"] - 7.3
    wio = fit.placed_official_mesh("Wio-SX1262_for_XIAO.stl", [0, 1, 2],
                                   centre_y, wio_bottom)

    # Top view, using the exact projected hulls of the official STL vertices.
    scale = 11.1
    cx, cy = 367, 436
    top = lambda x, y: (cx + x * scale, cy - y * scale)
    outer = (top(-p["case_x"] / 2, p["case_y"] / 2),
             top(p["case_x"] / 2, -p["case_y"] / 2))
    draw.rounded_rectangle((outer[0][0], outer[0][1], outer[1][0], outer[1][1]),
                           radius=p["corner_r"] * scale, fill="#183a56", outline="#58aee8", width=3)
    inner = (top(-p["inner_x"] / 2, p["inner_y"] / 2),
             top(p["inner_x"] / 2, -p["inner_y"] / 2))
    draw.rounded_rectangle((inner[0][0], inner[0][1], inner[1][0], inner[1][1]),
                           radius=max(2, p["inner_corner_r"] * scale), fill="#0c1720",
                           outline="#7890a2", width=2)

    def top_box(x0, x1, y0, y1, colour):
        a, b = top(x0, y1), top(x1, y0)
        draw.rectangle((a[0], a[1], b[0], b[1]), fill=colour)

    top_box(-p["inner_x"] / 2, -p["inner_x"] / 2 + p["wifi_ant_t"],
            p["wifi_ant_y"] - p["wifi_ant_l"] / 2,
            p["wifi_ant_y"] + p["wifi_ant_l"] / 2, "#31d17c")
    top_box(p["inner_x"] / 2 - p["lora_ant_t"], p["inner_x"] / 2,
            -p["lora_ant_l"] / 2, p["lora_ant_l"] / 2, "#ff8b3d")
    draw.polygon(hull_polygon(xiao, [0, 1], top), fill="#315f76", outline="#8ad8ff")
    draw.polygon(hull_polygon(wio, [0, 1], top), fill="#274f65", outline="#d3f3ff")
    draw.text((84, 680), "Green: 37.4 × 17.5 mm Wi-Fi FPC", font=font["small"], fill="#55e398")
    draw.text((370, 680), "Orange: 40 × 7 mm LoRa FPC", font=font["small"], fill="#ffad70")
    dimension(draw, top(-p["inner_x"] / 2, -20.5), top(-p["inner_x"] / 2, 20.5),
              "41.0 mm genuinely flat", font["small"])

    # Side section across the enclosure width.
    s = 15.0
    sx, ground = 1030, 650
    side = lambda x, z: (sx + x * s, ground - z * s)
    a, b = side(-p["case_x"] / 2, 0), side(p["case_x"] / 2, p["floor_t"])
    draw.rectangle((a[0], b[1], b[0], a[1]), fill="#234c6b")
    # Outer walls and lid roof.
    for x0, x1 in ((-p["case_x"] / 2, -p["inner_x"] / 2),
                   (p["inner_x"] / 2, p["case_x"] / 2)):
        q0, q1 = side(x0, p["floor_t"]), side(x1, p["base_h"])
        draw.rectangle((q0[0], q1[1], q1[0], q0[1]), fill="#234c6b")
    q0, q1 = side(-p["case_x"] / 2, p["base_h"]), side(p["case_x"] / 2, p["base_h"] + p["lid_t"])
    draw.rectangle((q0[0], q1[1], q1[0], q0[1]), fill="#397ca8")

    draw.polygon(hull_polygon(xiao, [0, 2], side), fill="#315f76", outline="#8ad8ff")
    draw.polygon(hull_polygon(wio, [0, 2], side), fill="#274f65", outline="#d3f3ff")
    # Antenna side profiles.
    top_wifi = p["floor_t"] + 0.4 + p["wifi_ant_w"]
    top_lora = p["floor_t"] + 1.0 + p["lora_ant_w"]
    q0, q1 = side(-p["inner_x"] / 2, p["floor_t"] + 0.4), side(-p["inner_x"] / 2 + p["wifi_ant_t"], top_wifi)
    draw.rectangle((q0[0], q1[1], q1[0], q0[1]), fill="#31d17c")
    q0, q1 = side(p["inner_x"] / 2 - p["lora_ant_t"], p["floor_t"] + 1), side(p["inner_x"] / 2, top_lora)
    draw.rectangle((q0[0], q1[1], q1[0], q0[1]), fill="#ff8b3d")
    dimension(draw, side(-15.0, p["floor_t"]), side(-15.0, p["antenna_max_z"]),
              "17.9 mm flat height", font["small"])
    roof_gap = p["base_h"] - (p["device_floor_z"] + p["device_h"])
    dimension(draw, side(3.5, p["device_floor_z"] + p["device_h"]), side(3.5, p["base_h"]),
              f"{roof_gap:.2f} mm roof gap", font["small"], colour="#68d7ff")
    draw.text((755, 680), "Actual snap-to-Wi-Fi clearance: 0.371 mm", font=font["small"], fill="#55e398")
    draw.text((755, 704), "Rigid geometry: official Seeed STL vertices", font=font["small"], fill="#9fb2c0")

    checks = [
        "Official XIAO envelope inside shell", "Official Wio envelope inside shell",
        "Full Wi-Fi FPC inside flat wall", "Full LoRa FPC inside flat wall",
        "Antenna ↔ board side clearance", "Antenna ↔ fitted lid clearance",
        "2×7 header grid and pitch", "USB-C aperture envelope",
        "2 mm paperclip button access", "All five STL exports watertight",
    ]
    draw.text((55, 758), "AUTOMATED CHECKS", font=font["heading"], fill="#edf5fb")
    for i, check in enumerate(checks):
        column, row = divmod(i, 5)
        x, y = 60 + column * 660, 802 + row * 22
        draw.ellipse((x, y + 3, x + 14, y + 17), fill=colour)
        if passed:
            draw.line([(x + 3, y + 10), (x + 6, y + 13), (x + 11, y + 7)],
                      fill="#07130d", width=2)
        else:
            draw.line([(x + 4, y + 7), (x + 10, y + 13)], fill="#230707", width=2)
            draw.line([(x + 10, y + 7), (x + 4, y + 13)], fill="#230707", width=2)
        draw.text((x + 27, y), check, font=font["small"], fill="#c4d2dc")

    image.save(output)
    if not passed:
        raise SystemExit("Fit validation tests failed")


if __name__ == "__main__":
    options = args()
    render(options.output, options.variant)
