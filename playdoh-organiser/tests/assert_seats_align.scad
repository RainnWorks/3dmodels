// Both leg kinds must seat at the same depth, or only one of them ever bears.
include <lib.scad>
gap         = pitch - tray_fh - deck_t;
corner_seat = tray_ph * (1 - leg_seat_f);
inner_seat  = inner_cone_h * (1 - leg_fit / (inner_r - inner_plug_r));
assert(abs(corner_seat - gap) < 0.01, str("corner seat ", corner_seat, " != gap ", gap));
assert(abs(inner_seat  - gap) < 0.01, str("inner seat ",  inner_seat,  " != gap ", gap));
