// Variant 2 shares variant 1's placement entirely -- same measured ink, same
// lifted baseline, same struts. These are the assertions that stop that from
// silently regressing when the tag is driven from a different set of scripts.
include <lib.scad>

assert(measured,
       "ink_drop was not measured -- placement fell back to the font metric, \
which is not a bound on the ink in either direction. Run measure.py.");

// The baseline sits where the name's OWN deepest tail bites `bite` into the
// bar. That is what style="lift" means and it is why the name rides at a
// different height on each tag.
assert(base_y >= glass_gap,
       "baseline is below the bar: ink_drop is negative or nonsense");
assert(abs(base_y - (drop + glass_gap)) < 1e-6,
       str("baseline ", base_y, " is not this name's own drop ", drop,
           " plus the gap -- style is not lift"));
assert(drop <= place_drop + 0.001,
       str("drop ", drop, " exceeds the placement drop ", place_drop));

// The letters must actually reach the bar, or the name prints as loose pieces.
assert(base_y - drop < bar_w,
       str("the deepest ink sits at ", base_y - drop,
           " but the bar only reaches ", bar_w, " -- it would not weld"));
// ...and the bar must be at least as deep as the clip's stroke, or the clip
// stands proud of the bar it grows out of.
assert(bar_w >= clip_w - 1e-9,
       str("bar ", bar_w, " is shallower than the clip's ", clip_w));
