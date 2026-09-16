// =============================================================================
//  tests/lib.scad -- shared pieces for the geometry tests
// =============================================================================
//  Include the model without letting it render anything, then rebuild what a
//  test needs from the model's OWN modules, so a test checks the real part
//  rather than a re-derivation of it.
//
//  Note this pulls in TWO files: nametag_back.scad, and through it variant 1's
//  nametag.scad. Both output switches have to be silenced, and both are, by
//  the same rule -- OpenSCAD resolves a scope's assignments before evaluating
//  geometry and the last one wins.
// =============================================================================
include <../nametag_back.scad>
part = "none";

// Fine enough that a clearance test cannot pass on tessellation alone.
$fn = 200;

big = 1000;
// `ttol` clear of the face, so a body that merely TOUCHES the glass -- which
// the letters' back faces do by design, that is what makes the tag lie flat --
// is not counted as a crossing. Without it CGAL returns a zero-volume shared
// face and the test fails on contact.
ttol = 0.01;

// Everything behind the glass face: where only the clip may go.
module behind_the_glass() {
    translate([-big / 2, -big / 2, -big - ttol]) cube([big, big, big]);
}

// Everything in front of the letter plane's front face.
module in_front_of_the_letters() {
    translate([-big / 2, -big / 2, thick + ttol]) cube([big, big, big]);
}

// The band the bar occupies, seen head-on. Nothing of the clip may leave it.
module bar_band() {
    translate([-big / 2, -ttol]) square([big, bar_w + 2 * ttol]);
}

// Behind the start of the bar: the arm must never reach here, or the rim would
// have nothing behind it to be clamped against.
module past_the_end_of_the_bar() {
    translate([-big, -big / 2, -big / 2]) cube([big, big, big]);
}
