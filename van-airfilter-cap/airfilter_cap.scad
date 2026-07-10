// =============================================================================
//  airfilter_cap.scad -- tapered press-fit weather cap for a van air filter
// =============================================================================
//  A tapered cup (truncated cone). The BIG end clips onto the ~250mm housing
//  rim; it tapers down to a smaller closed end that sits over the ~160mm filter
//  element. It fits HORIZONTALLY: the small closed end faces out, and DOWNWARD
//  LOUVERS on the lower side let air in while the top sheds rain.
//
//        printed small-end-down (Z up):
//                       ___________________        <- big end (clip): 250mm,
//                      /                   \           grips the housing rim
//                     /   taper 250 -> 160  \
//                    /      over 140mm        \
//        closed  -> |__________________________|   <- small end: 160mm, over
//        vented        louvers (lower side)          the filter, closed + vented
//        end
//
//  HOW IT FITS
//    Big end = a straight GRIP BAND (the "clip") sized to press over the housing
//    rim (`lip_od`). Below it the bore is clearance, so it only bites at the rim.
//    The cone tapers `big_d -> small_d` over `taper_len`; the filter sits at the
//    small end. Measure `lip_od` (rim OD), `small_d` (filter OD) and `taper_len`
//    (rim -> filter distance) and everything follows. An assert keeps the widest
//    OD <= 250mm (build volume).
//
//  PRINT (single colour, supports OFF)
//    SMALL END DOWN (closed end on the plate, clip mouth up). The cone flares out
//    ~18deg off vertical -> self-supporting. Louver blades are angled so their
//    underside stays a printable overhang. ~180mm tall, up to ~250mm wide at the
//    top -- uses most of the plate, so skip the brim (a few mouse-ears is plenty).
//
//  Pure OpenSCAD (no libraries). Annotated for the MakerWorld customizer.
// =============================================================================

/* [Part to make] */
// cap = the part; section = cut-away; on_filter = over a filter stub (preview)
render_part = "cap"; // [cap:Cap (the part), section:Preview - cut-away, on_filter:Preview - on a filter, inuse:Preview - as fitted]

/* [Clip end -- MEASURE THE HOUSING RIM] */
// Outer diameter of the rim the cap clips onto, at the big end (mm)
lip_od = 243;        // [120:1:245]
// Interference at the grip band: grip bore = lip_od - this (bigger = tighter) (mm)
press_fit = 0.30;    // [0:0.05:1]
// Diametral clearance elsewhere so the cap slides on easily (mm)
mouth_clear = 0.8;   // [0.2:0.1:3]
// Straight grip section length at the big end (mm)
clip_len = 25;       // [10:1:60]
// Length of the grip band within the clip section (mm)
grip_len = 18;       // [5:1:40]
// Gap from the rim to the top of the grip band (mm)
grip_gap = 5;        // [0:1:20]

/* [Taper + small end] */
// Small-end outer diameter -- goes over the filter (mm)
small_d = 160;       // [80:1:240]
// Taper length, big end down to small end = rim -> filter distance (mm)
taper_len = 140;     // [40:1:220]
// Straight section at the small end (holds the closed end + vents) (mm)
small_len = 15;      // [5:1:60]
// Closed-end thickness (mm)
end_t = 3.0;         // [1.5:0.5:8]

/* [Shell] */
// Side wall thickness (mm)
wall = 3.0;          // [1.5:0.5:6]
// Chamfer at the clip mouth to start the press (mm)
lead_in = 2.0;       // [0:0.5:6]

/* [Vents -- on the lower side; rain shed by the downward-facing openings] */
// Vent pattern
vent_style = "grid"; // [grid:Diamond grid (max air, easiest print), louver:Slanted louvers]
// Angular spread of the vent band, centred on the bottom (deg). ~170 = lower half
vent_arc = 160;      // [0:5:240]
// Which way is "down" in use (deg around the cap): 270 = bottom
vent_center = 270;   // [0:5:355]
// Start of the vent band, from the base (closed end) (mm)
vent_from_end = 8;   // [0:1:120]

/* [Vents: diamond grid] */
// Hole width, tangential (mm)
grid_w = 9;          // [3:0.5:25]
// Hole height, vertical -- taller than wide gives a self-supporting point (mm)
grid_h = 14;         // [4:0.5:30]
// Bar thickness between holes (mm)
grid_web = 3;        // [1.5:0.5:8]
// Rows of holes up the side
grid_rows = 8;       // [1:1:24]

/* [Vents: slanted louvers] */
// Number of louvers up the side
louver_count = 7;    // [0:1:24]
// Open height of each louver (mm)
louver_h = 6;        // [3:0.5:20]
// Solid web between louvers (mm)
louver_web = 4;      // [2:0.5:15]
// Roof slope from horizontal; >=45 prints WITHOUT support (deg)
louver_angle = 48;   // [45:1:70]

/* [Hidden] */
max_build = 250;     // printer max build volume (mm)
$fa = 2;
$fs = 1;

// -----------------------------------------------------------------------------
//  DERIVED + CHECKS
// -----------------------------------------------------------------------------
grip_bore  = lip_od - press_fit;        // tight band that grips the rim
bore_clear = lip_od + mouth_clear;      // clearance bore (slides on)
big_d      = bore_clear + 2*wall;       // big-end (clip) outer diameter
cap_len    = small_len + taper_len + clip_len;   // overall height

z1 = small_len;                 // top of the small straight
z2 = small_len + taper_len;     // top of taper = bottom of clip section
z3 = cap_len;                   // top rim
band_top = z3 - grip_gap;       // grip band, from the rim down
band_bot = band_top - grip_len;

echo(big_d = big_d, small_d = small_d, cap_len = cap_len, grip_band = [band_bot, band_top]);
assert(big_d <= max_build,
       str("big_d ", big_d, "mm exceeds the ", max_build,
           "mm build volume -- reduce wall or lip_od"));
assert(band_bot >= z2, "grip band dips into the taper -- raise clip_len or lower grip_gap/grip_len");
assert(small_d > 2*wall + 20, "small_d too small for the wall");

// -----------------------------------------------------------------------------
//  HELPERS
// -----------------------------------------------------------------------------

// outer wall radius at height z (follows the small-straight / taper / clip)
function r_at(z) =
    z <= z1 ? small_d/2 :
    z >= z2 ? big_d/2   :
              small_d/2 + (big_d - small_d)/2 * (z - z1)/taper_len;

// one louver: a slanted through-slot swept along the lower vent arc. The slot is
// a parallelogram whose roof rises at `louver_angle` from horizontal, so printed
// small-end-down the overhang is self-supporting (>=45). The opening still faces
// down on the underside in use, so it sheds rain.
lv_dr   = 2*wall;                          // radial cut-through depth
lv_rise = lv_dr * tan(louver_angle);       // z rise across the slot
lv_ext  = louver_h + lv_rise;              // total vertical extent of a slot

module louver_opening(zc) {
    rotate([0, 0, vent_center - vent_arc/2])
        rotate_extrude(angle = vent_arc)
            translate([r_at(zc), zc])
                polygon([[-lv_dr/2, -lv_rise/2 - louver_h/2],
                         [-lv_dr/2, -lv_rise/2 + louver_h/2],
                         [ lv_dr/2,  lv_rise/2 + louver_h/2],
                         [ lv_dr/2,  lv_rise/2 - louver_h/2]]);
}

module louvers() {
    if (vent_arc > 0 && louver_count > 0) {
        pitch = lv_ext + louver_web;
        for (i = [0:louver_count-1])
            louver_opening(end_t + vent_from_end + lv_ext/2 + i*pitch);
    }
}

// diamond-grid vent: holes taller than wide (grid_h > grid_w) come to a point at
// top, so there is NO flat roof to bridge -> prints without support. Maximum open
// area, and on the underside in use so it still sheds rain.
module at_wall(a, z) {
    rotate([0,0,a]) translate([r_at(z),0,z]) rotate([0,90,0]) children();
}
module diamond_hole(a, z) {
    at_wall(a, z)
        linear_extrude(height = 4*wall, center=true)
            polygon([[-grid_h/2,0],[0,grid_w/2],[grid_h/2,0],[0,-grid_w/2]]);
}
module grid_vents() {
    if (vent_arc > 0 && grid_rows > 0)
        for (ri = [0:grid_rows-1]) {
            z = end_t + vent_from_end + grid_h/2 + ri*(grid_h + grid_web);
            r = r_at(z);
            a_pitch = (grid_w + grid_web) / (PI*r/180);   // arc spacing -> degrees
            ncols   = max(1, floor(vent_arc / a_pitch));
            off     = (ri % 2) * a_pitch/2;               // brick offset
            for (ci = [0:ncols])
                diamond_hole(vent_center - vent_arc/2 + off + ci*a_pitch, z);
        }
}

module vents() { if (vent_style == "grid") grid_vents(); else louvers(); }

// -----------------------------------------------------------------------------
//  THE CAP  (small closed end on the plate at Z=0, clip mouth up at Z=cap_len)
// -----------------------------------------------------------------------------
module outer() {
    cylinder(d = small_d, h = small_len);                              // small straight
    translate([0,0,z1]) cylinder(d1 = small_d, d2 = big_d, h = taper_len); // taper
    translate([0,0,z2]) cylinder(d = big_d, h = clip_len);            // clip straight
}

module cavity() {
    // small + taper inner: uniform wall, from the closed end up
    translate([0,0,end_t]) cylinder(d = small_d - 2*wall, h = small_len - end_t + 0.01);
    translate([0,0,z1]) cylinder(d1 = small_d - 2*wall, d2 = big_d - 2*wall, h = taper_len + 0.01);
    // clip inner: clearance up to the grip band...
    translate([0,0,z2-0.01]) cylinder(d = bore_clear, h = band_bot - z2 + 0.02);
    // grip band (the "clip")
    translate([0,0,band_bot-0.01]) cylinder(d = grip_bore, h = grip_len + 0.02);
    // ...clearance above the band to the mouth
    translate([0,0,band_top-0.01]) cylinder(d = bore_clear, h = z3 - band_top + 1);
    // lead-in chamfer at the mouth
    if (lead_in > 0)
        translate([0,0,z3-lead_in]) cylinder(d1 = bore_clear, d2 = bore_clear + 2*lead_in, h = lead_in+0.01);
}

module cap() {
    difference() {
        outer();
        cavity();
        vents();
    }
}

// a stub of the filter (context only): 160mm, sitting ~taper_len from the rim
module filter_stub() {
    color("DimGray")
    translate([0,0,z1])
        difference() {
            cylinder(d = small_d, h = taper_len - 10);
            translate([0,0,-1]) cylinder(d = small_d - 8, h = taper_len - 8);
        }
}

// -----------------------------------------------------------------------------
//  RENDER SELECTOR
// -----------------------------------------------------------------------------
if (render_part == "cap")
    color("SteelBlue") cap();
else if (render_part == "section")
    difference() { cap(); translate([-300,0,-10]) cube([600,300,600]); }
else if (render_part == "profile")
    // vertical cut through the vent side, to read the louver print overhangs
    difference() { cap(); translate([0,-300,-10]) cube([600,600,600]); }
else if (render_part == "on_filter") {
    color("SteelBlue", 0.55) cap();
    filter_stub();
} else if (render_part == "inuse")
    // as fitted: axis horizontal, vents pointing down
    rotate([90,0,0]) color("SteelBlue") cap();
else
    cap();
