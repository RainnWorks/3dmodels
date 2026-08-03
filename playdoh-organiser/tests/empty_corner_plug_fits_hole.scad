// A corner leg's plug must pass through the hole punched in the plate below.
// Regression: leg_loft used hull(), which convexified the concave outline, so
// the plug was filled in across the very arc the hole followed. Two trays could
// not go together. The old hull leg left 172 facets here.
include <lib.scad>
linear_extrude(1) difference() {
    section_at(tray_ph + leg_plug / 2) corner_leg();
    offset(r = -leg_hole) leg_outline();
}
