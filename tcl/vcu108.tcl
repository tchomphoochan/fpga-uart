## Project setup

set top_level top_loopback

## Output directory setup

set output_dir build/vcu108
file mkdir $output_dir
set files [glob -nocomplain "$output_dir/*"]
if {[llength $files] != 0} {
    puts "Deleting contents of $output_dir."
    file delete -force {*}[glob -directory $output_dir *];
} else {
    puts "$output_dir is empty."
}

## FPGA setup

set part_num xcvu095-ffva2104-2-e
set_part $part_num

## Source file setup

# Read in all system verilog files:
set sources_sv [ glob ./hdl/*.sv ]
read_verilog -sv $sources_sv
# Read in all (if any) verilog files:
set sources_v [ glob -nocomplain ./hdl/*.v ]
if {[llength $sources_v] > 0 } {
  read_verilog $sources_v
}
# Read in constraint files:
read_xdc [ glob ./xdc/*.xdc ]
# read in all (if any) hex memory files:
set sources_mem [ glob -nocomplain ./data/*.mem ]
if {[llength $sources_mem] > 0} {
  read_mem $sources_mem
}

## IP generation

set sources_ip [ glob -nocomplain -directory ./ip -tails * ]
puts $sources_ip
foreach ip_source $sources_ip {
  if {[file isdirectory ./ip/$ip_source]} {
	  read_ip ./ip/$ip_source/$ip_source.xci
    set ip_wrappers_v [ glob -nocomplain ./ip/$ip_source/*.v ]
    if {[llength $ip_wrappers_v] > 0 } {
      read_verilog $ip_wrappers_v
    }
    set ip_wrappers_sv [ glob -nocomplain ./ip/$ip_source/*.sv ]
    if {[llength $ip_wrappers_sv] > 0 } {
      read_verilog $ip_wrappers_sv
    }
  }
}
generate_target all [get_ips]
synth_ip [get_ips]

## Bitstream generation steps

# Run Synthesis

synth_design -top $top_level -part $part_num -verbose
opt_design
write_checkpoint -force $output_dir/post_synth.dcp
report_timing_summary -file $output_dir/post_synth_timing_summary.rpt
report_utilization -file $output_dir/post_synth_util.rpt -hierarchical -hierarchical_depth 4
report_timing -file $output_dir/post_synth_timing.rpt

# Run place

place_design
report_clock_utilization -file $output_dir/clock_util.rpt

# Get timing violations and run optimizations if needed
if {[get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]] < 0} {
 puts "Found setup timing violations => running physical optimization"
 phys_opt_design
}

write_checkpoint -force $output_dir/post_place.dcp
report_timing_summary -file $output_dir/post_place_timing_summary.rpt
report_utilization -file $output_dir/post_place_util.rpt
report_timing -file $output_dir/post_place_timing.rpt

# Run route

route_design -directive Explore
report_route_status -file $output_dir/post_route_status.rpt
report_timing_summary -file $output_dir/post_route_timing_summary.rpt
report_timing -file $output_dir/post_route_timing.rpt
report_power -file $output_dir/post_route_power.rpt
report_drc -file $output_dir/post_imp_drc.rpt

# Write bitstream

write_bitstream -force $output_dir/final.bit


# Original source:
# https://fpga.mit.edu/6205/_static/F24/default_files/build.tcl