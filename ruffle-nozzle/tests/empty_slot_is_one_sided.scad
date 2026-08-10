// THE regression for the worst bug this model has had.
//
// Beyond the mouth, the aperture must lie entirely on ONE side of the axis.
// If it straddles the axis, the prism cut goes through BOTH walls: the cone is
// severed into two free petals and the tip becomes see-through. That is what
// anchoring the traced outline on its centroid did, and a whole-part render
// does not show it -- you have to look at the back, or at this.
//
// The real part settles it: the side photo's tip rim is a continuous oval.
include <lib.scad>
linear_extrude(1) intersection() {
    aperture_2d();
    difference() { circle(r = big); circle(r = one_sided_r); }  // outside the mouth
    translate([-big, 0]) square([2 * big, big]);                // the far half-plane
}
