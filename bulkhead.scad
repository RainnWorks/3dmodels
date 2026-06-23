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
render_part = "body";  // body|cap|cap_out|net_out|widener|collet_nut|assembly|section|test

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

// ---- Net vent cap (bug screen; passive airflow) -----------------------------
net_standoff = 4;   // gap between collar tip and the grille, so the Ø-barrel
                    //   core never reaches the mesh
grille_t     = 2.5; // grille thickness
grille_bar   = 1.5; // mesh bar width
grille_gap   = 2.0; // mesh opening (smaller = stops smaller bugs, less airflow)

// ---- Outside (plain) caps -- screw onto the outboard collar, NO clamp flange
//      (the body flange is already on the outside; don't stack a 2nd gear on it)
out_engage  = collar_len; // female-thread depth (matches the outboard collar)
out_flutes  = 16;         // light knurl for finger grip (not the big gear)
out_flute_r = 3;

// ---- Widener (duct funnel)  (MEASURE THE DUCT) ------------------------------
duct_od     = 135; // AC hose OD; the hose inserts INTO the mouth. Tuned from a
                   //   test print: duct_od 130 (138 mouth OD) was slightly small,
                   //   so +5mm -> 135 gives a 143 mouth OD / 137 bore.
insert_clear = 2.0;// mouth ID = duct_od + this  (slide-in clearance)
flare_len   = 16;  // steep flare height: throat -> mouth (short = widens fast)
// hose clamp = ALL-PRINTED collet + screw-on cap-nut (no hardware). The mouth is
// a slotted collet with an external thread on its base; the separate cap-nut goes
// over the hose and screws down, its inner cone squeezing the collet onto the
// hose.  The nut (collet_nut) is its own model.
collet_thread_len = 14;  // externally-threaded base of the collet (nut runs on this)
collet_finger_len = 20;  // slotted fingers above the thread (these get squeezed)
collet_slots      = 6;   // number of slots / fingers
collet_slot_w     = 3;   // slot width
collet_wall       = 2.5; // collet wall at the thread root
collet_pitch      = 6;   // coarse external thread (nut clamps in ~1 turn)
nut_wall          = 4;   // cap-nut wall thickness
nut_flutes        = 18;  // knurl on the cap-nut for grip
nut_cone          = 10;  // axial length of the nut's squeeze cone

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
            accessory_collar(extra_h=acc_clear_depth);   // flange + collar + cbore
            translate([0,0,flare_z])                      // steep flare to collet root
                cylinder(d1=acc_od, d2=collet_minor, h=flare_len);
            translate([0,0,flat_z])                       // threaded base for the nut
                ext_thread(collet_major, collet_thread_len, collet_pitch);
            translate([0,0,flat_z+collet_thread_len-0.01]) // smooth slotted fingers
                cylinder(d=collet_minor, h=collet_finger_len);
        }
        accessory_bore();
        // bore: flare then straight (stays >= airway throughout)
        translate([0,0,flare_z-0.01]) cylinder(d1=acc_clear_d, d2=mouth_bore, h=flare_len+0.02);
        translate([0,0,flat_z-0.01])  cylinder(d=mouth_bore, h=collet_len+0.02);
        // external chamfer on the finger tips (lead for the nut cone) + slots
        translate([0,0,mouth_top-0.01])
            cylinder(h=3.5, r1=collet_minor/2+0.2, r2=collet_minor/2-3);
        collet_slots_cut(flat_z);
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
else if (render_part == "widener")  widener();
else if (render_part == "collet_nut") collet_nut();
else if (render_part == "clampdemo")
    difference() {
        union() {
            color("SteelBlue") widener();
            color("Goldenrod") translate([0,0, acc_stack_h+flare_len]) collet_nut();
            color("Gainsboro") translate([0,0, acc_stack_h+flare_len+8])   // hose stub
                difference() { cylinder(d=duct_od, h=50); translate([0,0,-1]) cylinder(d=duct_od-8, h=52); }
        }
        translate([-300,-300,-300]) cube([600,300,900]);
    }
else if (render_part == "test")     test_coupon();
else if (render_part == "assembly") assembly();
else if (render_part == "section")
    difference() { assembly(); translate([-300,-300,-300]) cube([600,300,900]); }
