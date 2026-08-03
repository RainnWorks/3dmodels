// Same for an inner leg against each of the four cells it sits between.
include <lib.scad>
pot_margin = 0.3;
linear_extrude(1) intersection() {
    section_at(0.5) inner_leg();
    for (sx = [-1, 1], sy = [-1, 1])
        translate([sx * cell / 2, sy * cell / 2])
            circle(d = hang_d + 2 * pot_margin, $fn = 240);
}
