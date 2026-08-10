// The sleeve's nose must fit inside the nozzle's bore -- it is cut to follow
// r_i(z) exactly, less 0.3mm, so any part of it outside the cavity means the
// coupler cannot be seated without forcing the nozzle open.
include <lib.scad>
difference() { nose(); cavity(); }
