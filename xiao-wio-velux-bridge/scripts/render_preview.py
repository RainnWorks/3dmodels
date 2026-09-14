"""Dependency-light, headless isometric renderer for enclosure previews."""

import argparse
import os

import numpy as np
import trimesh
from PIL import Image, ImageDraw, ImageFont


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--view", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--variant", choices=["standard", "captive_usb"], default="standard")
    return parser.parse_args()


def moved(mesh, xyz):
    result = mesh.copy()
    result.apply_translation(xyz)
    return result


def box(extents, center):
    return moved(trimesh.creation.box(extents=extents), center)


def cable(points, diameter=1.13):
    pieces = []
    for p1, p2 in zip(points, points[1:]):
        p1 = np.asarray(p1, dtype=float)
        p2 = np.asarray(p2, dtype=float)
        direction = p2 - p1
        length = np.linalg.norm(direction)
        cylinder = trimesh.creation.cylinder(radius=diameter / 2, height=length, sections=12)
        cylinder.apply_transform(trimesh.geometry.align_vectors([0, 0, 1], direction))
        cylinder.apply_translation((p1 + p2) / 2)
        pieces.append(cylinder)
    return trimesh.util.concatenate(pieces)


def render(items, output, caption, labels=None):
    camera_axis = np.array([1.0, -1.25, 0.9])
    camera_axis /= np.linalg.norm(camera_axis)
    right = np.cross(np.array([0.0, 0.0, 1.0]), camera_axis)
    right /= np.linalg.norm(right)
    up = np.cross(camera_axis, right)
    light = np.array([-0.35, -0.55, 1.0])
    light /= np.linalg.norm(light)

    all_vertices = np.vstack([mesh.vertices for mesh, _ in items])
    center = (all_vertices.min(axis=0) + all_vertices.max(axis=0)) / 2
    projected = []
    sx_values, sy_values = [], []
    for mesh, color in items:
        vertices = mesh.vertices - center
        sx = vertices @ right
        sy = vertices @ up
        depth = vertices @ camera_axis
        sx_values.extend(sx)
        sy_values.extend(sy)
        projected.append((mesh, color, sx, sy, depth))

    width, height, supersample = 960, 720, 3
    margin_x, margin_top, margin_bottom = 70, 55, 78
    span_x = max(sx_values) - min(sx_values)
    span_y = max(sy_values) - min(sy_values)
    scale = min((width - 2 * margin_x) / max(span_x, 1),
                (height - margin_top - margin_bottom) / max(span_y, 1)) * supersample
    render_w, render_h = width * supersample, height * supersample
    pixels = np.empty((render_h, render_w, 3), dtype=np.uint8)
    for row in range(render_h):
        shade = int(20 + 15 * row / render_h)
        pixels[row, :, :] = (shade - 5, shade, shade + 5)
    zbuffer = np.full((render_h, render_w), -np.inf, dtype=np.float32)
    x_mid = width * supersample / 2
    y_mid = (margin_top + (height - margin_bottom)) * supersample / 2
    for mesh, color, sx, sy, depth in projected:
        for index, face in enumerate(mesh.faces):
            points = np.array([(x_mid + sx[v] * scale, y_mid - sy[v] * scale) for v in face])
            brightness = 0.42 + 0.58 * max(0.0, float(np.dot(mesh.face_normals[index], light)))
            face_color = tuple(max(0, min(255, int(channel * brightness))) for channel in color)
            x0, y0 = points[0]
            x1, y1 = points[1]
            x2, y2 = points[2]
            xmin = max(0, int(np.floor(min(x0, x1, x2))))
            xmax = min(render_w - 1, int(np.ceil(max(x0, x1, x2))))
            ymin = max(0, int(np.floor(min(y0, y1, y2))))
            ymax = min(render_h - 1, int(np.ceil(max(y0, y1, y2))))
            if xmin > xmax or ymin > ymax:
                continue
            denom = (y1-y2)*(x0-x2) + (x2-x1)*(y0-y2)
            if abs(denom) < 1e-7:
                continue
            yy, xx = np.mgrid[ymin:ymax+1, xmin:xmax+1]
            w0 = ((y1-y2)*(xx-x2) + (x2-x1)*(yy-y2)) / denom
            w1 = ((y2-y0)*(xx-x2) + (x0-x2)*(yy-y2)) / denom
            w2 = 1.0 - w0 - w1
            inside = (w0 >= -1e-6) & (w1 >= -1e-6) & (w2 >= -1e-6)
            z = w0*depth[face[0]] + w1*depth[face[1]] + w2*depth[face[2]]
            current = zbuffer[ymin:ymax+1, xmin:xmax+1]
            visible = inside & (z > current)
            current[visible] = z[visible]
            region = pixels[ymin:ymax+1, xmin:xmax+1]
            region[visible] = face_color

    image = Image.fromarray(pixels).resize((width, height), Image.Resampling.LANCZOS)
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle([28, height-56, width-28, height-18], radius=10,
                           fill=(8,13,19), outline=(55,72,88), width=1)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 17)
    except OSError:
        font = ImageFont.load_default()
    if labels:
        for label, position in labels:
            point = np.asarray(position, dtype=float) - center
            px = x_mid / supersample + float(point @ right) * scale / supersample
            py = y_mid / supersample - float(point @ up) * scale / supersample
            bounds = draw.textbbox((0, 0), label, font=font)
            tw, th = bounds[2]-bounds[0], bounds[3]-bounds[1]
            draw.rounded_rectangle([px-tw/2-9, py-th/2-6,
                                    px+tw/2+9, py+th/2+6],
                                   radius=6, fill=(8,13,19),
                                   outline=(105,145,175), width=1)
            draw.text((px-tw/2,py-th/2),label,fill=(238,244,249),font=font)
    draw.text((48, height-47), caption, fill=(220,230,239), font=font)
    image.save(output)


def main():
    args = parse_args()
    project = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    captive = args.variant == "captive_usb"
    exports = os.path.join(project, "export-captive-usb" if captive else "export")
    blue, lid_blue = (50, 135, 205), (86, 172, 230)
    pcb, silver = (18, 92, 75), (185, 195, 203)
    wifi, lora, black = (30, 185, 92), (246, 105, 30), (18, 20, 23)

    labels = None
    if args.view == "base":
        items = [(trimesh.load_mesh(os.path.join(exports, "base.stl")), blue)]
        caption = "BASE · four clip recesses end below a solid snap-over shoulder"
    elif args.view == "lid":
        items = [(trimesh.load_mesh(os.path.join(exports, "lid.stl")), lid_blue)]
        caption = "LID · four sideways-reinforced internal clips; clean exterior"
    elif args.view == "top":
        lid = trimesh.load_mesh(os.path.join(exports, "lid.stl"))
        lid.apply_transform(trimesh.transformations.rotation_matrix(np.pi, [1, 0, 0]))
        items = [(lid, lid_blue)]
        caption = "TOP · clean outer face with 2 mm paperclip button access"
    elif args.view == "bottom":
        base = trimesh.load_mesh(os.path.join(exports, "base.stl"))
        base.apply_transform(trimesh.transformations.rotation_matrix(np.pi, [1, 0, 0]))
        items = [(base, blue)]
        caption = "BOTTOM · clean outer face and four straight-through vents"
    elif args.view == "rear":
        base = trimesh.load_mesh(os.path.join(exports, "base.stl"))
        base.apply_transform(trimesh.transformations.rotation_matrix(np.pi, [0, 0, 1]))
        items = [(base, blue)]
        caption = "REAR · large recessed RW mark opposite the USB-C opening"
    elif args.view == "closed":
        base = trimesh.load_mesh(os.path.join(exports, "base.stl"))
        lid = trimesh.load_mesh(os.path.join(exports, "lid.stl"))
        lid.apply_transform(trimesh.transformations.rotation_matrix(np.pi, [1, 0, 0]))
        lid.apply_translation([0, 0, 23.5])
        items = [(base, blue), (lid, lid_blue)]
        caption = "CLOSED · uninterrupted rounded-box exterior; all four clips are internal"
    elif args.view == "fit_test":
        items = [(trimesh.load_mesh(os.path.join(exports, "fit_test.stl")), blue)]
        caption = "FIT TEST · complete 2×7 XIAO locator with deeper pin sockets"
    elif args.view == "pair":
        base_x, lid_x = -24, 24
        items = [
            (moved(trimesh.load_mesh(os.path.join(exports, "base.stl")),
                   (base_x, 0, 0)), blue),
            (moved(trimesh.load_mesh(os.path.join(exports, "lid.stl")),
                   (lid_x, 0, 0)), lid_blue),
        ]
        variant_name = "CAPTIVE USB" if captive else "STANDARD USB"
        caption = f"{variant_name} · this base and this lid are one matched pair"
        labels = [(f"{variant_name} BASE", (base_x, 0, 25)),
                  (f"{variant_name} LID", (lid_x, 0, 8))]
    else:
        spread = 23 if args.view == "layout" else 0
        base_y = 0 if args.view == "layout" else -30
        lid_y = 0 if args.view == "layout" else 31
        base_x, lid_x = -spread, spread
        device_y = 8 if captive else -8
        items = [
            (moved(trimesh.load_mesh(os.path.join(exports, "base.stl")), (base_x, base_y, 0)), blue),
            (moved(trimesh.load_mesh(os.path.join(exports, "lid.stl")), (lid_x, lid_y, 0)), lid_blue),
            (box((17.9, 22.6, 9.1), (base_x, base_y + device_y, 16.45)), pcb),
            (box((1, 40, 7), (base_x + 13.0, base_y, 6.5)), lora),
            (box((1.8, 37.4, 17.5), (base_x - 12.6, base_y + 1, 11.15)), wifi),
        ]
        if captive:
            items.extend([
                (box((12.5, 13, 6.5), (base_x, base_y - 11.8, 14.4)), (60, 65, 70)),
                (cable([(base_x, base_y - 18.3, 14.4),
                        (base_x, base_y - 32, 14.4)], 3.4), black),
                (cable([(base_x + 12.5, base_y - 20, 6.5), (base_x + 11, base_y - 17, 6),
                        (base_x + 10, base_y - 10, 7), (base_x + 10, base_y, 9),
                        (base_x + 9, base_y + 10, 12), (base_x + 6, base_y + 16, 15)]), black),
                (cable([(base_x - 11.7, base_y - 17.7, 11.2), (base_x - 11, base_y - 17, 9),
                        (base_x - 10, base_y - 10, 8), (base_x - 10, base_y, 9),
                        (base_x - 9, base_y + 10, 11), (base_x - 6, base_y + 16, 13)]), black),
            ])
            caption = "CAPTIVE USB · rear board, internal plug and split cable entry"
        else:
            items.extend([
                (box((8.94, 4.5, 4.2), (base_x, base_y - 21.5, 14.26)), silver),
                (cable([(base_x + 12.5, base_y + 20, 6.5), (base_x + 11, base_y + 17, 6),
                        (base_x + 7, base_y + 14, 7), (base_x + 7, base_y + 8, 11),
                        (base_x + 6, base_y + 3, 15)]), black),
                (cable([(base_x - 11.7, base_y + 19.7, 11.2), (base_x - 11, base_y + 17, 9),
                        (base_x - 7, base_y + 14, 7), (base_x - 7, base_y + 8, 10),
                        (base_x - 6, base_y + 3, 13)]), black),
            ])
            caption = ("LAYOUT · antennas face outwards from opposite walls" if args.view == "layout"
                       else "EXPLODED · compact header-located XIAO + Wio enclosure")
    render(items, args.output, caption, labels)


if __name__ == "__main__":
    main()
