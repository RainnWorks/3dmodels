// The ring has to slide down over the cone to reach the flange. Its bore and
// its 45 deg clamp cone must touch the flange's matching cone and NOTHING
// else -- face contact has no volume, so any solid here is a real clash.
include <lib.scad>
intersection() { ring(); nozzle(); }
