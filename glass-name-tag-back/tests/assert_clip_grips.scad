// The clip is variant 1's, unchanged, so these are variant 1's numbers -- but
// variant 1 only asserts them when IT is building a tag, and here it never is.
// Re-stating them is what keeps them switched on.
include <lib.scad>

// The jaw at the end of the arm must close to LESS than the rim it holds.
assert(jaw < glass_t,
       str("jaw ", jaw, "mm does not close on a ", glass_t, "mm rim -- no grip"));
// ...and the gap where the rim BOTTOMS OUT must be the rim itself. This is the
// reason variant 1 derives the bend from the glass rather than picking a
// radius: the rim seats in the curl, so the clip clamps along its arm instead
// of clawing at one point.
assert(abs(jaw_root - glass_t) < 1e-9,
       str("the curl's throat is ", jaw_root, "mm on a ", glass_t, "mm rim"));
assert(abs(bend_r - glass_t / 2) < 1e-9 || clip_rad >= 0,
       str("bend_r ", bend_r, " is not glass_t/2 -- the rim will not seat"));
// The convergence has to be solvable at all.
assert(abs(sin_a) <= 1, "the arm cannot close that jaw over that length");
assert(spring_ang > 0.5 && spring_ang < 30,
       str("spring angle ", spring_ang, " deg is implausible"));

// Variant 2's own: the clip is rotated into the y direction, so its width
// along the rim is now a real dimension rather than the print thickness. It
// must not exceed the bar it hides behind.
assert(cw > 0.8 && cw <= bar_w + 1e-9,
       str("clip is ", cw, "mm wide against a ", bar_w, "mm bar"));
// The curl has to clear its own radius: an arc tighter than the material is
// thick turns the outer fibre into a crack.
assert(bend_r >= clip_w * 0.35,
       str("bend radius ", bend_r, " is tight for a ", clip_w, "mm section"));
// The rim seats at the innermost point of the curl, and everything on the tag
// hangs below that.
assert(rim_x > clip_len, "the rim is not past the end of the bar");
