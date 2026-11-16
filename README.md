# Matched R-TC-FABS controller experiment — 6 September 2026

The frozen seed-17 model is unchanged. The baseline scans all 49 first-layer
features; the skip controller visits only active mask positions. No new training,
threshold tuning, pruning method, or physical-board result is claimed.

| Result | Baseline | First-layer skip |
|---|---:|---:|
| Full RTL vectors / mismatches | 10,000 / 0 | 10,000 / 0 |
| Cycles per inference | 14,468 | 10,116 |
| Shared evaluated clock | 75 MHz | 75 MHz |
| Calculated active latency | 192.907 us | 134.880 us |
| ALMs / registers | 1,153 / 633 | 1,401 / 634 |
| Memory bits / RAM blocks / DSPs | 52,367 / 7 / 0 | 52,367 / 7 / 0 |
| Worst 75-MHz setup / hold slack | +0.775 / +0.169 ns | +0.303 / +0.172 ns |
| Estimated core dynamic power | 7.39 mW | 12.05 mW |
| Estimated total thermal power | 427.08 mW | 431.77 mW |
| Estimated total energy / inference | 82.3866 uJ | 58.2371 uJ |
| Estimated core dynamic energy / inference | 1.42558 uJ | 1.62530 uJ |
| Toggle rates supplied by simulation | 35.1% | 30.2% |
| Quartus power confidence | Low | Low |

Latency decreases 30.08%, ALMs increase 21.51%, total estimated energy decreases
29.31%, and core dynamic energy increases 14.01%. Total energy is total thermal
power multiplied by active inference time, including whole-device static power
over that interval. It is not incremental switching energy, idle-to-active energy,
or a physical board measurement. The VCD represents the first 32 retained inputs
at a shared 6.667-ns half-period. Unmatched activity is largely inferred.

Both designs were fitted with the same Quartus Lite 25.1std.0 Build 1129 settings,
two processors, and Cyclone V 5CSEMA5F31C6. Both matched 80-MHz fits failed setup
(baseline -0.058 ns; skip -0.530 ns). All four available setup and hold corners
pass when the same routed netlists are reanalyzed at 75 MHz. External interface
delays, HPS power, feature extraction, and transfer are outside this core boundary.

## Verification and provenance

- `evidence.json` contains parsed numerical results, limitations, and source/VCD hashes.
- `reports/verilator_full_*.txt`: 10,000 predictions and exact cycle counts per controller.
- `reports/power_*.txt`: independent Icarus checks on the 32 activity vectors.
- `reports/corners.txt`: 448 next-active checks and 14 complete-controller corner cases
  comparing both RTL implementations, including empty/padding masks and signed ties.
- `reports/{baseline,skip}`: fit, timing, power, activity coverage, and all 75-MHz corners.
- `*_activity.vcd.gz`: preserved activity traces; decompress to reproduce power analysis.
- `generated/`: the exact retained vectors, expected decisions, and model memories.
- `SHA256SUMS.json`: all packaged experiment files except the manifest itself.

The earlier Icarus run stopped after 3,300 checked vectors with zero mismatches.
Its partial log is retained, but the completion claim comes from the full Verilator
4.038 runs on the unchanged RTL. Verilator is a two-state compiled simulator;
Icarus additionally checks the stated four-state activity and corner tests.
Both simulator logs and Quartus warnings are preserved, not silently discarded.

`history/` contains superseded 100-vector notes. The structural/certificate pilot
files record unsuccessful exploratory screens, not measured hardware gains and
not part of the paper's claimed method. The decision-bound pilot resolved none
of its 256 inputs before evaluating the whole first layer.

## Reproduce

Run `bash run_verification.sh` from this directory with Verilator 4.038 or compatible,
GNU make/g++, and Icarus installed. The harness refuses missing vectors/labels and
requires exactly 10,000 successful inputs for each controller. The baseline file
retains the same module name so the identical top-level and harness can be reused.
Python/NumPy are needed only for `python check_integer_skip.py`.

On Windows, use `run_quartus.ps1 -QuartusBin <quartus-bin64>` after decompression.
It fits both projects with their original 80-MHz settings, reanalyzes the same
netlists with `skip75.sdc`, and uses the VCDs for the matched 75-MHz power estimate.
A successful compile does not imply successful timing: inspect the retained
80-MHz failure reports and 75-MHz setup/hold reports separately.

Training data and checkpoints are not needed to rerun this fixed-export hardware
experiment. Reproducing training follows the repository's main reproducibility
instructions and the datasets' original access conditions.

## Withheld file

`generated/r_tc_fabs_nfbot/full_inputs.hex` is not published here. It holds the
10,000 binarized input vectors used to drive the RTL testbenches, derived from
NF-BoT-IoT-v3, and is withheld so that nothing derived from that dataset is
redistributed. The dataset itself is available from its original providers
(Sarhan et al., NetFlow Datasets for Machine Learning-Based Network Intrusion
Detection Systems).

Consequences for anyone re-running this repository:

- `tb_skip.sv`, `tb_resume.sv`, `tb_power.sv` and `verify_verilator.cpp` all
  read that file, so the full 10,000-vector equivalence run cannot be
  reproduced from the repository as published.
- `check_integer_skip.py`, `pilot_decision_bounds.py` and
  `screen_certified_structure.py` reference it for the same reason.
- `SHA256SUMS.json` still carries its digest, so the checksum manifest will
  report one missing file.
- Everything else — the RTL sources, the exported mask, threshold and schedule
  memories, the Quartus project, the fitter and timing reports, and
  `full_expected_dense.hex` / `full_expected_sparse.hex` — is complete.

The vectors can be regenerated from the cited dataset using the binarization
and endpoint-pair split described in the paper. They are available from the
author on request.
