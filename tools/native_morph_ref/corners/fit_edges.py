#!/usr/bin/env python3
"""Fit every edge of the fitted silhouette with  smooth step (to x0 at t0) + damped spring + slow tail  d*exp(-(tau-t0)/ts).
usage: fit_edges.py open|close   (uses data/native_fit_*.json)   -> prints the parameters and the rms next to the plain spring."""
import sys, json, os
import numpy as np
here = os.path.dirname(os.path.abspath(__file__))
kind = sys.argv[1]
js = json.load(open(f'{here}/data/native_fit_{kind}.json'))
T = np.array([r['tau'] for r in js]); o = np.argsort(T); T = T[o]
D = {k: np.array([r[k] for r in js])[o] for k in 'LRTB'}
cap = dict(L=282.0, R=385.3, T=62.7, B=105.7); menu = dict(L=136.7, R=385.7, T=62.3, B=228.0)
rest, fin = (cap, menu) if kind == 'open' else (menu, cap)
def model(p, t, xr, xf, tail):
    t0, x0, v0, w, z, d, ts = p
    s = np.maximum(t - t0, 0)
    wd = w * np.sqrt(max(1 - z * z, 1e-6))
    dd = x0 - xf
    sp = xf + np.exp(-z * w * s) * (dd * np.cos(wd * s) + (v0 + z * w * dd) / wd * np.sin(wd * s))
    if tail: sp = sp + d * np.exp(-s / ts) * (t > t0)
    sm = np.clip(t / t0, 0, 1); pre = xr + (x0 - xr) * sm * sm * (3 - 2 * sm)
    return np.where(t <= t0, pre, sp)
rng = np.random.default_rng(3)
def fit(k, tail):
    m = (T >= -5) & (T <= 700); t = T[m]; y = D[k][m]; xr, xf = rest[k], fin[k]
    best = None
    for _ in range(30):
        p = np.array([rng.uniform(0, 60), xr + rng.uniform(-30, 30), rng.uniform(-2, 2), rng.uniform(0.01, 0.04), rng.uniform(0.3, 1.0), rng.uniform(-6, 6) if tail else 0, rng.uniform(40, 300)])
        err = lambda q: np.sqrt(np.mean((model(q, t, xr, xf, tail) - y) ** 2))
        e0 = err(p); st = np.array([8, 5, 0.5, 0.006, 0.1, 2.0 if tail else 0, 40])
        for it in range(2500):
            q = p + rng.normal(size=7) * st * (0.992 ** (it / 20)); q[3] = max(q[3], 0.004); q[4] = min(max(q[4], 0.1), 0.98); q[6] = max(q[6], 10)
            e1 = err(q)
            if e1 < e0: p, e0 = q, e1
        if best is None or e0 < best[0]: best = (e0, p)
    return best
for k in 'LRTB':
    a = fit(k, False); b = fit(k, True)
    print(kind, k, 'spring rms %.2f' % a[0], '| +tail rms %.2f' % b[0], ' t0=%.1f x0=%.1f v0=%.3f w=%.4f z=%.2f d=%.2f ts=%.0f' % tuple(b[1]), '| plain: t0=%.1f x0=%.1f v0=%.3f w=%.4f z=%.2f' % tuple(a[1][:5]))
