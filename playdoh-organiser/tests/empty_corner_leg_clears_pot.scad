// A corner leg must never reach over a cell, or the pot cannot drop in. Its
// widest section is at the deck, so testing there covers the whole leg.
// Regression: the hulled leg's chord came 0.037mm inside the pot hole at the
// then-default leg_sweep of 60 degrees.
//
// Tested against a circle `pot_margin` LARGER than the hole, and at high $fn.
// Bare tangency is not good enough to assert -- the original intrusion was
// smaller than the tessellation of a 45.8mm circle at the model's own $fa, so a
// test for exact overlap sailed straight past it. Demand real clearance.
include <lib.scad>
pot_margin = 0.3;
linear_extrude(1) intersection() {
    section_at(0.5) corner_leg();
    translate([cx(cols - 1), cy(rows - 1)])
        circle(d = hang_d + 2 * pot_margin, $fn = 240);
}
