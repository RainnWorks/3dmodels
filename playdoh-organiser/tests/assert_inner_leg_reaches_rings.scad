// An inner leg has to reach the rings around it or it is an island floating in
// the middle of the deck, joined to nothing.
// Regression: inner_r was 9mm, and the reach needed is 11.43mm.
include <lib.scad>
reach = cell / sqrt(2) - cell / 2;
assert(inner_r > reach,
       str("inner_r ", inner_r, " does not reach the deck rings at ", reach));
