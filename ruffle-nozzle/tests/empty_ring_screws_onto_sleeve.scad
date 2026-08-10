// The two coupler halves, each at its modelled position, must not share any
// volume: the ring's internal thread is the sleeve's external thread grown by
// thr_rclear/thr_aclear, so if this is non-empty the ring will not go on.
// This is the check that a derived-value assert cannot make -- both threads
// are individually correct; the question is whether they mate.
include <lib.scad>
intersection() { sleeve(); ring(); }
