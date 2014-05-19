# 
# Synthesis run script generated by Vivado
# 

set top [file dirname [file normalize [info script]]]
set output "${top}/out"
set topsrc "${top}/src"
set libsrc "${top}/lib"
set ipsrc "${top}/ip"
set design_name "zynq_design_wrapper"

file mkdir $output

# propagating constant 0 across sequential element
set_msg_config -id {Synth 8-3333} -suppress
# sequential element is unused and will be removed
set_msg_config -id {Synth 8-3332} -suppress
# module 'foo' declared at 'bar' bound to instance 'baz' of component 'bla'
set_msg_config -id {Synth 8-3491} -suppress
# synthesizing module 'foobar'
set_msg_config -id {Synth 8-638} -suppress
# done synthesizing module 'foobar'
set_msg_config -id {Synth 8-256} -suppress

create_project -in_memory -part xc7z020clg484-1
set_property target_language VHDL [current_project]
set_property board_part em.avnet.com:zed:part0:1.0 [current_project]
set_param project.compositeFile.enableAutoGeneration 0
set_property default_lib xil_defaultlib [current_project]

add_files [ glob -directory $ipsrc -type f */*.xci ]

#set_property generate_synth_checkpoint false [ get_files -filter {FILE_TYPE == IP} ]

add_files -fileset sources_1 -scan_for_includes $topsrc


read_vhdl -library sha256_lib [ glob -directory $libsrc/sha256_lib -type f *.vhd ]
read_vhdl -library global_lib [ glob -directory $libsrc/global_lib -type f *.vhd ]
set_property top ${design_name} [current_fileset]

set_param synth.vivado.isSynthRun true

generate_target -force {Synthesis} [get_files -filter {FILE_TYPE == IP && NAME !~ "*_axi_periph_*"} ]


set_property is_enabled false [ get_files */ps7_init.* ]

synth_design -part xc7z020clg484-1
write_checkpoint -force $output/post-synth_${design_name}.dcp
report_utilization -file $output/post-synth_${design_name}.utilization
opt_design
place_design
route_design

write_checkpoint -force $output/post-route_${design_name}.dcp
report_timing_summary -file $output/post-route_${design_name}.timing
write_bitstream -force $output/system.bit

quit
