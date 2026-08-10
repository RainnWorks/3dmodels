// =============================================================================
//  nozzle.scad -- a ruffle piping nozzle (after Birkmann #122) + a coupler
// =============================================================================
//  Pure OpenSCAD, no libraries. Pick a part with -D render_part="...".
//
//  The aperture is not invented: it is TRACED from the manufacturer's
//  top-down product photo (trace/trace.py) and stored below in units of the
//  base diameter, so `base_d` scales the whole design coherently.
//
//  It is anchored on its BULB, which is the tip mouth -- not on its centroid.
//  The traced S is a PROJECTION of two separate features, the round mouth on
//  the axis and the slot running down one flank, and only the mouth is on the
//  axis. Anchoring on the centroid drags the tail across the axis and the cut
//  slices BOTH walls, giving a see-through tip with two free petals. The side
//  photo rules that out: the rim up there is a continuous, unbroken oval.
// =============================================================================

/* [Part] */
// Which part to render. nozzle/sleeve/ring are the printable ones.
render_part = "nozzle"; // [nozzle, sleeve, ring, assembly, section, aperture, all]

/* [Size] */
// Outer diameter at the base. Everything else is derived from this.
base_d = 23;        // [10:0.5:40]
// Height, as a multiple of base_d. From trace/trace_side.py: the camera looks
// 19.6 deg DOWN at the nozzle, so the naive tallest-row/widest-row reading of
// 2.111 is wrong twice over -- the axis is foreshortened and the base rim's
// near edge pads the height. Corrected via the base ellipse.
height_ratio = 2.063; // [1.2:0.025:3]
// Diameter of the truncated tip. Measured at 3.1 (by fitting the two flanks to
// straight lines and comparing the virtual apex with where the cone stops), but
// opened up here: the mouth is cut by the aperture's bulb at O2.55, so the real
// part's rim is only 0.28mm of steel. FDM cannot lay that. 4.4 gives a ~0.9mm
// rim -- a slightly blunter tip than the original, and a printable one.
tip_d = 4.4;        // [1:0.1:8]

/* [Walls] */
// Wall at the base, where you push it into the bag. 3 x 0.40mm exactly.
wall_t = 1.2;       // [0.6:0.1:2.5]
// Wall at the tip. THINNER than the base, deliberately: the aperture lives up
// here, and the wall thickness IS the land the icing squeezes along before it
// separates. Steel manages 0.5mm; 0.8 is as close as a 0.4mm nozzle gets while
// still being 2 clean extrusions. 0.45 is sharper again and much more fragile.
tip_wall_t = 0.8;   // [0.4:0.05:3]

/* [Aperture] */
// Grow the traced outline all round. FDM lays the aperture narrower than
// modelled; this is the compensation, and it is the number to tune first.
slot_grow = 0.20;   // [0:0.05:1]
// Break the outer edge of the mouth at the very top. Only the mouth -- the
// slot's own sharpness comes from tip_wall_t, not from a chamfer.
mouth_bevel = 0.3;  // [0:0.1:2]

/* [Retention] */
// Base flange. Steel nozzles have none -- they rely on the bag alone. A
// printed cone is slicker, and this is what the coupler ring clamps.
flange_t = 2.0;     // [0:0.2:4]
flange_over = 1.4;  // [0:0.2:4]

/* [Coupler] */
// Length of the sleeve body that sits inside the bag.
sleeve_body_h = 22;  // [10:1:40]
// Big open end of the sleeve, as a multiple of base_d.
sleeve_flare = 1.48; // [1.1:0.02:2]
// How far the sleeve's nose reaches up inside the nozzle.
nose_h = 7;          // [3:0.5:14]
// Ring wall, outside the thread.
ring_wall = 2.5;     // [1.5:0.1:5]

/* [Advanced - thread] */
thr_pitch  = 3.0;   // [1.5:0.5:5]
thr_starts = 3;     // [1:1:4]
thr_h      = 9;     // [4:1:16]
thr_depth  = 1.0;   // [0.6:0.1:2]
thr_flank  = 20;    // [10:1:35]
thr_layers = 6;     // [3:1:12]
// Radial and axial clearance cut into the ring's internal thread.
thr_rclear = 0.25;  // [0.1:0.05:0.6]
thr_aclear = 0.35;  // [0.1:0.05:0.8]
// How far the ring's groove runs out past the sleeve's rib, each end.
thr_runout = 1.0;   // [0.4:0.2:3]
// The sleeve's rib stops this far short of the seat, so the groove can end
// clear of it WITHOUT running up into the ring's clamp cone and slicing
// the lip off the body.
thr_top_gap = 0.6; // [0.2:0.1:2]
// Ramp the sleeve's rib out of the core over this, at each end, rather than
// starting it square. 1.5 against a 1.0 depth is a 34 deg cone off vertical.
thr_lead_in = 1.5; // [0:0.1:4]
// Gap left between the ring's clamp cone and the flange's, so the two are
// not modelled as coincident faces. The ring takes it up on the thread.
clamp_relief = 0.2; // [0.05:0.05:0.6]

/* [Advanced - misc] */
// Your slicer's wall extrusion width. Not used for geometry -- only to check
// that wall_t and tip_wall_t come out as whole extrusions, so a 999-perimeter
// slice fills them exactly instead of leaving a void or a gap-fill worm.
line_w = 0.40;      // [0.3:0.01:0.8]

/* [Hidden] */
$fa = 2;
$fs = 0.35;
eps = 0.01;
big = 500;

// =============================================================================
//  The traced aperture
// =============================================================================
//  120 points, in units of base_d, with the BULB (the tip mouth) on the axis
//  and the tail running off to one side. Straight out of trace/trace.py -- do
//  not hand-edit; re-run the tracer if the source photo changes.
// Radius of the bulb -- the tip mouth -- in the same units. Everything beyond
// it is the one-sided tail. Generated with the outline; do not hand-edit.
APERTURE_BULB_R = 0.05548;

// How narrow the slot gets (5th percentile of its local width, same units).
// The bulb is wide and prints regardless; the TAIL is what closes up, and this
// is the number that decides whether the part works. Generated with the
// outline; do not hand-edit.
APERTURE_MIN_W = 0.02452;

APERTURE = [
  [ 0.01763, -0.35615],
  [ 0.01319, -0.35815],
  [ 0.00610, -0.35742],
  [-0.00219, -0.35466],
  [-0.01058, -0.35056],
  [-0.01846, -0.34545],
  [-0.02528, -0.33940],
  [-0.03015, -0.33255],
  [-0.03196, -0.32530],
  [-0.03006, -0.31834],
  [-0.02486, -0.31222],
  [-0.01757, -0.30700],
  [-0.00942, -0.30221],
  [-0.00126, -0.29725],
  [ 0.00640, -0.29165],
  [ 0.01318, -0.28517],
  [ 0.01862, -0.27774],
  [ 0.02230, -0.26944],
  [ 0.02392, -0.26056],
  [ 0.02339, -0.25150],
  [ 0.02086, -0.24270],
  [ 0.01658, -0.23449],
  [ 0.01088, -0.22704],
  [ 0.00416, -0.22031],
  [-0.00318, -0.21411],
  [-0.01082, -0.20821],
  [-0.01858, -0.20244],
  [-0.02633, -0.19666],
  [-0.03394, -0.19073],
  [-0.04128, -0.18450],
  [-0.04820, -0.17785],
  [-0.05464, -0.17075],
  [-0.06055, -0.16322],
  [-0.06586, -0.15529],
  [-0.07052, -0.14696],
  [-0.07440, -0.13825],
  [-0.07739, -0.12921],
  [-0.07931, -0.11991],
  [-0.08004, -0.11047],
  [-0.07943, -0.10111],
  [-0.07727, -0.09215],
  [-0.07334, -0.08402],
  [-0.06767, -0.07700],
  [-0.06088, -0.07092],
  [-0.05419, -0.06503],
  [-0.04910, -0.05851],
  [-0.04676, -0.05099],
  [-0.04732, -0.04273],
  [-0.04984, -0.03410],
  [-0.05289, -0.02526],
  [-0.05531, -0.01619],
  [-0.05651, -0.00687],
  [-0.05638,  0.00257],
  [-0.05500,  0.01193],
  [-0.05247,  0.02105],
  [-0.04887,  0.02974],
  [-0.04421,  0.03777],
  [-0.03843,  0.04491],
  [-0.03165,  0.05101],
  [-0.02407,  0.05596],
  [-0.01585,  0.05947],
  [-0.00707,  0.06131],
  [ 0.00211,  0.06165],
  [ 0.01143,  0.06080],
  [ 0.02055,  0.05883],
  [ 0.02914,  0.05550],
  [ 0.03686,  0.05066],
  [ 0.04343,  0.04437],
  [ 0.04866,  0.03685],
  [ 0.05262,  0.02842],
  [ 0.05553,  0.01944],
  [ 0.05751,  0.01016],
  [ 0.05846,  0.00073],
  [ 0.05822, -0.00870],
  [ 0.05665, -0.01795],
  [ 0.05383, -0.02693],
  [ 0.05016, -0.03564],
  [ 0.04634, -0.04424],
  [ 0.04310, -0.05286],
  [ 0.04067, -0.06159],
  [ 0.03856, -0.07040],
  [ 0.03593, -0.07919],
  [ 0.03227, -0.08775],
  [ 0.02751, -0.09591],
  [ 0.02187, -0.10361],
  [ 0.01568, -0.11094],
  [ 0.00934, -0.11813],
  [ 0.00343, -0.12553],
  [-0.00136, -0.13345],
  [-0.00445, -0.14203],
  [-0.00560, -0.15109],
  [-0.00485, -0.16027],
  [-0.00234, -0.16919],
  [ 0.00180, -0.17751],
  [ 0.00735, -0.18504],
  [ 0.01406, -0.19165],
  [ 0.02166, -0.19736],
  [ 0.02986, -0.20227],
  [ 0.03845, -0.20662],
  [ 0.04717, -0.21072],
  [ 0.05580, -0.21495],
  [ 0.06400, -0.21971],
  [ 0.07125, -0.22537],
  [ 0.07679, -0.23217],
  [ 0.07986, -0.24003],
  [ 0.08012, -0.24854],
  [ 0.07784, -0.25715],
  [ 0.07372, -0.26547],
  [ 0.06839, -0.27330],
  [ 0.06221, -0.28056],
  [ 0.05538, -0.28727],
  [ 0.04808, -0.29350],
  [ 0.04054, -0.29946],
  [ 0.03312, -0.30547],
  [ 0.02637, -0.31194],
  [ 0.02105, -0.31923],
  [ 0.01782, -0.32737],
  [ 0.01696, -0.33596],
  [ 0.01786, -0.34425],
  [ 0.01881, -0.35131]
];

// =============================================================================
//  Derived
// =============================================================================
base_r   = base_d / 2;
tip_r    = tip_d / 2;
nozzle_h = base_d * height_ratio;

// Outer cone: r_o(z). Inner cavity: r_i(z) = r_o(z) - wall(z), and because
// wall(z) is linear in z the cavity is a cone too -- one cylinder() call.
function r_o(z) = base_r - z * (base_r - tip_r) / nozzle_h;
function wall(z) = wall_t + (tip_wall_t - wall_t) * z / nozzle_h;
function r_i(z) = r_o(z) - wall(z);

flange_od = base_d + 2 * flange_over;

// The clamp is a 45 deg cone, not a flat step. clamp_d is where it ends: it
// must clear the cone at that height, and still leave flange to bear on.
clamp_d = base_d + 0.6;
clamp_c = (flange_od - clamp_d) / 2;   // 45 deg, so radial == axial

// How far the aperture reaches from the axis, once grown.
ap_r = max([for (p = APERTURE) norm(p)]) * base_d + slot_grow;

// The mouth at the tip, and the radius beyond which the aperture must be
// entirely one-sided (with margin) or the cut would sever the cone.
mouth_d  = 2 * APERTURE_BULB_R * base_d + 2 * slot_grow;
one_sided_r = 1.4 * APERTURE_BULB_R * base_d;

// The slot breaks out through the flank from the height where the cone is
// narrower than the aperture's reach, up to the tip. It is a slot down ONE
// side -- see the note on anchoring above -- so the cone stays a closed tube
// all the way up and this is not a free-standing petal.
slit_z   = (base_r - ap_r) / ((base_r - tip_r) / nozzle_h);
slit_len = nozzle_h - slit_z;

// Aperture area, by the shoelace formula on the traced outline (this ignores
// `slot_grow`, so it is the floor, not the actual).
ap_area = 0.5 * abs(base_d * base_d *
    (sum_x(APERTURE) - sum_y(APERTURE)));
function sum_x(P) = _sx(P, 0);
function _sx(P, i) = i >= len(P) ? 0
    : P[i].x * P[(i + 1) % len(P)].y + _sx(P, i + 1);
function sum_y(P) = _sy(P, 0);
function _sy(P, i) = i >= len(P) ? 0
    : P[(i + 1) % len(P)].x * P[i].y + _sy(P, i + 1);

// Thread. Cut on the sleeve, cut away in the ring, from one module -- so the
// two can only ever match.
thr_major = base_d + 6;
thr_minor = thr_major - 2 * thr_depth;
thr_lead  = thr_pitch * thr_starts;
thr_rib_t = thr_pitch / 2;

echo(str("nozzle  ", base_d, " x ", nozzle_h, " mm, wall ", wall_t, "-", tip_wall_t));
echo(str("aperture ", ap_area, " mm^2 (a plain #12 round tip is 12.6), reach ", ap_r, " mm"));
echo(str("tip mouth ", mouth_d, " mm in a ", tip_d, " mm tip -> ",
         (tip_d - mouth_d) / 2, " mm of rim"));
echo(str("flank slot ", slit_len, " mm long (", 100 * slit_len / nozzle_h,
         "% of height; the photo measures 72%)"));
echo(str("land at the slot: ", wall(slit_z), " mm at its foot -> ", wall(nozzle_h),
         " mm at the tip (steel is ~0.5)"));
slot_min_w = APERTURE_MIN_W * base_d + 2 * slot_grow;
echo(str("slot narrows to ", slot_min_w, " mm as modelled = ",
         slot_min_w / line_w, " extrusions; FDM lays it ~0.1-0.2 narrower"));
if (slot_min_w < 2 * line_w)
    echo(str("NOTE: under 2 extrusions at the tail -- the fine end of the ",
             "ruffle may close up. Raise slot_grow if the print shows it."));
echo(str("thread: ", thr_h - thr_top_gap, " mm of rib, ", 2 * thr_lead_in,
         " of it lead-in ramped at ", atan(thr_depth / thr_lead_in),
         " deg off vertical"));
echo(str("walls at ", line_w, " line width: base ", wall_t / line_w,
         " extrusions, tip ", tip_wall_t / line_w,
         " -- both should be whole numbers"));

// Not an assert: a fractional wall still prints, the slicer just widens the
// last perimeter to fill. But it is worth knowing you asked for it.
if (abs(wall_t / line_w - round(wall_t / line_w)) > 0.02)
    echo(str("NOTE: wall_t is ", wall_t / line_w, " extrusions, not a whole number"));
if (abs(tip_wall_t / line_w - round(tip_wall_t / line_w)) > 0.02)
    echo(str("NOTE: tip_wall_t is ", tip_wall_t / line_w, " extrusions, not a whole number"));

assert(ap_r < r_i(0) - 0.8,
       "Aperture reaches the wall at the base -- raise base_d or shrink the trace.");
assert(flange_od < thr_minor - 2 * thr_rclear - 0.4,
       "Flange will not pass through the coupler ring -- raise thr_major.");
assert(tip_d > mouth_d + 1.0,
       "No rim left at the tip -- raise tip_d, the mouth is set by the trace.");
assert(thr_h - thr_top_gap > 2 * thr_lead_in + 1.0,
       "Lead-in eats the whole thread -- lower thr_lead_in or raise thr_h.");
assert(clamp_d > 2 * r_o(flange_t) + 0.3,
       "The ring's lip would foul the cone instead of bearing on the flange.");
assert(flange_t > clamp_c + 0.3 && flange_t > (thr_minor + 2 * thr_rclear - clamp_d) / 2,
       "Flange too thin for the 45 deg clamp cone -- raise flange_t.");

// =============================================================================
//  Aperture
// =============================================================================
module aperture_2d() {
    offset(r = slot_grow)
        polygon([for (p = APERTURE) [p.x * base_d, p.y * base_d]]);
}

// The aperture is a CONSTANT cross-section prism running straight up the axis.
// Everything the shape does on the flank falls out of that: near the tip the
// cone is narrower than the prism and the prism cuts through, lower down the
// cone is wider and the prism is buried inside the cavity, doing nothing.
module aperture_cut() {
    translate([0, 0, -eps]) linear_extrude(nozzle_h + 2 * eps, convexity = 10)
        aperture_2d();
    if (mouth_bevel > 0)
        translate([0, 0, nozzle_h - mouth_bevel])
            linear_extrude(mouth_bevel + eps, convexity = 10)
                offset(r = mouth_bevel) aperture_2d();
}

// =============================================================================
//  Nozzle
// =============================================================================
module nozzle() {
    difference() {
        union() {
            cylinder(h = nozzle_h, r1 = base_r, r2 = tip_r);
            // Flange, with its top outer edge taken off at 45 deg. That cone is
            // the clamping face: the ring carries the same 45 deg cone, so the
            // pair self-centres, and neither part has an overhang to bridge.
            if (flange_t > 0) {
                cylinder(h = flange_t - clamp_c, d = flange_od);
                translate([0, 0, flange_t - clamp_c])
                    cylinder(h = clamp_c, d1 = flange_od, d2 = clamp_d);
            }
        }
        // cavity
        translate([0, 0, -eps])
            cylinder(h = nozzle_h + 2 * eps, r1 = r_i(0), r2 = r_i(nozzle_h));
        aperture_cut();
    }
}

// =============================================================================
//  Thread
// =============================================================================
//  A helical rib is a TWISTED PRISM whose 2D section is the rib's plan view:
//  at any height the rib occupies one angular sector, and that sector rotates
//  with height. linear_extrude(twist=) sweeps exactly that. A trapezoid needs
//  the sector to narrow as the radius grows, which one extrude cannot do, so
//  it is stacked as thr_layers nested helices -- the same staircase trick the
//  playdoh-organiser uses on its legs, and for the same reason.
module wedge_2d(r, a) {
    n = max(6, ceil(a / 6));
    polygon([[0, 0], for (i = [0:n]) r * [cos(-a/2 + a*i/n), sin(-a/2 + a*i/n)]]);
}

//  z0/h are ABSOLUTE, and the 2D shape is pre-rotated by the phase z0 has
//  already accumulated. Without that, cutting the ring's groove over a taller
//  span than the sleeve's rib -- which is the only way to avoid the two
//  threads ending on one coincident plane -- would silently put them 40 deg
//  out of phase and they would not screw together at all.
// Ramp the rib out of the core over `lead_in` at each end, instead of letting
// it start square. Two reasons, and the second is the one that matters:
//   - a square start is a full-depth horizontal ledge (thr_depth wide) hanging
//     off the core; the ramp turns that into a cone atan(depth/lead_in) off
//     vertical, which the printer does not have to bridge at all;
//   - a chamfered rib self-centres going into the ring, so the thread can be
//     started one-handed rather than hunted for.
// Only the sleeve's rib gets this. The ring's GROOVE must stay full depth to
// the ends or it would foul the very rib it is cut to accept, so it passes 0.
module thread_envelope(z0, h, lead_in, rclear) {
    union() {
        translate([0, 0, z0 - eps])
            cylinder(h = h + 2 * eps, r = thr_minor / 2 + rclear + eps);
        translate([0, 0, z0])
            cylinder(h = lead_in, r1 = thr_minor / 2 + rclear,
                                  r2 = thr_major / 2 + rclear + eps);
        translate([0, 0, z0 + lead_in])
            cylinder(h = h - 2 * lead_in, r = thr_major / 2 + rclear + eps);
        translate([0, 0, z0 + h - lead_in])
            cylinder(h = lead_in, r1 = thr_major / 2 + rclear + eps,
                                  r2 = thr_minor / 2 + rclear);
    }
}

module thread(z0, h, rclear = 0, aclear = 0, lead_in = 0) {
    if (lead_in > 0) intersection() {
        thread_ribs(z0, h, rclear, aclear);
        thread_envelope(z0, h, lead_in, rclear);
    } else thread_ribs(z0, h, rclear, aclear);
}

module thread_ribs(z0, h, rclear = 0, aclear = 0) {
    translate([0, 0, z0])
    for (s = [0:thr_starts - 1]) rotate([0, 0, s * 360 / thr_starts])
        for (k = [0:thr_layers - 1]) {
            f = (k + 1) / thr_layers;
            r = thr_minor / 2 + thr_depth * f + rclear;
            t = thr_rib_t - 2 * thr_depth * f * tan(thr_flank) + aclear;
            if (t > 0.15)
                linear_extrude(height = h, twist = -360 * h / thr_lead,
                               slices = max(24, ceil(h * 6)), convexity = 8)
                    rotate(360 * z0 / thr_lead)
                    intersection() { circle(r = r); wedge_2d(r * 1.2, 360 * t / thr_lead); }
        }
}

// =============================================================================
//  Coupler
// =============================================================================
//  Modelled in the assembly frame and printed in it too -- no part is ever
//  flipped, which is the only way an external and an internal thread stay
//  the same hand.
//
//    z = 0        the seat: the nozzle's flange lands here
//    0 .. nose_h  the nose, up inside the nozzle's bore
//    0 .. -thr_h  the external thread, poking out through the snipped bag
//    -thr_h down  the body, inside the bag, flaring so it cannot pull through

sleeve_z0 = -(thr_h + sleeve_body_h);   // the big open end
sleeve_od = base_d * sleeve_flare;
sleeve_wall = 1.8;

module sleeve() {
    difference() {
        union() {
            // body: flared inside the bag, tapering up to the thread core
            translate([0, 0, sleeve_z0])
                cylinder(h = sleeve_body_h, d1 = sleeve_od, d2 = thr_minor);
            // thread core + rib
            translate([0, 0, -thr_h]) cylinder(h = thr_h, d = thr_minor);
            thread(-thr_h, thr_h - thr_top_gap, lead_in = thr_lead_in);
            // nose: follows the nozzle's own bore, so it centres the nozzle
            // instead of just plugging it
            cylinder(h = nose_h, r1 = r_i(0) - 0.3, r2 = r_i(nose_h) - 0.3);
        }
        // bore, opening out downward all the way -- no step to trap icing
        translate([0, 0, sleeve_z0 - eps])
            cylinder(h = nose_h - sleeve_z0 + 2 * eps,
                     d1 = sleeve_od - 2 * sleeve_wall,
                     d2 = 2 * (r_i(nose_h) - 0.3) - 2 * 1.1);
    }
}

ring_bore  = thr_minor + 2 * thr_rclear;
ring_od    = thr_major + 2 * ring_wall;
ring_lip_t = 1.5;
// The ring's cone runs from the bore in to clamp_d, at the same 45 deg the
// flange is chamfered at -- so the two meet face to face over an annulus
// rather than on one corner, and the printed overhang is 45 deg, not 90.
ring_cone_h = (ring_bore - clamp_d) / 2;

module ring() {
    difference() {
        union() {
            translate([0, 0, -thr_h])
                cylinder(h = thr_h + flange_t + ring_lip_t, d = ring_od);
            // grip flutes
            for (i = [0:11]) rotate([0, 0, i * 30])
                translate([ring_od / 2, 0, -thr_h])
                    cylinder(h = thr_h + flange_t + ring_lip_t, d = 2.4);
        }
        // bore, then the 45 deg clamp cone, then the lip. The cone is lifted
        // by clamp_relief so it does not sit as a coincident face on the
        // flange: the ring simply screws that much further down before it
        // bites, and the thread has 9mm of travel to give.
        // NB the +2*eps: the bore must run PAST where the cone starts. Ending
        // both on the same plane at the same diameter leaves a degenerate
        // zero-volume face that CGAL then hands to every later boolean, and it
        // shows up as phantom interference in the fit tests.
        translate([0, 0, -thr_h - eps])
            cylinder(h = thr_h + flange_t + clamp_relief - ring_cone_h + 2 * eps, d = ring_bore);
        translate([0, 0, flange_t + clamp_relief - ring_cone_h])
            cylinder(h = ring_cone_h, d1 = ring_bore, d2 = clamp_d);
        translate([0, 0, flange_t + clamp_relief - eps])
            cylinder(h = ring_lip_t + 2 * eps, d = clamp_d);
        // run the groove out past both ends of the rib: two threads that stop
        // on the same plane leave a coincident face, not a fit.
        thread(-thr_h - thr_runout, thr_h + thr_runout,
               rclear = thr_rclear, aclear = thr_aclear);
    }
}

// =============================================================================
//  Views
// =============================================================================
module assembly() {
    color("Silver")     nozzle();
    color("SteelBlue")  sleeve();
    color("Goldenrod")  ring();
}

module clipped() { intersection() { children(); translate([-big, 0, -big]) cube(2 * big); } }

module section() {
    color("Silver")    clipped() nozzle();
    color("SteelBlue") clipped() sleeve();
    color("Goldenrod") clipped() ring();
}

if      (render_part == "nozzle")   nozzle();
else if (render_part == "sleeve")   translate([0, 0, -sleeve_z0]) sleeve();
else if (render_part == "ring")     translate([0, 0, thr_h]) ring();
else if (render_part == "assembly") assembly();
else if (render_part == "section")  section();
else if (render_part == "aperture") linear_extrude(1) aperture_2d();
else if (render_part == "all") {
    nozzle();
    translate([base_d * 1.6, 0, -sleeve_z0]) sleeve();
    translate([-base_d * 1.9, 0, thr_h])     ring();
}
