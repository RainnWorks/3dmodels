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

// The rim must actually SEAT in the curl. If the legs of the U are much wider
// apart than the rim, nothing touches until the very tip of the arm and the
// clip is really a hook -- which is what the first version of this was.
assert(jaw_root <= glass_t * 1.25,
       str("the curl opens to ", jaw_root, "mm for a ", glass_t,
           "mm rim -- the rim will not seat, and only the arm tip will touch"));

// ...and the curl must not be so tight the rim cannot enter it at all.
assert(jaw_root >= glass_t * 0.9,
       str("the curl is ", jaw_root, "mm for a ", glass_t, "mm rim -- too tight"));

// The arm has to close on the glass along its length, not just at a point.
assert(spring_ang > 0 && spring_ang < 15,
       str("arm converges at ", spring_ang,
           " deg -- over about 15 it is clawing at the tip, not clamping"));

// The geometry must be solvable at all.
assert(abs(sin_a) <= 1, "spring angle has no solution -- lengthen spring_len");

// The entry lip must flare OUTWARD past the arm, or the rim catches on a
// square end instead of sliding up it.
assert(lip_len == 0 || lip_ang > spring_ang,
       str("lip angle ", lip_ang, " does not flare past the arm's ", spring_ang));
