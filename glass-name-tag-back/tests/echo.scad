// The derived numbers a mesh check needs, in a form a script can read.
// tests/run.py compares the exported MESH against what the MODEL believes,
// rather than against numbers typed into the test -- which would only ever
// prove that two files were edited on the same day.
include <lib.scad>
echo(vals = [clip_len, bar_w, thick, base_y, drop, txt_w, jaw, jaw_root,
             glass_t, bend_r, cw, rim_x, spring_len, spring_ang]);
