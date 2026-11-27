#!/usr/bin/env python3
"""Two-plate model: the menu plate B and the control's own plate A (a pill that rests where the capsule is) joined by a smooth union
(polynomial smooth-min of the two signed distances, width k pt) -- what LiquidGlassGroup does.  Fitted per frame on the same
evidence as fit_corners.py.   usage: fit_union.py FRAMES_DIR PTS T0 FIRST LAST STEP OUT.json REST_L,T,R,B [BG_FRAME]"""
import sys, json
import numpy as np
sys.path.insert(0, __file__.rsplit('/', 1)[0])
import fit_corners as fc


def sdf_rr(xs, ys, L, T, R, B, r):
    w, h = max(R - L, 2.0), max(B - T, 2.0)
    r = max(0.0, min(r, w / 2, h / 2))
    cx, cy = (L + R) / 2, (T + B) / 2
    qx = np.abs(xs - cx) - (w / 2 - r); qy = np.abs(ys - cy) - (h / 2 - r)
    return np.hypot(np.maximum(qx, 0), np.maximum(qy, 0)) + np.minimum(np.maximum(qx, qy), 0) - r


def smin(a, b, k):
    k = max(k, 1e-3)
    h = np.maximum(k - np.abs(a - b), 0) / k
    return np.minimum(a, b) - h * h * k / 4


def union_mask(xs, ys, p):
    # p: A(L,T,R,B,r) B(L,T,R,B,r) k
    return smin(sdf_rr(xs, ys, *p[0:5]), sdf_rr(xs, ys, *p[5:10]), p[10]) <= 0


def fit(g, bg, rest, single, thr=4.0):
    sl = (slice(fc.Y0 * 3, fc.Y1 * 3, 2), slice(fc.X0 * 3, fc.X1 * 3, 2))
    gg, bb = g[sl], bg[sl]
    dark = bb < 14
    glass = fc.largest_component(fc.clean(dark & (gg - bb > thr)))
    notg = dark & ~(gg - bb > thr)
    ys_i, xs_i = np.mgrid[0:gg.shape[0], 0:gg.shape[1]]
    xs = fc.X0 + xs_i * 2 / 3 + 0.5 / 3; ys = fc.Y0 + ys_i * 2 / 3 + 0.5 / 3

    def score(p):
        m = union_mask(xs, ys, p)
        return (m & glass).sum() - (m & notg).sum()
    Lr, Tr, Rr, Br = rest
    best = None
    for A0 in ((Lr, Tr, Rr, Br), ((Lr + Rr) / 2 + 10, Tr + 4, Rr - 2, Br - 4)):
        p = np.array(list(A0) + [(A0[3] - A0[1]) / 2, single['L'], single['T'], single['R'], single['B'], single['tl'], 10.0], float)
        st = np.array([3, 3, 3, 3, 4, 3, 3, 3, 3, 8, 4], float)
        sc = score(p)
        while st.max() > 0.25:
            moved = False
            for j in range(len(p)):
                for sgn in (1, -1):
                    q = p.copy(); q[j] += sgn * st[j]
                    if j == 10: q[j] = min(max(q[j], 0.5), 60)
                    s2 = score(q)
                    if s2 > sc:
                        p, sc, moved = q, s2, True
                        break
            if not moved:
                st *= 0.5
        if best is None or sc > best[0]:
            best = (sc, p)
    p = best[1]
    m = union_mask(xs, ys, p)
    return p, float((m & glass).sum()) / float(glass.sum() + (m & notg).sum())


def main():
    d, pf, t0 = sys.argv[1], sys.argv[2], float(sys.argv[3])
    a, b, step, out = int(sys.argv[4]), int(sys.argv[5]), int(sys.argv[6]), sys.argv[7]
    rest = [float(v) for v in sys.argv[8].split(',')]
    singles = {r['i']: r for r in json.load(open(sys.argv[9]))}
    bgf = int(sys.argv[10]) if len(sys.argv) > 10 else 100
    pts = {int(l.split()[0]): float(l.split()[1]) for l in open(pf)}
    bg = fc.load(d, bgf); bg[170:330, 820:1170] = 0
    res = []
    for i in range(a, b + 1, step):
        if i not in singles:
            continue
        p, iou = fit(fc.load(d, i), bg, rest, singles[i])
        res.append(dict(i=i, tau=(pts[i] - t0) * 100, p=list(map(float, p)), iou=iou, iou_single=singles[i]['iou']))
        print(i, f"tau{res[-1]['tau']:.0f} iou_union{iou:.3f} vs single{singles[i]['iou']:.3f}  A[{p[0]:.0f},{p[1]:.0f},{p[2]:.0f},{p[3]:.0f}] B[{p[5]:.0f},{p[6]:.0f},{p[7]:.0f},{p[8]:.0f} r{p[9]:.0f}] k{p[10]:.0f}", flush=True)
        json.dump(res, open(out, 'w'))


if __name__ == '__main__':
    main()
