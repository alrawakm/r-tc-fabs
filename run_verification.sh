#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
ROOT=$(pwd)
mkdir -p work reports/reproduced
verilator --version | tee reports/reproduced/verilator_version.txt
for variant in skip baseline; do
  rtl=tc_fabs_skip_network.sv
  cycles=10116
  if [ "$variant" = baseline ]; then rtl=matched_baseline/tc_fabs_skip_network.sv; cycles=14468; fi
  verilator --cc --exe --build -j 2 -Wno-fatal --top-module skip_top --Mdir "$ROOT/work/$variant" \
    "$rtl" skip_top.sv "$ROOT/verify_verilator.cpp" > "reports/reproduced/${variant}_build.txt" 2>&1
  "work/$variant/Vskip_top" "$cycles" | tee "reports/reproduced/${variant}_full.txt"
  iverilog -g2012 -s tb_power -o "work/${variant}_power.vvp" "$rtl" skip_top.sv tb_power.sv
  vvp "work/${variant}_power.vvp" "+CYCLES=$cycles" "+VCD=${variant}_activity.vcd" | tee "reports/reproduced/${variant}_power.txt"
done
sed 's/module tc_fabs_skip_network/module tc_fabs_baseline_network/' matched_baseline/tc_fabs_skip_network.sv > work/baseline_for_corner.sv
iverilog -g2012 -s tb_corners -o work/corners.vvp tc_fabs_skip_network.sv work/baseline_for_corner.sv tb_corners.sv
vvp work/corners.vvp | tee reports/reproduced/corners.txt
