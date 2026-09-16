// The constraint both variants are built around, restated for this one. In
// variant 1 the tag's plane is radial and the rule is that nothing but the
// clip may reach past y = 0; here the plane is tangential and the same rule is
// about z. The letters, the bar and the struts all live at z = 0..thick, and
// the clip is the only thing allowed behind them.
//
// This one is cheap and it is honest to say so: the body is a linear_extrude
// from z = 0, so it holds by construction. What it is really guarding is the
// join -- unioning the clip into body_3d(), or extruding the body about z = 0
// instead of from it, both look harmless and both put letters inside the wall.
include <lib.scad>

intersection() {
    body3();
    behind_the_glass();
}
