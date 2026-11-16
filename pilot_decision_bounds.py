"""Fixed-policy feasibility screen, not an RTL speed or energy measurement."""
import hashlib
import json
from pathlib import Path
import numpy as np

ROOT = Path(__file__).resolve().parent
NET = ROOT / 'generated/r_tc_fabs_nfbot/network'
def read(name):
    return [int(s, 16) for s in (NET / ('network_' + name + '.hex')).read_text().split()]
def signed(v):
    return v - (1 << 32) if v >= (1 << 31) else v

weights = [np.array([[(1 if w & (1 << j) else -1) if m & (1 << j) else 0
                     for j in range(49)] for w, m in zip(read('l0_weights'), read('l0_masks'))])]
for layer, width, previous in [(1,128,256),(2,64,128),(3,1,64)]:
    w = np.zeros((width,previous), dtype=np.int64)
    for bits,a,n,l,v in zip(read('schedule_weights'),read('schedule_addresses'),
                            read('schedule_neurons'),read('schedule_layers'),read('schedule_valid')):
        if l == layer and v:
            w[n,a*32:a*32+32] += [1 if bits & (1 << j) else -1 for j in range(32)]
    weights.append(w)
thresholds = [np.array([signed(v) for v in read(f'l{i}_thresholds')]) for i in range(3)]
thresholds.append(np.array([signed(read('output_threshold')[0])]))
directions = [np.array(read(f'l{i}_directions'),dtype=bool) for i in range(3)] + [np.ones(1,dtype=bool)]

def propagate(lo,hi,w,t,d):
    positive, negative = np.maximum(w,0), np.minimum(w,0)
    sl = lo @ positive.T + hi @ negative.T
    sh = hi @ positive.T + lo @ negative.T
    yes = np.where(d,sl>=t,sh<=t)
    no = np.where(d,sh<t,sl>t)
    assert not np.any(yes & no)
    return np.where(yes,1,-1), np.where(no,-1,1)

# Boundary/tie tests, and exhaustive corner checks for a small signed linear layer.
import itertools
small = np.array([[1,-1,0],[-1,1,1]])
lo, hi = np.array([[-1,-1,-1]]), np.array([[1,1,1]])
bl,bh = propagate(lo,hi,small,np.array([0,1]),np.array([True,False]))
for corner in itertools.product([-1,1],repeat=3):
    sums = np.array(corner) @ small.T
    actual = np.where([sums[0]>=0,sums[1]<=1],1,-1)
    assert np.all(actual>=bl) and np.all(actual<=bh)
for d in [False,True]:
    a,b=propagate(np.array([[0]]),np.array([[0]]),np.array([[1]]),np.array([0]),np.array([d]))
    assert a[0,0]==b[0,0]==1

# Policy fixed before evaluation: first 256 retained vectors; natural neuron order;
# check every 16 neurons. No labels, learned router, reordering, or threshold tuning.
path = NET.parent / 'full_inputs.hex'
raw = [int(s,16) for s in path.read_text().split()[:256]]
x = np.array([[(v>>(8*j))&255 for j in range(49)] for v in raw],dtype=np.int64)
x = np.where(x>=128,x-256,x)
layer0 = np.where(np.where(directions[0],x@weights[0].T>=thresholds[0],x@weights[0].T<=thresholds[0]),1,-1)
full=layer0
for l in range(1,4):
    z=full@weights[l].T
    full=np.where(np.where(directions[l],z>=thresholds[l],z<=thresholds[l]),1,-1)
expected=np.array([int(s,16) for s in (NET.parent/'full_expected_sparse.hex').read_text().split()[:256]])
assert np.array_equal(full[:,0]>0,expected.astype(bool))

stopped=np.zeros(len(x),dtype=bool)
first=np.full(len(x),256,dtype=int)
prediction=np.zeros(len(x),dtype=int)
checkpoints=[]
for count in range(0,257,16):
    lower=np.full_like(layer0,-1); upper=np.ones_like(layer0)
    lower[:,:count]=layer0[:,:count]; upper[:,:count]=layer0[:,:count]
    for l in range(1,4):
        lower,upper=propagate(lower,upper,weights[l],thresholds[l],directions[l])
    resolved=lower[:,0]==upper[:,0]
    assert np.all(lower[:,0]<=full[:,0]) and np.all(full[:,0]<=upper[:,0])
    newly=resolved & ~stopped
    first[newly]=count; prediction[newly]=lower[newly,0]; stopped|=resolved
    checkpoints.append({'first_layer_neurons_evaluated':count,'cumulative_certified':int(stopped.sum())})
assert stopped.all() and np.array_equal(prediction,full[:,0])
costs=1+np.maximum(np.count_nonzero(weights[0],axis=1),1)
prefix=np.r_[0,np.cumsum(costs)]
base=int(prefix[-1]+4*len(read('schedule_weights')))
static_clean_base=9700  # retained dependency screen: 10116 - 4*104
result={'status':'feasibility only; no novelty or hardware advantage established',
        'policy':'natural order, groups of 16, first 256 stored vectors; fixed before run',
        'vectors':len(x),'prediction_mismatches':int(np.count_nonzero(prediction!=full[:,0])),
        'checkpoints':checkpoints,'mean_l0_neurons_evaluated':float(first.mean()),
        'mean_l0_cycles_only':float(prefix[first].mean()),
        'baseline_cycles':base,'static_cleanup_baseline_cycles':static_clean_base,
        'mean_break_even_total_certificate_cycles_vs_static_cleanup':float(static_clean_base-prefix[first].mean()),
        'qualification':'Certificate propagation cost is excluded from L0 cycles. Positive break-even budget is NOT a measured speedup. Full L0 precomputed only to emulate sequential reveal; unresolved activations are not exposed to the certificate.',
        'input_sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
(ROOT/'decision_bounds_pilot.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2))
