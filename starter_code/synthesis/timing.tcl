# Timing analysis for rv_core, mapped to sky130nm.lib.
#
# The clock period comes from the PERIOD environment variable so the same netlist
# can be measured at several constraints; a netlist's fmax is the period at which
# the worst slack reaches zero. Timing does not change when only the constraint
# changes, so one synthesis can be swept many times.
#
#   PERIOD=6 sta -exit synthesis/timing.tcl
#
# Run this twice for the fusion A/B: once with FUSE_ENABLE = 1'b0 and once with
# 1'b1 in code/rv_core.sv, re-synthesising between runs. The feature pays in time
# only while f_on/f_off > 1048/1339 = 0.782.

read_liberty synthesis/sky130nm.lib
read_verilog synth.v
link_design rv_core

set period 10.0
if {[info exists ::env(PERIOD)]} {
    set period $::env(PERIOD)
}

create_clock -name clk -period $period [get_ports clk]
set_input_delay  0 -clock clk [delete_from_list [all_inputs] [get_ports clk]]
set_output_delay 0 -clock clk [all_outputs]

report_checks -path_delay max -format full_clock_expanded
report_checks -path_delay min
report_tns
report_wns

set slack [worst_slack -max]
# period_min is the tightest clock this netlist can take: the constraint minus
# however much slack is left (or plus however much it is short).
set min_period [expr {$period - $slack}]
puts [format "RESULT period_constraint_ns = %.3f" $period]
puts [format "RESULT worst_slack_ns       = %.3f" $slack]
puts [format "RESULT period_min_ns        = %.3f" $min_period]
puts [format "RESULT fmax_mhz             = %.2f" [expr {1000.0 / $min_period}]]
