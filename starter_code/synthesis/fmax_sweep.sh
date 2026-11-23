#!/bin/bash
# fmax_sweep.sh -- map rv_core once, then find the clock period where slack hits zero.
#
# Run from starter_code/. Requires the EA-machine toolchain: yosys + the slang
# plugin (plugin -i slang) and OpenSTA (sta). Neither is available on the
# development laptop, which is why this script exists rather than a measured
# number in the report.
#
# For the fusion A/B, run this script twice -- once with FUSE_ENABLE = 1'b0 and
# once with 1'b1 in code/rv_core.sv -- and compare the two fmax figures. The
# feature pays in time only while f_max(on) / f_max(off) > 1048/1339 = 0.782.

set -e
PERIODS="${PERIODS:-10 8 6 5 4 3 2.5 2}"

echo "=== mapping (yosys) ==="
yosys synthesis/synthesis.ys > synthesis/yosys.log 2>&1 || {
    echo "yosys failed; see synthesis/yosys.log"; exit 1; }
echo "netlist: synth.v ($(ls -la synth.v | awk '{print $5}') bytes)"

printf '%-12s %-14s %-12s %-10s\n' "constraint" "slack_ns" "period_min" "fmax_MHz"
for P in $PERIODS; do
    out=$(PERIOD=$P sta -exit synthesis/timing.tcl 2>&1)
    slack=$(echo "$out"  | awk '/RESULT worst_slack_ns/{print $4}')
    pmin=$(echo "$out"   | awk '/RESULT period_min_ns/{print $4}')
    fmax=$(echo "$out"   | awk '/RESULT fmax_mhz/{print $4}')
    printf '%-12s %-14s %-12s %-10s\n' "${P}ns" "$slack" "$pmin" "$fmax"
done

echo
echo "fmax is the value at the constraint where slack crosses 0 (period_min == constraint)."
echo "Compare against the FUSE_ENABLE=0 run: fusion pays only while the ratio > 0.782."
