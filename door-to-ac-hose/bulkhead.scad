// =============================================================================
//  Bulkhead fan-duct fitting  --  modular, parametric  (OpenSCAD + BOSL2)
// =============================================================================
//  A threaded port through a hole drilled in a door, for a portable-AC hose.
//
//  HOW IT WORKS  (one thread spec, used on BOTH faces of the door)
//    * BODY  = outside flange + short externally-threaded OUTBOARD COLLAR (the
//      outside port) + externally-threaded BARREL through the door (the inside
//      port). It's a flanged tube, threaded at both ends. Drops through the
//      hole from outside; the barrel is a loose fit in the bore.
//    * Two accessory styles, because the two faces of the door do different jobs:
//      INSIDE (GEARED) -- clamps the door: a grip flange bears on the inside face
//      so screwing it down traps the door between it and the body flange. The
//      accessory IS the clamp (no separate nut).
//        - CAP      = flanged, closed top.  Winter seal / blanking plate.
//        - WIDENER  = flanged, flares to a slotted COLLET mouth the hose pushes
//                     into; its base is externally threaded for COLLET_NUT.
//        - COLLET_NUT = separate all-printed clamp. Goes over the hose, screws
//                     onto the collet; its inner cone squeezes the fingers onto
//                     the hose. Hand on/off, no hardware. (Its own model.)
//      OUTSIDE (PLAIN) -- the body flange is already on the outside, so these are
//      compact threaded knobs (light knurl, NO clamp flange) on the outboard
//      collar -- no second gear stacked on the body flange.
//        - CAP_OUT  = plain closed cap.  Outside blank.
//        - NET_OUT  = plain bug-mesh vent.  Air in/out, insects out; mesh sits
//                     clear above the collar tip so the core never protrudes.
//    * Same accessories fit the outboard collar too, so EITHER face of the door
//      can be capped or ducted. Swap cap<->widener by hand (twice a year); the
//      door is only unclamped for the few seconds of the swap.
//
//  ---------------------------------------------------------------------------
//  PRINT NOTES   (Bambu; PLA for first fit-test, PETG for the real thing)
//  ---------------------------------------------------------------------------
//  FIT-TEST FIRST
//    render_part="test" is a short male thread coupon. Print it + the CAP in
//    PLA and check the thread runs smoothly and snugs up. Too tight -> raise
//    thread_clearance; sloppy -> lower it. Reprint the coupon (minutes), THEN
//    commit to the big parts.
//
//  ORIENTATION (all parts: THREAD AXIS VERTICAL).  Design is self-supporting --
//  run with SUPPORTS OFF.  Two things make that work: the thread flanks are
//  sloped (thread_angle ~50) so the downward flank never exceeds a printable
//  overhang, and a 45deg cone under each flange (support_cones) replaces the
//  flat overhang ring.
//    BODY     -> outboard collar DOWN on the plate, barrel + threads UP. Flange
//                seating face prints flat (up); its collar-side is the cone.
//    CAP      -> flange DOWN on the plate, closed top up.
//    WIDENER  -> MOUTH DOWN (collet/threaded mouth ring on the plate, flange on
//                top). Flare + flange cone self-support.
//    COLLET_NUT -> HOLE-END DOWN (the small hose-hole face on the plate, OPEN
//                threaded end UP) -- i.e. like a cup the right way up. The squeeze
//                cone is then the inside-bottom (supported), not a ceiling, so no
//                support. Printed open-end-down instead, the cone is a ceiling
//                and the slicer asks for support -- just flip it.
//
//  PLA (fit-test):  nozzle ~210C / bed ~60C, layer 0.20, walls 3, infill 20%.
//  PETG (final):    nozzle ~250-260C / bed ~70-80C, layer 0.20, walls 3-4,
//                   infill 25-40% gyroid, cooling 30-50%, slow first layer.
//
//  TOLERANCE / FIT
//    thread_clearance = 0.45mm diametral. Barrel is a deliberate loose fit in
//    the bore (fit_clearance = 1mm) -- the clamp, not the bore, holds it.
//    Add foam/weather tape under the flanges for an air seal on the door.
// =============================================================================

include <BOSL2/std.scad>
include <BOSL2/threading.scad>

// -----------------------------------------------------------------------------
//  PARAMETER BLOCK  -- everything dimension-driving lives here
//  (annotated for the OpenSCAD / MakerWorld MakerLab Customizer)
// -----------------------------------------------------------------------------

/* [Part to make] */
// Which piece to generate. Functional parts are printable; assembly/section/
// clampdemo are preview-only visualisations.
render_part = "body"; // [body:Body - port through the door, cap:Cap - inside blanking plate, widener:Widener - hose inlet, collet_nut:Collet nut - hose clamp, cap_out:Cap out - outside blank, net_out:Vent - outside bug screen, spanner:Spanner - turns the collet nut, spanner_w:Small spanner - holds the widener, test:Thread test coupon, assembly:Preview - assembled, section:Preview - cut-away, clampdemo:Preview - hose clamp]

/* [Hole and door -- MEASURE THESE] */
// Drilled hole diameter in the door (mm)
bore_d = 86; // [40:1:160]
// Door thickness (mm)
door_thickness = 40; // [10:1:80]

/* [Hose] */
// AC / heat-pump hose OD, measured across the RIB CRESTS -- the hose screws
// into the widener mouth (mm)
duct_od = 146; // [80:1:220]
// Slide-in clearance: mouth bore = hose OD + this (mm)
insert_clear = 2.0; // [0:0.1:5]

/* [Fit and thread] */
// Barrel OD = bore - this. A loose drop-in: the clamp holds it, not the bore (mm)
fit_clearance = 1.0; // [0:0.1:4]
// Thread pitch -- coarse (mm)
thread_pitch = 5.0; // [2:0.5:8]
// Diametral clearance between male and female thread (mm)
thread_clearance = 0.45; // [0.1:0.05:1]
// Thread INCLUDED angle. The printed flank ends up at exactly HALF this off the
// horizontal, so 50 -> 25deg flanks, which is below Bambu's 30deg default support
// threshold: set the threshold to 20 and print with supports off (see Printing).
//
// 80 would give 40deg flanks and remove the overhang entirely (measured: body
// sub-30deg area 74.16 -> 0.11 cm2) -- but it re-cuts male AND female, and a
// 50deg tooth crest (1.33mm wide at the major dia) will NOT enter an 80deg groove
// (0.40mm there). So it is a whole-kit change. HELD AT 50 to stay compatible with
// the already-printed body; adopt 80 the next time the full kit is reprinted.
// Do not exceed 90: at thread_depth = pitch/2 the profile degenerates to a
// knife-edge V with no crest flat left. (deg)
thread_angle = 50; // [30:1:90]

/* [Ports and barrel] */
// Barrel thread protruding inside (accessory travel; absorbs door-thickness error) (mm)
inside_thread_len = 20; // [10:1:40]
// Outboard (outside) threaded port length (mm)
collar_len = 14; // [6:1:30]
// Clear through-airway diameter -- keep airflow open (mm)
airway_d = 74; // [40:1:130]
// Nominal wall thickness (mm)
wall = 3.0; // [1.5:0.5:6]

/* [Flange (outside, seats on door)] */
// Seating ring width added around the bore: flange OD = bore + this (mm)
flange_margin = 29; // [10:1:60]
// Flange thickness (mm)
flange_t = 5; // [2:0.5:12]

/* [Accessories (cap / widener)] */
// Grip + clamp flange width added around the bore (mm)
acc_flange_margin = 29; // [10:1:60]
// Accessory flange thickness (mm)
acc_flange_t = 6; // [2:0.5:12]
// Internal thread depth (should swallow the barrel protrusion) (mm)
acc_thread_len = 20; // [10:1:40]
// Clearance counterbore above the thread (swallows the barrel tip if the door is thin) (mm)
acc_clear_depth = 8; // [0:1:20]
// Hand-grip scallops around the accessory rim (count)
grip_flutes = 14; // [0:1:40]
// Scallop cutter radius (mm)
grip_r = 7; // [1:0.5:15]

/* [Cap] */
// Closed-end thickness (mm)
cap_top_t = 4; // [1:0.5:10]

/* [Outside caps and vent] */
// Light knurl flutes on the compact outside knobs (count)
out_flutes = 16; // [0:1:40]
// Knurl cutter radius (mm)
out_flute_r = 3; // [1:0.5:10]
// Gap between collar tip and the grille so the core never reaches the mesh (mm)
net_standoff = 4; // [1:0.5:12]
// Grille thickness (mm)
grille_t = 2.5; // [1:0.5:6]
// Mesh bar width (mm)
grille_bar = 1.5; // [0.5:0.1:4]
// Mesh opening -- smaller stops smaller bugs but cuts airflow (mm)
grille_gap = 2.0; // [1:0.5:6]

/* [Widener flare and collet] */
// Steep flare height: throat -> mouth (short = widens fast) (mm)
flare_len = 16; // [6:1:40]
// Externally-threaded base of the collet (the nut runs on this) (mm)
collet_thread_len = 14; // [6:1:30]
// Slotted fingers above the thread (these get squeezed, and carry the grip
// rings -- must be long enough to hold the ring stack, see assert) (mm)
collet_finger_len = 34; // [8:1:60]
// Number of slots / fingers (count)
collet_slots = 6; // [3:1:12]
// Slot width (mm)
collet_slot_w = 3; // [1:0.5:8]
// Collet wall at the thread root (mm)
collet_wall = 2.5; // [1.5:0.5:6]
// Coarse external collet thread pitch (nut clamps in ~1 turn) (mm)
collet_pitch = 6; // [3:0.5:10]
// Cap-nut wall thickness (mm)
nut_wall = 4; // [2:0.5:8]
// Knurl flutes on the cap-nut (count)
nut_flutes = 18; // [0:1:40]
// Axial length of the nut's squeeze cone. LONGER = shallower wedge = far less hand
// force for the same squeeze: 10mm is a 31deg wedge (1.7x), 20mm is 17deg (3.3x) (mm)
nut_cone = 20; // [4:1:30]

/* [Nut spanner (tool)] */
// The nut is O167 and needs real torque -- too big to grip and too stiff to turn by
// hand, so it gets a printed C-spanner. Jaw wrap in degrees; 180 slides on sideways
// without flexing (it has to go on sideways -- the flare blocks one end, the hose
// the other).
spanner_wrap = 180; // [120:5:270]
// Arc of the wrap that carries teeth (leave the ends clear so it slides on) (deg)
spanner_teeth_arc = 120; // [40:5:200]
// Jaw wall thickness (mm)
spanner_wall = 9; // [4:0.5:16]
// Tool thickness / height (mm)
spanner_h = 15; // [6:1:30]
// Handle length from the nut's OD. 140 keeps the whole tool at 244mm so it fits a
// 255x255 X2D plate flat, unrotated. Going to 185 (289mm) does NOT fit at any
// rotation, and only buys 19% more torque -- the lever arm is measured from the
// nut's AXIS, not the handle root, so the jaw radius is most of it already. (mm)
spanner_handle = 140; // [60:5:300]
// Handle bar width (mm)
spanner_grip_w = 22; // [12:1:40]
// Clearance between jaw bore and the target OD (mm)
spanner_slop = 0.6; // [0:0.1:2]
// Small (widener-holding) spanner: jaw/handle thickness (mm)
wspanner_h = 14; // [6:1:25]
// Small spanner handle length (mm)
wspanner_handle = 120; // [50:5:250]

/* [Hose grip rings] */
// Axial spacing of the internal grip rings. Deliberately WIDE and deliberately
// NOT matched to the hose's rib spacing -- see decision #7. The hose is flexible,
// so each ring independently finds a valley or squashes the rib a little; a dense
// stack tuned to a guessed pitch is all-or-nothing and worse. (mm)
ring_spacing = 11; // [4:0.5:30]
// Rib pitch of the real hose -- PREVIEW ONLY, does not affect any printed part
hose_rib_pitch = 6.3; // [3:0.1:20]
// Thickness of each ring at its tip (mm)
ring_thick = 1.2; // [0.4:0.1:4]
// How far each ring reaches in past the hose crest BEFORE the nut is tightened.
// Deliberately shallow -- the nut's squeeze supplies the rest, which is what
// makes the grip tolerant of an unmeasured rib depth (mm)
ring_engage = 1.35; // [0.4:0.05:4]
// Number of grip rings. Few and wide beats many and dense (decision #7)
ring_count = 3; // [2:1:12]
// Gap between the collet thread top and the first ring (mm)
ring_start = 3; // [0:0.5:15]

/* [Advanced] */
// 45deg cones under the flanges so they print self-supporting (supports OFF)
support_cones = true;
// false = plain bores/barrel for a fast proportions check (no thread geometry)
show_threads = true;

/* [Hidden] */
$fa = 2;
$fs = 0.8;

// -----------------------------------------------------------------------------
//  DERIVED + SANITY CHECKS
// -----------------------------------------------------------------------------
thread_depth   = thread_pitch * 0.5;            // shallow, robust printed engagement
flange_od      = bore_d + flange_margin;        // outside seating flange OD
acc_flange_od  = bore_d + acc_flange_margin;    // accessory grip/clamp flange OD
out_engage     = collar_len;                    // outside-knob thread depth = collar
barrel_od  = bore_d - fit_clearance;            // thread MAJOR diameter
thread_d   = barrel_od;
barrel_len = door_thickness + inside_thread_len;// barrel: door + inside port
acc_od     = thread_d + 2*wall;                 // accessory threaded-collar OD
acc_clear_d = barrel_od + 1;                    // counterbore dia (clears barrel)
barrel_minor = thread_d - 2*thread_depth;
barrel_wall_at_root = (barrel_minor - airway_d)/2;
// The cone lands on the thread ROOT (barrel_minor), not the crest. Landing it on
// the crest left a flat annular shelf (thread_depth wide) hanging over the thread
// valleys all the way round -- a dead-horizontal overhang, the worst kind, and the
// real reason the slicer demanded support here. Height tracks the base diameter so
// the cone stays a true 45deg.
body_cone_h = support_cones ? (flange_od - barrel_minor)/2 : 0; // 45deg, flange->collar
acc_cone_h  = support_cones ? (acc_flange_od - acc_od)/2  : 0; // 45deg, flange->collar
out_od      = acc_od + 6;                                      // compact knob OD
// collet (widener mouth) + cap-nut dims
mouth_bore   = duct_od + insert_clear;            // hose slides into this
collet_minor = mouth_bore + 2*collet_wall;        // collet OD at thread root / fingers
collet_major = collet_minor + collet_pitch;       // external thread crest dia
collet_len   = collet_thread_len + collet_finger_len;
nut_id       = collet_major + thread_clearance;   // nut runs over the collet thread
nut_od       = nut_id + 2*nut_wall;               // cap-nut outer dia
hose_hole    = duct_od + 2;                        // nut top/cone throat: hose passes
                                                   //   through, and it squeezes the
                                                   //   142 fingers down onto the hose
// grip rings (inside the collet fingers -- these are what hold the hose)
ring_tip_d  = duct_od - 2*ring_engage;      // ring crest dia: reaches past the hose crest
ring_proj   = (mouth_bore - ring_tip_d)/2;  // radial projection off the bore wall
ring_span   = (ring_count-1)*ring_spacing + ring_thick + ring_proj;  // axial stack height
max_squeeze = collet_minor - hose_hole;     // diametral, at full nut travel

echo(barrel_od=barrel_od, barrel_len=barrel_len, acc_od=acc_od);
echo(barrel_wall_at_root=barrel_wall_at_root);
assert(barrel_od < bore_d, "barrel must be smaller than bore");
assert(barrel_wall_at_root > 1.0, "barrel wall at thread root too thin");
assert(acc_thread_len >= inside_thread_len, "accessory thread must swallow barrel protrusion");
assert(duct_od + insert_clear > airway_d, "duct mouth narrower than airway");
assert(ring_tip_d < duct_od, "grip rings must reach inside the hose crest dia");
assert(collet_finger_len >= ring_start + ring_span + 3,
       "collet fingers too short for the grip-ring stack -- raise collet_finger_len");
assert(hose_hole > duct_od, "nut throat must clear the hose -- this is what jammed the 135 design");
echo(ring_tip_d=ring_tip_d, ring_span=ring_span, max_squeeze=max_squeeze);

// -----------------------------------------------------------------------------
//  THREAD PRIMITIVES   (one spec: same pitch/angle/depth everywhere)
// -----------------------------------------------------------------------------
module male_thread(len) {
    if (show_threads)
        trapezoidal_threaded_rod(d=thread_d, l=len, pitch=thread_pitch,
                     thread_angle=thread_angle, thread_depth=thread_depth,
                     internal=false, bevel1=false, bevel2=true,
                     blunt_start=false, anchor=BOTTOM);
    else
        cylinder(d=barrel_od, h=len);
}

module female_thread_cutter(len) {
    if (show_threads)
        trapezoidal_threaded_rod(d=thread_d, l=len, pitch=thread_pitch,
                     thread_angle=thread_angle, thread_depth=thread_depth,
                     internal=true, bevel=false,
                     $slop=thread_clearance/2, anchor=BOTTOM);
    else
        cylinder(d=thread_d + thread_clearance, h=len);
}

// Generic threads at an arbitrary diameter/pitch (used for the collet + nut).
module ext_thread(d, len, pitch) {
    if (show_threads)
        trapezoidal_threaded_rod(d=d, l=len, pitch=pitch, thread_angle=thread_angle,
                     thread_depth=pitch*0.5, internal=false, bevel1=false,
                     bevel2=true, blunt_start=false, anchor=BOTTOM);
    else cylinder(d=d, h=len);
}
module int_thread_cut(d, len, pitch) {
    if (show_threads)
        trapezoidal_threaded_rod(d=d, l=len, pitch=pitch, thread_angle=thread_angle,
                     thread_depth=pitch*0.5, internal=true, bevel=false,
                     $slop=thread_clearance/2, anchor=BOTTOM);
    else cylinder(d=d + thread_clearance, h=len);
}

// Conical lead-in so a female bore starts onto the thread easily.
module lead_in(z, flip=false) {
    lead = thread_depth + 0.6;
    translate([0,0,z]) {
        if (flip) mirror([0,0,1])
            cylinder(h=lead, r1=thread_d/2+lead, r2=thread_d/2-thread_depth);
        else
            cylinder(h=lead, r1=thread_d/2+lead, r2=thread_d/2-thread_depth);
    }
}

// -----------------------------------------------------------------------------
//  BODY  -- flanged tube threaded both ends.  Origin (Z=0) at the OUTSIDE door
//           face / flange seating face.  Barrel runs +Z (through door, inside).
//           Outboard collar runs -Z (outside / duct or cap port).
// -----------------------------------------------------------------------------
module body() {
    difference() {
        union() {
            // flange (seating face at Z=0, body outside the door at -Z)
            translate([0,0,-flange_t]) cylinder(d=flange_od, h=flange_t);
            // 45deg support cone (collar side) so the flange self-supports.
            // d1 = barrel_minor (thread root) so the cone base is fully carried by
            // the collar thread below it -- no overhanging shelf. See body_cone_h.
            translate([0,0,-flange_t-body_cone_h])
                cylinder(d1=barrel_minor, d2=flange_od, h=body_cone_h);
            // outboard collar (outside port, external thread) below the cone
            translate([0,0,-flange_t-body_cone_h-collar_len]) male_thread(collar_len);
            // barrel (inside port, external thread, through the door)
            male_thread(barrel_len);
        }
        // through airway
        translate([0,0,-flange_t-body_cone_h-collar_len-1])
            cylinder(d=airway_d, h=flange_t+body_cone_h+collar_len+barrel_len+2);
    }
}

// -----------------------------------------------------------------------------
//  ACCESSORY BASE  -- fluted clamp flange + internally-threaded collar (open).
//    Local origin (Z=0) = the face that bears on the door; grows +Z away from
//    the door.  Shared by cap() and widener().
// -----------------------------------------------------------------------------
module accessory_collar(extra_h=0) {
    // solid stock: flange + collar tube (caller cuts the thread + features)
    union() {
        difference() {                          // fluted flange
            cylinder(d=acc_flange_od, h=acc_flange_t);
            for (i=[0:grip_flutes-1])
                rotate([0,0,i*360/grip_flutes])
                    translate([acc_flange_od/2,0,-1]) cylinder(r=grip_r, h=acc_flange_t+2);
        }
        // 45deg support cone under the flange free face (self-supporting)
        translate([0,0,acc_flange_t])
            cylinder(d1=acc_flange_od, d2=acc_od, h=acc_cone_h);
        cylinder(d=acc_od, h=acc_thread_len+extra_h); // collar
    }
}

// female thread + clearance counterbore (swallows barrel tip) + lead-in
module accessory_bore() {
    translate([0,0,-0.5]) female_thread_cutter(acc_thread_len+0.5);
    translate([0,0,acc_thread_len-0.01])
        cylinder(d=acc_clear_d, h=acc_clear_depth+0.02);
    lead_in(-0.01);                              // door-side entry lead-in
}

// height from the door-bearing face up to the top of the clearance counterbore
acc_stack_h = acc_thread_len + acc_clear_depth;

// -----------------------------------------------------------------------------
//  CAP  -- closed-top accessory.  Seals / blanks a port and clamps the door.
// -----------------------------------------------------------------------------
module cap() {
    difference() {
        accessory_collar(extra_h=acc_clear_depth+cap_top_t); // solid top = seal
        accessory_bore();                          // thread + counterbore below
    }
}

// slots that split the collet into fingers (cut from the rim down, leaving the
// threaded base solid so the nut always has full thread to run on)
module collet_slots_cut(flat_z) {
    slot_z0 = flat_z + collet_thread_len;          // slots start above the thread
    slot_h  = collet_finger_len + 1;
    for (i=[0:collet_slots-1]) rotate([0,0, i*360/collet_slots + 180/collet_slots])
        translate([0, -collet_slot_w/2, slot_z0])
            cube([collet_major/2+2, collet_slot_w, slot_h]);
}

// -----------------------------------------------------------------------------
//  NET GRILLE  -- a printable square mesh disc (bars bridge the gaps, so it
//                 prints flat with no support).  Clipped to diameter d.
// -----------------------------------------------------------------------------
module net_grille(d, t) {
    pitch = grille_bar + grille_gap;
    n = ceil(d/pitch);
    intersection() {
        cylinder(d=d, h=t);
        union() {
            // rim ring so the mesh is tied to the collar wall
            difference() {
                cylinder(d=d, h=t);
                translate([0,0,-0.5]) cylinder(d=d-2*grille_bar, h=t+1);
            }
            // crossed bars
            for (i=[-n:n]) {
                translate([i*pitch, 0, t/2]) cube([grille_bar, d, t], center=true);
                translate([0, i*pitch, t/2]) cube([d, grille_bar, t], center=true);
            }
        }
    }
}

// -----------------------------------------------------------------------------
//  PLAIN (OUTSIDE) BASE  -- compact threaded knob with a light knurl.  Screws
//    onto the outboard collar.  NO clamp flange -- the body flange is already on
//    the outside, so we don't stack a second gear on it.  Origin Z=0 = open end.
// -----------------------------------------------------------------------------
module plain_collar(extra_h=0) {
    difference() {
        cylinder(d=out_od, h=out_engage+extra_h);
        for (i=[0:out_flutes-1])                  // light knurl
            rotate([0,0,i*360/out_flutes])
                translate([out_od/2,0,-1]) cylinder(r=out_flute_r, h=out_engage+extra_h+2);
    }
}

module plain_bore() {
    translate([0,0,-0.5]) female_thread_cutter(out_engage+0.5);
    lead_in(-0.01);
}

// CAP_OUT -- plain closed cap for the outside port (winter blank).
module cap_out() {
    difference() {
        plain_collar(extra_h=cap_top_t);          // solid top = the seal
        plain_bore();
    }
}

// NET_OUT -- plain bug-vent for the outside port.  Mesh sits above the collar
//            tip (net_standoff) so the core never reaches it.
module net_out() {
    grille_z = out_engage + net_standoff;
    union() {
        difference() {
            plain_collar(extra_h=net_standoff);
            plain_bore();
            translate([0,0,out_engage-0.01])      // open chamber to the grille
                cylinder(d=acc_clear_d, h=net_standoff+0.02);
        }
        translate([0,0,grille_z]) net_grille(out_od, grille_t);
    }
}

// -----------------------------------------------------------------------------
//  HOSE GRIP RINGS  -- plain circumferential barbs inside the collet mouth.
//
//  NOT a helical thread. The OEM adapter that ships with these units uses plain
//  rings and the hose still screws in fine, because the hose's helical rib flexes
//  to ride over them. Rings are also far more forgiving: a helix accumulates
//  phase error every turn, whereas each ring only has to land somewhere in the
//  ~5.5mm valley between hose ribs, so a few tenths of pitch error never matters.
//
//  Profile is asymmetric (a barb):
//    - the mouth-facing side is a 45deg ramp -> the hose feeds in easily, AND it
//      is the DOWN-facing side when printed mouth-down, so it self-supports.
//    - the flange-facing side is square -> it bites on pull-out.
// -----------------------------------------------------------------------------
module hose_barbs(z0) {
    Rb = mouth_bore/2;                 // bore wall
    Rt = ring_tip_d/2;                 // ring crest (reaches past the hose crest)
    for (i = [0:ring_count-1])
        translate([0,0, z0 + i*ring_spacing])
            rotate_extrude(convexity=4)
                polygon([[Rb, 0],
                         [Rt, 0],                        // square biting face
                         [Rt, ring_thick],               // crest
                         [Rb, ring_thick + ring_proj]]); // 45deg feed ramp
}

// -----------------------------------------------------------------------------
//  WIDENER  -- flares to a COLLET mouth the AC hose pushes into. The collet's
//              base is externally threaded for the separate cap-nut (collet_nut),
//              which screws over the hose and squeezes the fingers onto it.
//              Print MOUTH-DOWN.
// -----------------------------------------------------------------------------
module widener() {
    flare_z   = acc_stack_h;
    flat_z    = flare_z + flare_len;
    mouth_top = flat_z + collet_len;
    difference() {
        union() {
            // hollow mouth first, THEN add the barbs -- otherwise the bore cut
            // would swallow them.
            difference() {
                union() {
                    accessory_collar(extra_h=acc_clear_depth);  // flange + collar + cbore
                    translate([0,0,flare_z])                     // steep flare to collet root
                        cylinder(d1=acc_od, d2=collet_minor, h=flare_len);
                    translate([0,0,flat_z])                      // threaded base for the nut
                        ext_thread(collet_major, collet_thread_len, collet_pitch);
                    translate([0,0,flat_z+collet_thread_len-0.01]) // slotted fingers
                        cylinder(d=collet_minor, h=collet_finger_len);
                }
                accessory_bore();
                // bore: flare then straight (stays >= airway throughout)
                translate([0,0,flare_z-0.01])
                    cylinder(d1=acc_clear_d, d2=mouth_bore, h=flare_len+0.02);
                translate([0,0,flat_z-0.01]) cylinder(d=mouth_bore, h=collet_len+0.02);
                // external chamfer on the finger tips (lead for the nut cone)
                translate([0,0,mouth_top-0.01])
                    cylinder(h=3.5, r1=collet_minor/2+0.2, r2=collet_minor/2-3);
            }
            // grip rings, on the fingers so the nut's squeeze drives them home
            hose_barbs(flat_z + collet_thread_len + ring_start);
        }
        collet_slots_cut(flat_z);      // slots split the fingers AND the rings
    }
}

// -----------------------------------------------------------------------------
//  COLLET NUT  -- separate printed clamp. Goes over the hose, screws onto the
//    collet's external thread; the inner cone squeezes the fingers onto the hose
//    as it tightens.  Hand on/off, no hardware.  Print THREAD-AXIS VERTICAL.
// -----------------------------------------------------------------------------
module collet_nut() {
    h = collet_len + 3;                               // spans thread + fingers
    difference() {
        // fluted knurl body
        difference() {
            cylinder(d=nut_od, h=h);
            for (i=[0:nut_flutes-1]) rotate([0,0,i*360/nut_flutes])
                translate([nut_od/2,0,-1]) cylinder(r=2.6, h=h+2);
        }
        // internal thread over the base (engages the collet)
        translate([0,0,-0.5]) int_thread_cut(collet_major, collet_thread_len+2, collet_pitch);
        // clearance bore over the fingers, then the squeeze cone, then hose hole
        translate([0,0,collet_thread_len])
            cylinder(d=collet_major+1, h=collet_finger_len-nut_cone+0.5);
        translate([0,0,collet_thread_len+collet_finger_len-nut_cone])  // squeeze cone
            cylinder(d1=collet_major+1, d2=hose_hole, h=nut_cone);
        translate([0,0,collet_thread_len+collet_finger_len-0.01])      // hose pass-through
            cylinder(d=hose_hole, h=4);
    }
}

// -----------------------------------------------------------------------------
//  NUT SPANNER  -- printed C-wrench for the collet nut.
//
//  WHY: the nut is O167 with only a 2.6mm knurl (the 4mm wall will not allow a
//  deeper one), so by hand you are relying on fingertip friction on a very large
//  diameter and simply cannot generate the torque to close the fingers. Adding
//  hand-grip lugs was considered and rejected -- the force needed is tool
//  territory, not hand territory. (User's call, and correct.)
//
//  The jaw must go on SIDEWAYS: the widener's flare blocks axial entry from one
//  end and the hose blocks the other. A 180deg wrap slides straight on, since a
//  half-circle's opening equals the full diameter -- no flexing needed. Teeth sit
//  on the middle arc only, so the mouth of the jaw stays clear on the way in.
//
//  Print FLAT ON THE PLATE. Every wall is vertical -- no overhangs at all.
// -----------------------------------------------------------------------------
module c_spanner(target_od, flutes, flute_r, tooth_h, jaw_h, handle_len) {
    Rb = target_od/2 + spanner_slop/2;              // jaw bore
    Ro = Rb + spanner_wall;                         // jaw outside
    union() {
        // --- jaw: a ring masked to the wrap sector -------------------------------
        intersection() {
            difference() {
                cylinder(r=Ro, h=jaw_h);
                translate([0,0,-1]) cylinder(r=Rb, h=jaw_h+2);
            }
            rotate([0,0,90 - spanner_wrap/2])
                rotate_extrude(angle=spanner_wrap, convexity=4)
                    polygon([[0.1,0],[Ro+2,0],[Ro+2,jaw_h],[0.1,jaw_h]]);
        }
        // --- teeth filling the target's scallops ---------------------------------
        //  tooth_h is capped at the scallop's depth in Z: on the widener the flange
        //  is only 6mm thick and a 45deg cone starts immediately above it, so a
        //  taller tooth would foul the cone.
        for (i = [0:flutes-1]) {
            a = i*360/flutes;
            if (a >= 90 - spanner_teeth_arc/2 && a <= 90 + spanner_teeth_arc/2)
                rotate([0,0,a]) translate([target_od/2, 0, 0])
                    cylinder(r = flute_r - spanner_slop/2, h = tooth_h);
        }
        // --- handle, radial off the closed side ----------------------------------
        //  trimmed at the jaw bore, or its root blob intrudes into the target.
        difference() {
            hull() {
                translate([0, Rb, 0]) cylinder(d=spanner_grip_w+16, h=jaw_h);
                translate([0, Ro + handle_len, 0]) cylinder(d=spanner_grip_w, h=jaw_h);
            }
            translate([0,0,-1]) cylinder(r=Rb, h=jaw_h+2);
        }
    }
}

// Big spanner: turns the collet nut.
module nut_spanner() {
    c_spanner(nut_od, nut_flutes, 2.6, spanner_h, spanner_h, spanner_handle);
}

// Small spanner: HOLDS the widener while the nut is turned. Without it, tightening
// the nut torques the widener backwards and unscrews it from the body -- i.e. it
// releases the door clamp. Two-spanner job, exactly like a plumbing fitting.
// Grips the widener's clamp flange, whose 7mm scallops bite far better than the
// nut's 2.6mm knurl. Jaw is taller than the teeth for strength: a 5.6mm-thick
// handle would only take ~17Nm, which is not enough to hold against the big one.
module widener_spanner() {
    c_spanner(acc_flange_od, grip_flutes, grip_r, acc_flange_t - 0.4,
              wspanner_h, wspanner_handle);
}

// -----------------------------------------------------------------------------
//  HOSE STUB  (visualisation only) -- a length of ribbed AC hose, so the previews
//    show the grip rings actually sitting in the rib valleys. Modelled as a
//    helical rib at hose_rib_pitch; the real hose is helical and our rings are not,
//    and the rings are deliberately not spaced to match it -- the hose flexes.
// -----------------------------------------------------------------------------
module hose_stub(len=50) {
    difference() {
        trapezoidal_threaded_rod(d=duct_od, l=len, pitch=hose_rib_pitch, thread_angle=55,
            thread_depth=2.5, internal=false, bevel1=false, bevel2=false,
            blunt_start=false, anchor=BOTTOM);
        translate([0,0,-1]) cylinder(d=duct_od-12, h=len+2);
    }
}

// -----------------------------------------------------------------------------
//  TEST COUPON  -- short male stub (+ thin base) to fit-check against the CAP.
// -----------------------------------------------------------------------------
module test_coupon() {
    coupon_len = 20;
    cylinder(d=acc_od, h=2);                       // bed-adhesion base
    translate([0,0,2]) male_thread(coupon_len);
    translate([0,0,-0.01]) cylinder(d=airway_d, h=0.02); // (label the airway)
}

// -----------------------------------------------------------------------------
//  DOOR  (visualisation only)
// -----------------------------------------------------------------------------
module door() {
    door_w = flange_od + 30;
    difference() {
        translate([-door_w/2,-door_w/2,0]) cube([door_w,door_w,door_thickness]);
        translate([0,0,-1]) cylinder(d=bore_d, h=door_thickness+2);
    }
}

// -----------------------------------------------------------------------------
//  ASSEMBLED  -- body through door, widener clamped on the inside, cap on the
//    outboard collar (outside).  Accessory flanges sit a pitch-multiple away so
//    threads phase-mate in the render.
// -----------------------------------------------------------------------------
module assembly() {
    color("SteelBlue")        body();
    color("Gainsboro", 0.45)  door();
    // widener on the inside: flange bears on the inside door face (Z=door_thickness)
    color("Goldenrod")        translate([0,0,door_thickness]) widener();
    // plain cap on the outboard collar (outside): compact knob, no stacked flange
    color("IndianRed")
        translate([0,0,-flange_t-body_cone_h]) mirror([0,0,1]) cap_out();
}

// -----------------------------------------------------------------------------
//  RENDER SELECTOR
// -----------------------------------------------------------------------------
if      (render_part == "body")     body();
else if (render_part == "cap")      cap();
else if (render_part == "cap_out")  cap_out();
else if (render_part == "net_out")  net_out();
// widener + collet_nut are EXPORTED ALREADY FLIPPED into their print orientation
// (mouth-down / hole-end-down), so dropping the file on the plate is correct with
// no manual rotate. Printed the other way up the grip rings' square biting faces
// become 31cm2 of dead-flat ceiling and bridge badly -- which is exactly what
// happened on the first widener. The assembly/section views call widener() and
// collet_nut() directly, so they are unaffected by this.
else if (render_part == "widener")    rotate([180,0,0]) widener();
else if (render_part == "collet_nut") rotate([180,0,0]) collet_nut();
else if (render_part == "clampdemo")
    difference() {
        union() {
            color("SteelBlue") widener();
            color("Goldenrod") translate([0,0, acc_stack_h+flare_len]) collet_nut();
            color("Gainsboro") translate([0,0, acc_stack_h+flare_len+8])
                hose_stub(50);                                 // ribbed hose, screwed in
        }
        translate([-300,-300,-300]) cube([600,300,900]);
    }
else if (render_part == "spanner")  nut_spanner();
else if (render_part == "spanner_w") widener_spanner();
else if (render_part == "test")     test_coupon();
else if (render_part == "assembly") assembly();
else if (render_part == "section")
    difference() { assembly(); translate([-300,-300,-300]) cube([600,300,900]); }
