// THE constraint this model exists to enforce: no part of the tag's body --
// letters, tails, bar, i-dot struts -- may cross the glass face.
//
// This is the boolean form of the question. If any ink reaches past y=0 the
// intersection is non-empty and the test fails. It is deliberately asked of
// the whole body rather than of the text alone, because the failure the
// original model has is a letter poking past the BAR, and only the assembled
// body can show that.
include <lib.scad>

intersection() {
    body();
    past_glass_face();
}
