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
//    * Screw-on ACCESSORIES clamp the door themselves: each has a flange that
//      bears on the door, so screwing it down traps the door between the body
//      flange (outside) and the accessory flange (inside). The accessory IS the
//      clamp -- no separate nut.
//        - CAP      = flanged, closed top.  Winter seal / blanking plate.
//        - WIDENER  = flanged, flares out to a mouth the AC hose INSERTS INTO;
//                     internal helical tabs grip the hose's spiral (twist on).
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
//    WIDENER  -> MOUTH DOWN (mouth ring on the plate, flange on top). Flare and
//                flange cone both self-support. The only marginal feature is the
//                internal helical tabs (~4mm bridge) -- if they sag in PLA, dab
//                support on just those, or raise tab_r.
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
// -----------------------------------------------------------------------------
render_part = "body";  // "body"|"cap"|"widener"|"assembly"|"section"|"test"

// ---- Hole / door (MEASURE THESE) --------------------------------------------
bore_d         = 86;    // TODO MEASURE: drilled hole diameter in the door [mm]
door_thickness = 40;    // TODO MEASURE: door thickness [mm]

// ---- Fit --------------------------------------------------------------------
fit_clearance  = 1.0;   // barrel OD = bore_d - fit_clearance (loose drop-in)

// ---- Thread (coarse; one spec used everywhere) ------------------------------
thread_pitch     = 5.0;  // coarse, 4-6 mm
thread_clearance = 0.45; // diametral clearance male<->female (0.4-0.5)
thread_angle     = 50;   // flank angle -- larger = sloped flanks that self-support
                         //   (downward flank ~45deg overhang, no flat underside)
thread_depth     = thread_pitch * 0.5;  // shallow, robust printed engagement

// ---- Barrel / ports ---------------------------------------------------------
inside_thread_len  = 20; // barrel thread protruding inside (nut/accessory travel;
                         //   absorbs door-thickness error, 15-20mm)
collar_len         = 14; // outboard (outside) threaded port length
airway_d           = 74; // clear through-airway diameter (keep airflow open)
wall               = 3.0;// nominal wall thickness

// ---- Flange (outside, seats on door) ----------------------------------------
flange_od = bore_d + 29; // bore + ~28-30  -> ~14-15mm seating ring
flange_t  = 5;           // flange thickness

// ---- Accessories (cap / widener) shared base --------------------------------
acc_flange_od  = bore_d + 29; // clamp + grip flange on accessories
acc_flange_t   = 6;           // accessory flange thickness
acc_thread_len = 20;          // internal thread depth (= barrel inside port)
acc_clear_depth = 8;          // clearance counterbore above thread: swallows the
                              //   barrel tip when the door is THINNER than nominal
grip_flutes    = 14;          // hand-grip scallops on accessory rim
grip_r         = 7;           // scallop cutter radius

// ---- Cap --------------------------------------------------------------------
cap_top_t = 4;   // closed-end thickness

// ---- Widener (duct funnel)  (MEASURE THE DUCT) ------------------------------
duct_od     = 130; // TODO MEASURE: AC hose OD; the hose inserts INTO the mouth
insert_clear = 2.0;// mouth ID = duct_od + this  (slide-in clearance)
flare_len   = 16;  // steep flare height: throat -> mouth (short = widens fast)
flat_len    = 30;  // straight mouth section the hose inserts into
// internal helical grip tabs -- the hose's spiral twists into these (like a
// coarse interrupted thread).  See the reference photo.
tab_count    = 3;   // number of helical tabs around the inside
tab_arc      = 75;  // angular span of each tab [deg]
tab_pitch    = 14;  // helix lead [mm/turn]; TODO match the hose's rib pitch
tab_protrude = 4.0; // how far each tab sticks inward [mm]
tab_r        = 3.0; // tab cross-section radius (thickness)

// ---- Printability -----------------------------------------------------------
support_cones = true;  // 45deg cones under the flanges so they print self-supporting

// ---- Quality ----------------------------------------------------------------
show_threads = true;   // false = plain bores/barrel for a fast proportions check
$fa = 2;
$fs = 0.8;

// -----------------------------------------------------------------------------
//  DERIVED + SANITY CHECKS
// -----------------------------------------------------------------------------
barrel_od  = bore_d - fit_clearance;            // thread MAJOR diameter
thread_d   = barrel_od;
barrel_len = door_thickness + inside_thread_len;// barrel: door + inside port
acc_od     = thread_d + 2*wall;                 // accessory threaded-collar OD
acc_clear_d = barrel_od + 1;                    // counterbore dia (clears barrel)
barrel_minor = thread_d - 2*thread_depth;
barrel_wall_at_root = (barrel_minor - airway_d)/2;
body_cone_h = support_cones ? (flange_od - barrel_od)/2 : 0;  // 45deg, flange->collar
acc_cone_h  = support_cones ? (acc_flange_od - acc_od)/2  : 0; // 45deg, flange->collar

echo(barrel_od=barrel_od, barrel_len=barrel_len, acc_od=acc_od);
echo(barrel_wall_at_root=barrel_wall_at_root);
assert(barrel_od < bore_d, "barrel must be smaller than bore");
assert(barrel_wall_at_root > 1.0, "barrel wall at thread root too thin");
assert(acc_thread_len >= inside_thread_len, "accessory thread must swallow barrel protrusion");
assert(duct_od + insert_clear > airway_d, "duct mouth narrower than airway");

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
            // 45deg support cone (collar side) so the flange self-supports
            translate([0,0,-flange_t-body_cone_h])
                cylinder(d1=barrel_od, d2=flange_od, h=body_cone_h);
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

// one internal helical tab: a rounded rib swept along a helix arc, protruding
// inward from the mouth wall.  The hose's spiral twists into these.
module helical_tab(bore_r, z0, arc, pitch, rr, protrude) {
    rc = bore_r - protrude + rr;                   // path radius (innermost = bore_r-protrude)
    steps = max(6, ceil(arc/6));
    for (i=[0:steps-1]) hull() {
        a0 = i*arc/steps; a1 = (i+1)*arc/steps;
        translate([rc*cos(a0), rc*sin(a0), z0+(a0/360)*pitch]) sphere(r=rr);
        translate([rc*cos(a1), rc*sin(a1), z0+(a1/360)*pitch]) sphere(r=rr);
    }
}

// -----------------------------------------------------------------------------
//  WIDENER  -- steep flare to a straight mouth the AC hose INSERTS INTO; internal
//              helical tabs grip the hose's spiral (twist to engage). Clamps the
//              door like the cap.  Best printed MOUTH-DOWN (flare self-supports).
// -----------------------------------------------------------------------------
module widener() {
    mouth_id = duct_od + insert_clear;             // hose slides into this
    mouth_od = mouth_id + 2*wall;
    flare_z  = acc_stack_h;
    flat_z   = flare_z + flare_len;
    tab_rise = (tab_arc/360)*tab_pitch;
    tab_z0   = flat_z + (flat_len - tab_rise)/2;   // centre tabs in the flat band
    union() {
        difference() {
            union() {
                accessory_collar(extra_h=acc_clear_depth); // flange + collar + cbore
                translate([0,0,flare_z])                    // steep flare
                    cylinder(d1=acc_od, d2=mouth_od, h=flare_len);
                translate([0,0,flat_z])                     // straight mouth
                    cylinder(d=mouth_od, h=flat_len);
            }
            accessory_bore();
            // bore: flare then straight (stays >= airway throughout)
            translate([0,0,flare_z-0.01]) cylinder(d1=acc_clear_d, d2=mouth_id, h=flare_len+0.02);
            translate([0,0,flat_z-0.01])  cylinder(d=mouth_id, h=flat_len+0.02);
        }
        // internal helical grip tabs (added after the bore so they protrude in)
        for (i=[0:tab_count-1]) rotate([0,0,i*360/tab_count])
            helical_tab(mouth_id/2, tab_z0, tab_arc, tab_pitch, tab_r, tab_protrude);
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
    // cap on the outboard collar (outside): flange bears on the flange face
    color("IndianRed")
        translate([0,0,-flange_t]) mirror([0,0,1]) cap();
}

// -----------------------------------------------------------------------------
//  RENDER SELECTOR
// -----------------------------------------------------------------------------
if      (render_part == "body")     body();
else if (render_part == "cap")      cap();
else if (render_part == "widener")  widener();
else if (render_part == "test")     test_coupon();
else if (render_part == "assembly") assembly();
else if (render_part == "section")
    difference() { assembly(); translate([-300,-300,-300]) cube([600,300,900]); }
