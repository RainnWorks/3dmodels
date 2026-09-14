// =============================================================================
// XIAO ESP32-S3 + Wio-SX1262 Velux bridge enclosure
// =============================================================================
// Two-piece, support-free enclosure for the stacked XIAO/Wio radio bridge and
// both supplied adhesive-backed FPC antennas.  The antennas face outwards from
// opposite side walls, keeping the plan area close to the antenna envelope and
// avoiding a PCB directly behind either radiator.  The XIAO's installed 2x7
// pin headers locate in printed sockets on their standard 2.54 mm grid.
//
// Print orientation:
//   base : floor on the build plate
//   lid  : smooth outside face on the build plate; antenna guides face upward
//
// Dimensions below come from Seeed's official CAD and antenna documentation.
// The stacked height is deliberately conservative because the two STEP models
// describe the boards separately and the mating connector overlaps in use.
// =============================================================================

/* [Part to make] */
render_part = "assembly"; // [base:Base, lid:Lid, print_plate:Both printable parts, assembly:Exploded fitted preview, layout:Antenna and board layout, cutaway:Enclosure cutaway, fit_test:Complete board locator test]
function captive_usb() = !is_undef(usb_mode) && usb_mode == "captive";

/* [Enclosure] */
case_x = 31;              // [29:1:45]
case_y = 46;              // [44:1:70]
base_h = 21.5;            // [20:0.5:30]
lid_t = 2.0;              // [1.2:0.2:3]
wall = 2.0;               // [1.4:0.2:3]
floor_t = 2.0;            // [1.4:0.2:3]
corner_r = 4.0;           // [1:0.5:8]
inner_corner_r = 0.5;     // maximises the genuinely flat antenna wall
lid_fit_clearance = 0.30; // clearance per side; increase if the lid is tight
lid_skirt_depth = 1.2;    // alignment skirt; clears the full-height Wi-Fi antenna
lid_skirt_wall = 1.2;     // [0.8:0.1:2]
lid_lead_in = 0.35;       // taper at the skirt's insertion edge
lid_clip_length = 6.0;    // external flex arm below the closed lid
lid_clip_w = 5.0;         // enough width to survive normal FDM printing
lid_clip_wall = 0.7;      // printable but flexible at this arm length
lid_clip_clearance = 0.25; // arm-to-base clearance before the hook
lid_clip_hook_depth = 0.55;
lid_clip_pocket_top_gap = 3.5; // solid wall above recess creates the snap shoulder
lid_pry_notch_w = 5.0;    // opening along the long lid edge
lid_pry_notch_depth = 3.0; // crosses the 2 mm wall and reaches behind it
rear_logo_w = 21.0;       // large RW mark across the rear flat wall
rear_logo_depth = 0.55;   // recessed for a clean, support-free vertical wall

/* [Electronics -- official STEP envelopes] */
wio_x = 17.7801;
wio_y = 21.4398;
wio_z = 7.3001;
xiao_x = 17.7800;
xiao_y_with_usb = 22.4820;
xiao_z = 4.4600;
device_x = 17.9;
device_y = 22.6;
board_stack_pcb_h = 6.2;  // measured: lower-PCB underside to upper-PCB top
device_h = 9.1;           // measured: lower-PCB underside to tallest SX1262 part
device_clearance = 0.45;  // around each board edge
device_center_y = captive_usb() ? 8.0 : -8.0;
device_floor_z = base_h-device_h-0.5; // tallest component sits 0.5 mm below roof

/* [Installed XIAO pin headers] */
header_pitch = 2.54;
header_row_spacing = 15.24;
header_pins_per_row = 7;
header_pin_d = 0.64;       // nominal square pin width
header_socket_d = 1.25;    // printable round socket; +0.10 after physical fit test
header_relief_d = 2.2;     // clears solder fillets at the PCB underside
header_relief_h = 0.8;

/* [Wio button] */
wio_button_x = 0;          // relative to board centre; measure if not central
wio_button_y = 0;
wio_button_access_d = 2.0; // paperclip access, not a finger opening

/* [Supplied Wi-Fi antenna -- official datasheet] */
wifi_ant_l = 37.4;
wifi_ant_w = 17.5;
wifi_ant_t = 1.8;         // maximum including release paper
wifi_cable_len = 65;
wifi_cable_d = 1.13;
wifi_ant_x = -(case_x/2-wall);
wifi_ant_y = 1.0;
wifi_ant_z = floor_t + wifi_ant_w/2 + 0.4;

/* [Supplied LoRa antenna -- official Seeed comparison] */
lora_ant_l = 40;
lora_ant_w = 7;
lora_ant_t = 1;
lora_cable_len = 50;
lora_cable_d = 1.13;
lora_ant_x = case_x/2-wall;
lora_ant_y = 0;
lora_ant_z = floor_t + lora_ant_w/2 + 1.0;

/* [Antenna mounting and cable care] */
antenna_lid_clearance = 0.4;
antenna_max_line_h = 0.4;
antenna_max_line_l = 8.0;
antenna_max_line_depth = 0.30;
coax_min_bend_r = 5;      // documentation / preview; never crease the cable
coax_channel_clearance = 2.2;

/* [USB and ventilation] */
usb_open_w = 9.4;         // 8.94 mm nominal shell + 0.23 mm clearance per side
usb_open_h = 4.6;         // 4.20 mm nominal shell + 0.20 mm clearance per side
usb_open_r = 1.3;
usb_open_raise = 3.0;     // measured correction for the installed pin spacers
usb_open_z = device_floor_z + 0.1 + usb_open_raise;
captive_cable_slot_w = 4.5;
captive_cable_slot_h = 4.5;
captive_cable_z = device_floor_z + 2.5;
captive_plug_body_w = 12.5;
captive_plug_body_h = 6.5;
captive_plug_body_l = 13.0;
captive_tongue_clearance = 0.20;
vent_slot_w = 2.2;
vent_slot_l = 6.0;
vent_slot_x = 10.5;
vent_slot_y = 14.0;

/* [Optional wall mounting] */
wall_mount_ears = false;
mount_hole_d = 3.5;

/* [Hidden] */
$fa = 5;
$fs = 0.4;
eps = 0.02;
inner_x = case_x - 2*wall;
inner_y = case_y - 2*wall;
lid_outer_x = inner_x - 2*lid_fit_clearance;
lid_outer_y = inner_y - 2*lid_fit_clearance;
board_pocket_x = device_x + 2*device_clearance;
board_pocket_y = device_y + 2*device_clearance;
inside_h = base_h - floor_t;

echo(case_outer_mm = [case_x, case_y, base_h + lid_t]);
echo(measured_board_stack_mm = board_stack_pcb_h,
     measured_max_stack_mm = device_h);
echo(wifi_antenna_mm = [wifi_ant_l, wifi_ant_w, wifi_ant_t], wifi_lead_mm = wifi_cable_len);
echo(lora_antenna_mm = [lora_ant_l, lora_ant_w, lora_ant_t], lora_lead_mm = lora_cable_len);

assert(device_floor_z + device_h + 0.45 <= base_h,
       "Not enough vertical clearance above the stacked boards");
assert(abs(wifi_ant_y) + wifi_ant_l/2 <= inner_y/2-inner_corner_r,
       "Wi-Fi antenna exceeds the flat side-wall length");
assert(wifi_ant_z + wifi_ant_w/2 <= base_h-lid_skirt_depth-antenna_lid_clearance,
       "Wi-Fi antenna enters the lid-skirt keep-out");
assert(abs(lora_ant_y) + lora_ant_l/2 <= inner_y/2-inner_corner_r,
       "LoRa antenna exceeds the flat side-wall length");
assert(lora_ant_z + lora_ant_w/2 <= base_h-lid_skirt_depth-antenna_lid_clearance,
       "LoRa antenna enters the lid-skirt keep-out");
assert((inner_x-device_x)/2-wifi_ant_t >= coax_channel_clearance,
       "Wi-Fi-side coax channel is narrower than its configured clearance");

// --- geometry helpers -------------------------------------------------------
module rounded_rect_2d(size, r) {
    rr = min(r, min(size[0], size[1])/2);
    hull()
        for (x = [-size[0]/2 + rr, size[0]/2 - rr])
            for (y = [-size[1]/2 + rr, size[1]/2 - rr])
                translate([x,y]) circle(r=rr);
}

module rounded_box(size, r) {
    linear_extrude(height=size[2]) rounded_rect_2d([size[0],size[1]], r);
}

module rounded_frame(outer, inner, h, r) {
    linear_extrude(height=h)
        difference() {
            rounded_rect_2d(outer, r);
            rounded_rect_2d(inner, max(0.4, r-(outer[0]-inner[0])/2));
        }
}

module tapered_rounded_frame(outer,inner,h,r,taper) {
    difference() {
        hull() {
            linear_extrude(height=eps)
                rounded_rect_2d(outer,r);
            translate([0,0,h-eps]) linear_extrude(height=eps)
                rounded_rect_2d([outer[0]-2*taper,outer[1]-2*taper],
                                max(0.5,r-taper));
        }
        translate([0,0,-eps]) linear_extrude(height=h+2*eps)
            rounded_rect_2d(inner,max(0.4,r-(outer[0]-inner[0])/2));
    }
}

module cable_between(p1, p2, d=1.13) {
    hull() {
        translate(p1) sphere(d=d);
        translate(p2) sphere(d=d);
    }
}

module cable_path(points, d=1.13) {
    for (i=[0:len(points)-2]) cable_between(points[i], points[i+1], d);
}

// --- printable base ---------------------------------------------------------
module mount_ear(xsign) {
    translate([xsign*(case_x/2 + 4.2), device_center_y, 0])
        difference() {
            hull() {
                cylinder(d=10, h=floor_t);
                translate([-xsign*5,0,0]) cylinder(d=8, h=floor_t);
            }
            translate([0,0,-eps]) cylinder(d=mount_hole_d, h=floor_t+2*eps);
        }
}

module rounded_front_opening(x,z,w,h,r) {
    // Close-fitting rounded USB-C aperture. The remaining short roof is an easy
    // bridge when the base is printed floor-down; no large triangular overhang.
    translate([x,-case_y/2+wall+eps,z+h/2])
        rotate([90,0,0])
            linear_extrude(height=3*wall)
                rounded_rect_2d([w,h],r);
}

module horizontal_ventilation_cuts(z,h) {
    // Four straight-through slots form bottom-to-top airflow. Because their
    // walls follow Z, neither the floor-down base nor face-down lid bridges a
    // ventilation ceiling.
    for (x=[-vent_slot_x,vent_slot_x], y=[-vent_slot_y,vent_slot_y])
        translate([x-vent_slot_w/2,y-vent_slot_l/2,z])
            cube([vent_slot_w,vent_slot_l,h]);
}

module antenna_max_height_cuts() {
    // One shallow engraved line per antenna wall. Its upper edge marks the
    // maximum safe height; being recessed, it cannot snag the antenna or lid.
    max_z = base_h-lid_skirt_depth-antenna_lid_clearance;
    for (xsign=[-1,1])
        translate([xsign > 0 ? inner_x/2-eps : -inner_x/2-antenna_max_line_depth,
                   -antenna_max_line_l/2,max_z-antenna_max_line_h])
            cube([antenna_max_line_depth+eps,antenna_max_line_l,
                  antenna_max_line_h+eps]);
}

module usb_cut() {
    if (captive_usb())
        // Open to the rim so a complete cable can be laid in; the captive lid
        // tongue closes everything above the final 4.5 x 4.5 mm aperture.
        translate([-captive_cable_slot_w/2,-case_y/2-wall,
                   captive_cable_z-captive_cable_slot_h/2])
            cube([captive_cable_slot_w,3*wall,
                  base_h-(captive_cable_z-captive_cable_slot_h/2)+eps]);
    else
        rounded_front_opening(0,usb_open_z,usb_open_w,usb_open_h,usb_open_r);
}

module header_socket_rails() {
    // Two rails match the canonical XIAO footprint: 2x7 pins on 2.54 mm pitch,
    // with 15.24 mm between rows. Deep narrow bores locate the pin tails; a
    // shallow counterbore keeps uneven solder fillets from carrying the board.
    rail_w = 2.8;
    rail_l = (header_pins_per_row-1)*header_pitch + 2.8;
    rail_h = device_floor_z-floor_t;
    for (x=[-header_row_spacing/2, header_row_spacing/2])
        difference() {
            translate([x-rail_w/2,device_center_y-rail_l/2,floor_t-eps])
                cube([rail_w,rail_l,rail_h+eps]);
            for (i=[0:header_pins_per_row-1]) {
                py = device_center_y + (i-(header_pins_per_row-1)/2)*header_pitch;
                translate([x,py,floor_t-2*eps])
                    cylinder(d=header_socket_d,h=rail_h+3*eps);
                translate([x,py,device_floor_z-header_relief_h])
                    cylinder(d=header_relief_d,h=header_relief_h+2*eps);
            }
        }
}

module board_locator() {
    // Header sockets provide precise XY registration. Two short end shelves
    // establish board height. The removable lid now retains the board, so
    // there are no awkward individual clips to release around the USB end.
    shelf_d = 1.35;
    for (sy=[-1,1])
        translate([-device_x/2,
                   device_center_y + sy*device_y/2 - (sy < 0 ? 0 : shelf_d),
                   floor_t-eps])
            cube([device_x,shelf_d,device_floor_z-floor_t+eps]);

    header_socket_rails();
}

module captive_plug_strain_shoulders() {
    if (captive_usb()) {
        port_face_y = device_center_y-device_y/2-2.2;
        stop_y = port_face_y-captive_plug_body_l-0.8;
        shoulder_outer = captive_plug_body_w/2+1.0;
        for (xsign=[-1,1])
            translate([xsign > 0 ? captive_cable_slot_w/2 : -shoulder_outer,
                       stop_y-0.65,floor_t-eps])
                cube([shoulder_outer-captive_cable_slot_w/2,1.3,
                      captive_cable_z+captive_plug_body_h/2+0.5-floor_t+eps]);
    }
}

module lid_clip_pockets() {
    // These recesses are deliberately bounded by solid wall at the top. The
    // external lid clips must flex over that shoulder before their hooks can
    // snap into the recesses; an open-topped notch cannot retain the lid.
    pocket_depth = lid_clip_hook_depth + 0.15;
    pocket_bottom = base_h-lid_clip_length-0.1;
    pocket_top = base_h-lid_clip_pocket_top_gap;
    for (xsign=[-1,1], y=[-9,9])
        translate([xsign > 0 ? case_x/2-pocket_depth : -case_x/2-eps,
                   y-(lid_clip_w+0.4)/2,pocket_bottom])
            cube([pocket_depth+eps,lid_clip_w+0.4,pocket_top-pocket_bottom]);
}

module rear_logo_cut() {
    // The rear is the end opposite the standard USB-C opening. The source logo
    // has a 560 x 446 viewBox; centring it here uses most of the genuinely flat
    // 23 mm-wide rear face without entering the rounded corner zones. This
    // OpenSCAD build imports SVG CSS pixels at 72 DPI, so convert the viewBox
    // units to mm before applying the requested physical width.
    svg_mm_per_px = 25.4/72;
    svg_w = 560*svg_mm_per_px;
    svg_h = 446*svg_mm_per_px;
    translate([0,case_y/2+eps,base_h/2])
        rotate([90,0,0])
            linear_extrude(height=rear_logo_depth+eps)
                scale([rear_logo_w/svg_w,rear_logo_w/svg_w])
                    mirror([1,0,0]) // reads correctly from outside the rear wall
                        translate([-svg_w/2,-svg_h/2])
                            import("assets/rainn-logo-single-color.svg");
}

module base() {
    union() {
        difference() {
            rounded_box([case_x,case_y,base_h],corner_r);
            translate([0,0,floor_t])
                rounded_box([inner_x,inner_y,base_h-floor_t+eps],inner_corner_r);
            usb_cut();
            horizontal_ventilation_cuts(-eps,floor_t+2*eps);
            antenna_max_height_cuts();
            lid_clip_pockets();
            rear_logo_cut();
        }
        board_locator();
        captive_plug_strain_shoulders();
        if (wall_mount_ears) {
            mount_ear(-1);
            mount_ear(1);
        }
    }
}

// --- printable lid ----------------------------------------------------------
module one_lid_snap_clip(y) {
    arm_inner_x = case_x/2 + lid_clip_clearance;
    hook_peak_z = lid_t + lid_clip_length - 1.3;
    hook_ramp_h = 1.2;

    // A local printable ear joins the outside arm to the lid plate. The arm is
    // outside the base wall, so making it genuinely deep cannot collide with
    // either of the full-height side-mounted antennas.
    translate([case_x/2-0.2,y-lid_clip_w/2,0])
        cube([arm_inner_x+lid_clip_wall-(case_x/2-0.2),lid_clip_w,lid_t+eps]);
    translate([arm_inner_x,y-lid_clip_w/2,lid_t-eps])
        cube([lid_clip_wall,lid_clip_w,lid_clip_length+eps]);

    // A diamond-section inward hook: both faces are self-supporting in the
    // lid's exterior-face-down print orientation. Its free-end ramp pushes the
    // arm outward during insertion; it then snaps under the base's solid rim.
    hull() {
        translate([arm_inner_x-eps,y-lid_clip_w/2,
                   hook_peak_z-hook_ramp_h])
            cube([eps*2,lid_clip_w,0.10]);
        translate([arm_inner_x-lid_clip_hook_depth,y-lid_clip_w/2,
                   hook_peak_z])
            cube([lid_clip_hook_depth+eps,lid_clip_w,0.10]);
    }
    hull() {
        translate([arm_inner_x-lid_clip_hook_depth,y-lid_clip_w/2,
                   hook_peak_z])
            cube([lid_clip_hook_depth+eps,lid_clip_w,0.10]);
        translate([arm_inner_x-eps,y-lid_clip_w/2,
                   hook_peak_z+hook_ramp_h])
            cube([eps*2,lid_clip_w,0.10]);
    }
}

module lid_snap_clips() {
    for (xsign=[-1,1], y=[-9,9])
        if (xsign > 0)
            one_lid_snap_clip(y);
        else
            mirror([1,0,0]) one_lid_snap_clip(y);
}

module captive_cable_slot_tongue() {
    if (captive_usb()) {
        tongue_w = captive_cable_slot_w-2*captive_tongue_clearance;
        tongue_h = base_h-(captive_cable_z+captive_cable_slot_h/2);
        // The lid is modelled upside-down for printing. Its +Y edge becomes the
        // enclosure's USB/front edge when fitted_lid() rotates it into place.
        translate([-tongue_w/2,case_y/2-wall,lid_t-eps])
            cube([tongue_w,wall,tongue_h+eps]);
    }
}

module wio_button_access_cut() {
    // fitted_lid() reverses Y, hence the negative printed Y coordinate.
    translate([wio_button_x,-(device_center_y+wio_button_y),-eps])
        cylinder(d=wio_button_access_d,h=lid_t+2*eps);
}

module lid_pry_notches() {
    // Exactly one square-ended slot in each long edge of the horizontal lid
    // plate. It crosses the complete 2 mm base-wall thickness and continues
    // 1 mm behind its inner face, allowing a flat blade to get behind the wall
    // rather than merely pressing against the outside edge.
    for (xsign=[-1,1])
        translate([xsign > 0 ? case_x/2-lid_pry_notch_depth : -case_x/2-eps,
                   -lid_pry_notch_w/2,-eps])
            cube([lid_pry_notch_depth+eps,lid_pry_notch_w,
                  lid_t+2*eps]);
}

module lid() {
    difference() {
        union() {
            rounded_box([case_x,case_y,lid_t],corner_r);

            // Tapered leading edge self-centres before the snap clips engage.
            translate([0,0,lid_t])
                tapered_rounded_frame([lid_outer_x,lid_outer_y],
                              [lid_outer_x-2*lid_skirt_wall,lid_outer_y-2*lid_skirt_wall],
                              lid_skirt_depth,max(0.8,corner_r-wall-lid_fit_clearance),
                              lid_lead_in);
            lid_snap_clips();
            captive_cable_slot_tongue();
        }
        horizontal_ventilation_cuts(-eps,lid_t+2*eps);
        wio_button_access_cut();
        lid_pry_notches();
    }
}

// --- non-printing fit references -------------------------------------------
module device_mock() {
    color("DarkSlateGray")
        translate([-device_x/2,device_center_y-device_y/2,device_floor_z])
            cube([device_x,device_y,device_h]);
    color("Silver")
        translate([-8.94/2,device_center_y-device_y/2-2.2,device_floor_z+0.26])
            cube([8.94,4.5,4.20]);
}

module captive_usb_mock() {
    if (captive_usb()) {
        port_face_y = device_center_y-device_y/2-2.2;
        color("DimGray")
            translate([-captive_plug_body_w/2,port_face_y-captive_plug_body_l,
                       captive_cable_z-captive_plug_body_h/2])
                cube([captive_plug_body_w,captive_plug_body_l,captive_plug_body_h]);
        color("Black") cable_path([[0,port_face_y-captive_plug_body_l,captive_cable_z],
                                   [0,-case_y/2-8,captive_cable_z]],3.4);
    }
}

module antenna_mock(w,l,t,x,y,z,xsign,cable_points,cable_d,col) {
    color(col)
        translate([x-xsign*t/2,y-l/2,z-w/2])
            rotate([0,90,0]) cube([w,l,t]);
    color("Black") cable_path(cable_points,cable_d);
}

module antenna_mocks() {
    if (captive_usb()) {
        antenna_mock(lora_ant_w,lora_ant_l,lora_ant_t,lora_ant_x,lora_ant_y,lora_ant_z,1,
            [[lora_ant_x-lora_ant_t,lora_ant_y-lora_ant_l/2,lora_ant_z],
             [11,-17,6],[10,-10,7],[10,0,9],[9,10,12],[6,16,15]],
             lora_cable_d,"DarkOrange");
        antenna_mock(wifi_ant_w,wifi_ant_l,wifi_ant_t,wifi_ant_x,wifi_ant_y,wifi_ant_z,-1,
            [[wifi_ant_x+wifi_ant_t,wifi_ant_y-wifi_ant_l/2,wifi_ant_z],
             [-11,-17,9],[-10,-10,8],[-10,0,9],[-9,10,11],[-6,16,13]],
             wifi_cable_d,"SeaGreen");
    } else {
        antenna_mock(lora_ant_w,lora_ant_l,lora_ant_t,lora_ant_x,lora_ant_y,lora_ant_z,1,
            [[lora_ant_x-lora_ant_t,lora_ant_y+lora_ant_l/2,lora_ant_z],
             [11,17,6],[7,14,7],[7,8,11],[6,3,15]],lora_cable_d,"DarkOrange");
        antenna_mock(wifi_ant_w,wifi_ant_l,wifi_ant_t,wifi_ant_x,wifi_ant_y,wifi_ant_z,-1,
            [[wifi_ant_x+wifi_ant_t,wifi_ant_y+wifi_ant_l/2,wifi_ant_z],
             [-11,17,9],[-7,14,7],[-7,8,10],[-6,3,13]],wifi_cable_d,"SeaGreen");
    }
}

module fitted_lid() {
    translate([0,0,base_h+lid_t]) rotate([180,0,0]) lid();
}

module assembly(exploded=0) {
    color("SteelBlue") base();
    device_mock();
    captive_usb_mock();
    antenna_mocks();
    translate([0,0,exploded]) color("LightSteelBlue",0.82) fitted_lid();
}

module fit_test() {
    // Reuse the exact production locator: all 14 pins, both rows and both end
    // shelves. A partial lid corner did not reproduce the
    // stiffness or opposing catches of the real lid, so it was not a useful
    // tolerance test and has deliberately been removed.
    coupon_x = device_x + 6;
    coupon_y = device_y + 6;
    translate([-coupon_x/2,-coupon_y/2,0])
        cube([coupon_x,coupon_y,floor_t]);
    // board_locator() is authored around device_center_y; shift that centre
    // to zero for a compact, standalone full-board fitting fixture.
    translate([0,-device_center_y,0]) board_locator();
}

// --- render selector --------------------------------------------------------
if (render_part == "base")
    base();
else if (render_part == "lid")
    lid();
else if (render_part == "print_plate") {
    base();
    translate([case_x+8,0,0]) lid();
} else if (render_part == "assembly") {
    color("SteelBlue") base();
    device_mock();
    captive_usb_mock();
    antenna_mocks();
    translate([0,case_y+12,base_h+lid_t+8])
        rotate([180,0,0]) color("LightSteelBlue",0.82) lid();
} else if (render_part == "layout") {
    color("SteelBlue",0.35) base();
    device_mock();
    captive_usb_mock();
    antenna_mocks();
    translate([case_x+10,0,0]) color("LightSteelBlue",0.82) lid();
} else if (render_part == "cutaway") {
    difference() {
        assembly(0);
        translate([-case_x,-case_y,base_h/2]) cube([2*case_x,case_y,2*base_h]);
    }
} else if (render_part == "fit_test")
    fit_test();
else
    assembly(0);
