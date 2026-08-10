// =============================================================================
//  tests/lib.scad -- shared pieces for the geometry tests
// =============================================================================
//  Include the model without letting it render anything, then rebuild the
//  sub-shapes a test needs from the model's OWN modules, so a test compares
//  the real parts rather than a re-derivation of them.
// =============================================================================
include <../nozzle.scad>
// AFTER the include, not before: OpenSCAD resolves a scope's assignments before
// evaluating geometry and the last one wins, so setting this first would just
// be overwritten by the model's default and every test would render a nozzle.
render_part = "none";

// Fine enough that a fit test cannot pass on tessellation alone. The organiser
// learned this the hard way: a 0.037mm intrusion hid inside the facets of a
// 45.8mm circle at the model's default $fa.
$fn = 240;

// The nozzle's internal cavity, exactly as nozzle() cuts it.
module cavity() {
    translate([0, 0, -eps])
        cylinder(h = nozzle_h + 2 * eps, r1 = r_i(0), r2 = r_i(nozzle_h));
}

// The sleeve's nose: whatever of the REAL sleeve stands above the seat plane.
// Deliberately not a copy of the cone in sleeve() -- a test that re-derives
// the shape it is checking passes whatever the model actually does.
module nose() {
    intersection() {
        sleeve();
        translate([0, 0, eps]) cylinder(h = big, r = big);
    }
}
