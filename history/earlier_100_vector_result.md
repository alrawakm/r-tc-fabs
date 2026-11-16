# First-layer skipping: RTL and post-fit development result

6 September 2026. Model weights, masks, integer thresholds and later-layer
schedule are unchanged. This is a separate architecture experiment, not a
replacement for frozen R-TC-FABS results or proof of methodological novelty.

## Results

| Quantity | Original R-TC-FABS controller | Skip prototype |
|---|---:|---:|
| Cycles per inference | 14,468 (retained original record) | 10,116 (new RTL run) |
| Core clock used for latency calculation | 80 MHz | 75 MHz |
| Calculated classifier latency | 180.850 us | 134.880 us |
| ALMs | 1,157 (retained original fit) | 1,401 (new fit) |
| Registers | 630 | 634 |
| Block-memory bits | 52,367 | 52,367 |
| RAM blocks | 7 | 7 |
| DSP blocks | 0 | 0 |

Cycle count falls 30.08%. After allowing for the lower clock, calculated latency
falls 25.42%. ALMs increase by 244 (21.09%); memory and DSP counts are unchanged.
The baseline was not refitted in this run. Both fits use the same device and
performance settings, but the new fit limits compilation to two processors.

## Functional evidence

Icarus Verilog compiled the new RTL and ran the retained end-to-end vectors:

    PASS vectors=100 mismatches=0 cycles_per_inference=10116

The behavioral testbench uses a 12.5-ns cycle to count transactions. It has no
post-route delays, so that run is not evidence of 80-MHz timing closure.
Latency above uses 75 MHz, independently checked against the routed netlist.
An independent integer check also matches all 10,000 stored expected decisions
and all first-layer sums. Only 100 inputs have been executed in the new RTL.

RTL SHA-256:
011F1A1E20468FF485DF324DD58B0AA85664419CE8993532F517FABAF2893E10

## Timing evidence

Quartus Lite 25.1std.0 build 1129, Cyclone V 5CSEMA5F31C6.
The design was placed/routed with a 12.5-ns constraint. Compilation completed,
but setup failed at 80 MHz: worst slack -0.530 ns. This failed result is retained
in output_files/skip.sta.summary. Do not describe compilation success as timing
success.

Reanalysis of the same routed netlist with skip75.sdc passes setup and hold
in all four available corners. Worst setup is +0.303 ns; worst hold +0.172 ns.
Quartus truncates 13.333333 ns to 13.333 ns (slightly tighter than exact 75 MHz).
Reports: timing75_*_setup.txt and timing75_*_hold.txt.

External inputs/outputs have no interface delay constraints, as in the original
project. Timing claims cover the internal clocked core, not a board interface.
The compilation contains warnings, including virtual-I/O and ROM-port warnings.
No physical FPGA, gate-level simulation, new power estimate, energy measurement
or deployment-throughput result is claimed.

## Simulator installation

User approved Icarus installation after Questa license failure. The distributor
installer installed to C:\iverilog, rather than the requested workspace path.
Existing Questa/license configuration was not modified.
Installer SHA-256: 5D65C90C269AF75C12BA6E9AF6CEB0D64511EA8913D0B2A28EB82E697521CF17.
Source: https://www.bleyer.org/icarus/iverilog-v14-20260804-x64_setup.exe

## Remaining checks

Run the full 10,000-vector RTL set and direct RTL corner-mask tests. Refit the
baseline under matched settings, check other masks/seeds, and use matched VCD
activity before making an energy claim. Literature comparison is still needed
to determine whether this standard zero-skipping adaptation adds publishable
novelty when combined with the full method.
