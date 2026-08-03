// Same for an inner leg's spike and its (round) hole.
include <lib.scad>
linear_extrude(1) difference() {
    section_at(inner_cone_h + inner_plug_len / 2) inner_leg();
    circle(r = inner_plug_r + leg_fit);
}
