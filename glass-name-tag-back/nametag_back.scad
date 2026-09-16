// =============================================================================
//  nametag_back.scad -- VARIANT 2: variant 1's tag, with the clip rotated 90
//  degrees out of the letter plane.
// =============================================================================
//  This file is deliberately thin. It INCLUDES ../glass-name-tag/nametag.scad
//  and changes exactly one thing:
//
//      variant 1 sweeps the clip in the LETTER plane (XY), so the tag hangs
//      edge-on on the side of the glass;
//      this sweeps the same clip in XZ instead, so the letter plane ends up
//      PARALLEL to the glass wall and the name faces the room.
//
//  Everything else -- the measured ink placement, the lifted baseline, the bar
//  with its rounded end, the MST struts that weld the i-dots, the clip's
//  profile and the reasoning behind its bend radius -- is variant 1's, not a
//  copy of variant 1's. Including it rather than forking it is the point: it
//  is what makes "only the clip's plane changed" a fact about the file rather
//  than a claim in a README.
//
//  Frame. Variant 1 already has x running UP the glass and the clip's arm
//  returning down the inside; only the meaning of the other two axes changes:
//
//      x   up the glass -- the name runs along it, read vertically
//      y   along the rim (variant 1: radial)
//      z   radial, out of the glass (variant 1: along the rim)
//
//      z = 0 is the glass wall's outer face and the letter plane's BACK face.
//      The wall occupies z = -glass_t .. 0, below the rim at x = rim_x.
//
//        looking along Y -- the x-z section, the clip's own plane
//
//                                    ,--.       <- the curl, over the rim
//          x = rim_x  --------------(  # )
//                     ==============###--'      <- the bar's end
//             glass ->  ###########             <- the sprung arm, inside
//             wall      -----------
//                     ##############=========   the bar and the letters,
//                     z<0        |  z>0         outside, at z = 0..thick
//
//  The clip is only as wide as the bar in y, and it sits in the bar's own y
//  band -- so seen head-on it hides behind the bar and crosses no lettering.
//  tests/empty_clip_hides_behind_the_bar.scad is that, as a boolean.
//
//  Because this file includes variant 1's, that file's own render_part switch
//  has to be silenced, and the switch here is called `part` instead. Everything
//  else you would pass to variant 1 -- name, font, style, bite, set_drop, the
//  struts -- is passed to this file unchanged, which is why measure.py and
//  bridges.py are used directly rather than copied.
//
//    part = tag     - the whole thing, as worn (default)
//           body    - the flat part only: bar, letters, struts
//           clip    - the clip alone
//           print   - rolled into the print orientation, letters face-down
//           bite    - the clip intersected with the wall: the grip, as a solid
//           section - the clip cut through, on a mock rim (preview colours, so
//                     render this one WITHOUT --render)
//           onglass - the whole tag on the mock glass
// =============================================================================

include <../glass-name-tag/nametag.scad>

// AFTER the include, so it wins: OpenSCAD resolves a scope's assignments before
// evaluating geometry and the last one takes effect, so variant 1's own output
// switch is silenced here and its geometry is only reached through its modules.
// (-D still overrides both, which is how the scripts drive this.)
render_part = "none";

/* [Name] */
// Great Vibes' thin strokes measure 0.30mm at size 15 -- under one 0.4mm
// extrusion -- so they have to be fattened. Variant 1 defaults this to 0
// because it is a knob there; here it is the shipping value.
bold        = 0.15;                 // [0:0.05:1]

/* [Clip out of plane] */
// How wide the clip is ALONG THE RIM. Variant 1's clip is `thick` wide in the
// direction it is now being rotated into; making it the bar's own depth
// instead keeps the clip flush with the bar, which is what keeps it hidden
// behind the bar head-on. < 0 -> the bar's depth.
clip_wide   = -1;                   // [-1:0.1:8]

/* [Hidden] */
// Variant 1's `render_part` is spoken for (above), so this file's switch has a
// name of its own.
part        = "tag";
// mock glass, for the previews only
rim_r       = 35;
glass_h     = 34;
sec_y       = 6;

// =============================================================================
//  Derived
// =============================================================================
cw          = (clip_wide < 0) ? bar_w : clip_wide;
// Where the rim's top edge sits: the innermost point of the curl, because the
// whole reason variant 1 derives bend_r from glass_t/2 is so the rim SEATS in
// the curl rather than being clawed at the tip.
rim_x       = clip_len + bend_r;

assert(cw > 0, "clip_wide resolves to zero");
assert(cw <= bar_w + 0.001,
       str("the clip is ", cw, "mm wide against a ", bar_w,
           "mm bar -- it would show past the bar head-on"));

echo(str("[", name, "] bar ", clip_len, " x ", bar_w, " x ", thick,
         "  baseline y=", base_y, "  clip ", cw, "mm wide",
         "  jaw ", jaw, "..", jaw_root, "  bend_r ", bend_r,
         "  rim at x=", rim_x, "  struts ", len(struts)));

// =============================================================================
//  3D -- the one change
// =============================================================================

// The flat part, exactly as variant 1 extrudes it.
module body3() { linear_extrude(thick) body_2d(); }

// The same clip_2d(), swept in XZ instead of XY. rotate([90,0,0]) carries the
// drawing's y into z (so the glass face stays at z=0 and the curl still wraps
// a slab below it) and the extrusion depth into -y; the translate puts it back
// into the bar's own y band. Determinant +1: this is a rotation, not a mirror,
// so the clip is the same hand as variant 1's.
module clip3() {
    translate([0, cw, 0]) rotate([90, 0, 0]) linear_extrude(cw) clip_2d();
}

module tag3() { union() { body3(); clip3(); } }

// The wall of the glass as the clip sees it: a slab under the rim with a
// ROUND end, because that is what a fire-polished wine rim is and because
// variant 1's whole reason for deriving `bend_r` from `glass_t/2` is that the
// rim seats in the curl. Modelled square-ended, the wall's corner cuts the
// curl and the measured interference comes out as the full 2mm of glass
// instead of the 0.8mm of preload -- which is what it did, until this was
// drawn properly. The half-round end is concentric with the curl by
// construction: same centre, same radius.
module wall_2d(tol = 0.01) {
    L = 4 * clip_len;
    offset(r = -tol) union() {
        translate([-L, -glass_t]) square([L + clip_len, glass_t]);
        translate([clip_len, -glass_t / 2]) circle(d = glass_t, $fn = 160);
    }
}

module wall(tol = 0.01, w = 40) {
    translate([0, w / 2, 0]) rotate([90, 0, 0]) linear_extrude(w) wall_2d(tol);
}

// A mock glass, for the previews only.
module glass() {
    translate([rim_x - glass_h, cw / 2, -rim_r])
        rotate([0, 90, 0]) difference() {
            cylinder(r = rim_r, h = glass_h, $fn = 200);
            translate([0, 0, -eps])
                cylinder(r = rim_r - glass_t, h = glass_h + 2 * eps, $fn = 200);
        }
}

module sec_box() {
    translate([clip_len - 40, cw / 2 - sec_y, -14])
        cube([40 + bend_rc + clip_w, sec_y, 14 + thick + 2]);
}

// =============================================================================
//  Output
// =============================================================================

// Letters face-DOWN on the bed: the orientation the print study picked, and the
// only one that puts the letters' own faces on glass rather than on support.
module printed() { translate([0, 0, thick]) rotate([180, 0, 0]) tag3(); }

if      (part == "tag")     tag3();
else if (part == "body")    body3();
else if (part == "clip")    clip3();
else if (part == "print")   printed();
else if (part == "bite")    intersection() { clip3(); wall(); }
else if (part == "section") {
    color("#2e7d9a")               intersection() { tag3();       sec_box(); }
    color([0.85, 0.93, 1.0, 0.55]) intersection() { wall(0, 200); sec_box(); }
}
else if (part == "onglass") {
    color("#2e7d9a")               tag3();
    color([0.85, 0.93, 1.0, 0.45]) glass();
}
else if (part == "none") ;
else assert(false, str("unknown part \"", part, "\""));
