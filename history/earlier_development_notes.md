# First-layer skip prototype

UPDATE: Icarus now verifies 100 RTL vectors with zero mismatch and 10,116
cycles. A new fit uses 1,401 ALMs and seven RAM blocks. It fails 80-MHz setup
but passes checked core setup/hold paths at 75 MHz. See VERIFIED_RESULT.md for
the current evidence, tradeoffs and limitations. The initial notes below record
the earlier stage; the Questa blocker was bypassed with user-approved Icarus.

Original frozen model, thresholds and later-layer schedule are unchanged.
The separate tc_fabs_skip_network module replaces the 49-feature first-layer
scan with a next-active-feature scan. A sentinel handles zero-active rows;
padding beyond feature 48 is ignored. No learned weight or decision threshold
is modified. This is an architecture prototype, not demonstrated novel pruning.

## Checks completed

- Questa vlog compiled module and testbench: zero errors and warnings.
- Independent integer model: all 10,000 retained inputs give identical complete
  first-layer sums and match all 10,000 expected final predictions.
- Software traversal checks include empty masks, padding-only masks, dense
  masks and first/last active features.
- Source hash and numerical results: integer_skip_report.json.

## Unverified benefit

State-sequence analysis predicts 10,116 cycles instead of 14,468 (30.08% fewer)
for the existing 49-input NF-BoT-IoT R-TC-FABS export. This is a cycle prediction,
not a new executed RTL measurement. Clock frequency may change: the priority
encoder adds combinational work and its fit/timing must be checked. No ALM,
RAM, power, energy or throughput advantage has been measured for this prototype.

## Blocking condition

Questa simulation cannot check out a license (Invalid license environment).
Retry with a valid installed Questa license or an available alternate simulator.
The first failed run and a retry using configured user-level license variables
both failed. No license files or system settings were modified.

## Next verification

1. Run tb_skip on at least 100 inputs, then all 10,000.
2. Add direct RTL corner-mask tests and compare both controllers.
3. Compile a separate Quartus project at the same 80-MHz constraint.
4. Report measured simulation cycles, post-fit frequency, ALMs and memory.
5. Only after matching activity is available compare estimated power/energy.

This directory is separate from all original experiment and manuscript sources.
