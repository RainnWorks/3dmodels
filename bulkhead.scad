// =============================================================================
//  Bulkhead fan-duct fitting  --  two-part, parametric  (OpenSCAD + BOSL2)
// =============================================================================
//  Mounts a portable fan duct through a hole drilled in a door.
//
//  HOW IT WORKS
//    * BODY  = flange + outer spigot + threaded barrel. Goes through the hole
//      from the OUTSIDE. Flange seats on the outside face of the door.
//    * NUT   = fluted ring nut. Screws onto the barrel from the INSIDE and
//      clamps the door between flange and nut. The printed thread does the
//      clamping; the barrel is a loose fit in the bore, so bore slop is
//      non-structural.
//    * Duct connects (assumed) push-fit over the outer spigot.
//
//  ---------------------------------------------------------------------------
//  PRINT NOTES   (Bambu X1/P1, PETG)
//  ---------------------------------------------------------------------------
//  ORIENTATION
//    BODY  -> print SPIGOT-DOWN: duct boss flat on the plate, barrel + threads
//             pointing UP. This keeps the flange's door-SEATING face pointing
//             up so it prints flat and clean, and puts the thread on a vertical
//             axis. The flange's duct-side underside is a ~14mm annular
//             overhang -> turn on supports there (non-critical cosmetic face)
//             or add a brim. Seating face and threads need no support.
//    NUT   -> print FLAT on the plate, either face down. Internal trapezoidal
//             thread (30 deg flanks, flat crests) is self-supporting -> NO
//             supports. The flutes are the hand grip.
//
//  THREAD DIRECTION (why it prints clean)
//    Print BOTH parts with the THREAD AXIS VERTICAL. Each layer is then a
//    continuous ring climbing one pitch - no bridging across the helix, so the
//    coarse trapezoidal crests come out crisp. Male thread tip faces UP on the
//    body; the female thread is a vertical bore in the nut.
//
//  PETG SETTINGS (start from your Bambu PETG profile, then)
//    nozzle 0.4mm | layer 0.20mm (0.16 for finer crests)
//    walls 3-4 perimeters  (barrel wall is solid wall-to-wall at ~3mm)
//    infill 25-40% gyroid  | nozzle ~250-260C | bed ~70-80C
//    part cooling 30-50%   | slow first layer | no vase mode | no ironing
//
//  TOLERANCE
//    thread_clearance = 0.45mm diametral is tuned for PETG on a Bambu.
//    Nut too tight -> raise thread_clearance; sloppy -> lower it; reprint just
//    the nut to dial it in (cheap, fast). Barrel is a deliberate loose fit in
//    the bore (fit_clearance = 1mm); the clamp - not the bore - holds it.
// =============================================================================

include <BOSL2/std.scad>
include <BOSL2/threading.scad>

// -----------------------------------------------------------------------------
//  PARAMETER BLOCK  -- everything dimension-driving lives here
// -----------------------------------------------------------------------------
render_part   = "body";   // "body" | "nut" | "assembly" | "section"

// ---- Hole / door (MEASURE THESE) --------------------------------------------
bore_d         = 86;    // TODO MEASURE: drilled hole diameter in the door [mm]
door_thickness = 40;    // TODO MEASURE: door thickness [mm]

// ---- Fit -------------------------------------------------------------------
fit_clearance  = 1.0;   // barrel OD = bore_d - fit_clearance (loose drop-in)

// ---- Thread (coarse, prints clean at large dia) -----------------------------
thread_pitch     = 5.0;  // coarse, 4-6 mm
thread_clearance = 0.45; // diametral clearance male<->female (0.4-0.5)
thread_length    = 18;   // nut-travel / engagement zone beyond nominal door
                         //   (15-20mm; absorbs door-thickness error)
thread_angle     = 30;   // trapezoidal flank half-angle (flat crests print clean)
thread_depth     = thread_pitch * 0.5;  // shallow, robust printed engagement

// ---- Flange (outside, seats on door) ----------------------------------------
flange_od = bore_d + 29; // bore + ~28-30  -> ~14-15mm seating ring
flange_t  = 5;           // flange thickness

// ---- Ring nut (inside) ------------------------------------------------------
nut_od     = bore_d + 29;  // matches flange OD
nut_h      = 16;           // nut height
nut_flutes = 14;           // hand-grip scallops around the rim
flute_r    = 7;            // scallop cutter radius (deeper = grippier)

// ---- Outer spigot (duct push-fit) -------------------------------------------
spigot_od  = 80;   // TODO MEASURE duct: push-fit, just UNDER duct inner dia
spigot_len = 25;   // TODO confirm: spigot length the duct slips over

// ---- General ----------------------------------------------------------------
wall      = 3.0;   // nominal wall thickness
airway_d  = 74;    // clear through-airway diameter (keep airflow open)

// ---- Dev toggles ------------------------------------------------------------
show_threads = true;   // false = plain barrel/bore for a fast proportions check
$fa = 2;
$fs = 0.6;

// -----------------------------------------------------------------------------
//  DERIVED + SANITY CHECKS
// -----------------------------------------------------------------------------
barrel_od = bore_d - fit_clearance;          // thread MAJOR diameter
thread_d  = barrel_od;
barrel_len = door_thickness + thread_length; // fully threaded barrel length
barrel_minor = thread_d - 2*thread_depth;
barrel_wall_at_root = (barrel_minor - airway_d)/2;

echo(barrel_od=barrel_od, barrel_len=barrel_len);
echo(barrel_minor=barrel_minor, barrel_wall_at_root=barrel_wall_at_root);
assert(barrel_od < bore_d, "barrel must be smaller than bore");
assert(airway_d < spigot_od - 2*0.8, "airway leaves no spigot wall");
assert(barrel_wall_at_root > 1.0, "barrel wall at thread root too thin");

// -----------------------------------------------------------------------------
//  MALE THREAD on the barrel  (major dia = barrel_od)
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

// -----------------------------------------------------------------------------
//  BODY  -- flange + spigot + barrel.  Origin at flange seating face (Z=0).
//           Barrel runs +Z (through door / inside).  Spigot runs -Z (duct).
// -----------------------------------------------------------------------------
module body() {
    difference() {
        union() {
            // flange (seating face at Z=0, body below)
            translate([0,0,-flange_t])
                cylinder(d=flange_od, h=flange_t);
            // outer spigot (duct side, -Z)
            translate([0,0,-flange_t-spigot_len])
                cylinder(d=spigot_od, h=spigot_len);
            // threaded barrel (+Z, through door to inside)
            male_thread(barrel_len);
        }
        // through airway
        translate([0,0,-flange_t-spigot_len-1])
            cylinder(d=airway_d, h=flange_t+spigot_len+barrel_len+2);
    }
}

// -----------------------------------------------------------------------------
//  FEMALE THREAD cutter (for the nut bore).  $slop gives running clearance.
// -----------------------------------------------------------------------------
module female_thread_cutter(len) {
    if (show_threads)
        trapezoidal_threaded_rod(d=thread_d, l=len, pitch=thread_pitch,
                     thread_angle=thread_angle, thread_depth=thread_depth,
                     internal=true, bevel=false,
                     $slop=thread_clearance/2, anchor=BOTTOM);
    else
        cylinder(d=thread_d + thread_clearance, h=len);
}

// -----------------------------------------------------------------------------
//  RING NUT  -- fluted hand grip, internal thread, clear bore.
//              Sits base at Z=0, grows +Z.
// -----------------------------------------------------------------------------
module nut() {
    difference() {
        // fluted blank
        difference() {
            cylinder(d=nut_od, h=nut_h);
            for (i = [0:nut_flutes-1])
                rotate([0,0,i*360/nut_flutes])
                    translate([nut_od/2, 0, -1])
                        cylinder(r=flute_r, h=nut_h+2);
        }
        // threaded bore (its minor dia > airway_d, so airway stays clear)
        translate([0,0,-0.5]) female_thread_cutter(nut_h+1);
        // conical lead-in chamfers, both ends, so the nut starts easily
        lead = thread_depth + 0.6;
        translate([0,0,-0.01])
            cylinder(h=lead, r1=thread_d/2+lead, r2=thread_d/2-thread_depth);
        translate([0,0,nut_h+0.01]) mirror([0,0,1])
            cylinder(h=lead, r1=thread_d/2+lead, r2=thread_d/2-thread_depth);
    }
}

// -----------------------------------------------------------------------------
//  DOOR  (visualisation only)  -- slab with the drilled bore, Z=0..door_thickness
// -----------------------------------------------------------------------------
module door() {
    door_w = flange_od + 30;
    difference() {
        translate([-door_w/2, -door_w/2, 0]) cube([door_w, door_w, door_thickness]);
        translate([0,0,-1]) cylinder(d=bore_d, h=door_thickness+2);
    }
}

// -----------------------------------------------------------------------------
//  ASSEMBLED  -- body through door, nut run down to the inside face.
//    Nut placed at an integer number of pitches so its thread phase-mates
//    the body thread in the render.
// -----------------------------------------------------------------------------
nut_z = round(door_thickness/thread_pitch) * thread_pitch;  // inside face, in phase

module assembly() {
    color("SteelBlue")  body();
    color("Gainsboro", 0.35) door();
    // nut flipped so its lead-in faces the door, clamping face against inside
    color("Goldenrod") translate([0,0,nut_z + nut_h]) mirror([0,0,1]) nut();
}

// -----------------------------------------------------------------------------
//  RENDER SELECTOR
// -----------------------------------------------------------------------------
if (render_part == "body")      body();
else if (render_part == "nut")  nut();
else if (render_part == "assembly")  assembly();
else if (render_part == "section")
    difference() { assembly(); translate([-200,-200,-200]) cube([400,200,600]); }
