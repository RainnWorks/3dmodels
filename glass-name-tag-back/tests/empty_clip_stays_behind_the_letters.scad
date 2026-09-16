// The other side of the same statement. The clip curls BACKWARD out of the
// letter plane; if any of it came forward past the letters' front face it
// would stand proud of the name, catch on the tablecloth, and print on top of
// the very faces that are supposed to be lying on the bed.
include <lib.scad>

intersection() {
    clip3();
    in_front_of_the_letters();
}
