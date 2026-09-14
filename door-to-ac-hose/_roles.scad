include <bulkhead.scad>
difference() {
    union() {
        color("SteelBlue")       body();
        color("Gainsboro", 0.5)  door();
        translate([0,0,door_thickness]) {
            color("Goldenrod")   widener();
            color("IndianRed")   translate([0,0, acc_stack_h+flare_len]) collet_nut();
            color("DarkSeaGreen")translate([0,0, acc_stack_h+flare_len+10]) hose_stub(46);
        }
    }
    translate([-400,-400,-400]) cube([800,400,900]);
}
