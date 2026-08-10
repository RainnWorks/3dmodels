// At the base the aperture prism must lie inside the cavity. If it reaches the
// wall it would slit the cone from top to bottom and the nozzle would leak
// down its whole length instead of piping out of the tip.
include <lib.scad>
intersection() {
    linear_extrude(0.5) aperture_2d();
    difference() { cylinder(h = 1, r = big); translate([0,0,-eps]) cavity(); }
}
