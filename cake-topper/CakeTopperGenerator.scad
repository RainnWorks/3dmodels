// =============================================================================
//  CakeTopperGenerator.scad -- multi-line cake topper with a big "background"
//  number (the age) sitting behind all the text lines.
// =============================================================================
//  Layout (centred, stacked top -> bottom):
//
//        H A P P Y          <- Line1
//      B I R T H D A Y      <- Line2          with a giant "1" behind
//          M I A            <- Line3 (bigger)  all three, a small gap around
//          | |                                 the letters where they cross it
//         posts (into cake)
//
//  The number sits BEHIND the text. How it's shown is set by Age_Style:
//    "inlay"  - the number is set INTO the white plate, flush with the surface,
//               in the accent colour (cut in, not a bump on top).   [default]
//    "deboss" - the number is an open recess (groove) in the white plate,
//               same colour -- reads by shadow only.
//    "raised" - the number is a raised accent layer on top of the plate.
//  A gap is kept clear around every letter so the white plate shows through as
//  a clean outline between the number and the text.
//
//  Rendered/exported per-part with -D render_part="..."  (see Makefile):
//    topper  - the whole thing (default)
// =============================================================================

/* [Fonts] */
// macOS swirly options: "Snell Roundhand:style=Bold", "Savoye LET",
// "Apple Chancery", "Zapfino", "Brush Script MT", "SignPainter:style=HouseScript"
Text_Font       = "Snell Roundhand:style=Bold";
Age_Font        = "Arial Black";   // the big number -- hard, clear, easy to read

/* [Text] */
Line1           = "Happy";
Line2           = "Birthday";
Line3           = "Mia";        // the name -- printed bigger
Line1_Size      = 30;
Line2_Size      = 30;
Line3_Size      = 50;           // bigger than the other two
Line_Gap        = 4;            // extra vertical gap between lines (mm)
Text_Boldness   = 1.4;          // fatten the letters (offset r, mm)
Text_Spacing    = 1.0;

/* [Background number] */
Age             = "1";          // the big number behind the text
Age_Style       = "inlay";      // "inlay" | "engrave" | "deboss" | "raised"
Age_Scale       = 1.12;         // number height vs. the text-block height
Age_Boldness    = 3.0;          // fatten the number strokes (mm)
Gap             = 2.2;          // clear gap between the number and the text (mm)
Number_Outline  = 2.4;          // width of the engraved "1" outline groove (mm)
Number_Stroke   = 1.5;          // width of the black outline around the inlaid
                                // "1" (mm). 0 = no stroke

/* [Outline / halo] */
Outline_thickness = 2.0;        // white border around the words (mm)
Connect           = 3.0;        // close gaps in the base plate so floating bits
                                // (e.g. script "i" dots) bridge to their letter (mm)

/* [Layers] */
Extrusion_Layer_Height = 0.20;
Base_Layers     = 6;            // base plate
Engrave_Layers  = 4;            // depth of the engraved number outline
Inlay_Layers    = 5;            // number depth for inlay/deboss (< Base_Layers)
                                // near-full so the gold "1" reads through the white
Age_Layers      = 8;            // number height when Age_Style="raised"
Text_Layers     = 12;           // letters sit highest

/* [Posts] */
Post_Spacing    = 80;           // distance between the two posts (mm). 0 = none
Post_Width      = 5;
Post_Length     = 70;

/* [Colours (preview only)] */
col_text        = "red";
col_outline     = "white";      // the white backing/border around the words
col_age         = "gold";       // the "1" cut into the white
col_age_stroke  = "black";      // the outline around the "1" (also inlaid)

/* [Hidden] */
render_part     = "topper";
// Solid=true -> one watertight single-colour solid (plate + raised text, no
// colour inlay) for clean STL export. The 3MF export leaves this false so the
// per-colour objects survive.
Solid           = false;
$fn             = 64;

// --- derived heights ---------------------------------------------------------
base_h    = Base_Layers    * Extrusion_Layer_Height;
inlay_d   = Inlay_Layers   * Extrusion_Layer_Height;   // recess depth from the top
engrave_d = Engrave_Layers * Extrusion_Layer_Height;   // groove depth for "engrave"
age_h     = base_h + Age_Layers  * Extrusion_Layer_Height;
text_h    = base_h + Text_Layers * Extrusion_Layer_Height;
eps       = 0.001;
weld      = 0.1;   // gold inlay grown slightly past its recess so walls overlap
                   // (not coincide) -> clean watertight union
// how far the carved/inlaid region (number + its black stroke) reaches past the
// glyph, and how far the white PLATE reaches past that -- so a white outline
// always wraps the black stroke, even where the "1" expands the part.
age_recess = (Age_Style == "inlay") ? Number_Stroke : 0;
age_plate  = (Age_Style == "inlay") ? Number_Stroke + Outline_thickness : 0;

// --- vertical layout ---------------------------------------------------------
// line centres, stacked from the bottom (Line3) up; bottom of Line3 sits at y=0
c3 = Line3_Size/2;
c2 = c3 + (Line3_Size + Line2_Size)/2 + Line_Gap;
c1 = c2 + (Line2_Size + Line1_Size)/2 + Line_Gap;

blockTop = c1 + Line1_Size/2;
blockBot = c3 - Line3_Size/2;
blockMid = (blockTop + blockBot)/2;
blockH   = blockTop - blockBot;

age_size = blockH * Age_Scale;     // font size for the number

lines  = [Line1,      Line2,      Line3];
sizes  = [Line1_Size, Line2_Size, Line3_Size];
ys     = [c1,         c2,         c3];

// =============================================================================
//  2D glyph helpers
// =============================================================================

// one line of text as a 2D shape, centred at its y
module line_2d(i, grow=0) {
    translate([0, ys[i], 0])
        offset(r = Text_Boldness + grow)
            text(lines[i], size=sizes[i], font=Text_Font, spacing=Text_Spacing,
                 halign="center", valign="center");
}

// all text lines together, optionally grown
module text_2d(grow=0) {
    for (i=[0:len(lines)-1]) line_2d(i, grow);
}

// the big background number as a 2D shape, centred on the text block
module age_2d(grow=0) {
    translate([0, blockMid, 0])
        offset(r = Age_Boldness + grow)
            text(Age, size=age_size, font=Age_Font, spacing=Text_Spacing,
                 halign="center", valign="center");
}

// the number area as it appears -- with a clear gap kept around the letters
module age_visible() {
    difference() {
        age_2d(0);
        text_2d(Gap);
    }
}

// a thin band tracing the number's silhouette -- the engraved "1" outline,
// kept clear of the letters
module age_band() {
    difference() {
        difference() {
            age_2d(Number_Outline/2);
            age_2d(-Number_Outline/2);
        }
        text_2d(Gap);
    }
}

// morphological "close": dilate then erode, to bridge nearby islands
module close2d(c) { offset(r=-c) offset(r=c) children(); }

// the base-plate footprint: a white border around the WORDS, plus the bare
// number shape (so the gold "1" reaches the plate edge / extends past it
// instead of being wrapped in white), plus posts. Closed so floating glyph
// bits (script i-dots) join the rest into one piece.
module plate_2d() {
    close2d(Connect)
        union() {
            text_2d(Outline_thickness);  // white border hugs the words
            age_2d(age_plate);           // number + black stroke + white outline
            posts_2d();
        }
}

// the two posts (legs) as a 2D shape, hanging below the text
module posts_2d() {
    if (Post_Length > 0) {
        for (m=[-1,1]) {
            translate([m*Post_Spacing/2 - Post_Width/2, -Post_Length, 0])
                square([Post_Width, Post_Length + Line3_Size/2]);
            translate([m*Post_Spacing/2, -Post_Length, 0])
                circle(d = Post_Width);
        }
    }
}

// =============================================================================
//  The topper -- one module per COLOUR, emitted as separate top-level objects.
//  With `--enable lazy-union` (see the Makefile 3MF rule) each becomes its own
//  coloured object in the .3mf, so Bambu Studio imports a part per filament.
//  For .stl (no lazy-union) the three implicitly union into one watertight mesh.
// =============================================================================

// 1) the white plate: footprint, with the number carved out of the top
module part_white() {
    raised  = (Age_Style == "raised");
    engrave = (Age_Style == "engrave");
    color(col_outline)
        difference() {
            linear_extrude(base_h) plate_2d();
            // engrave: a thin groove tracing the number outline
            if (engrave)
                translate([0, 0, base_h - engrave_d + eps])
                    linear_extrude(engrave_d)
                        age_band();
            // inlay: cut the FULL number (+ black stroke) out of the top, so gold
            //        runs right up to and under the letters -> the letter "stroke"
            //        reads gold wherever the 1 is, with a black outline around it
            if (Age_Style == "inlay")
                translate([0, 0, base_h - inlay_d + eps])
                    linear_extrude(inlay_d)
                        age_2d(age_recess);
            // deboss: groove the number but keep a clear gap around the letters
            if (Age_Style == "deboss")
                translate([0, 0, base_h - inlay_d + eps])
                    linear_extrude(inlay_d)
                        age_visible();
        }
}

// 2) the number in the accent colour
module part_gold() {
    if (Age_Style == "inlay")
        // fill the recess flush with the surface
        color(col_age)
            translate([0, 0, base_h - inlay_d])
                linear_extrude(inlay_d - eps)
                    age_2d(weld);   // grown past the recess walls -> watertight
    else if (Age_Style == "raised")
        // sit proud on top of the plate
        color(col_age)
            translate([0, 0, base_h - eps])
                linear_extrude(age_h - base_h + eps)
                    age_visible();
    // ("deboss"/"engrave" -> no separate body; the carved plate is the effect)
}

// 2b) the black stroke around the "1" -- a ring just outside the gold, inlaid
//     flush the same way (only for inlay, when Number_Stroke > 0)
module part_black() {
    if (Age_Style == "inlay" && Number_Stroke > 0)
        color(col_age_stroke)
            translate([0, 0, base_h - inlay_d])
                linear_extrude(inlay_d - eps)
                    difference() {
                        age_2d(Number_Stroke + weld);  // overlaps the white wall
                        age_2d(0);                     // gold fills the centre
                    }
}

// 3) the text letters, raised highest
module part_red() {
    color(col_text)
        translate([0, 0, base_h - weld])
            linear_extrude(text_h - base_h + weld)
                text_2d(0);
}

// convenience wrapper (used for single-object PNG previews)
module topper() { part_white(); part_gold(); part_black(); part_red(); }

// a single watertight solid (no colour inlay) -- same outer shape, for STL
module solid() {
    color(col_outline) linear_extrude(base_h) plate_2d();
    part_red();
}

// =============================================================================
//  Output -- separate top-level objects so 3MF colour survives (lazy-union);
//  Solid=true collapses to one watertight body for clean STL export.
// =============================================================================
if (Solid) {
    solid();
} else {
    part_white();
    part_gold();
    part_black();
    part_red();
}
