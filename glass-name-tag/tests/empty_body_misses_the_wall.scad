// Stronger, and the one that matches how it is actually used: with the tag
// clipped on, the wall of the glass occupies a real slab. The body must miss
// it entirely, or the tag cannot lie flat -- which is exactly the complaint
// reported against the original ("the nametag can no longer stay flat").
include <lib.scad>

intersection() {
    body();
    glass_wall();
}
