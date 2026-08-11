// The clip is a spring, and a spring that does not interfere with the glass is
// just a hook that falls off. These are the derived numbers that decide it.
include <lib.scad>

// The jaw must close to LESS than the glass it has to hold, or there is no
// grip at all -- the tag would hang on friction it does not have.
assert(jaw < glass_t,
       str("jaw ", jaw, "mm does not close on a ", glass_t, "mm rim -- no grip"));

// ...but not so far that the arm is asked to bend more than it can. Past about
// a third of the spring's length the arm is being levered, not sprung.
assert(glass_t - jaw < spring_len / 3,
       str("preload ", glass_t - jaw, "mm over a ", spring_len,
           "mm arm -- the arm will take a set or snap, not spring"));

// The bend has to clear its own radius: an arc tighter than the material is
// thick turns the outer fibre into a crack.
assert(clip_rad >= spine_w * 0.8,
       str("bend radius ", clip_rad, " is tight for a ", spine_w,
           "mm section -- it will crack at the outside of the bend"));

// The geometry must be solvable at all.
assert(abs(sin_a) <= 1, "spring angle has no solution -- lengthen spring_len");
assert(spring_ang > 2 && spring_ang < 45,
       str("spring angle ", spring_ang, " deg is implausible"));
