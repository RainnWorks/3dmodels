// The rim is clamped between the arm on the inside and the BAR on the outside.
// An arm longer than the bar it hangs from reaches past the end of that bar
// and the last of its grip presses on nothing at all -- and, printed
// letters-down, that stretch of arm has no body under it either, so it is
// support that buys nothing.
include <lib.scad>

intersection() {
    clip3();
    past_the_end_of_the_bar();
}
