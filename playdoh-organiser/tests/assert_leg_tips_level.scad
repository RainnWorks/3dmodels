// Every leg must end at the same height, or a tray set down rests on some of
// them and not others -- and the ones left hanging were the middle pair, which
// is exactly where the plate bows.
// Regression: inner spikes finished 3.91mm short, because matching SEAT depths
// does not give matching TIP heights when the two tapers differ in steepness.
include <lib.scad>
corner_tip = tray_ph + leg_plug;
inner_tip  = inner_cone_h + inner_plug_len;
assert(abs(corner_tip - inner_tip) < 0.01,
       str("leg tips not level: corner ", corner_tip, " vs inner ", inner_tip));
