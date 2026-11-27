#!/usr/bin/env python3
"""Score the shapes written by morph_iou_test.dart against the pixels (not against our own fit).
usage: score_vs_evidence.py FRAMES_DIR open|close [BG_FRAME]  -> out/evidence_{kind}.txt   (IoU over the certain glass / certain not-glass pixels)"""
import sys, json, os
import numpy as np
here = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, here)
import fit_corners as fc
d, kind = sys.argv[1], sys.argv[2]
bgf = int(sys.argv[3]) if len(sys.argv) > 3 else 100
rows = json.load(open(f'{here}/out/ours_{kind}.json'))
bg = fc.load(d, bgf); bg[170:330, 820:1170] = 0
keys = ['ours_code', 'ours_codetail', 'ours_prop_edges', 'nat_prop']
lines = ['tau  ' + '  '.join(keys)]; acc = {k: [] for k in keys}
sl = (slice(fc.Y0 * 3, fc.Y1 * 3, 2), slice(fc.X0 * 3, fc.X1 * 3, 2))
ys_i, xs_i = np.mgrid[0:(fc.Y1 - fc.Y0) * 3 // 2, 0:(fc.X1 - fc.X0) * 3 // 2]
xs = fc.X0 + xs_i * 2 / 3 + 0.5 / 3; ys = fc.Y0 + ys_i * 2 / 3 + 0.5 / 3
for r in rows:
    g = fc.load(d, r['i']); gg, bb = g[sl], bg[sl]
    dark = bb < 14
    glass = fc.largest_component(fc.clean(dark & (gg - bb > 4))); notg = dark & ~(gg - bb > 4)
    out = []
    for k in keys:
        s = r[k]
        m = fc.rrect_mask(xs, ys, [s['L'], s['T'], s['R'], s['B'], s['tl'], s['tr'], s['br'], s['bl']])
        v = (m & glass).sum() / max(glass.sum() + (m & notg).sum(), 1)
        out.append(v); acc[k].append(v)
    lines.append(f"{r['tau']:5.0f}  " + '  '.join(f'{v:.3f}' for v in out))
for name, lo, hi in (('open', 15, 40), ('close', 100, 230)):
    if name == kind:
        sel = [i for i, r in enumerate(rows) if lo <= r['tau'] <= hi]
        lines.append(f'window {name} {lo}-{hi} ({len(sel)} frames)  ' + '  '.join(f"{np.mean([acc[k][i] for i in sel]):.3f}" for k in keys))
lines.append('mean   ' + '  '.join(f'{np.mean(acc[k]):.3f}' for k in keys))
open(f'{here}/out/evidence_{kind}.txt', 'w').write('\n'.join(lines))
print('\n'.join(lines[:1] + lines[-2:]))
