"""Independent integer check; not a substitute for executing RTL."""
import json,hashlib
from pathlib import Path
import numpy as np
root=Path(__file__).parent
assets=root/'generated/r_tc_fabs_nfbot'; network=assets/'network'
def values(path):return [int(s.strip(),16) for s in path.read_text().splitlines() if s.strip()]
def signed(v,bits):return v-(1<<bits) if v&(1<<(bits-1)) else v
raw=values(assets/'full_inputs.hex')
x=np.array([[signed((v>>(8*j))&255,8) for j in range(49)] for v in raw],dtype=np.int32)
weight=values(network/'network_l0_weights.hex');mask=values(network/'network_l0_masks.hex')
wm=np.array([[(1 if v&(1<<j) else -1) for j in range(49)] for v in weight],dtype=np.int32)
mm=np.array([[int(bool(v&(1<<j))) for j in range(49)] for v in mask],dtype=np.int32)
dense=x@(wm*mm).T
skip=np.zeros_like(dense)
for neuron in range(256):
    for j in np.flatnonzero(mm[neuron]):skip[:,neuron]+=x[:,j]*wm[neuron,j]
assert np.array_equal(dense,skip)
threshold=np.array([signed(v,32) for v in values(network/'network_l0_thresholds.hex')])
direction=np.array(values(network/'network_l0_directions.hex'),dtype=bool)
act=np.where(direction,dense>=threshold,dense<=threshold)
acts={0:act}
ws=values(network/'network_schedule_weights.hex');addresses=values(network/'network_schedule_addresses.hex')
neurons=values(network/'network_schedule_neurons.hex');layers=values(network/'network_schedule_layers.hex')
valid=values(network/'network_schedule_valid.hex');last=values(network/'network_schedule_last.hex')
out=None
for layer,width in [(1,128),(2,64),(3,1)]:
    sums=np.zeros((len(x),width),dtype=np.int32)
    for w,a,n,l,v in zip(ws,addresses,neurons,layers,valid):
        if l!=layer or not v:continue
        bits=np.array([bool(w&(1<<j)) for j in range(32)])
        sums[:,n]+=2*(acts[layer-1][:,a*32:(a+1)*32]==bits).sum(1).astype(np.int32)-32
    if layer<3:
        t=np.array([signed(v,32) for v in values(network/f'network_l{layer}_thresholds.hex')])
        d=np.array(values(network/f'network_l{layer}_directions.hex'),dtype=bool)
        acts[layer]=np.where(d,sums>=t,sums<=t)
    else:
        out=sums[:,0]>=signed(values(network/'network_output_threshold.hex')[0],32)
expected=np.array(values(assets/'full_expected_sparse.hex'),dtype=bool)
assert len(expected)==len(out)
mismatch=int((expected!=out).sum());assert mismatch==0
# Sentinel behavior, padding, dense and empty rows: independently model next_active.
for m in [0,(1<<49)-1,1,1<<48,(1<<64)-1,1<<63,0x1555555555555]:
    selected=[i for i in range(49) if m&(1<<i)]
    scanned=[];start=0
    while True:
        nxt=next((i for i in range(start,49) if m&(1<<i)),49)
        if nxt==49:break
        scanned.append(nxt);start=nxt+1
    assert scanned==selected
active=mm.sum(1)
original_cycles=256*50+4*len(ws)
skip_cycles=int(256+np.maximum(active,1).sum()+4*len(ws))
report=dict(scope='independent integer and schedule analysis; RTL simulation blocked by Questa license',
            vectors=len(x),first_layer_sum_mismatches=int((dense!=skip).sum()),
            final_prediction_mismatches=mismatch,schedule_entries=len(ws),
            first_layer_active_weights=int(active.sum()),empty_first_layer_neurons=int((active==0).sum()),
            original_cycles=original_cycles,predicted_skip_cycles=skip_cycles,
            predicted_cycle_reduction=1-skip_cycles/original_cycles,
            source_sha256=hashlib.sha256((root/'tc_fabs_skip_network.sv').read_bytes()).hexdigest(),
            qualification='No measured timing, fitted resource or power improvement established')
(root/'integer_skip_report.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report,indent=2))
