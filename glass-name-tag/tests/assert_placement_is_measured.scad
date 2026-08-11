// The whole model turns on placing text by MEASURED ink rather than by the
// font's metric. These assertions are what stop that from silently regressing.
include <lib.scad>

// A tag must never be built from the metric fallback. If ink_drop was not
// supplied, placement is guesswork and the glass clearance is unproven.
assert(measured,
       "ink_drop was not supplied -- placement fell back to the font metric, \
which is not a bound on the ink. Run measure.py.");

// The measured ink must fit under wherever the baseline was put.
assert(base_y - drop >= -0.001,
       str("baseline ", base_y, " cannot clear ", drop, "mm of ink"));

// The letters must actually reach the bar, or the name prints as loose pieces.
// "lift" and "solid" weld into the bar; "rail" welds along the baseline.
lowest_ink = base_y - drop;
assert(eff_style != "lift" || lowest_ink < bar_w,
       str("lifted name's deepest ink sits at ", lowest_ink,
           " but the bar only reaches ", bar_w, " -- it would not weld"));
assert(eff_style != "solid" || lowest_ink < bar_w,
       str("deepest ink at ", lowest_ink, " above a bar of ", bar_w));
