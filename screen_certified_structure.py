"""Data-free feasibility screen. No model/RTL changes; not a novelty claim."""
import json
from pathlib import Path
import numpy as np

ROOT = Path(__file__).resolve().parent
NET = ROOT / 'generated/r_tc_fabs_nfbot/network'
def read(name):
    return [int(s, 16) for s in (NET / ('network_' + name + '.hex')).read_text().split()]
def signed(v):
    return v - (1 << 32) if v >= (1 << 31) else v

weights = []
w0 = np.array([[(1 if w & (1 << j) else -1) if m & (1 << j) else 0
                for j in range(49)] for w, m in zip(read('l0_weights'), read('l0_masks'))])
weights.append(w0)
for layer, width, previous in [(1, 128, 256), (2, 64, 128), (3, 1, 64)]:
    matrix = np.zeros((width, previous), dtype=np.int64)
    for w, a, n, l, v in zip(read('schedule_weights'), read('schedule_addresses'),
                            read('schedule_neurons'), read('schedule_layers'), read('schedule_valid')):
        if l == layer and v:
            matrix[n, a*32:a*32+32] += [1 if w & (1 << j) else -1 for j in range(32)]
    weights.append(matrix)

# Entire signed-int8 input domain, not observed sample min/max.
lower, upper = np.full(49, -128), np.full(49, 127)
constant_masks = []
report = []
for layer, matrix in enumerate(weights):
    lo = np.maximum(matrix, 0) @ lower + np.minimum(matrix, 0) @ upper
    hi = np.maximum(matrix, 0) @ upper + np.minimum(matrix, 0) @ lower
    thresholds = np.array([signed(v) for v in read('output_threshold' if layer == 3 else f'l{layer}_thresholds')])
    direction = np.ones(1, dtype=bool) if layer == 3 else np.array(read(f'l{layer}_directions'), dtype=bool)
    true = np.where(direction, lo >= thresholds, hi <= thresholds)
    false = np.where(direction, hi < thresholds, lo > thresholds)
    constant = true | false
    assert not np.any(true & false)
    constant_masks.append(constant)
    lower = np.where(true, 1, -1)
    upper = np.where(false, -1, 1)
    report.append({'layer': layer, 'neurons': len(matrix), 'provably_constant': int(constant.sum())})

# Backward dependency: a nonconstant required neuron needs its nonzero inputs.
required = np.ones(1, dtype=bool)
needed = {}
for layer in range(3, -1, -1):
    needed[layer] = required & ~constant_masks[layer]
    report[layer]['required_nonconstant'] = int((required & ~constant_masks[layer]).sum())
    report[layer]['not_required'] = int((~required).sum())
    required = np.any(weights[layer][required & ~constant_masks[layer]] != 0, axis=0)
entries = list(zip(read('schedule_layers'), read('schedule_neurons')))
removed = sum(not needed[l][n] for l, n in entries)
# Independent regression check after the structure is fixed. Inputs do not select it.
assets = NET.parent
raw = [int(s, 16) for s in (assets / 'full_inputs.hex').read_text().split()]
x = np.array([[(v >> (8*j)) & 255 for j in range(49)] for v in raw], dtype=np.int64)
x = np.where(x >= 128, x - 256, x)
full = x.copy()
reduced = x.copy()
for layer, matrix in enumerate(weights):
    thresholds = np.array([signed(v) for v in read('output_threshold' if layer == 3 else f'l{layer}_thresholds')])
    direction = np.ones(1, dtype=bool) if layer == 3 else np.array(read(f'l{layer}_directions'), dtype=bool)
    fs = full @ matrix.T
    rs = reduced @ matrix[needed[layer]].T
    full = np.where(np.where(direction, fs >= thresholds, fs <= thresholds), 1, -1)
    reduced = np.zeros_like(full)
    reduced[:, needed[layer]] = np.where(np.where(direction[needed[layer]], rs >= thresholds[needed[layer]], rs <= thresholds[needed[layer]]), 1, -1)
    # This model has no required constant neuron; stop rather than invent constant values.
    if layer < 3:
        used_next = np.any(weights[layer+1][needed[layer+1]] != 0, axis=0)
        assert not np.any(used_next & constant_masks[layer])
assert np.array_equal(full, reduced)
expected = np.array([int(s, 16) for s in (assets / 'full_expected_sparse.hex').read_text().split()])
assert np.array_equal(full[:, 0] > 0, expected.astype(bool))
result = {'scope': 'Conservative interval and dependency screening over all signed-int8 inputs. No training or test samples used.',
          'layers': report, 'schedule_entries': len(entries), 'removable_schedule_entries': removed,
          'modeled_cycles_saved_at_four_cycles_per_entry': 4*removed,
          'regression_vectors': len(x), 'regression_prediction_mismatches': 0,
          'qualification': 'Structure selection is data-free; retained vectors used only for regression. Dead-code elimination is known. No hardware savings or novelty established.'}
(ROOT / 'certified_structure_screen.json').write_text(json.dumps(result, indent=2))
print(json.dumps(result, indent=2))
