// =============================================================================
//  tests/lib.scad -- shared pieces for the geometry tests
// =============================================================================
//  Include the model without letting it render anything, then rebuild the two
//  leg kinds exactly as vertical() does, so a test is checking the real thing
//  rather than a re-derivation of it.
// =============================================================================
include <../organiser.scad>
// AFTER the include, not before: OpenSCAD resolves a scope's assignments before
// evaluating geometry and the last one wins, so setting this first would just be
// overwritten by the model's own default and every test would render a tray.
render_part = "none";

// A corner leg, as vertical() builds it.
module corner_leg() {
    difference() {
        leg_stack(tray_ph, 0, 0) leg_outline();
        translate([0, 0, -eps]) leg_stack(tray_ph + eps, leg_t, 2) leg_outline();
    }
}

// An inner leg, as vertical() builds it.
module inner_leg() {
    difference() {
        inner_solid(0);
        translate([0, 0, -eps]) inner_solid(leg_t);
    }
}

// The horizontal cross-section of `children()` at height z, as a 2D shape.
module section_at(z) { projection(cut = true) translate([0, 0, -z]) children(); }
