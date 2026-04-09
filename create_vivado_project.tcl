# ============================================================
# create_vivado_project.tcl
# Run this script in Vivado to recreate the full project.
#
# Usage (Vivado Tcl Console):
#   source scripts/create_vivado_project.tcl
# ============================================================

set project_name "emg_gesture_fpga"
set project_dir  "[file normalize "./vivado_project"]"
set part         "xc7a35ticsg324-1L"

# Create project
create_project $project_name $project_dir -part $part
set_property board_part digilentinc.com:arty-a7-35:part0:1.1 [current_project]

# Add RTL sources
add_files -norecurse {
    rtl/top_module.v
    rtl/emg_preprocessor.v
    rtl/argmax.v
    rtl/mac_unit.v
    rtl/weight_memory.v
    rtl/conv1d_layer.v
    rtl/dense_layer.v
}

# Add weights memory init file
add_files -norecurse {
    model/weights_real_data_init.mem
}

# Add constraints
add_files -fileset constrs_1 -norecurse {
    constraints/constraints.xdc
}

# Add testbench
add_files -fileset sim_1 -norecurse {
    testbench/tb_emg_top.v
}

# Set top module
set_property top emg_gesture_recognition_top [current_fileset]
set_property top tb_emg_top [get_filesets sim_1]

# Update compile order
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Project created at: $project_dir"
puts "Run synthesis:   launch_runs synth_1 -jobs 4"
puts "Run simulation:  launch_simulation"
