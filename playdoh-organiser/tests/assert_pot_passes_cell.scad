// The pot's body must clear the cell hole, and its lip must not.
include <lib.scad>
assert(hang_d > pot_shoulder_d, "cell hole is narrower than the pot body");
assert(hang_d < pot_lip_d,      "cell hole is wider than the lip: nothing to hang on");
