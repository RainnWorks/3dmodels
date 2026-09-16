// The point of making the clip only as wide as the bar, and putting it in the
// bar's own y band, is that head-on you cannot see it: it is directly behind
// the bar, and it crosses no lettering anywhere.
//
// So say it as a boolean. Flatten the real clip into the letter plane and
// demand it stay inside the band the bar occupies. Widen the clip past the bar
// and this fills with geometry.
include <lib.scad>

linear_extrude(1) difference() {
    projection() clip3();
    bar_band();
}
