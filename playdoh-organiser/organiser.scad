// =============================================================================
//  organiser.scad -- stackable tray organiser for Play-Doh (and similar) pots
// =============================================================================
//  Built entirely out of features the pots already have, adding none of its own.
//
//    1. Every lid has a ~4mm RECESS that the next pot's base nests into. That is
//       how the pots stack, and the tray must not get in its way.
//    2. The body flares out to a LIP at the top, 49.1 over a 45.2 body. That is
//       a downward-facing step on the pot itself -- the thing to hang from.
//
//  Default `hang` cells use both. Each cell is a 45.8 hole: it clears the body,
//  and the LIP catches on it. So every pot hangs by its own lip and a loaded tray
//  can be picked straight up -- while the pot still nests 4mm into the lid below
//  at exactly the same height, so the tray costs NO extra height at all.
//
//           | lid |            lid entirely clear, ~3mm above the plate
//     .-----'     '-----.
//     |                 |   <- pot, base nested 4mm into the lid below
//     '---.         .---'      lip flares 45.2 -> 49.1
//    ======[       ]======  <- plate: body passes, LIP lands on top
//          |       |            1.65mm of ledge, all the way round
//
//  Deliberately NOT the lid: a lid is soft press-on plastic that 85g would work
//  loose over time, and a lidless pot would drop straight through.
//  (`nest` = spacer only, no retention. `cup` = collar cradles the base.)
//
//  LEGS (`stack_style`)
//    Four corner legs reach DOWN to the tray below, or to the table, so an empty
//    tray stands up on its own and can be loaded on a worktop. A leg is not a
//    post bolted to the corner -- it IS the corner, hollowed out: bounded by the
//    deck's own edge outside and the corner cell's ring inside, so it fills space
//    that was dead anyway and never stands proud of the tray outline.
//    `pots` drops them entirely (lightest, but only stands up once full);
//    `rails` and `walls` fill in between them.
//
//  THERE IS ONLY ONE PART. Print one tray per layer of pots. Every tray is
//  identical -- no base, no lid, no cap, and no special case at either end.
//
//  PRINT (single colour, supports OFF)
//    Plate down, legs standing up -- nothing to bridge, nothing to support.
//    TURN IT OVER TO USE IT: in use the plate is at the top of its layer, just
//    under the lips, and the legs reach down. The plate is symmetric, so the
//    only thing the flip changes is which way the legs point.
//
//  Pure OpenSCAD (no libraries). Annotated for the MakerWorld customizer.
// =============================================================================

/* [Layout] */
// How many pots across, left to right
cols = 3;             // [1:1:8]
// How many pots deep, front to back
rows = 2;             // [1:1:8]

/* [Pot size] */
// Which pots this is for. Every other size is worked out from the pot itself --
// cell spacing, hole diameter, layer height -- so this is usually the only thing
// to set besides the layout. Choose Custom to enter your own measurements under
// "Advanced - Pot dimensions".
pot_preset = "playdoh"; // [playdoh:Play-Doh pot - 51mm lid, 57mm tall, custom:Custom - measure your own]

/* [Options] */
// How each pot is held. Hang is the only one that RETAINS pots, so you can pick
// a loaded tray straight up: the hole clears the pot's body and its lip catches
// on it. The other two are spacers -- useful if your pots have no usable lip.
cell_style = "hang";  // [hang:Hang - pots hang by their lip (holds them in), nest:Nest - spacer only, cup:Cup - collar under each pot]
// What holds a tray at its height. Legs let an empty tray stand on its own, so
// you can put it on the worktop and load it.
stack_style = "posts"; // [posts:Corner legs (recommended), pots:None - the pots carry it, rails:End walls - bookend, walls:Full walls + front scoop]
// Open leaves out the plate between the rings. Saves material and looks better.
deck_style = "open";  // [open:Open - frame and rings, solid:Solid plate]

/* [Advanced - Pot dimensions] */
// These are used only when Pot size is set to Custom. The defaults are a real
// Play-Doh pot, measured with calipers -- start from them and adjust.
// Total height, lid on, bottom to top of lid (mm)
custom_pot_h = 57.1;       // [20:0.1:140]
// Diameter of the flat bottom (mm)
custom_base_d = 38.6;      // [15:0.1:120]
// Diameter where the taper stops, at the base of the lip (mm)
custom_shoulder_d = 45.2;  // [15:0.1:130]
// Diameter of the lip at the top of the body -- this is what the pot hangs on,
// so it and the one above matter more than the rest (mm)
custom_lip_d = 49.1;       // [15:0.1:135]
// Diameter over the lid: the widest point, which sets the cell spacing (mm)
custom_lid_d = 51.2;       // [15:0.1:140]
// Height of the lid itself (mm)
custom_lid_h = 7;          // [2:0.1:25]
// Height of the lip -- how far down the body flares out to the lip diameter.
// Only shifts how far up the pot the tray sits, so a rough figure is fine (mm)
custom_lip_h = 4;          // [1:0.1:15]
// Depth of the recess in the lid's top: how the pots stack on each other (mm)
custom_recess_h = 4;       // [1:0.1:15]
// Diameter of that recess (mm)
custom_recess_d = 38.6;    // [15:0.1:120]

/* [Advanced - Tray] */
// Gap between neighbouring pots, measured at their widest (the lid) (mm)
pot_gap = 4;          // [1:0.5:15]
// Tray material outside the outermost pots (mm)
edge = 3;             // [0:0.5:15]
// Plate thickness (mm)
deck_t = 2.4;         // [1.2:0.2:6]
// Hole through the middle of each cell, for the nest and cup styles (mm)
open_d = 32;          // [0:1:40]
// Extra headroom per layer. Leave at 0 to keep a tower no taller than a bare
// stack of pots. Ignored with Nest cells, where the pots set the pitch
// themselves and any extra would make the trays drift off them every layer. (mm)
head_clear = 0;       // [0:0.5:16]
// Nest cells only: the bottom tray's pots stand on the table instead of dropping
// into a lid, so its legs need to be longer. Print ONE tray with this ticked.
bottom_tray = false;

/* [Advanced - Legs] */
// How far each corner leg wraps around its pot, in degrees. Wider is stiffer and
// heavier; 90 would run from one edge of the tray to the other. It cannot foul a
// pot at any setting -- the outline is cut against the pot's ring.
leg_sweep = 60;       // [20:2:90]
// Leg wall thickness. A leg only ever carries about 4N, so this is set by what
// prints cleanly -- 1.2mm is exactly three perimeters on a 0.4mm nozzle. (mm)
leg_t = 1.2;          // [1.2:0.2:5]
// How far the leg runs into the rings, so its wall sits ON one rather than
// alongside it. Below one wall thickness the corner looks fat on the ring side.
leg_overlap = 1.2;    // [0:0.2:6]
// Legs between the cells, where four of them meet. Without these a loaded tray
// bows: the corner legs stiffen only the ends, whereas one of these is a deep rib
// right where the plate sags, and it carries the tray above at mid-span too.
// There are (pots across - 1) x (pots deep - 1) of them.
inner_legs = true;
// How far an inner leg reaches before the surrounding pots cut into it. Past
// ~12.6mm on the default pot they do, and it stops being a circle and becomes
// the four-lobed diamond that actually fills the gap -- which is the point, as
// that is what bonds it to the rings along a real length of arc rather than at
// four tangent points. (mm)
inner_r = 16;         // [6:0.5:26]
// Radius of the spike an inner leg tapers down to. The leg is fat where it meets
// the rings and thin where it plugs in: it is a rib first and an interlock
// second, so there is no reason for the plug to be anything like as wide. (mm)
inner_plug_r = 4;     // [1.5:0.5:12]
// Straight length on the end of each leg. It passes through the plate below and
// into that tray's own leg, so stacked trays slot together and can't slide. The
// bottom tray stands on these, which is why it sits a little proud. Only (this
// minus the plate thickness) engages the leg below, so there is little point
// going long -- 6mm still gives about 9mm of engagement once the taper above the
// seat is counted. (mm)
leg_plug = 6;         // [0:0.5:25]
// What the leg seats on. There is no shoulder -- the leg tapers the whole way --
// so it slides down until its taper matches the hole below. The taper is very
// shallow, so a little here buys a lot of travel and a longer leg. Raise it if
// your printer runs off-size. (mm)
leg_seat = 0.15;      // [0.05:0.05:1]
// Narrowest the leg is allowed to get where it runs into a ring, so it tapers to
// a point rather than stopping square. Keep near one extrusion width. (mm)
leg_min = 0.8;        // [0.4:0.1:4]
// Wall / rail thickness, for the Rails and Walls styles (mm)
wall_t = 2.4;         // [1.2:0.2:6]
// Height of the front scoop, as a fraction of the wall height
scoop_frac = 0.72;    // [0:0.02:1]

/* [Advanced - Fit] */
// Clearance between a pot and its hole, on the diameter. Bigger is looser (mm)
pot_clear = 0.6;      // [0:0.1:2]
// Clearance of a leg's plug in the leg it drops into, on the diameter (mm)
leg_fit = 0.35;       // [0.1:0.05:1]
// Cup cells only: clearance of the underside cone in the lid recess (mm)
recess_clear = 1.0;   // [0:0.1:3]

/* [Advanced - Cup cells] */
// Height of the collar around each pot (mm)
cup_h = 8;            // [2:0.5:30]
// Collar wall thickness (mm)
cup_t = 1.8;          // [1.2:0.2:5]
// Notches front and back of each collar, to get a finger to the pot
cup_notch = true;
// Notch width (mm)
cup_notch_w = 18;     // [5:1:40]

/* [Hidden] */
// Which part to render. Hidden from the MakerWorld customizer on purpose: there
// the plate comes from mw_plate_1() and the preview from mw_assembly_view(), and
// leaving this on show would let someone put a *preview* on the build plate.
// Still settable from the command line -- it is what the Makefile drives.
//   tray | stack | slice | section | pot
render_part = "tray";

$fa = 2;
$fs = 0.5;
eps = 0.01;
// Slices used to taper a corner leg (see leg_loft -- hull() cannot be used)
leg_steps = 32;

// --- pot presets --------------------------------------------------------------
// Order: total height, base dia, dia at the base of the lip, lip dia, dia over
// the lid, lid height, lip height, lid recess depth, recess dia.
// `playdoh` is a real pot measured with calipers, except lip height (estimated)
// and recess dia (assumed equal to the base, since that is what pots nest on).
// Adding a preset means measuring a pot and adding a row here plus an entry in
// the pot_preset dropdown -- deliberately not guessed at for sizes nobody has
// put a caliper on.
POT_PLAYDOH = [57.1, 38.6, 45.2, 49.1, 51.2, 7, 4, 4, 38.6];

POT = pot_preset == "custom"
    ? [custom_pot_h, custom_base_d, custom_shoulder_d, custom_lip_d, custom_lid_d,
       custom_lid_h, custom_lip_h, custom_recess_h, custom_recess_d]
    : POT_PLAYDOH;

// Note for anyone driving this from the command line: these are now DERIVED, so
// `-D pot_h=60` no longer does anything. Use -D pot_preset=\"custom\" together
// with -D custom_pot_h=60.
pot_h          = POT[0];
pot_base_d     = POT[1];
pot_shoulder_d = POT[2];
pot_lip_d      = POT[3];
pot_lid_d      = POT[4];
lid_h          = POT[5];
lip_h          = POT[6];
lid_recess_h   = POT[7];
lid_recess_d   = POT[8];
// Thickness of the `slice` preview cross-section (mm)
slice_t = 9;

// --- derived: the pot ---------------------------------------------------------
// Bottom to top: a cone from pot_base_d up to pot_shoulder_d (the base of the
// lip), then the lip flaring out to pot_lip_d, then the lid over the top of it.
body_h = pot_h - lid_h;                             // 50.1: where the lid starts
cone_h = body_h - lip_h;                            // 46.1: where the lip starts
// Radial taper of the pot body, mm of radius per mm of height.
taper  = (pot_shoulder_d - pot_base_d) / 2 / cone_h;
// Body diameter h above the pot's base (valid up the cone, h <= cone_h).
function pot_d(h) = pot_base_d + 2 * taper * h;

// --- derived: the grid --------------------------------------------------------
// Cell pitch is set by the widest part of the pot, the lid.
cell   = pot_lid_d + pot_gap;
deck_w = cols * cell + 2 * edge;
deck_d = rows * cell + 2 * edge;
deck_r = 4;                                         // deck corner radius

hang       = (cell_style == "hang");
nest       = (cell_style == "nest");
// Clamped so a small custom pot can't produce a cell with no ledge, or a collar
// taller than the pot it holds.
open_bore  = min(open_d, pot_base_d - 3);
cup_z      = min(cup_h, pot_h - lid_h - 5);
cupd       = (cell_style == "cup");
uses_posts = (stack_style != "pots");

// --- derived: heights ---------------------------------------------------------
// The underside frusta drop into the lid recesses. They must never bottom out,
// or the plate stops bearing on the lid rim and the stack grows every layer.
frustum_h = min(3.2, lid_recess_h - 0.8);
// `hang` and `nest` trays are bare plates -- no underside at all. Only a `cup`
// tray stands off on frusta.
tray_fh   = cupd ? frustum_h : 0;
foot_w    = 4;                                      // perimeter rim width
rib_w     = 3;                                      // rib width

// Layer pitch, pot base to pot base.
//   hang/nest: the pot above nests into the lid below exactly as it would with
//              no tray present, so the pitch is the pots' own -- costs nothing.
//   cup:       the plate sits on the lid rim, the pot above sits on the plate.
// Nest cells ignore head_clear: there the pot is located by the pot BELOW while
// the plate is located by the legs, so any gap between them compounds every
// layer until the cells bind on the pots. Hang cells are immune -- each pot
// hangs from its own plate -- so there the extra simply spaces the layers out.
head_gap = (nest && uses_posts) ? 0 : head_clear;
pitch = (cupd ? pot_h + deck_t : pot_h - lid_recess_h) + (uses_posts ? head_gap : 0);

// The leg is ONE unbroken taper from its full section at the plate down to the
// plug's, then straight for the last leg_plug. No shoulder, no blend, no zone
// that tapers faster than another -- so there is nothing to read as an edge.
// The plate's hole is leg_seat smaller than the plug, and the leg seats where
// its taper has grown back to that. That fraction of the taper ends up BELOW the
// seat, so the taper has to be longer than the gap it spans by exactly that.
leg_hole   = leg_t + leg_fit - leg_seat;
leg_seat_f = leg_seat / (leg_t + leg_fit);

// Post length, measured from the plate's top face up to the next plate's lowest
// face. Getting this wrong by the foot height makes posts foul the corner pads
// of the tray above and grows the stack every layer.
// The bottom tray is the one exception: with `nest` cells its pots stand on the
// table instead of dropping into a lid, so they sit lid_recess_h higher.
// ...less the sliver of blend that sits ABOVE the seat, since the leg's taper
// section stops there rather than at the seat itself.
tray_ph = (pitch - tray_fh - deck_t) / (1 - leg_seat_f)
        + ((bottom_tray && nest) ? lid_recess_h : 0);
// Inner legs taper on a CONE rather than by offsetting the outline, so they can
// go from the full diamond at the plate to a small spike without hull()
// convexifying them on the way. Height chosen so an inner leg seats at the same
// depth as a corner one -- otherwise only one of the two would ever bear.
inner_cone_h = (pitch - tray_fh - deck_t)
             / (1 - leg_fit / max(0.5, inner_r - inner_plug_r));

// Where the leg seats, measured up from the start of the plug...
leg_seat_z = tray_ph * leg_seat_f;
// ...and so how far it hangs below that. The bottom tray stands on this.
leg_below = leg_seat_z + leg_plug;

// Direction from the corner cell out to the deck corner, and how far along the
// deck edge the leg's sector ends up reaching -- the rail and wall cutouts need
// to clear that.
leg_a     = atan2(deck_d / 2 - cy(rows - 1), deck_w / 2 - cx(cols - 1));
leg_end_a = leg_a + leg_sweep / 2;
leg_reach = deck_w / 2 - cx(cols - 1)
          - (deck_d / 2 - cy(rows - 1)) * cos(leg_end_a) / sin(leg_end_a);

// `hang` cell: a straight hole sized to just clear the BODY, so it slides up
// past the pot until the LIP catches on it. Every pot hangs by its own lip and a
// loaded tray can be picked up. The pot still nests into the lid below at the
// same height, so the two supports sit in parallel and the pitch is unchanged.
//
// Deliberately NOT the lid: a lid is soft press-on plastic, and hanging the pot
// off it indefinitely would work it loose. The lip is part of the pot, gives
// more than twice the ledge, leaves a much stiffer plate, and lets a pot stay
// put with its lid off.
// (Defined before pot_z0, which uses it -- OpenSCAD hoists functions but NOT
// variables, so a forward reference here silently evaluates to undef.)
hang_d     = pot_shoulder_d + pot_clear;
hang_ledge = (pot_lip_d - hang_d) / 2;
// Where up the pot the plate ends up: the point on the lip flare that has grown
// to hang_d. Depends on the estimated lip_h, but only cosmetically -- the layer
// pitch comes from the pots nesting, not from where the plate grips.
hang_seat  = cone_h + lip_h * (hang_d - pot_shoulder_d)
                            / max(0.01, pot_lip_d - pot_shoulder_d);
hang_z     = hang_seat - deck_t;

// Height of the first layer's pot base above the tower's floor.
//   cup:         the pot sits in a collar on the deck.
//   hang + legs: the bottom tray stands on its legs, so the pots hang clear of
//                the table -- and every layer then behaves identically.
//   otherwise:   the pot goes straight through to the table.
pot_z0 = cupd ? tray_fh + deck_t
       : (hang && uses_posts) ? pitch - deck_t - hang_z + leg_below
       : 0;


// Diagonal deck brace: corner cell centre -> deck corner.
brace_dx = deck_w / 2 - cx(cols - 1);
brace_dy = deck_d / 2 - cy(rows - 1);
brace_l  = sqrt(brace_dx * brace_dx + brace_dy * brace_dy);
brace_a  = atan2(brace_dy, brace_dx);

// A `nest` cell is a hole the pot passes through on its way to the recess below.
// It follows the pot's taper, so clearance is the same at the top and bottom.
nest_d1 = pot_d(lid_recess_h) + pot_clear;
nest_d2 = pot_d(lid_recess_h + deck_t) + pot_clear;

// These three are clamped rather than asserted: this file is published as a
// MakerWorld customizer, where an assert reads as a broken model rather than as
// a hint. Anything that merely needs bounding gets bounded; the asserts below
// are kept only for combinations that cannot produce a working part at all.
assert(!cupd || frustum_h > 0.8,
       "the lid recess is too shallow for Cup cells to locate in -- use Hang or Nest");
// The hole must clear the recess mouth, or the plate fouls the pot dropping in.
assert(!nest || nest_d1 > lid_recess_d,
       "nest hole narrower than the lid recess -- the pot can't drop through");
// ...and still leave a rim of lid to bear on.
assert(!nest || nest_d2 < pot_lid_d - 3,
       "nest hole leaves too little lid rim to bear on -- check pot_lid_d");
// With `nest` cells the POTS fix the layer pitch (they nest into each other), so
// posts holding the plates any further apart makes plate and pot drift by
// head_clear EVERY layer until the cell holes bind on the pots. Harmless with
// `cup`, where the pot sits on the plate and the plate sets the pitch.
// `hang` lives in the step between the base of the lip and the lip itself.
assert(!hang || pot_lip_d > pot_shoulder_d + 1.0,
       "the lip barely stands proud of the body, so there is nothing for a pot to hang on: check pot_shoulder_d and pot_lip_d");
assert(!hang || hang_d < pot_lip_d - 1.0,
       "no ledge left under the lip for the pots to hang on -- pot_clear is too big for the step between pot_shoulder_d and pot_lip_d");
// The plate has to sit clear of the lid skirt, or it fouls the lid instead.
assert(!hang || hang_seat < body_h - 0.5,
       "the plate would seat at or above the lid skirt -- check lip_h");
assert(!hang || hang_d + 3 < cell,
       "hang holes leave too thin a web between cells -- raise pot_gap");


// Cell centres.
function cx(i) = (i - (cols - 1) / 2) * cell;
function cy(j) = (j - (rows - 1) / 2) * cell;

// Preview cuts are taken through the centre of the rear row of cells -- with an
// even number of rows, y = 0 falls in the gap between them and a cut there
// misses every pot, showing an unbroken plate and an apparently solid lid.
cut_y = cy(rows - 1);
clip  = render_part == "slice" ? "slice"
      : render_part == "section" ? "half" : "none";

// The region a preview cut keeps.
module clip_solid() {
    translate([-deck_w, cut_y, -10])
        cube([deck_w * 2, clip == "slice" ? slice_t : deck_d * 2, pitch * 10]);
}

// Clip children to that region. MUST be called at the top level, where the
// coordinates are global -- called inside at_cells() the clip solid gets that
// cell's translate applied to it too, and wanders off the model.
// It also has to sit INSIDE the colour and OUTSIDE the geometry: a CGAL boolean
// gives its cut faces the default colour, so `color(c) clipped() geom` keeps a
// cross-section coloured where `clipped() color(c) geom` renders it flat teal.
module clipped() {
    if (clip == "none") children();
    else intersection() { children(); clip_solid(); }
}

module at_cells() {
    for (i = [0:cols-1], j = [0:rows-1]) translate([cx(i), cy(j), 0]) children();
}
module at_corners() {
    for (sx = [1, -1], sy = [1, -1]) scale([sx, sy, 1]) children();
}
module rrect(w, d, r, h) {
    linear_extrude(h) rrect_2d(w, d, r);
}
module rrect_2d(w, d, r) {
    offset(r = r) offset(r = -r) square([w, d], center = true);
}

// =============================================================================
//  Corner leg
// =============================================================================
// Outline of the +X+Y corner leg, in deck coordinates. Bounded by the deck's own
// edge on the outside and the corner cell's ring on the inside -- so it occupies
// the wedge of deck that was dead space anyway, is flush with the tray outline
// rather than bolted onto it, and gets a far wider footprint than a post could.
// The sector the leg occupies, apex on the corner cell's centre.
module leg_wedge() {
    rr = deck_w;                                     // any radius past the deck
    polygon(concat([[0, 0]],
        [for (i = [0 : 24])
            let (t = leg_a - leg_sweep / 2 + i * leg_sweep / 24)
                [rr * cos(t), rr * sin(t)]]));
}

module leg_outline() {
    // ...then a morphological OPENING, which erases anything narrower than
    // leg_min and rounds off what is left. Opening at a whole wall thickness
    // chops the tapering ends square and leaves a notch where the leg should run
    // into the ring, so it is deliberately opened at a hair over one extrusion
    // width instead: enough to kill true slivers, little enough that the leg
    // still comes to a point. Where the outline is thinner than two walls,
    // leg_section() simply leaves it solid.
    offset(r = leg_min / 2) offset(r = -leg_min / 2)
    difference() {
        intersection() {
            rrect_2d(deck_w, deck_d, deck_r);
            // A sector of the corner cell, centred on the direction of the deck
            // corner. Its two ends are radial cuts across the ring, so the leg
            // meets the ring squarely and hugs it the whole way between them.
            translate([cx(cols - 1), cy(rows - 1)]) leg_wedge();
        }
        // Every ring, not just the corner one, so the leg simply follows
        // whatever cells it runs up against and wraps around them.
        at_cells() circle(d = cell - 2 * leg_overlap);
    }
}
// A lofted slice of the leg: `h` tall, its profile inset `i0` at the bottom and
// `i1` at the top. Everything -- taper, blend, plug and the bore of all three --
// is built from these, which is what keeps the wall thickness constant.
// Tapers the outline from inset i0 to i1 over height h, as a stack of thin
// prisms rather than a hull() between two profiles.
//
// It HAS to be done this way. hull() returns a CONVEX hull, and this outline is
// concave -- it is cut against the pot ring. A hulled leg therefore came out as
// a triangular tube with a straight chord where the ring's arc should be, while
// the hole it plugs into is punched from the outline directly and kept the arc.
// The plug was filled in across exactly the curve the hole followed, so two
// trays could not go together at all. Found on a print.
//
// Each step is offset by the value at its mid-height, so the staircase
// straddles the true cone. At the default 1.55mm of taper over ~56mm and 32
// steps that is a 0.05mm ridge every 1.75mm -- far under a layer line.
module leg_loft(h, i0, i1) {
    for (k = [0 : leg_steps - 1])
        translate([0, 0, k * h / leg_steps])
            linear_extrude(h / leg_steps + eps)
                offset(r = -(i0 + (i1 - i0) * (k + 0.5) / leg_steps)) children();
}

// The whole leg as one profile chain, `extra` further inset (0 for the outside,
// leg_t for the bore). Bottom to top: a full-length gentle taper, a short 45deg
// blend, then the straight plug.
//   ph            gradual taper, full section -> leg_seat short of the hole below
//   leg_blend     45deg, on to the plug's section. Under a mm: no visible step.
//   leg_plug      straight, so there is real length engaging the leg below
module leg_stack(ph, extra, tail) {
    t2 = extra + leg_t + leg_fit;                    // the plug's section
    leg_loft(ph, extra, t2) children();              // one taper, the whole way
    translate([0, 0, ph - eps])                      // then straight
        leg_loft(leg_plug + tail + eps, t2, t2) children();
}
// Hollowed to a constant-thickness closed shell -- far stiffer than a small
// square tube for the same material, and it wastes nothing on a solid core.
module leg_section() {
    difference() { children(); offset(r = -leg_hole) children(); }
}
// The hollow down the middle of that shell.
module leg_bore_2d() { offset(r = -leg_t) leg_outline(); }
// The hole punched through the plate: the leg above seats on its rim, and its
// plug passes through into the leg below.
module leg_hole_2d() { offset(r = -leg_hole) children(); }

// Interior legs. Between every four cells the deck has a diamond of dead space
// that nothing else uses, and a leg there is what stops a loaded tray bowing:
// the corner legs only stiffen the ends, whereas a 56mm-deep column bonded to
// the middle of the plate acts as a very deep rib exactly where it sags. It also
// carries the tray above at mid-span rather than only at its corners.
// Shaped by the four rings around it, so it fills the gap and bonds to each of
// them along an arc instead of touching at a point.
module inner_outline() {
    offset(r = leg_min / 2) offset(r = -leg_min / 2)
    difference() {
        circle(r = inner_r);
        for (sx = [-1, 1], sy = [-1, 1])
            translate([sx * cell / 2, sy * cell / 2])
                circle(d = cell - 2 * leg_overlap);
    }
}
// One inner leg as a solid, `in` shrunk -- 0 for the outside, leg_t for the bore,
// which is what keeps the wall an even thickness.
module inner_solid(in) {
    h = inner_cone_h;
    tail = (in > 0) ? 2 : 0;                         // bore runs past the tip
    intersection() {
        linear_extrude(h + 2 * eps) offset(r = -in) inner_outline();
        cylinder(h = h + 2 * eps, r1 = inner_r - in, r2 = inner_plug_r - in);
    }
    translate([0, 0, h - eps])
        cylinder(h = leg_plug + tail + eps, r = inner_plug_r - in);
}

// The (cols-1) x (rows-1) points where four cells meet.
module at_inner() {
    if (inner_legs && cols > 1 && rows > 1)
        for (i = [0:cols-2], j = [0:rows-2])
            translate([cx(i) + cell / 2, cy(j) + cell / 2, 0]) children();
}


// =============================================================================
//  Reference pot -- previews only
// =============================================================================
// Split into body and lid so the tower can colour and clip each in one go.
module pot_body() {
    cylinder(h = cone_h, d1 = pot_base_d, d2 = pot_shoulder_d);
    translate([0, 0, cone_h])                        // lip, under the lid skirt
        cylinder(h = lip_h, d1 = pot_shoulder_d, d2 = pot_lip_d);
}
// Lid, with the stacking recess in its top. Deliberately pale in the previews so
// that a pot nested down into the recess reads clearly.
module pot_lid() translate([0, 0, body_h]) difference() {
    cylinder(h = lid_h, d = pot_lid_d);
    translate([0, 0, lid_h - lid_recess_h + eps])
        cylinder(h = lid_recess_h, d = lid_recess_d);
}
module pot() {
    color("#e8543f") pot_body();
    color("#ffe9a8") pot_lid();
}

// =============================================================================
//  Plate features -- each is modelled from z = 0 and positioned by plate()
// =============================================================================

// Underside standoff: perimeter rim + corner pads + a 45deg frustum per cell +
// ribs. Everything starts on the build plate and the frusta flare at 45deg, so
// none of it is an overhang.
module underside(fh) {
    difference() {                                   // perimeter rim
        rrect(deck_w, deck_d, deck_r, fh);
        translate([0, 0, -eps])
            rrect(deck_w - 2 * foot_w, deck_d - 2 * foot_w,
                  max(0.1, deck_r - foot_w), fh + 2 * eps);
    }
    if (uses_posts) {
        at_corners() linear_extrude(fh) leg_section() leg_outline();
        at_inner()   linear_extrude(fh) inner_outline();
    }
    at_cells() cylinder(h = fh, d1 = lid_recess_d - recess_clear,
                        d2 = lid_recess_d - recess_clear + 2 * fh);
    for (i = [0:cols-1])                             // ribs, rim <-> frusta
        translate([cx(i), 0, fh / 2]) cube([rib_w, deck_d, fh], center = true);
    for (j = [0:rows-1])
        translate([0, cy(j), fh / 2]) cube([deck_w, rib_w, fh], center = true);
}

// The plate itself.
module deck() {
    if (deck_style == "solid") {
        rrect(deck_w, deck_d, deck_r, deck_t);
    } else {
        // open: a perimeter frame, a ring per cell, and ribs joining them. The
        // rings must reach pot_lid_d -- that lid rim is what the plate sits on.
        difference() {
            rrect(deck_w, deck_d, deck_r, deck_t);
            translate([0, 0, -eps])
                rrect(deck_w - 2 * foot_w, deck_d - 2 * foot_w,
                      max(0.1, deck_r - foot_w), deck_t + 2 * eps);
        }
        at_cells() cylinder(h = deck_t, d = cell);
        if (uses_posts) {
            at_corners() linear_extrude(deck_t) leg_section() leg_outline();
            at_inner()   linear_extrude(deck_t) inner_outline();
        }
        for (i = [0:cols-1])
            translate([cx(i), 0, deck_t / 2]) cube([rib_w, deck_d, deck_t], center = true);
        for (j = [0:rows-1])
            translate([0, cy(j), deck_t / 2]) cube([deck_w, rib_w, deck_t], center = true);
        // Corner braces -- only where there is no leg, which stiffens the
        // corner far more and would just chop them up anyway.
        if (!uses_posts) for (sx = [-1, 1], sy = [-1, 1])
            translate([sx * (cx(cols-1) + deck_w / 2) / 2,
                       sy * (cy(rows-1) + deck_d / 2) / 2, deck_t / 2])
                rotate([0, 0, sx * sy * brace_a])
                    cube([brace_l, rib_w, deck_t], center = true);
    }
}

// Tapered collar around each cell, matching the pot's own taper. Only used where
// there is no pot below to do the job: `cup` cells, and the base plate.
module collars() at_cells() difference() {
    union() {
        cylinder(h = cup_z, d1 = pot_base_d + pot_clear + 2 * cup_t,
                 d2 = pot_d(cup_z) + pot_clear + 2 * cup_t);
        translate([0, 0, cup_z - eps])               // lead-in flare at the mouth
            cylinder(h = 1.2, d1 = pot_d(cup_z) + pot_clear + 2 * cup_t,
                     d2 = pot_d(cup_z) + pot_clear + 2 * cup_t + 2.4);
    }
    translate([0, 0, -eps])                          // the pot-shaped void
        cylinder(h = cup_z + 2, d1 = pot_base_d + pot_clear,
                 d2 = pot_d(cup_z + 2) + pot_clear);
    if (cup_notch)                                   // finger notches
        for (s = [-1, 1])
            translate([0, s * cell / 2, cup_z / 2 + 1.5])
                cube([cup_notch_w, cell, cup_z], center = true);
}

// Front scoop profile, in the XZ plane, measured from the plate's top face.
module scoop_2d(ph) {
    sw = deck_w - 2 * (leg_reach + 2);
    sh = ph * scoop_frac;
    z0 = ph - sh;
    r  = min(sw / 2, sh / 2, 14);
    hull() for (s = [-1, 1]) translate([s * (sw / 2 - r), z0 + r]) circle(r = r);
    translate([-sw / 2, z0 + r]) square([sw, sh]);
}

// Corner posts (+ pegs), and the rails / walls that span between them.
module vertical(ph) {
    // No locating peg anywhere: the pots already tie every tray to its
    // neighbours (they thread through the plate and nest into the lid below),
    // and a peg on a leg's foot would leave the bottom tray rocking on studs
    // instead of standing flat.
    at_corners() {
        // The free end is the FOOT once the tray is turned over. It tapers the
        // whole way down and plugs through the plate below into that tray's leg.
        // Printable as-is: the section only ever shrinks going up.
        difference() {
            leg_stack(ph, 0, 0) leg_outline();
            translate([0, 0, -eps]) leg_stack(ph + eps, leg_t, 2) leg_outline();
        }
    }
    // Inner legs: the full diamond where they meet the deck, coned down hard to
    // a small spike that plugs into the tray below. Built as prism INTERSECT
    // cone rather than a hull() loft -- a hull would convex-fill the diamond's
    // concave sides and swallow the pots.
    at_inner() difference() {
        inner_solid(0);
        translate([0, 0, -eps]) inner_solid(leg_t);
    }
    if (stack_style == "rails" || stack_style == "walls") {
        difference() {
            rrect(deck_w, deck_d, deck_r, ph);
            translate([0, 0, -eps])
                rrect(deck_w - 2 * wall_t, deck_d - 2 * wall_t,
                      max(0.1, deck_r - wall_t), ph + 2 * eps);
            if (stack_style == "rails")              // keep only the end walls
                translate([0, 0, ph / 2])
                    cube([deck_w - 2 * (leg_reach + 2), deck_d + 2, ph + 2], center = true);
            if (stack_style == "walls")              // scoop the front, open at the
                translate([0, -deck_d / 2 + wall_t * 2, 0])   // top so nothing arches
                    rotate([90, 0, 0]) linear_extrude(wall_t * 4) scoop_2d(ph);
        }
    }
}

// =============================================================================
//  The three printable parts
// =============================================================================
//  fh         underside frustum height (0 = a bare plate)
//  cups       collars on top
//  ph         post length, or 0 for no vertical structure
//  nest_cells cell holes sized for a pot to drop through to the lid below
module plate(fh, cups, ph, cells) difference() {
    union() {
        if (fh > 0) underside(fh);
        translate([0, 0, fh]) deck();
        if (cups) translate([0, 0, fh + deck_t]) collars();
        if (ph > 0 && uses_posts)
            translate([0, 0, fh + deck_t]) vertical(ph);
    }
    // cell holes
    if (cells == "hang")
        // straight: the lip passes, the lid rim lands on top
        at_cells() translate([0, 0, -1]) cylinder(h = deck_t + 2, d = hang_d);
    else if (cells == "nest")
        // follows the pot's taper, so clearance is even top and bottom
        at_cells() translate([0, 0, fh - 1])
            cylinder(h = deck_t + 2, d1 = pot_d(lid_recess_h - 1) + pot_clear,
                     d2 = pot_d(lid_recess_h + deck_t + 1) + pot_clear);
    else
        at_cells() translate([0, 0, -1]) cylinder(h = fh + deck_t + 2, d = open_bore);
    // Punch each leg's bore through the plate, so the spigot of the tray above
    // can pass through it. Also trims the frame and the corner brace back to the
    // leg wall, which the leg itself more than makes up for.
    if (uses_posts && leg_plug > 0)
        at_corners() translate([0, 0, -1])
            linear_extrude(fh + deck_t + 2) leg_hole_2d() leg_outline();
        // Only a spike-sized hole, so the plug from above actually locates in it
        at_inner() translate([0, 0, -1])
            cylinder(h = fh + deck_t + 2, r = inner_plug_r + leg_fit);
}

// The only part. One per layer of pots.
module tray() plate(fh = tray_fh, cups = cupd, ph = tray_ph, cells = cell_style);

// =============================================================================
//  Previews
// =============================================================================
// A tower is: base (its collars seat the first layer) + N trays + a top cap.
// With `nest` cells every tray hangs on the lid rims and the pots nest straight
// through it, so the trays cost no height at all.
// One tray per layer -- the bottom one just lies on the table -- plus an optional
// cap, which is simply another tray laid on the top lids.
module tower(layers = 3, cap = true) {
    zs = [for (k = [0:layers-1]) pot_z0 + k * pitch];   // pot base heights
    // Each colour is clipped once, here at the top level, in global coordinates.
    color("#e8543f") clipped()
        for (z = zs) translate([0, 0, z]) at_cells() pot_body();
    color("#ffe9a8") clipped()
        for (z = zs) translate([0, 0, z]) at_cells() pot_lid();
    color("#2f8f96") clipped() {
        if (hang)
            // One plate per layer, each caught under that layer's own lips.
            // Referenced to its own pots rather than to the layer below, so every
            // plate is identical -- no bottom-tray special case, and no cap.
            // Used FLIPPED relative to how it prints: it prints plate-down with
            // the legs standing up (nothing to bridge), and is turned over in use
            // so the plate is at the top of its layer and the legs reach down.
            for (z = zs)
                translate([0, 0, z + hang_seat]) rotate([0, 180, 0]) tray();
        else {
            tray();                                    // bottom, on the table
            for (k = [0:layers-1])                     // and one on each layer's lids
                if (k < layers - 1 || cap)
                    translate([0, 0, zs[k] + pot_h - tray_fh]) tray();
        }
    }
}

// =============================================================================
//  MakerWorld Parametric Model Maker entry points
// =============================================================================
//  PMM builds its 3MF from `mw_plate_N()` modules and uses `mw_assembly_view()`
//  for the on-screen preview only -- the assembly is explicitly NOT included in
//  the exported 3MF. Defining both means a customizer user gets the tray on the
//  plate and the loaded tower as a preview, and cannot accidentally export a
//  preview as though it were a part.
//
//  These sit alongside the `render_part` dispatch below, which is what the
//  Makefile drives locally. Sourced from community documentation of PMM rather
//  than an official spec, so check the plate in MakerLab's own preview before
//  publishing rather than trusting it.
// =============================================================================
module mw_plate_1()       { tray(); }
module mw_assembly_view() { tower(3); }

// =============================================================================
//  Dispatch
// =============================================================================
if (render_part == "tray")        tray();
else if (render_part == "pot")    pot();
else if (render_part == "stack")  tower(3);
// `section` keeps everything behind the cut plane; `slice` keeps only a thin
// cross-section. Prefer `slice` for reading a joint: a half-cut viewed straight
// on still shows what is BEHIND it, so a cell hole reads as solid (you are
// looking at the far side of the ring) and a lid recess reads as full. Both are
// applied per object inside clipped(), so the cut faces keep their colours.
else if (render_part == "section" || render_part == "slice") tower(3);
