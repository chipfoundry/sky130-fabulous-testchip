# Copyright 2025 LibreLane Contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

source $::env(SCRIPTS_DIR)/openroad/common/set_global_connections.tcl
set_global_connections

puts "\[INFO\] Generating padring…"

set block [ord::get_db_block]
set units [$block getDefUnits]

# Pad Placement Algorithm
#
# For all sides:
#
# 1. Sum up all pad widths for the side
# 2. If that value is larger than the side, throw an error
# 3. Subtract that value from the side width
# 4. Divide this value with the number of pads for this side + 1
# 5. Round this value to the minimum site width (this is the spacing between pads)
# 6. Multiply this value with the number of pads for this side minus one, subtract this value from the side width
# 7. Divide this value by two, this is the spacing from pads to corners
# 8. Throw an error if this spacing is not a multiple of the minimum site width

set DIE_HEIGHT [expr {[lindex $::env(DIE_AREA) 3] - [lindex $::env(DIE_AREA) 1]}]
set DIE_WIDTH [expr {[lindex $::env(DIE_AREA) 2] - [lindex $::env(DIE_AREA) 0]}]

# Get pad and corner site
set pad_site [pad::find_site $::env(PAD_SITE_NAME)]
set pad_corner_site [pad::find_site $::env(PAD_CORNER_SITE_NAME)]

if { $pad_site == "NULL" } {
    puts stderr "\[ERROR\] No pad site $::env(PAD_SITE_NAME) found."
    exit 1
}

if { $pad_corner_site == "NULL" } {
    puts stderr "\[ERROR\] No pad corner site $::env(PAD_CORNER_SITE_NAME) found."
    exit 1
}

if { [$pad_site getClass] != "PAD" } {
    puts stderr "\[ERROR\] Wrong class for pad site $::env(PAD_SITE_NAME): [$pad_site getClass] (expected PAD)."
    exit 1
}

if { [$pad_corner_site getClass] != "PAD" } {
    puts stderr "\[ERROR\] Wrong class for pad corner site $::env(PAD_CORNER_SITE_NAME): [$pad_corner_site getClass] (expected PAD)."
    exit 1
}

set pad_site_width [expr double([$pad_site getWidth]) / $units]
set pad_site_height [expr double([$pad_site getHeight]) / $units]

set pad_corner_site_width [expr double([$pad_corner_site getWidth]) / $units]
set pad_corner_site_height [expr double([$pad_corner_site getHeight]) / $units]

puts "\[INFO\] $::env(PAD_SITE_NAME): $pad_site_width μm by $pad_site_height μm"
puts "\[INFO\] $::env(PAD_CORNER_SITE_NAME): $pad_corner_site_width μm by $pad_corner_site_height μm"

# Make IO sites
make_io_sites \
    -horizontal_site $::env(PAD_SITE_NAME) \
    -vertical_site $::env(PAD_SITE_NAME) \
    -corner_site $::env(PAD_CORNER_SITE_NAME) \
    -offset $::env(PAD_EDGE_SPACING) \
    -rotation_horizontal $::env(PAD_ROTATION_HORIZONTAL) \
    -rotation_vertical $::env(PAD_ROTATION_VERTICAL) \
    -rotation_corner $::env(PAD_ROTATION_CORNER)

set sides {PAD_SOUTH PAD_EAST PAD_NORTH PAD_WEST}
set vertical_sides [list PAD_EAST PAD_WEST]
set horizontal_sides [list PAD_SOUTH PAD_NORTH]
set row_names [dict create PAD_SOUTH IO_SOUTH PAD_EAST IO_EAST PAD_NORTH IO_NORTH PAD_WEST IO_WEST]

set caravel_pad_pos [dict create]

# bottom row pad centers (left to right): 11
dict set caravel_pad_pos PAD_SOUTH "\
    437.5 \
    706.5 \
    975.5 \
    1249.5 \
    1518.5 \
    1792.5 \
    2066.5 \
    2340.5 \
    2614.5 \
    2888.5 \
    3157.5 \
"

# top row pad centers (left to right): 11
dict set caravel_pad_pos PAD_NORTH "\
    429.5 \
    686.5 \
    943.5 \
    1200.5 \
    1458.5 \
    1710.5 \
    1967.5 \
    2412.5 \
    2669.5 \
    2921.5 \
    3178.5 \
"

# left column pad centers (bottom to top): 21
dict set caravel_pad_pos PAD_WEST "\
    383.5 \
    594.5 \
    956.5 \
    1172.5 \
    1388.5 \
    1604.5 \
    1820.5 \
    2036.5 \
    2247.5 \
    2458.5 \
    2674.5 \
    2890.5 \
    3106.5 \
    3322.5 \
    3538.5 \
    3754.5 \
    3970.5 \
    4181.5 \
    4392.5 \
    4603.5 \
    4819.5 \
"

# right column pad centers (bottom to top): 20
dict set caravel_pad_pos PAD_EAST "\
    543.5 \
    769.5 \
    994.5 \
    1220.5 \
    1445.5 \
    1670.5 \
    1896.5 \
    2121.5 \
    2342.5 \
    2562.5 \
    2782.5 \
    3008.5 \
    3233.5 \
    3459.5 \
    3684.5 \
    3909.5 \
    4135.5 \
    4355.5 \
    4581.5 \
    4801.5 \
"

# Some pads have the bondpad slightly offset from the center
set bondpad_offsets [dict create]
dict set bondpad_offsets sky130_ef_io__gpiov2_pad 2.885

foreach side $sides {
    puts "Placing pads for $side…"

    puts [dict get $caravel_pad_pos $side]

    set pad_positions [dict get $caravel_pad_pos $side]
    
    if {[llength [dict get $caravel_pad_pos $side]] != [llength $::env($side)]} {
        puts stderr "\[ERROR\] Number of pad instances and number of pad positions do not match!"
        exit 1
    }
    
    for { set i 0 } { $i < [llength [dict get $caravel_pad_pos $side]] } { incr i } {
        set pad_position [lindex [dict get $caravel_pad_pos $side] $i]
        set inst_name [lindex $::env($side) $i]

        puts "Placing $inst_name bondpad center at $pad_position…"
        
        if { [set inst [$block findInst $inst_name]] == "NULL" } {
            puts stderr "\[ERROR\] No instance $inst_name found."
            exit 1
        }
        set master_name [[$inst getMaster] getName]
        
        set bondpad_offset 0
        if { [dict exists $bondpad_offsets $master_name] } {
            set bondpad_offset [dict get $bondpad_offsets $master_name]
        }
        
        # Convert to micrometer
        set width  [expr [[$inst getMaster] getWidth] / $units]
        set height [expr [[$inst getMaster] getHeight] / $units]
        
        # Place the pads
        set final_pad_position [expr $pad_position + $bondpad_offset - double($width)/2]
        puts "Final pad position: $final_pad_position…"
        place_pad -row [dict get $row_names $side] -location $final_pad_position $inst_name -master $master_name
    }
}

# Add additional pad slices to connect power domains

place_pad -row IO_SOUTH -location $pad_corner_site_width \
    vcchib_vccd_and_vswitch_vddio_slices\\\[0\\\].vcchib_vccd_and_vswitch_vddio_slice -master sky130_ef_io__connect_vcchib_vccd_and_vswitch_vddio_slice_20um
place_pad -row IO_SOUTH -location [expr $DIE_WIDTH - $pad_corner_site_width - 20] \
    vcchib_vccd_and_vswitch_vddio_slices\\\[1\\\].vcchib_vccd_and_vswitch_vddio_slice -master sky130_ef_io__connect_vcchib_vccd_and_vswitch_vddio_slice_20um

place_pad -row IO_EAST -location $pad_corner_site_height \
    vcchib_vccd_and_vswitch_vddio_slices\\\[2\\\].vcchib_vccd_and_vswitch_vddio_slice -master sky130_ef_io__connect_vcchib_vccd_and_vswitch_vddio_slice_20um
place_pad -row IO_EAST -location [expr $DIE_HEIGHT - $pad_corner_site_height - 20] \
    vcchib_vccd_and_vswitch_vddio_slices\\\[3\\\].vcchib_vccd_and_vswitch_vddio_slice -master sky130_ef_io__connect_vcchib_vccd_and_vswitch_vddio_slice_20um

place_pad -row IO_NORTH -location $pad_corner_site_width \
    vcchib_vccd_and_vswitch_vddio_slices\\\[5\\\].vcchib_vccd_and_vswitch_vddio_slice -master sky130_ef_io__connect_vcchib_vccd_and_vswitch_vddio_slice_20um
place_pad -row IO_NORTH -location [expr $DIE_WIDTH - $pad_corner_site_width - 20] \
    vcchib_vccd_and_vswitch_vddio_slices\\\[4\\\].vcchib_vccd_and_vswitch_vddio_slice -master sky130_ef_io__connect_vcchib_vccd_and_vswitch_vddio_slice_20um

place_pad -row IO_WEST -location $pad_corner_site_height \
    vcchib_vccd_and_vswitch_vddio_slices\\\[7\\\].vcchib_vccd_and_vswitch_vddio_slice -master sky130_ef_io__connect_vcchib_vccd_and_vswitch_vddio_slice_20um
place_pad -row IO_WEST -location [expr $DIE_HEIGHT - $pad_corner_site_height - 20] \
    vcchib_vccd_and_vswitch_vddio_slices\\\[6\\\].vcchib_vccd_and_vswitch_vddio_slice -master sky130_ef_io__connect_vcchib_vccd_and_vswitch_vddio_slice_20um

place_pad -row IO_SOUTH -location [expr $pad_corner_site_width + 20] \
    vdda_vddio_and_vssa_vssio_slices\\\[0\\\].vdda_vddio_and_vssa_vssio_slice -master sky130_ef_io__connect_vdda_vddio_and_vssa_vssio_slice_20um
place_pad -row IO_SOUTH -location [expr $DIE_WIDTH - $pad_corner_site_width - 40] \
    vdda_vddio_and_vssa_vssio_slices\\\[1\\\].vdda_vddio_and_vssa_vssio_slice -master sky130_ef_io__connect_vdda_vddio_and_vssa_vssio_slice_20um

place_pad -row IO_EAST -location [expr $pad_corner_site_height + 20] \
    vdda_vddio_and_vssa_vssio_slices\\\[2\\\].vdda_vddio_and_vssa_vssio_slice -master sky130_ef_io__connect_vdda_vddio_and_vssa_vssio_slice_20um
place_pad -row IO_EAST -location [expr $DIE_HEIGHT - $pad_corner_site_height - 40] \
    vdda_vddio_and_vssa_vssio_slices\\\[3\\\].vdda_vddio_and_vssa_vssio_slice -master sky130_ef_io__connect_vdda_vddio_and_vssa_vssio_slice_20um

place_pad -row IO_NORTH -location [expr $pad_corner_site_width + 20] \
    vdda_vddio_and_vssa_vssio_slices\\\[5\\\].vdda_vddio_and_vssa_vssio_slice -master sky130_ef_io__connect_vdda_vddio_and_vssa_vssio_slice_20um
place_pad -row IO_NORTH -location [expr $DIE_WIDTH - $pad_corner_site_width - 40] \
    vdda_vddio_and_vssa_vssio_slices\\\[4\\\].vdda_vddio_and_vssa_vssio_slice -master sky130_ef_io__connect_vdda_vddio_and_vssa_vssio_slice_20um

place_pad -row IO_WEST -location [expr $pad_corner_site_height + 20] \
    vdda_vddio_and_vssa_vssio_slices\\\[7\\\].vdda_vddio_and_vssa_vssio_slice -master sky130_ef_io__connect_vdda_vddio_and_vssa_vssio_slice_20um
place_pad -row IO_WEST -location [expr $DIE_HEIGHT - $pad_corner_site_height - 40] \
    vdda_vddio_and_vssa_vssio_slices\\\[6\\\].vdda_vddio_and_vssa_vssio_slice -master sky130_ef_io__connect_vdda_vddio_and_vssa_vssio_slice_20um

puts "\[INFO\] Placing corner cells…"

# Place corner cells
place_corners $::env(PAD_CORNER)

puts "\[INFO\] Placing filler cells…"

# Place filler cells
place_io_fill -row IO_NORTH {*}$::env(PAD_FILLERS)
place_io_fill -row IO_SOUTH {*}$::env(PAD_FILLERS)
place_io_fill -row IO_WEST {*}$::env(PAD_FILLERS)
place_io_fill -row IO_EAST {*}$::env(PAD_FILLERS)

puts "\[INFO\] Connecting ring signals…"

# Connect the ring signals
connect_by_abutment

# Place bondpads (if needed)
if { [info exists ::env(PAD_BONDPAD_NAME)] } {
    puts "\[INFO\] Placing bondpads…"
    
    foreach side $sides {
        foreach inst_name $::env($side) {
            if { [set inst [$block findInst $inst_name]] == "NULL" } {
                puts stderr "\[ERROR\] No instance $inst_name found."
                exit 1
            }
            set master_name [[$inst getMaster] getName]

            dict for {master_regex offset} $::env(PAD_BONDPAD_OFFSETS) {
                set offset_x [lindex $offset 0]
                set offset_y [lindex $offset 1]
                
                if {[regexp $master_regex $master_name match]} {
                    puts "\[INFO\] Placing bondpad $::env(PAD_BONDPAD_NAME) for $inst_name of type $master_name at offset ($offset_x, $offset_y)…"
                    place_bondpad -bond $::env(PAD_BONDPAD_NAME) $inst_name -offset [list $offset_x $offset_y]
                }
            }
        }
    }
}

# Place io terminals (if needed)
if { [info exists ::env(PAD_PLACE_IO_TERMINALS)] } {
    puts "\[INFO\] Placing I/O terminals…"
    
    foreach side $sides {
        foreach inst_name $::env($side) {
            if { [set inst [$block findInst $inst_name]] == "NULL" } {
                puts stderr "\[ERROR\] No instance $inst_name found."
                exit 1
            }
            set master_name [[$inst getMaster] getName]
    
            # Try to find the master in PAD_PLACE_IO_TERMINALS
            foreach master_pin $::env(PAD_PLACE_IO_TERMINALS) {
            
                # Split the master name and the pin name
                set parts [split $master_pin /]
                set check_master_name [lindex $parts 0]
                set pin_name [lindex $parts 1]
                
                # Found a match, place the terminal
                if {$master_name == $check_master_name} {
                    place_io_terminals $inst_name/$pin_name
                    break
                }
            }
        }
    }
}

# Remove io rows to avoid causing confusion with the other tools
puts "\[INFO\] Removing I/O rows…"
remove_io_rows
