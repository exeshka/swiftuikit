#!/usr/bin/env python3
"""Markdown tables for MORPH_SPEC.md section 'Углы' from data/ and out/."""
import json, os, numpy as np
here = os.path.dirname(os.path.abspath(__file__))
def L(n): return json.load(open(f'{here}/data/{n}.json'))
def near(js, t): return min(js, key=lambda r: abs(r['tau'] - t))
out = []
for kind, taus in (('open', [-5, 5, 10, 15, 20, 25, 28, 32, 36, 40, 45, 50, 60, 70, 80, 90, 100, 120, 140, 160, 180, 200, 220, 240, 260, 280, 300, 340, 400]),
                   ('close', [0, 10, 20, 30, 40, 50, 60, 80, 100, 110, 120, 130, 140, 150, 160, 170, 180, 190, 200, 210, 220, 230, 240, 250, 260, 280, 300, 320])):
    c, e = L(f'native_fit_{kind}'), L(f'native_fit_ellip_{kind}')
    out.append(f'\n#### {kind}: радиусы по τ (круглые углы, 4 независимых; эллиптические углы rx×ry)\n')
    out.append('| τ мс | w | h | TL | TR | BR | BL | IoU | TL rx×ry | TR rx×ry | BR rx×ry | BL rx×ry | IoU эллипт. |')
    out.append('|' + '---|' * 13)
    for t in taus:
        a = near(c, t); b = near(e, t)
        out.append(f"| {a['tau']:.0f} | {a['R']-a['L']:.0f} | {a['B']-a['T']:.0f} | {a['tl']:.0f} | {a['tr']:.0f} | {a['br']:.0f} | {a['bl']:.0f} | {a['iou']:.3f} | "
                   f"{b['tlx']:.0f}×{b['tly']:.0f} | {b['trx']:.0f}×{b['try_']:.0f} | {b['brx']:.0f}×{b['bry']:.0f} | {b['blx']:.0f}×{b['bly']:.0f} | {b['iou']:.3f} |")
for kind in ('open', 'close'):
    rows = {}
    for l in open(f'{here}/out/evidence_{kind}.txt').read().splitlines()[1:-1]:
        v = l.split(); rows[float(v[0])] = [float(x) for x in v[1:]]
    iou = {r['tau']: r for r in json.load(open(f'{here}/out/ours_{kind}.json'))}
    out.append(f'\n#### IoU по τ, {kind}: форма из кода против пикселей (evidence) и против подогнанного нативного контура (fit)\n')
    out.append('| τ мс | evidence: текущая | evidence: предл. углы | evidence: предл. углы+рёбра | evidence: потолок (нат. прямоугольник + предл. углы) | fit: текущая | fit: предл. углы | fit: предл. углы+рёбра |')
    out.append('|' + '---|' * 8)
    bins = list(range(-5, 40, 10)) + list(range(40, 120, 20)) + list(range(120, 300, 20)) + [300, 340, 400, 500, 600]
    for t in bins:
        if kind == 'close' and t > 460: continue
        k = min(rows, key=lambda x: abs(x - t))
        if abs(k - t) > 12: continue
        f = iou[k]['iou'] if k in iou else None
        if f is None:
            kk = min(iou, key=lambda x: abs(x - k)); f = iou[kk]['iou']
        out.append(f"| {k:.0f} | {rows[k][0]:.3f} | {rows[k][1]:.3f} | {rows[k][2]:.3f} | {rows[k][4]:.3f} | {f[0]:.3f} | {f[1]:.3f} | {f[4]:.3f} |")
    allv = np.array(list(rows.values()))
    out.append(f"| **среднее** | **{allv[:,0].mean():.3f}** | **{allv[:,1].mean():.3f}** | **{allv[:,2].mean():.3f}** | **{allv[:,4].mean():.3f}** | | | |")
open(f'{here}/out/tables.md', 'w').write('\n'.join(out))
print(len(out))
