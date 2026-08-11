// Where does the clip intrude into the glass wall? That intrusion IS the grip:
// no intersection means the clip merely hangs there.
include <lib.scad>
intersection() {
    linear_extrude(thick) clip_2d();
    glass_wall();
}
