// =============================================================================
//  HallOfFame.scad -- a flat script-lettering sign for a mirror.
// =============================================================================
//  A few rows of script text, stacked, sized so the WHOLE composition is
//  exactly Total_Width across. Each WORD comes off as its own flat piece, so a
//  300 mm sign still prints on a normal bed -- you stick the pieces on the
//  mirror one at a time, using the 1:1 paper template to place them.
//
//        H a l l   o f          <- Row1  (two words -> two pieces)
//            F a m e            <- Row2  (one word  -> one piece)
//        |<---- 300 mm ---->|
//
//  Sizing works backwards from the width: the row that needs the most space
//  (row width x its Row_Scale) is set to Total_Width, and every other row
//  follows at the same font size. Rows are then stacked by their INK extents,
//  not by nominal line height -- Row_Gap is a real millimetre gap between the
//  lowest descender above and the highest ascender below, so it can go
//  negative to let a descender tuck into the row underneath.
//
//  Rendered/exported per-part with -D render_part="..."  (see Makefile):
//    layout          - the whole composition, as it goes on the mirror
//    template        - 2D only, for the 1:1 SVG placement template
//    word0 word1 ... - one printable piece per word, laid flat at the origin
// =============================================================================

/* [Text] */
// One row per line; leave a row empty to drop it. Words split on spaces and
// each word becomes its own printed piece.
Row1            = "Hall of";
Row2            = "Fame";
Row3            = "";
// Per-row size, relative to the others (1 = same font size)
Row1_Scale      = 1.0;          // [0.3:0.05:2]
Row2_Scale      = 1.0;          // [0.3:0.05:2]
Row3_Scale      = 1.0;          // [0.3:0.05:2]
// Slide a row sideways, as a fraction of the total width (0 = centred)
Row1_Nudge      = 0;            // [-0.5:0.01:0.5]
Row2_Nudge      = 0;            // [-0.5:0.01:0.5]
Row3_Nudge      = 0;            // [-0.5:0.01:0.5]

/* [Font] */
// Monoline wedding scripts, closest first. Sacramento is the reference match.
Font            = "Sacramento"; // [Sacramento, Yellowtail, Allura, Parisienne, Great Vibes]
// Letter spacing (1 = the font's own). Sacramento's capitals do NOT reach the
// letter after them at 1.0 -- "Hall" and "Fame" come out as two loose bits
// each. Tightening to 0.85 pulls the H and F crossbars through the following
// letter, which is how the script wants to be set anyway. `make check` is what
// says whether a given value holds together.
Spacing         = 0.85;         // [0.7:0.01:1.6]
// fatten every stroke by this much, all round (mm). Thin scripts need it to
// survive as a print -- see Min_Stroke in the echo output.
Boldness        = 0.6;          // [0:0.05:3]

/* [Size] */
// width of the whole composition, mirror-side (mm)
Total_Width     = 300;          // [100:5:600]
// how thick the letters stand off the mirror (mm)
Thickness       = 4;            // [1.5:0.5:12]
// Gap between one row's lowest ink and the next row's highest (mm). Measured
// on the rows' full extents, which is pessimistic -- the "of" descender and
// the "F" ascender are at opposite ends of the sign and never come near each
// other -- so a negative value here nests the rows properly. `make check`
// reports what the closest approach actually ends up being.
Row_Gap         = -40;          // [-120:1:60]

/* [Advanced] */
// Dilate-then-erode by this much, which fuses strokes that pass within ~2x of
// it without fattening anything. This is what turns the H/F crossbars merely
// grazing the next letter into a proper 5 mm join -- at 0 the words come off
// the bed in pieces. (mm)
Connect         = 2.0;          // [0:0.1:8]
// colour, for previews only
col_letters     = "goldenrod";

/* [Hidden] */
render_part     = "layout";
// which word to emit when render_part="word" (0-based, in reading order)
piece_index     = 0;
// 32 puts the chord error on the offset arcs around 0.01 mm and on the glyph
// curves around 0.05 mm -- both far under one extrusion, and it halves the
// mesh compared with 64.
$fn             = 32;

// =============================================================================
//  Text plumbing
// =============================================================================

// split a string on a separator, dropping empties: "Hall of" -> ["Hall","of"]
function split(s, sep=" ", i=0, cur="", out=[]) =
    i >= len(s) ? (cur == "" ? out : concat(out, [cur]))
  : s[i] == sep ? split(s, sep, i+1, "", cur == "" ? out : concat(out, [cur]))
  :               split(s, sep, i+1, str(cur, s[i]), out);

// join a slice of words back into a string, so we can measure a prefix
function joinwords(w, n, i=0, out="") =
    i >= n ? out : joinwords(w, n, i+1, str(out, w[i], i+1 < n ? " " : ""));

// the rows that actually have text in them
rows_raw   = [Row1, Row2, Row3];
scales_raw = [Row1_Scale, Row2_Scale, Row3_Scale];
nudges_raw = [Row1_Nudge, Row2_Nudge, Row3_Nudge];
keep       = [for (i=[0:2]) if (len(rows_raw[i]) > 0) i];

rows   = [for (i=keep) rows_raw[i]];
kscale = [for (i=keep) scales_raw[i]];
knudge = [for (i=keep) nudges_raw[i]];
nrows  = len(rows);

// words per row, and the running x offset of each word inside its row
words  = [for (r=rows) split(r)];

// --- metrics ------------------------------------------------------------
// Needs `--enable textmetrics` (the Makefile passes it). Everything is
// measured once at size 100 and scaled, so one font size drives the lot.
REF = 100;
function adv(s)   = textmetrics(s, size=REF, font=Font, spacing=Spacing).advance[0];
function inkTop(s)= let (m = textmetrics(s, size=REF, font=Font, spacing=Spacing))
                        m.position[1] + m.size[1];
function inkBot(s)= textmetrics(s, size=REF, font=Font, spacing=Spacing).position[1];

row_adv = [for (r=rows) adv(r)];                       // at size REF
// the row that dictates the width, once each row's own scale is applied
need    = [for (i=[0:nrows-1]) row_adv[i] * kscale[i]];
// per-row font size (mm): the neediest row is stretched to exactly Total_Width
fs      = [for (i=[0:nrows-1]) Total_Width * REF / max(need) * kscale[i]];
row_w   = [for (i=[0:nrows-1]) row_adv[i] * fs[i] / REF];

// --- vertical stacking, by ink ------------------------------------------
// Row 0's baseline sits at y=0; each row after drops far enough that its
// tallest ink clears the row above by Row_Gap.
function baseline(i) =
    i == 0 ? 0
           : baseline(i-1) + inkBot(rows[i-1]) * fs[i-1]/REF
                           - Row_Gap - Boldness*2
                           - inkTop(rows[i])   * fs[i]  /REF;

base_y  = [for (i=[0:nrows-1]) baseline(i)];

blockTop = max([for (i=[0:nrows-1]) base_y[i] + inkTop(rows[i])*fs[i]/REF]) + Boldness;
blockBot = min([for (i=[0:nrows-1]) base_y[i] + inkBot(rows[i])*fs[i]/REF]) - Boldness;
blockH   = blockTop - blockBot;
blockMid = (blockTop + blockBot) / 2;

// where each word sits in the finished composition (mirror coordinates,
// origin at the centre of the block)
function word_x(i, j) =
    -row_w[i]/2 + knudge[i]*Total_Width
    + adv(joinwords(words[i], j)) * fs[i]/REF
    + (j > 0 ? adv(" ") * fs[i]/REF : 0);

function word_y(i) = base_y[i] - blockMid;

// flatten to a single list, so the Makefile can address word0, word1, ...
pieces = [for (i=[0:nrows-1]) for (j=[0:len(words[i])-1]) [i, j]];

// =============================================================================
//  Geometry
// =============================================================================

// morphological "close": dilate then erode, to fuse near-touching strokes
module close2d(c) { if (c > 0) offset(r=-c) offset(r=c) children(); else children(); }

// one word as a 2D shape, sitting where it belongs in the composition
module word_2d(i, j, placed=true) {
    translate(placed ? [word_x(i,j), word_y(i)] : [0, 0])
        close2d(Connect)
            offset(r=Boldness)
                text(words[i][j], size=fs[i], font=Font, spacing=Spacing,
                     halign="left", valign="baseline");
}

// every word, in place -- the composition as it goes on the mirror
module composition_2d() {
    for (p = pieces) word_2d(p[0], p[1]);
}

// a printable piece: one word, dropped to the origin and laid flat
module piece(k) {
    p = pieces[k];
    linear_extrude(Thickness) word_2d(p[0], p[1], placed=false);
}

module layout() {
    color(col_letters) linear_extrude(Thickness) composition_2d();
}

// =============================================================================
//  Output
// =============================================================================

if (render_part == "layout")        layout();
else if (render_part == "template") composition_2d();          // 2D -> SVG/DXF
else if (render_part == "word")     piece(piece_index);        // one piece
else if (render_part == "pieces")                              // all, spread out
    for (k=[0:len(pieces)-1]) translate([0, -k*blockH/nrows, 0]) piece(k);

// =============================================================================
//  Report -- sizes, bed fit and the thinnest stroke, so nothing surprises you
//  at the slicer.
// =============================================================================
echo(str("font size          = ", fs[0], " mm"));
echo(str("composition        = ", Total_Width, " x ", blockH, " mm"));
for (k = [0:len(pieces)-1]) {
    i = pieces[k][0]; j = pieces[k][1];
    m = textmetrics(words[i][j], size=fs[i], font=Font, spacing=Spacing);
    echo(str("word", k, " '", words[i][j], "'  ",
             m.size[0] + 2*Boldness, " x ", m.size[1] + 2*Boldness, " mm"));
}
