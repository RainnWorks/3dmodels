// Derived-value checks that the model itself does not already make.
include <lib.scad>

// The flange must pass down the ring's bore to reach its seat.
assert(flange_od < ring_bore - 0.3,
       str("flange ", flange_od, " will not pass ring bore ", ring_bore));

// The clamp cones must actually overlap -- the flange's runs clamp_d..flange_od,
// the ring's clamp_d..ring_bore, so they share clamp_d..flange_od. If the
// flange were the wider of the two, the ring would bear on a corner.
assert(flange_od <= ring_bore + eps && flange_od - clamp_d > 1.0,
       "clamp cones overlap by less than 1mm of annulus");

// The thread must have somewhere to go: rib thickness at the crest > 0.
assert(thr_rib_t - 2 * thr_depth * tan(thr_flank) > 0.3,
       "thread crest is knife-thin -- lower thr_flank or thr_depth");

// Aperture must clear the bore at the base by a real wall, not a whisker.
assert(ap_r < r_i(0) - 0.8, "aperture too close to the bore wall");

// The nose must reach far enough up to actually locate the nozzle.
assert(nose_h > 3 && nose_h < nozzle_h / 3, "nose length implausible");
