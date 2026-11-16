# Novelty screen: evidence before another experiment

Checked 6 September 2026. Focused screening, not an exhaustive systematic review.
Publisher abstracts/previews and author repositories were inspected; inaccessible
full texts must be reviewed before claiming an absence of a mechanism.

## Closest work and implications

| Work | Established mechanism | Implication for this project |
| --- | --- | --- |
| PCBNN, 2026, https://doi.org/10.26599/TST.2026.9010073 | Parallel binary convolution, contrastive learning, channel segmentation for a fully binary input layer. Publisher states online 6 July 2026. | First-layer binarization plus hardware/software co-design is not a new claim. |
| Enhanced hardware efficiency and data reuse, 2025, https://doi.org/10.1016/j.mejo.2025.106556 | Enhanced thermometer input encoding and unified binary computation, reducing off-chip access. | Replacing the expensive first layer with binary computation is already addressed. Full text not accessed. |
| FPGA bit-level weight sparsity and mixed-bit accelerator, 2025, https://doi.org/10.1016/j.sysarc.2025.103463 | Bit sparsity and mixed-bit execution; addresses indexing and FPGA resource balance. | Sparse/mixed-precision hybrid hardware is not automatically novel. |
| BISMO, 2018, https://arxiv.org/abs/1806.08862 | Vectorized bit-serial matrix multiplication with configurable precision/parallelism. | Exact bit-plane execution alone is a baseline, not a contribution. |
| bitSMM, 2026 preprint, https://arxiv.org/abs/2603.14988 | Runtime operand precision 1–16 bits, two MAC variants. | Runtime precision configurability alone is insufficient. Preprint status retained. |
| PiC-BNN, 2026 preprint, https://arxiv.org/abs/2601.19920 | End-to-end BNN execution using processing-in-CAM, with a fabricated chip. | Moving computation into memory is established and requires a different validation platform. |
| BinDRAM, September 2026 issue, https://doi.org/10.1016/j.future.2026.108486 | End-to-end BNN on commodity DRAM; duplicated last layer. | End-to-end coverage and removing nonbinary overhead are already explicit research targets. |
| Activation-deterministic early termination, https://doi.org/10.1016/j.aeue.2026.156548 | Provable threshold-based termination and activation determinism before max pooling. | Exact early stopping is not a new mechanism. Publisher preview lists December 2026 issue; online-first date not confirmed, so do not describe it as a completed past issue. |

Earlier anchors: CPrune https://arxiv.org/abs/2207.01260;
DepGraph https://arxiv.org/abs/2301.12900;
O3BNN https://www.pnnl.gov/publications/o3bnn-out-order-architecture-high-performance-binarized-neural-network-inference-fine.
These rule out generic compiler-aware pruning, dependency grouping, and early
termination as independent novelty claims.

## Local bottleneck

Retained schedule: 256 first-layer neurons, 8192 active input weights, 417 later
schedule entries. Skip-controller cycle model: 256+8192+4*417 = 10116.
First-layer share = 8448/10116 = approximately 83.51 percent of cycles.
This is a latency decomposition, NOT an energy or memory-traffic measurement.
Do not infer external-DRAM bottlenecks: the retained core stores parameters on chip.

## Decision

No strong unclaimed mechanism has been established by this screen. Do not rename
the existing optimizations or start a new training campaign on that basis.

Narrow experimental question worth resolving: for this sparse signed-int8-input
layer, what does exact bit-plane execution cost relative to serial active-weight
execution, once mask handling, signed arithmetic, schedule storage and control are
included? This is initially a BASELINE comparison. It preserves the model and
does not require retraining or a board. If a known bit-serial baseline resolves
the bottleneck, report that engineering result, not a novel method.

A novel follow-on requires a concrete failure of the closest baselines and a new
mechanism resolving it, with a distinct algorithm/architecture description. A
combination alone, or lower operations on one model, is not sufficient evidence.

## Feasibility gate (proposed, not measured)

1. Compare exact sparse serial and bit-plane integer outputs including -128,
   empty/full masks, threshold ties and padding.
2. Compare matched RTL cycle counts, post-fit ALMs, memory and timing. Account for
   preprocessing/packing rather than assuming it is free.
3. Run matched activity-based power estimation if available. Keep estimated
   energy separate from physical-board measurements.
4. Check several masks/models without tuning on held-out labels.
5. Only invest in a new design if the comparison exposes a repeatable limitation
   that the cited prior mechanisms do not already solve.

Frozen source, manuscript and reported detection results have not been changed.
