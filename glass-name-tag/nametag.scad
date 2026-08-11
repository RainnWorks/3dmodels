// =============================================================================
//  nametag.scad -- a name tag that clips over the rim of a wine glass, so each
//  guest's glass is their place setting.
// =============================================================================
//  Printed FLAT. The whole part lives in XY and is extruded `thick` in Z, so
//  the print plane is the plane of the tag.
//
//      y                     the name, in a script font
//      ^          _   _
//      |        _/ \ / \_               <- ink_rise above the baseline
//      |   ----------------------       <- BASELINE  (y = base_y)
//      |        \_/                     <- ink_drop below it (the tails)
//      |   ======================  ]    <- spine
//      +-- - - - - - - - - - - - - - -  <- y = 0  THE GLASS FACE
//                                  |
//                          the clip wraps around here
//
//  y = 0 is the plane of the glass wall. Everything that prints must sit at
//  y >= 0 or it fouls the glass and the tag will not lie flat -- that is the
//  single hard constraint in this file, it is asserted below, and it is
//  measured off the exported mesh by tests/run.py.
//
//  Rendered/exported per-part with -D render_part="..."  (see Makefile):
//    tag    - the whole thing (default)
//    text   - just the letters, at their placed position (used by measure.py)
//    clip   - just the clip
// =============================================================================

/* [Name] */
name        = "Name";
// Any installed font. Great Vibes / Pacifico are Google fonts, so they render
// here AND in MakerWorld's customiser.
font        = "Great Vibes";        // font
txt_size    = 15;                   // [8:0.5:30]
// fatten the strokes so hairlines survive the nozzle (mm)
bold        = 0.0;                  // [0:0.05:1]
// letter spacing (1 = normal)
spacing     = 1.0;                  // [0.8:0.01:1.6]

/* [Measured ink -- see measure.py] */
// How far the deepest ink of THIS name falls below the baseline, in mm at the
// current txt_size. This is a MEASUREMENT of the actual glyphs, not the font's
// declared descent -- the two disagree, and trusting the metric is precisely
// the bug this model exists to avoid (see README).
//   ink_drop < 0  ->  "not measured", fall back to the font metric and warn.
ink_drop    = -1;
// Ink extent along the baseline, relative to the text origin (mm).
ink_x0      = 0;
ink_x1      = -1;                   // < 0 -> "not measured"
// For a MATCHED SET: the deepest ink_drop across all the names being printed.
// Every tag then shares one baseline height, so the set looks like a set
// instead of each name riding at its own level. < 0 -> use this name's own.
set_drop    = -1;

/* [Style] */
// How the letters are carried. Renders of all three are in previews/styles.png.
//   rail   - one thin bar ON the baseline, where script letters already join
//            each other. The tails hang below it in open air and clear the
//            glass by measurement. Only the clip end reaches down to the
//            glass face. This is the default and the reason is in the README.
//   window - rail plus a second bar at the glass face, closed at both ends.
//            Strong, but names without tails get an empty rectangle.
//   solid  - one bar from the glass face up to the baseline. Strongest, and it
//            swallows the descenders whole.
//   flush  - letters sit on a thin spine and anything reaching past the glass
//            face is trimmed off. Kept for comparison: it amputates the
//            descenders mid-bowl (previews/set_*.png) and should not be used.
//   lift   - one thin bar at the glass face, and the whole name lifted until
//            its OWN deepest tail just bites into the bar. Descenders stay
//            fully visible above a bar that sits at the bottom. The cost is
//            that the name rides at a different height on each tag, because
//            that height IS the name's descent -- see README.
style       = "rail";               // [rail, lift, window, solid, flush]
// clear air kept between the lowest ink and the glass face (mm)
glass_gap   = 0.4;                  // [0:0.1:2]
// bridge floating islands (script "i" dots) to their stem (mm)
connect     = 0.0;                  // [0:0.05:2]

/* [Bridges -- see bridges.py] */
// Struts welding the floating islands (the dots on i and j) to the body, as
// [[x1,y1,x2,y2], ...] in tag coordinates. An unbridged dot prints as a loose
// disc and falls off; a `connect` radius big enough to catch it also fills the
// counters of "e" and "o", so each one is bridged individually instead.
struts      = [];
strut_w     = 0.9;                  // [0.4:0.05:2]
// height of the probe strip used to measure the weld (see weld.py)
weld_probe  = 0.2;

/* [Clip] */
// Rim thickness of the glass. Wine glasses run 1-2mm; measure the real rim.
glass_t     = 2.0;                  // [0.5:0.1:5]
// how far the jaw closes past the glass thickness -- this is the grip (mm)
preload     = 0.8;                  // [0:0.1:2]
// the bar that lies against the outside of the glass
spine_w     = 2.2;                  // [1:0.1:8]
// the rail under the baseline, for style="window"
rail_w      = 1.6;                  // [0.8:0.1:4]
// shortest the clip bar may be, for short names (mm)
clip_min_len = 42;                  // [20:1:90]
// The bend is NOT a free radius. The two legs of the U must end up about a
// rim apart or the rim cannot seat in the curl, so the inner radius is
// glass_t/2 and the clip clamps along the arm instead of clawing at one point.
// This only overrides it for experiments.
clip_rad    = -1;                   // <0 = derive from glass_t
// the sprung return arm that presses on the inside of the glass
spring_len  = 18;                   // [8:1:40]
// the entry lip: the last of the arm flares back OUT, so the rim has something
// to slide up rather than a square end to catch on
lip_len     = 3.5;                  // [0:0.5:10]
lip_ang     = 22;                   // [0:1:60]
// gap between the end of the name and where the bend starts (mm)
clip_margin = 4;                    // [0:0.5:15]
// how far back from the hook the bar at the glass face runs, for style="rail".
// This is the length that actually bears against the glass.
clip_bar_len = 26;                  // [8:1:60]
// The swish: the flourish that carries the rail down to the glass face and
// becomes the clip. Length along the tag, and how wide the stroke ends up.
swish_len   = 22;                   // [10:1:60]
swish_w     = 2.4;                  // [1:0.1:5]
// 0 = the stroke leaves the rail flat and arrives flat (a lazy S).
// Higher = it dives away sooner and flattens later, so a deeper hook.
swish_bias  = 0.5;                  // [0.2:0.05:0.9]
// How far the stroke LIFTS off the baseline before it dives (mm). A curve that
// only ever falls reads as a ramp; a small rise first reads as a pen lifting
// into a flourish, and it is what stops the descent fighting the text's flow.
swish_rise  = 4;                    // [0:0.5:8]
// How steeply it leaves the rail and arrives at the hook (degrees from flat).
// 0 = tangent to both, which forces the S; higher makes it one sweeping curl.
swish_exit  = 0;                    // [0:5:60]

/* [Print] */
thick       = 2.0;                  // [1:0.2:4]

/* [Hidden] */
render_part = "tag";
$fn         = 64;
eps         = 0.001;
weld        = 0.4;   // overlap between welded bodies, so unions are watertight
                     // rather than coincident-faced

// =============================================================================
//  Derived
// =============================================================================

// --- the ink ----------------------------------------------------------------
// Fall back to the font's declared descent when unmeasured. This is the
// UNSAFE path: the metric is not a bound on the ink (README), so say so.
metric_drop = -textmetrics(name, size = txt_size, font = font, spacing = spacing).position.y;
measured    = ink_drop >= 0;
drop        = measured ? ink_drop : metric_drop;

// Where the baseline sits. The deepest ink lands `glass_gap` above the glass
// face -- this, and not a hand-tuned offset, is what keeps letters off the
// glass for EVERY name. A set shares one baseline (set_drop); a lone tag uses
// its own ink.
// "flush" is the exception: there the letters sit straight on the thin spine
// and the tails are trimmed at the glass face rather than cleared over it.
// "lift" deliberately ignores the shared set baseline: it references THIS
// name's own deepest ink, so that ink lands `weld` inside the bar's top edge
// and welds there. That is what keeps the tails visible above a low bar, and
// it is also why the name rides higher on a name with deeper tails.
place_drop  = (style == "lift" || set_drop < 0) ? drop : set_drop;
base_y      = (style == "flush") ? spine_w - weld
            : (style == "lift")  ? drop + spine_w - weld
            :                      place_drop + glass_gap;

// A rail only makes sense if there is room for one under the baseline. Short
// of that (a name with no descenders at all) the spine simply reaches the
// baseline itself, which is what "solid" does.
has_room    = base_y > rail_w + 0.3;
eff_style   = ((style == "window" || style == "rail") && !has_room)
              ? "solid" : style;
// lift always has room by construction: its baseline is derived FROM the bar.

// Text width: measured if we have it, else the font's advance.
metric_w    = textmetrics(name, size = txt_size, font = font, spacing = spacing).advance.x;
txt_w       = (ink_x1 >= 0) ? (ink_x1 - ink_x0) : metric_w;

// --- the spine --------------------------------------------------------------
// "solid" grows the bar all the way to the baseline; the others keep it thin.
bar_w       = (eff_style == "solid") ? base_y + weld : spine_w;
// The top edge of whatever bar actually carries the letters. For "rail" that
// is the rail at the baseline; for the others it is the low bar. This is the
// plane a name would break off along, so it is where weld.py probes.
weld_y      = (eff_style == "rail" || eff_style == "window")
              ? base_y + weld : bar_w;
// "lift" wants the full-length low bar, not the clip-end-only one.

// x where the ink starts, and how long the bar has to be
txt_x       = clip_margin;
// The swish starts where the name ends, and the tag ends where the swish does.
swish_x0    = txt_x + txt_w;
clip_len    = (eff_style == "rail") ? swish_x0 + swish_len
                                    : max(clip_min_len, txt_x + txt_w + clip_margin);

// --- the clip ---------------------------------------------------------------
// The jaw is the gap between the spine's glass face (y=0) and the return arm.
// At rest it closes to (glass_t - preload) so it grips; the arm springs open to
// take the rim.
// The rim seats in the curl, so the gap THERE is the rim thickness. The arm
// then closes to `jaw` over its length -- that 0.8mm of interference is the
// grip, and spreading it along the arm is what makes this a clip rather than
// a hook that touches at one point.
jaw_root    = glass_t;                       // gap where the rim bottoms out
jaw         = max(0.2, glass_t - preload);   // gap at the end of the arm
bend_r      = (clip_rad >= 0) ? clip_rad : jaw_root / 2;
clip_w      = swish_w;                       // the clip is the swish continuing
// centreline radius of the swept stroke round the bend
bend_rc     = bend_r + clip_w / 2;
// how much the arm converges over its length
sin_a       = (jaw_root - jaw) / spring_len;
spring_ang  = asin(min(1, max(-1, sin_a)));

// =============================================================================
//  Sanity -- these are cheap and they catch the failure modes that matter
// =============================================================================
// Only for a real tag: measure.py renders render_part="text" with the baseline
// deliberately pinned to y=0 to read the ink off, and that is not a tag.
building = (render_part == "tag" || render_part == "body");
assert(!building || base_y >= glass_gap,
       "baseline is below the glass face: ink_drop is negative or nonsense");
// This name's own ink must fit under the set's shared baseline.
assert(!building || drop <= place_drop + 0.001,
       str("\"", name, "\" drops ", drop, "mm but the set baseline only allows ",
           place_drop, "mm -- set_drop must be the MAX over the whole set"));
assert(abs(sin_a) <= 1,
       str("spring cannot close a ", jaw, "mm jaw over a ", clip_rad,
           "mm bend in ", spring_len, "mm -- lengthen spring_len"));
assert(thick > 0 && spine_w > 0 && txt_size > 0, "degenerate dimensions");
if (!measured)
    echo(str("WARNING: ink_drop not measured for \"", name,
             "\" -- falling back to the font metric (", metric_drop,
             "mm), which is NOT a bound on the ink. Run measure.py."));

// =============================================================================
//  2D -- the whole tag is one flat silhouette
// =============================================================================

// The letters, placed so the baseline is at y = base_y and the ink starts at
// x = txt_x. halign/valign are deliberately NOT used for the vertical: they
// align the font's metric box, which is the thing we do not trust.
module ink() {
    translate([txt_x - ink_x0, base_y])
        offset(r = bold)
            text(name, size = txt_size, font = font, spacing = spacing,
                 halign = "left", valign = "baseline");
}

// morphological close: dilate then erode, to bridge nearby islands
module close2d(c) {
    if (c > 0) offset(r = -c) offset(r = c) children();
    else children();
}

// The bar at the glass face. "rail" only needs it where the clip bears on the
// glass, so it runs back from the hook by clip_bar_len instead of the full
// length -- that is what stops a tail-less name from framing an empty box.
module spine_2d() {
    if (eff_style == "rail") {
        swish_2d();
    } else {
        square([clip_len, bar_w]);
    }
}

// The bar the letters actually sit on. Script letters already join each other
// along the baseline, so a bar there welds every glyph -- including the ones
// with no descender, which is exactly what a bar at the glass face cannot do.
module rail_2d() {
    if (eff_style == "rail" || eff_style == "window") {
        rlen = (eff_style == "rail") ? swish_x0 : clip_len;
        translate([0, base_y + weld - rail_w]) square([rlen, rail_w]);
        if (eff_style == "window")
            for (x = [0, clip_len - spine_w])
                translate([x, 0]) square([spine_w, base_y + weld]);
    }
}

// The flat silhouette of everything except the clip's hook: spine, rail, ink.
// This is the part that lies against the glass, so THIS is what must never
// reach below y=0 -- the clip legitimately wraps around past it.
module body_2d() {
    if (eff_style == "flush")
        // trim the tails at the glass face instead of clearing them over it
        intersection() {
            body_raw();
            translate([-clip_len, 0]) square([4 * clip_len, 20 * txt_size]);
        }
    else
        body_raw();
}

module body_raw() {
    close2d(connect) {
        union() {
            spine_2d();
            rail_2d();
            ink();
            struts_2d();
        }
    }
}

// A capsule across each measured gap -- round-ended so it blends into the
// stroke rather than showing a corner.
module struts_2d() {
    for (s = struts)
        hull() {
            translate([s[0], s[1]]) circle(d = strut_w);
            translate([s[2], s[3]]) circle(d = strut_w);
        }
}

// =============================================================================
//  The clip -- spine, a bend over the rim, and a sprung return arm
// =============================================================================
module clip_2d() {
    // Centreline of the bend: starts at the top, where the swish arrives, and
    // wraps clockwise 180 degrees plus the arm's convergence.
    c   = [clip_len, -jaw_root / 2];
    n   = 48;
    sweep = 180 + spring_ang;
    pts_bend = [for (i = [0:n]) let (t = sweep * i / n)
                    c + bend_rc * [sin(t), cos(t)]];
    // End of the bend, and the direction the arm runs in: back along -x,
    // tilted by spring_ang so the gap closes from jaw_root to jaw.
    pe  = pts_bend[n];
    dir = [-cos(spring_ang), sin(spring_ang)];
    pa  = pe + dir * spring_len;
    // the entry lip flares back out so the rim slides in
    dl  = [-cos(spring_ang - lip_ang), sin(spring_ang - lip_ang)];
    pl  = pa + dl * lip_len;
    path = concat(pts_bend, [pa], lip_len > 0 ? [pl] : []);
    stroke(path, clip_w);
}

// a constant-width stroke through a list of points, round ends
module stroke(pts, w) {
    for (i = [0:len(pts)-2]) hull() {
        translate(pts[i])   circle(d = w);
        translate(pts[i+1]) circle(d = w);
    }
}

// a 2D circular band (rotate_extrude has no 2D form, so sweep it by hand)
module rotate_extrude_2d(ang, r, w) {
    n = max(8, ceil($fn * ang / 360));
    pts_in  = [for (i = [0:n]) let (a = ang * i / n) [r * cos(a), r * sin(a)]];
    pts_out = [for (i = [n:-1:0]) let (a = ang * i / n)
                  [(r + w) * cos(a), (r + w) * sin(a)]];
    polygon(concat(pts_in, pts_out));
}

// =============================================================================
//  Output
// =============================================================================
module tag_2d() {
    union() {
        body_2d();
        clip_2d();
    }
}

module tag() { linear_extrude(thick) tag_2d(); }

if      (render_part == "tag")  tag();
else if (render_part == "body") linear_extrude(thick) body_2d();
else if (render_part == "text") linear_extrude(thick) ink();
// The weld: the ink alone, crossing a thin strip at the bar's top edge. Its
// area divided by the strip height is the total width of material holding the
// name onto the bar -- the number that decides whether a tag snaps at the
// tails. Measured, not argued: see weld.py.
else if (render_part == "weld")
    linear_extrude(thick) intersection() {
        ink();
        translate([-clip_len, weld_y - weld_probe])
            square([4 * clip_len, weld_probe]);
    }
else if (render_part == "clip") linear_extrude(thick) union() { spine_2d(); clip_2d(); }
// The clip with the glass wall drawn in, so the grip can be SEEN rather than
// taken on trust: the rim seats in the curl and the arm closes on it.
else if (render_part == "section") {
    color("SteelBlue") linear_extrude(thick) union() { spine_2d(); clip_2d(); }
    color("LightCyan", 0.65)
        translate([clip_len - 34, -glass_t, thick/2 - 0.6])
            cube([40, glass_t, 1.2]);
}
else if (render_part == "none") ;
else assert(false, str("unknown render_part \"", render_part, "\""));
