"""Mechanical fit regression tests for the complete XIAO/Wio bridge kit."""

from pathlib import Path
import math
import re
import unittest

import numpy as np
import trimesh


ROOT = Path(__file__).resolve().parents[1]
SCAD = ROOT / "velux_bridge_enclosure.scad"
SCAD_TEXT = SCAD.read_text()


def scalar(name):
    match = re.search(rf"(?m)^{re.escape(name)}\s*=\s*(-?[0-9]+(?:\.[0-9]+)?)\s*;", SCAD_TEXT)
    if not match:
        raise AssertionError(f"Cannot read numeric SCAD parameter {name}")
    return float(match.group(1))


P = {name: scalar(name) for name in (
    "case_x", "case_y", "base_h", "lid_t", "wall", "floor_t", "corner_r",
    "inner_corner_r", "lid_fit_clearance", "lid_skirt_depth", "lid_skirt_wall",
    "device_x", "device_y", "device_floor_z",
    "device_h", "wifi_ant_l", "wifi_ant_w", "wifi_ant_t",
    "lora_ant_l", "lora_ant_w", "lora_ant_t", "wifi_ant_y",
    "lora_ant_y", "antenna_lid_clearance", "coax_channel_clearance",
    "header_pitch", "header_row_spacing", "header_pins_per_row",
    "usb_open_w", "usb_open_h", "usb_open_raise",
    "usb_overmold_recess_depth", "usb_overmold_inner_w", "usb_overmold_inner_h",
    "usb_overmold_outer_w", "usb_overmold_outer_h", "wio_button_x", "wio_button_y",
    "wio_button_access_d",
    "lid_clip_length", "lid_clip_w", "lid_clip_wall",
    "lid_clip_root_w", "lid_clip_root_h", "lid_clip_wall_clearance",
    "lid_clip_hook_depth", "lid_clip_hook_ramp_h", "lid_clip_hook_peak_offset",
    "lid_clip_pocket_w", "lid_clip_pocket_depth", "lid_clip_pocket_ramp_h",
    "lid_clip_x", "usb_board_forward",
    "rear_logo_w", "rear_logo_depth",
)}
P["inner_x"] = P["case_x"] - 2 * P["wall"]
P["inner_y"] = P["case_y"] - 2 * P["wall"]
P["antenna_max_z"] = P["base_h"] - P["lid_skirt_depth"] - P["antenna_lid_clearance"]


def rounded_rectangle_sdf(x, y, width, length, radius):
    """Signed distance to a centred rounded rectangle; <= 0 is inside."""
    qx = abs(x) - (width / 2 - radius)
    qy = abs(y) - (length / 2 - radius)
    return math.hypot(max(qx, 0), max(qy, 0)) + min(max(qx, qy), 0) - radius


def placed_official_mesh(filename, axes, centre_y, bottom_z):
    """Axis-map and place an official Seeed reference mesh by its CAD bounds."""
    mesh = trimesh.load_mesh(ROOT / "references" / filename, process=False)
    vertices = np.asarray(mesh.vertices)[:, axes].copy()
    bounds = np.array([vertices.min(axis=0), vertices.max(axis=0)])
    vertices[:, 0] -= bounds[:, 0].mean()
    vertices[:, 1] -= bounds[:, 1].mean()
    vertices[:, 1] += centre_y
    vertices[:, 2] -= bounds[0, 2]
    vertices[:, 2] += bottom_z
    return vertices


def box_corners(x_bounds, y_bounds, z_bounds):
    return np.array([
        [x, y, z]
        for x in x_bounds
        for y in y_bounds
        for z in z_bounds
    ])


def centred_usb_loop(section, expected_centre_z):
    """Select the x-centred USB contour, ignoring nearby clip-pocket loops."""
    candidates = [
        line for line in section.discrete
        if line[:, 0].min() <= 0 <= line[:, 0].max()
    ]
    if not candidates:
        raise AssertionError("Centred USB contour missing")
    return min(
        candidates,
        key=lambda line: abs((line[:, 2].min() + line[:, 2].max()) / 2
                             - expected_centre_z),
    )


class ReferenceModelTests(unittest.TestCase):
    def test_official_seeed_model_dimensions_have_not_changed(self):
        xiao = trimesh.load_mesh(ROOT / "references" / "XIAO-ESP32S3.stl", process=False)
        wio = trimesh.load_mesh(ROOT / "references" / "Wio-SX1262_for_XIAO.stl", process=False)
        np.testing.assert_allclose(xiao.extents, [22.48198, 4.46, 17.78], atol=0.002)
        np.testing.assert_allclose(wio.extents, [17.78010, 21.43981, 7.30000], atol=0.002)

    def test_official_boards_fit_inside_shell_in_both_layouts(self):
        # XIAO CAD axes are length, height, width. Wio axes already match XYZ.
        self.assertAlmostEqual(P["usb_board_forward"], 0.5)
        for centre_y in (-8.0 - P["usb_board_forward"],
                         8.0 - P["usb_board_forward"]):
            xiao = placed_official_mesh(
                "XIAO-ESP32S3.stl", [2, 0, 1], centre_y, P["device_floor_z"]
            )
            # The separate CAD models overlap at their mating connectors. Align
            # the Wio's tallest point to the measured 9.1 mm assembled envelope.
            wio_bottom = P["device_floor_z"] + P["device_h"] - 7.30000
            wio = placed_official_mesh(
                "Wio-SX1262_for_XIAO.stl", [0, 1, 2], centre_y, wio_bottom
            )
            for name, vertices in (("XIAO", xiao), ("Wio", wio)):
                worst = max(
                    rounded_rectangle_sdf(x, y, P["inner_x"], P["inner_y"], P["inner_corner_r"])
                    for x, y in vertices[:, :2]
                )
                self.assertLessEqual(worst, 1e-6, f"{name} intersects a side wall")
                self.assertGreaterEqual(vertices[:, 2].min(), P["floor_t"])
                self.assertLessEqual(vertices[:, 2].max(), P["base_h"] - 0.5 + 1e-6)

    def test_official_wio_top_has_three_mm_to_fitted_lid(self):
        """Check the real reference mesh against the lid, not only the envelope maths."""
        for centre_y in (-8.0 - P["usb_board_forward"],
                         8.0 - P["usb_board_forward"]):
            wio_bottom = P["device_floor_z"] + P["device_h"] - 7.30000
            wio = placed_official_mesh(
                "Wio-SX1262_for_XIAO.stl", [0, 1, 2], centre_y, wio_bottom
            )
            actual_clearance = P["base_h"] - wio[:, 2].max()
            self.assertAlmostEqual(actual_clearance, 3.0, delta=0.002)


class AntennaFitTests(unittest.TestCase):
    def antenna_corners(self, side, length, height, thickness, centre_y, bottom_gap):
        wall_x = side * P["inner_x"] / 2
        inward_x = wall_x - side * thickness
        bottom = P["floor_t"] + bottom_gap
        return box_corners(
            [min(wall_x, inward_x), max(wall_x, inward_x)],
            [centre_y - length / 2, centre_y + length / 2],
            [bottom, bottom + height],
        )

    def test_full_fpc_rectangles_are_on_flat_wall_not_rounded_corners(self):
        flat_length = P["inner_y"] - 2 * P["inner_corner_r"]
        self.assertAlmostEqual(flat_length, 41.0)
        self.assertGreaterEqual(flat_length, P["lora_ant_l"])
        self.assertGreaterEqual(
            P["inner_y"] / 2 - P["inner_corner_r"],
            abs(P["wifi_ant_y"]) + P["wifi_ant_l"] / 2,
        )

    def test_both_complete_antennas_stay_inside_the_cavity(self):
        antennas = (
            self.antenna_corners(-1, P["wifi_ant_l"], P["wifi_ant_w"],
                                 P["wifi_ant_t"], P["wifi_ant_y"], 0.4),
            self.antenna_corners(1, P["lora_ant_l"], P["lora_ant_w"],
                                 P["lora_ant_t"], P["lora_ant_y"], 1.0),
        )
        for vertices in antennas:
            for x, y, _ in vertices:
                self.assertLessEqual(
                    rounded_rectangle_sdf(x, y, P["inner_x"], P["inner_y"], P["inner_corner_r"]),
                    1e-6,
                )
            self.assertGreaterEqual(vertices[:, 2].min(), P["floor_t"])
            self.assertLessEqual(vertices[:, 2].max(), P["antenna_max_z"] + 1e-6)

    def test_antennas_do_not_touch_the_board_envelope(self):
        board_left = -P["device_x"] / 2
        board_right = P["device_x"] / 2
        wifi_inner = -P["inner_x"] / 2 + P["wifi_ant_t"]
        lora_inner = P["inner_x"] / 2 - P["lora_ant_t"]
        self.assertGreater(board_left - wifi_inner, P["coax_channel_clearance"])
        self.assertGreater(lora_inner - board_right, P["coax_channel_clearance"])

    def test_exported_lid_features_clear_the_wifi_antenna(self):
        for folder in ("export", "export-captive-usb"):
            lid = trimesh.load_mesh(ROOT / folder / "lid.stl")
            lid.apply_transform(trimesh.transformations.rotation_matrix(np.pi, [1, 0, 0]))
            lid.apply_translation([0, 0, P["base_h"] + P["lid_t"]])
            # Inspect actual fitted lid vertices in the Wi-Fi antenna's X/Y zone.
            vertices = lid.vertices
            x0 = -P["inner_x"] / 2
            mask = (
                (vertices[:, 0] >= x0 - 0.6)
                & (vertices[:, 0] <= x0 + P["wifi_ant_t"] + 0.6)
                & (vertices[:, 1] >= P["wifi_ant_y"] - P["wifi_ant_l"] / 2)
                & (vertices[:, 1] <= P["wifi_ant_y"] + P["wifi_ant_l"] / 2)
                & (vertices[:, 2] <= P["base_h"])
            )
            self.assertTrue(mask.any())
            actual_lid_low = vertices[mask, 2].min()
            wifi_top = P["floor_t"] + 0.4 + P["wifi_ant_w"]
            self.assertGreaterEqual(actual_lid_low - wifi_top, 0.30)


class MechanicalFeatureTests(unittest.TestCase):
    def test_rear_logo_is_large_but_stays_on_the_flat_wall(self):
        self.assertTrue((ROOT / "assets" / "rainn-logo-single-color.svg").is_file())
        flat_rear_width = P["case_x"] - 2 * P["corner_r"]
        self.assertGreaterEqual(P["rear_logo_w"], 18.0)
        self.assertLessEqual(P["rear_logo_w"], flat_rear_width - 1.0)
        logo_h = P["rear_logo_w"] * 446 / 560
        self.assertLessEqual(logo_h, P["base_h"] - 2.0)
        self.assertGreaterEqual(P["rear_logo_depth"], 0.4)
        self.assertLess(P["rear_logo_depth"], P["wall"])
        self.assertIn("svg_mm_per_px = 25.4/72;", SCAD_TEXT)
        self.assertIn("mirror([1,0,0]) // reads correctly", SCAD_TEXT)

        # Check the physical recess on the exported rear wall; this catches the
        # SVG px-to-mm conversion that a parameter-only assertion would miss.
        base = trimesh.load_mesh(ROOT / "export" / "base.stl", process=False)
        recess_y = P["case_y"] / 2 - P["rear_logo_depth"]
        recess = base.vertices[np.isclose(base.vertices[:, 1], recess_y, atol=0.005)]
        self.assertTrue(len(recess), "RW recess missing from exported rear wall")
        expected_x = (-P["rear_logo_w"] / 2, P["rear_logo_w"] / 2)
        expected_z = (P["base_h"] / 2 - logo_h / 2,
                      P["base_h"] / 2 + logo_h / 2)
        for value in expected_x:
            self.assertLess(np.min(np.abs(recess[:, 0] - value)), 0.03)
        for value in expected_z:
            self.assertLess(np.min(np.abs(recess[:, 2] - value)), 0.03)

    def test_header_pattern_matches_xiao_2_by_7_grid(self):
        self.assertEqual(P["header_pins_per_row"], 7)
        self.assertAlmostEqual(P["header_pitch"], 2.54)
        self.assertAlmostEqual(P["header_row_spacing"], 15.24)
        pin_span = (P["header_pins_per_row"] - 1) * P["header_pitch"]
        self.assertLess(pin_span, P["device_y"])
        self.assertLess(P["header_row_spacing"], P["device_x"])

    def test_usb_aperture_clears_official_connector_envelope(self):
        self.assertGreaterEqual(P["usb_open_w"] - 8.94, 0.4)
        self.assertGreaterEqual(P["usb_open_h"] - 4.20, 0.4 - 1e-9)
        base = trimesh.load_mesh(ROOT / "export" / "base.stl")
        section = base.section(plane_origin=[0, -P["case_y"] / 2 + P["wall"] - 0.01, 0],
                               plane_normal=[0, 1, 0])
        self.assertIsNotNone(section)
        expected_centre_z = (
            P["device_floor_z"] + 0.1 + P["usb_open_raise"] + P["usb_open_h"] / 2
        )
        aperture = centred_usb_loop(section, expected_centre_z)
        self.assertAlmostEqual(np.ptp(aperture[:, 0]), P["usb_open_w"], delta=0.03)
        self.assertAlmostEqual(np.ptp(aperture[:, 2]), P["usb_open_h"], delta=0.03)

    def test_usb_aperture_includes_measured_pin_spacer_correction(self):
        self.assertAlmostEqual(P["usb_open_raise"], 3.0)
        base = trimesh.load_mesh(ROOT / "export" / "base.stl")
        section = base.section(plane_origin=[0, -P["case_y"] / 2 + P["wall"] - 0.01, 0],
                               plane_normal=[0, 1, 0])
        # usb_open_z is the aperture's lower edge; rounded_front_opening adds
        # half its height when centring the rounded rectangle.
        expected_centre_z = (
            P["device_floor_z"] + 0.1 + P["usb_open_raise"] + P["usb_open_h"] / 2
        )
        aperture = centred_usb_loop(section, expected_centre_z)
        actual_centre_z = (aperture[:, 2].min() + aperture[:, 2].max()) / 2
        self.assertAlmostEqual(actual_centre_z, expected_centre_z, delta=0.03)
        self.assertAlmostEqual(actual_centre_z, 17.3, delta=0.03)

    def test_usb_overmold_recess_is_deep_tapered_and_printable(self):
        self.assertGreaterEqual(P["usb_overmold_inner_w"], 12.4)
        self.assertGreaterEqual(P["usb_overmold_inner_h"], 8.2)
        self.assertGreaterEqual(P["wall"] - P["usb_overmold_recess_depth"], 0.8)
        roof_rise = (P["usb_overmold_outer_h"] - P["usb_overmold_inner_h"]) / 2
        self.assertGreaterEqual(roof_rise, P["usb_overmold_recess_depth"])

        base = trimesh.load_mesh(ROOT / "export" / "base.stl")
        centre_z = P["device_floor_z"] + 0.1 + P["usb_open_raise"] + P["usb_open_h"] / 2
        samples = (
            (-P["case_y"] / 2 + 0.01,
             P["usb_overmold_outer_w"], P["usb_overmold_outer_h"]),
            (-P["case_y"] / 2 + P["usb_overmold_recess_depth"] - 0.01,
             P["usb_overmold_inner_w"], P["usb_overmold_inner_h"]),
        )
        for y, expected_w, expected_h in samples:
            section = base.section(plane_origin=[0, y, 0], plane_normal=[0, 1, 0])
            self.assertIsNotNone(section)
            opening = min(section.discrete, key=lambda line: np.ptp(line[:, 0]))
            self.assertAlmostEqual(np.ptp(opening[:, 0]), expected_w, delta=0.08)
            self.assertAlmostEqual(np.ptp(opening[:, 2]), expected_h, delta=0.08)
            actual_z = (opening[:, 2].min() + opening[:, 2].max()) / 2
            self.assertAlmostEqual(actual_z, centre_z, delta=0.03)

    def test_case_height_increases_without_moving_board(self):
        self.assertAlmostEqual(P["base_h"], 24.0)
        self.assertAlmostEqual(P["device_floor_z"], 11.9)
        roof_clearance = P["base_h"] - (P["device_floor_z"] + P["device_h"])
        self.assertGreaterEqual(roof_clearance, 3.0 - 1e-9)

    def test_lid_clips_are_printable_and_snap_below_a_real_shoulder(self):
        self.assertGreaterEqual(P["lid_clip_length"], 7.0)
        self.assertGreaterEqual(P["lid_clip_w"], 7.0)
        self.assertGreaterEqual(P["lid_clip_wall"], 1.5)
        self.assertGreaterEqual(P["lid_clip_root_w"], 10.0)
        self.assertGreaterEqual(P["lid_clip_root_h"], 1.5)
        lip_inner_y = (
            P["inner_y"] / 2 - P["lid_fit_clearance"] - P["lid_skirt_wall"]
        )
        lip_outer_y = P["inner_y"] / 2 - P["lid_fit_clearance"]
        arm_outer_y = P["inner_y"] / 2 - P["lid_clip_wall_clearance"]
        arm_inner_y = arm_outer_y - P["lid_clip_wall"]
        self.assertLessEqual(arm_inner_y, lip_inner_y)
        self.assertGreaterEqual(arm_outer_y, lip_outer_y)
        self.assertGreaterEqual(
            P["lid_clip_root_w"] * P["lid_clip_wall"],
            3 * 2.8 * 0.7,
        )
        self.assertAlmostEqual(P["lid_clip_hook_depth"], 0.55)
        self.assertGreaterEqual(P["lid_clip_pocket_w"] - P["lid_clip_w"], 0.2)
        snap_deflection = P["lid_clip_hook_depth"] - P["lid_clip_wall_clearance"]
        self.assertGreaterEqual(snap_deflection, 0.4)
        self.assertLessEqual(snap_deflection, 0.5)
        # Small-deflection cantilever estimate: surface strain ~= 1.5*t*d/L^2.
        # The deeper retention nose raises the calculated flex demand, but the
        # full-depth 1.5 mm tongue and 10 mm root keep it below 2%.
        estimated_surface_strain = (
            1.5 * P["lid_clip_wall"] * snap_deflection / P["lid_clip_length"] ** 2
        )
        self.assertLessEqual(estimated_surface_strain, 0.02)
        hook_wall_half_height = (
            P["lid_clip_hook_ramp_h"] * snap_deflection / P["lid_clip_hook_depth"]
        )
        vertical_clearance = P["lid_clip_pocket_ramp_h"] - hook_wall_half_height
        self.assertGreaterEqual(P["lid_clip_pocket_depth"] - snap_deflection, 0.04)
        self.assertGreaterEqual(vertical_clearance, 0.1)
        self.assertLessEqual(vertical_clearance, 0.2)

        for folder in ("export", "export-captive-usb"):
            lid = trimesh.load_mesh(ROOT / folder / "lid.stl")
            vertices = lid.vertices
            hook_peak_z = (
                P["lid_t"] + P["lid_clip_length"]
                - P["lid_clip_hook_peak_offset"]
            )
            expected_hook_tip_y = (
                P["inner_y"] / 2 - P["lid_clip_wall_clearance"]
                + P["lid_clip_hook_depth"]
            )
            # The outside remains the original rounded box: all four long arms
            # live inside it and extend well below the short alignment skirt.
            np.testing.assert_allclose(lid.extents[:2],
                                       [P["case_x"], P["case_y"]], atol=0.03)
            for x in (-P["lid_clip_x"], P["lid_clip_x"]):
                for ysign in (-1.0, 1.0):
                    zone = vertices[
                        (np.abs(vertices[:, 0] - x) <= P["lid_clip_w"] / 2 + 0.1)
                        & (vertices[:, 1] * ysign > P["inner_y"] / 2 - 1.2)
                        & (vertices[:, 2] > P["lid_t"] + P["lid_skirt_depth"])
                    ]
                    self.assertTrue(len(zone), "internal lid clip missing")
                    self.assertGreaterEqual(zone[:, 2].max() - P["lid_t"],
                                            P["lid_clip_length"] - 0.05)
                    peak = zone[np.abs(zone[:, 2] - hook_peak_z) <= 0.08]
                    self.assertTrue(len(peak), "lid hook peak missing")
                    actual_hook_tip_y = np.max(peak[:, 1] * ysign)
                    self.assertAlmostEqual(actual_hook_tip_y,
                                           expected_hook_tip_y, delta=0.03)

        # The added case height puts the broad tabs above the XIAO side edges;
        # the Wio ends remain longitudinally clear of the tongues.
        clip_inner_y = (
            P["inner_y"] / 2 - P["lid_clip_wall_clearance"] - P["lid_clip_wall"]
        )
        fitted_clip_bottom = P["base_h"] - P["lid_clip_length"]
        xiao_side_top = P["device_floor_z"] + 3.25
        self.assertGreaterEqual(fitted_clip_bottom - xiao_side_top, 1.0)
        wio_end_y = 8.5 + 10.71990204
        self.assertGreaterEqual(clip_inner_y - wio_end_y, 0.15)
        wifi_rear_y = P["wifi_ant_y"] + P["wifi_ant_l"] / 2
        self.assertGreaterEqual(clip_inner_y - wifi_rear_y, 0.25)
        clip_outer_x = P["lid_clip_x"] + P["lid_clip_w"] / 2
        self.assertLessEqual(clip_outer_x, P["inner_x"] / 2 - P["inner_corner_r"])
        lora_top = P["floor_t"] + 1.0 + P["lora_ant_w"]
        self.assertGreaterEqual(fitted_clip_bottom - lora_top, 3.5)

        # The pocket is a close diamond negative rather than a tall slot. Its
        # deepest line shares the fitted hook peak height, limiting vertical play.
        base = trimesh.load_mesh(ROOT / "export" / "base.stl")
        expected_pocket_floor_y = (
            P["inner_y"] / 2 + P["lid_clip_pocket_depth"]
        )
        expected_peak_z = (
            P["base_h"] - P["lid_clip_length"] + P["lid_clip_hook_peak_offset"]
        )
        for x in (-P["lid_clip_x"], P["lid_clip_x"]):
            for side in (-1.0, 1.0):
                vertices = base.vertices
                recess_wall = vertices[
                    (np.abs(vertices[:, 0] - x) <= P["lid_clip_pocket_w"] / 2 + 0.1)
                    & (np.abs(vertices[:, 1] - side * expected_pocket_floor_y) <= 0.03)
                ]
                self.assertTrue(len(recess_wall), "clip pocket missing from exported base")
                self.assertAlmostEqual(recess_wall[:, 2].mean(), expected_peak_z, delta=0.04)
                self.assertLessEqual(np.ptp(recess_wall[:, 2]), 0.08)

    def test_button_access_is_paperclip_sized(self):
        self.assertGreaterEqual(P["wio_button_access_d"], 1.5)
        self.assertLessEqual(P["wio_button_access_d"], 2.0)
        self.assertAlmostEqual(P["wio_button_y"], -2.0)

        # Confirm the exported hole—not only its source parameter—moves with
        # the button while accounting for the lid's fitted Y-axis reversal.
        for folder, device_centre_y in (
            ("export", -8.0 - P["usb_board_forward"]),
            ("export-captive-usb", 8.0 - P["usb_board_forward"]),
        ):
            lid = trimesh.load_mesh(ROOT / folder / "lid.stl", process=False)
            section = lid.section(plane_origin=[0, 0, P["lid_t"] / 2],
                                  plane_normal=[0, 0, 1])
            self.assertIsNotNone(section)
            holes = [
                line for line in section.discrete
                if np.allclose(np.ptp(line[:, :2], axis=0),
                               P["wio_button_access_d"], atol=0.03)
            ]
            self.assertEqual(len(holes), 1, "paperclip button opening missing")
            hole = holes[0]
            actual_centre = (hole[:, :2].min(axis=0) + hole[:, :2].max(axis=0)) / 2
            expected_centre = np.array([
                P["wio_button_x"], -(device_centre_y + P["wio_button_y"])
            ])
            np.testing.assert_allclose(actual_centre, expected_centre, atol=0.03)

    def test_all_printable_stls_are_single_watertight_bodies(self):
        paths = [
            ROOT / "export" / "base.stl",
            ROOT / "export" / "lid.stl",
            ROOT / "export" / "fit_test.stl",
            ROOT / "export-captive-usb" / "base.stl",
            ROOT / "export-captive-usb" / "lid.stl",
        ]
        for path in paths:
            mesh = trimesh.load_mesh(path)
            self.assertTrue(mesh.is_watertight, str(path))
            self.assertEqual(len(mesh.split()), 1, str(path))


if __name__ == "__main__":
    unittest.main()
