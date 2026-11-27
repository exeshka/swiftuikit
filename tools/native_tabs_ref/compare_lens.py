#!/usr/bin/env python3
"""IoU of the lens outline (stadium) per time step between a native and our track (lens_track.py output).
usage: compare_lens.py <nat.json> <ours.json> <dx_px> [t0 t1]   (dx: shift of ours so that both travel the same tab, e.g. -257)
Our time axis is shifted (searched over +-80 ms) to the best mean IoU. Prints a table and the mean."""
import sys, json
import numpy as np
nat = [r for r in json.load(open(sys.argv[1])) if r[1] is not None and r[3] is not None and r[4] is not None]
ours = [r for r in json.load(open(sys.argv[2])) if r[1] is not None and r[3] is not None and r[4] is not None]
dx = float(sys.argv[3])
# the lens is symmetric about the bar's centre (hold: T 58 / B 274 px, rest capsule 85 / 246) and the bottom rim is the noisiest edge
# (bar rim, shadow): the bottom is taken as 332 - T for both tracks
nat = [[r[0], r[1], r[2], r[3], 332 - r[3]] for r in nat]
ours = [[r[0], r[1], r[2], r[3], 332 - r[3]] for r in ours]
t0, t1 = (float(sys.argv[4]), float(sys.argv[5])) if len(sys.argv) > 5 else (0.0, 215.0)  # the travel phase of the lens
nat = [r for r in nat if t0 <= r[0] <= t1]
def mask(L, R, T, B, W=1206, H=322):
    ys, xs = np.mgrid[0:H, 0:W]
    r = (B - T) / 2; cy = (T + B) / 2
    x = np.clip(xs, L + r, R - r)
    return ((xs - x) ** 2 + (ys - cy) ** 2) <= r * r
def at(tr, t):
    ts = np.array([r[0] for r in tr])
    if t < ts[0] or t > ts[-1]: return None
    return [np.interp(t, ts, [r[k] for r in tr]) for k in (1, 2, 3, 4)]
best = None
for sh in np.arange(-80, 81, 5):
    ious = []
    for r in nat:
        o = at(ours, r[0] + sh)
        if o is None: continue
        a = mask(*r[1:]); b = mask(o[0] + dx, o[1] + dx, o[2], o[3])
        ious.append((r[0], (a & b).sum() / (a | b).sum()))
    if len(ious) > 8 and (best is None or np.mean([v for _, v in ious]) > best[0]):
        best = (np.mean([v for _, v in ious]), sh, ious)
print('shift', best[1], 'ms; mean IoU %.3f' % best[0])
for t, v in best[2][::1]: print('%6.0f ms  IoU %.3f' % (t, v))
