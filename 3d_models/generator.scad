// ===
// parameters
// ===

//$fa = 1;
//$fs = 0.4;
$fn = 32;

key_width = 14;
key_height = 14;
key_distance = 5.1;
stagger_distance = 5;

right_stagger = [0, 0, 2, 1, 0, 0, 0];
left_stagger  = [0, 0, 2, 1, 0, 0];

plate_bridge = 25;
plate_margin = 7;

plate_thickness = 1.5;
bottom_plate_height = 2.5;

hull_height = 22 - plate_thickness - bottom_plate_height;
hull_thickness = 4;

// === USB cutout ===
usb_width    = 12;
usb_height   = 9;
// cut placement
usb_z_bottom = 0;
usb_y_outer  = 100;
usb_y_inner  = 20;

module usb_cutout() {
    translate([-usb_width/2, usb_y_inner, usb_z_bottom])
        cube([usb_width, usb_y_outer - usb_y_inner, usb_height]);
}

// ===
// modules
// ===

right_hole_centers = [
    [7 * (key_width + key_distance), -key_distance],
    [2 * (key_width + key_distance), -key_distance],
    [7 * (key_width + key_distance), 3 * (key_height + key_distance)],
    [3 * (key_width + key_distance), 3 * (key_height + key_distance) + stagger_distance + key_distance],
    [1 * (key_width + key_distance), -key_height - 1 - 2 * key_distance - 2 * stagger_distance]
];

left_hole_centers = [
    [-6 * (key_width + key_distance), -key_distance],
    [-2 * (key_width + key_distance), -key_distance],
    [-6 * (key_width + key_distance), 3 * (key_height + key_distance)],
    [-3 * (key_width + key_distance), 3 * (key_height + key_distance) + stagger_distance + key_distance],
    [-1 * (key_width + key_distance), -key_height - 1 - 2 * key_distance - 2 * stagger_distance]
];

module key_2d(x, y) {
    translate([x, y, 0])
        square([key_width, key_height]);
}

module right_keys() {
    for (i = [0:2]) {
        for (j = [0:6]) {
            x = j * (key_width + key_distance);
            y = i * (key_height + key_distance) + stagger_distance * right_stagger[j];
            key_2d(x, y);
        }
    }
    for (i = [-1:1]) {
        x = i * (key_width + key_distance);
        y = -key_height - key_distance - 2 * stagger_distance;
        key_2d(x, y);
    }
}

module left_keys() {
    for (i = [0:2]) {
        for (j = [0:5]) {
            x = -key_width - j * (key_width + key_distance);
            y = i * (key_height + key_distance) + stagger_distance * left_stagger[j];
            key_2d(x, y);
        }
    }
    for (i = [-1:1]) {
        x = -key_width - i * (key_width + key_distance);
        y = -key_height - key_distance - 2 * stagger_distance;
        key_2d(x, y);
    }
}

module all_keys_2d() {
    translate([25, 0, 0])  rotate([0, 0,  10]) right_keys();
    translate([-25, 0, 0]) rotate([0, 0, -10]) left_keys();
}

module hole_screws(hole_centers) {
    for (point = hole_centers) {
        translate([point[0], point[1], 0])
            circle(d = 2.2);
    }
}

module hole_heads(hole_centers) {
    for (point = hole_centers) {
        translate([point[0], point[1], 0])
            circle(d = 4);
    }
}

module hole_nuts(hole_centers) {
    for (point = hole_centers) {
        translate([point[0], point[1], 0])
            circle(d = 5, $fn = 6);
    }
}

module all_screws_2d() {
    translate([25, 0, 0])  rotate([0, 0,  10]) hole_screws(right_hole_centers);
    translate([-25, 0, 0]) rotate([0, 0, -10]) hole_screws(left_hole_centers);
}

module all_heads_2d() {
    translate([25, 0, 0])  rotate([0, 0,  10]) hole_heads(right_hole_centers);
    translate([-25, 0, 0]) rotate([0, 0, -10]) hole_heads(left_hole_centers);
}

module all_nuts_2d() {
    translate([25, 0, 0])  rotate([0, 0,  10]) hole_nuts(right_hole_centers);
    translate([-25, 0, 0]) rotate([0, 0, -10]) hole_nuts(left_hole_centers);
}

module all_screws() {
    union() {
        linear_extrude(20)
        all_screws_2d();
        
        translate([0, 0, 20])
        linear_extrude(2)
        all_heads_2d();
    }
}

module all_nuts() {
    linear_extrude(2)
        all_nuts_2d();
}

module plate_outline_2d() {
    offset(r = -3)
    offset(delta = 3)
    union() {
    offset(r = plate_margin)
        offset(delta = -plate_bridge)
            offset(r = plate_bridge)
                all_keys_2d();
    offset(r = 2)
    all_heads_2d();
    }
}

module plate() {
    linear_extrude(plate_thickness)
    difference() {
        plate_outline_2d();
        all_keys_2d();
    }
}

module walls() {
    union() {
        linear_extrude(hull_height)
        difference() {
            plate_outline_2d();
            
            offset(-hull_thickness)
                plate_outline_2d();
        };
        linear_extrude(hull_height)
        offset(2) all_screws_2d();
    }
}

module upper_half() {
    difference() {
        difference() {
            union() {
                walls();
                translate([0, 0, hull_height])
                    plate();
            };
            translate([0, 0, -bottom_plate_height])
            all_screws();
        };
        
        usb_cutout();
    }
}

module lower_half() {
    difference() {
    difference() {
        linear_extrude(bottom_plate_height)
            plate_outline_2d();
      
        all_screws();
    };
    all_nuts();
    }
}

// ===
// 3d-printing split
// ===

pseudoinf = 500;
dovetail_base = 6;
dovetail_tip = 8;
tab_depth = 2.5;
tab_ys = [-25, 5];

module tab(clear) {
    offset(delta = clear)
    polygon([
        [0, -dovetail_base / 2],
        [tab_depth, - dovetail_tip / 2],
        [tab_depth, dovetail_tip / 2],
        [0, dovetail_base / 2]
    ]);
}

module tabs(clear) {
    for (y = tab_ys) {
        translate([0, y, 0]) tab(clear);
    }
}

module cut_left_tabbed() {
    linear_extrude(pseudoinf, center=true)
    union() {
        translate([-pseudoinf, -pseudoinf / 2, 0])
            square([pseudoinf, pseudoinf]);
        tabs(0);
    }
}

module cut_right_tabbed() {
    linear_extrude(pseudoinf, center=true)
    difference() {
        translate([0, -pseudoinf / 2, 0])
            square([pseudoinf, pseudoinf]);
        
        tabs(0);
    }
}

module upper_left()  { intersection() { upper_half(); cut_left_tabbed();  } }
module upper_right() { intersection() { upper_half(); cut_right_tabbed(); } }
module lower_left()  { intersection() { lower_half(); cut_left_tabbed();  } }
module lower_right() { intersection() { lower_half(); cut_right_tabbed(); } }

upper_left();
upper_right();
lower_left();
lower_right();