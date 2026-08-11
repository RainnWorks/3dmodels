// =============================================================================
//  tests/lib.scad -- shared pieces for the geometry tests
// =============================================================================
//  Include the model without letting it render anything, then rebuild what a
//  test needs from the model's OWN modules, so a test checks the real part
//  rather than a re-derivation of it.
// =============================================================================
include <../nametag.scad>
// AFTER the include: OpenSCAD resolves a scope's assignments before evaluating
// geometry and the last one wins, so setting this first would be overwritten by
// the model's default and every test would render a tag.
render_part = "none";

// Fine enough that a clearance test cannot pass on tessellation alone.
$fn = 200;

big = 1000;

// The glass wall, as a solid: it occupies everything on the far side of the
// glass face, and is `glass_t` thick. The tag lives at y >= 0; the wall at
// y <= 0. Anything of the tag that reaches into this is a defect.
// `tol` below the face, so a body that merely TOUCHES y=0 -- which the bar
// and the clip both do by design -- is not counted as a crossing. Without it
// CGAL returns a zero-volume shared face and the test fails on contact.
tol = 0.01;
module glass_wall() {
    translate([-big/2, -glass_t - tol, -big/2]) cube([big, glass_t, big]);
}

// Everything beyond the glass face, to any depth -- for "does the body stay on
// its own side" rather than "does it hit the wall".
module past_glass_face() {
    translate([-big/2, -big - tol, -big/2]) cube([big, big, big]);
}

// The tag's body: spine, rail, letters, struts. NOT the clip, which wraps
// around the rim and is supposed to cross the glass face.
module body() { linear_extrude(thick) body_2d(); }

// Just the sprung return arm -- the half of the clip that must press on the
// INSIDE of the glass. Taken by cutting the real clip rather than re-drawing
// it, so it cannot drift from what prints.
module spring_arm() {
    intersection() {
        linear_extrude(thick) clip_2d();
        translate([-big/2, -big, -big/2]) cube([big, big - glass_t, big]);
    }
}
