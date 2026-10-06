read_liberty synthesis/sky130nm.lib
read_verilog synth.v
link_design rv_core

create_clock -name clk -period 10.0 [get_ports clk]   ;# adjust port name/period
set_input_delay  0 -clock clk [delete_from_list [all_inputs] [get_ports clk]]
set_output_delay 0 -clock clk [all_outputs]

report_checks -path_delay max -format full_clock_expanded
report_checks -path_delay min
report_tns
report_wns
if {[llength [info commands report_clock_min_period]]} {
    report_clock_min_period
} else {
    set min_period [expr {10.0 - [worst_slack -max]}]
    puts [format "clk period_min = %.2f fmax = %.2f" $min_period [expr {1000.0 / $min_period}]]
}
