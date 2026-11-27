#!/usr/bin/env python3
"""Fit a rounded rectangle with four independent corner radii to the native glass silhouette in every frame.

usage: fit_corners.py FRAMES_DIR PTS_FILE T0 FIRST LAST STEP OUT.json [BG_FRAME]
  FRAMES_DIR  frames f%04d.png of the slowed native recording (see frames_pts.swift: `frames_pts X.mov DIR > X.pts`), 3 px / pt
  T0          slow-clock second of tau = 0 (open: 2.98, close: 14.43 for the recording described in MORPH_SPEC.md)
Evidence per pixel (the background is the first frame, whose capsule rectangle is painted black):
  glass  = the background is dark (< 14) and the frame is brighter than it  (certain)
  not    = the background is dark and the frame is not brighter              (certain)
  text   = the background is bright (rows of text): unknown, ignored, so text under the glass cannot bend the contour
The model (Flutter RRect rules: radii are scaled down together when two of them do not fit a side) is fitted by pattern search
on  TP - FP  over the certain pixels; the result reports the IoU over the certain pixels as well.
tau is real milliseconds (slow clock x 10).
"""
import sys, json
import numpy as np
from PIL import Image

ROT = False  # --rotate: also fit an angle
ELL = False  # --ellip: elliptical corners (rx, ry per corner)
S = 3  # px per pt
STRIDE = 2  # fit on every 2nd pixel
X0, X1, Y0, Y1 = 100, 400, 48, 262  # ROI in pt


def load(d, i):
    return np.array(Image.open(f'{d}/f{i:04d}.png').convert('L')).astype(np.float32)


def clean(m, r=1):
    f = m.astype(np.float32)
    c = np.cumsum(np.cumsum(np.pad(f, ((1, 0), (1, 0))), 0), 1)
    n = 2 * r + 1
    out = np.zeros_like(m)
    box = (c[n:, n:] - c[:-n, n:] - c[n:, :-n] + c[:-n, :-n]) / (n * n)
    out[r:-r, r:-r] = box > 0.55
    return out


def largest_component(m):
    from collections import deque
    seen = np.zeros_like(m)
    best = []
    H, W = m.shape
    for y0, x0 in zip(*np.where(m)):
        if seen[y0, x0]:
            continue
        comp = [(y0, x0)]; seen[y0, x0] = True; dq = deque(comp)
        while dq:
            y, x = dq.popleft()
            for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                yy, xx = y + dy, x + dx
                if 0 <= yy < H and 0 <= xx < W and m[yy, xx] and not seen[yy, xx]:
                    seen[yy, xx] = True; comp.append((yy, xx)); dq.append((yy, xx))
        if len(comp) > len(best):
            best = comp
    out = np.zeros_like(m)
    for y, x in best:
        out[y, x] = True
    return out


def rrect_mask(xs, ys, p):
    L, T, R, B, tl, tr, br, bl = p
    w, h = R - L, B - T
    if w < 4 or h < 4:
        return np.zeros_like(xs, dtype=bool)
    tl, tr, br, bl = [max(0.0, v) for v in (tl, tr, br, bl)]
    k = min(1.0,
            w / max(tl + tr, 1e-6), w / max(bl + br, 1e-6),
            h / max(tl + bl, 1e-6), h / max(tr + br, 1e-6))
    tl, tr, br, bl = tl * k, tr * k, br * k, bl * k
    m = (xs >= L) & (xs <= R) & (ys >= T) & (ys <= B)
    for (r, cx, cy, sx, sy) in ((tl, L + tl, T + tl, -1, -1), (tr, R - tr, T + tr, 1, -1),
                                (br, R - br, B - br, 1, 1), (bl, L + bl, B - bl, -1, 1)):
        if r <= 0:
            continue
        zone = ((xs - cx) * sx > 0) & ((ys - cy) * sy > 0)
        m &= ~(zone & ((xs - cx) ** 2 + (ys - cy) ** 2 > r * r))
    return m


def erect_mask(xs, ys, p):
    """p = L,T,R,B, then (rx,ry) of TL, TR, BR, BL: a rounded rectangle with elliptical corners (Flutter RRect rules)."""
    L, T, R, B = p[:4]
    w, h = R - L, B - T
    if w < 4 or h < 4:
        return np.zeros_like(xs, dtype=bool)
    c = [(max(0.0, p[4 + 2 * i]), max(0.0, p[5 + 2 * i])) for i in range(4)]
    (tlx, tly), (trx, try_), (brx, bry), (blx, bly) = c
    k = min(1.0, w / max(tlx + trx, 1e-6), w / max(blx + brx, 1e-6), h / max(tly + bly, 1e-6), h / max(try_ + bry, 1e-6))
    m = (xs >= L) & (xs <= R) & (ys >= T) & (ys <= B)
    for (rx, ry), (cx, cy, sx, sy) in zip(((tlx * k, tly * k), (trx * k, try_ * k), (brx * k, bry * k), (blx * k, bly * k)),
                                         ((L, T, -1, -1), (R, T, 1, -1), (R, B, 1, 1), (L, B, -1, 1))):
        if rx <= 0 or ry <= 0:
            continue
        ccx, ccy = cx - sx * rx, cy - sy * ry
        zone = ((xs - ccx) * sx > 0) & ((ys - ccy) * sy > 0)
        m &= ~(zone & (((xs - ccx) / rx) ** 2 + ((ys - ccy) / ry) ** 2 > 1))
    return m


def rot_mask(xs, ys, p):
    """p = L,T,R,B,tl,tr,br,bl,angle(deg): a rounded rectangle rotated about its centre."""
    a = np.radians(p[8]); cx = (p[0] + p[2]) / 2; cy = (p[1] + p[3]) / 2
    c, s_ = np.cos(a), np.sin(a)
    dx, dy = xs - cx, ys - cy
    return rrect_mask(cx + c * dx + s_ * dy, cy - s_ * dx + c * dy, p[:8])


def fit_frame(g, bg, thr=4.0, rotate=False, ellip=False):
    sl = (slice(Y0 * S, Y1 * S, STRIDE), slice(X0 * S, X1 * S, STRIDE))
    gg, bb = g[sl], bg[sl]
    dark = bb < 14
    glass = dark & (gg - bb > thr)
    notg = dark & ~(gg - bb > thr)
    ys_i, xs_i = np.mgrid[0:gg.shape[0], 0:gg.shape[1]]
    xs = X0 + xs_i * STRIDE / S + 0.5 / S
    ys = Y0 + ys_i * STRIDE / S + 0.5 / S
    glass = largest_component(clean(glass))
    if glass.sum() < 40:
        return None
    gy, gx = np.where(glass)
    # robust initial box: percentiles of the glass pixels
    L0, R0 = np.percentile(xs[glass], [0.3, 99.7]); T0, B0 = np.percentile(ys[glass], [0.3, 99.7])

    mk = erect_mask if ellip else (rot_mask if rotate else rrect_mask)

    def score(p):
        m = mk(xs, ys, p)
        return (m & glass).sum() - (m & notg).sum()

    best = None
    for r0 in (None, 12.0):
        h = B0 - T0; w = R0 - L0
        rr = min(w, h) / 2 if r0 is None else min(r0, min(w, h) / 2)
        if ellip:
            p = np.array([L0, T0, R0, B0] + [rr] * 8, float)
            st = np.array([3, 3, 3, 3] + [10] * 8, float)
        else:
            p = np.array([L0, T0, R0, B0, rr, rr, rr, rr] + ([0.0] if rotate else []), float)
            st = np.array([3, 3, 3, 3, 10, 10, 10, 10] + ([8.0] if rotate else []), float)
        sc = score(p)
        while st.max() > 0.2:
            moved = False
            for j in range(len(p)):
                for sgn in (1, -1):
                    q = p.copy(); q[j] += sgn * st[j]
                    s2 = score(q)
                    if s2 > sc:
                        p, sc, moved = q, s2, True
                        break
            if not moved:
                st *= 0.5
        if best is None or sc > best[0]:
            best = (sc, p)
    sc, p = best
    m = mk(xs, ys, p)
    inter = (m & glass).sum(); union = glass.sum() + (m & notg).sum()
    return p, float(inter) / float(union)


def main():
    global ROT, ELL
    if '--ellip' in sys.argv:
        ELL = True; sys.argv.remove('--ellip')
    if '--rotate' in sys.argv:
        ROT = True; sys.argv.remove('--rotate')
    d, pf, t0 = sys.argv[1], sys.argv[2], float(sys.argv[3])
    a, b, step = int(sys.argv[4]), int(sys.argv[5]), int(sys.argv[6])
    out = sys.argv[7]
    bgf = int(sys.argv[8]) if len(sys.argv) > 8 else 100
    pts = {int(l.split()[0]): float(l.split()[1]) for l in open(pf)}
    bg = load(d, bgf)
    bg[170:330, 820:1170] = 0  # capsule rectangle (px)
    res = []
    for i in range(a, b + 1, step):
        r = fit_frame(load(d, i), bg, rotate=ROT, ellip=ELL)
        if r is None:
            continue
        p, iou = r
        if ELL:
            res.append(dict(i=i, tau=(pts[i] - t0) * 100, L=p[0], T=p[1], R=p[2], B=p[3], tlx=p[4], tly=p[5], trx=p[6], try_=p[7],
                            brx=p[8], bry=p[9], blx=p[10], bly=p[11], iou=iou))
            print(i, f"tau{res[-1]['tau']:.0f} L{p[0]:.1f} R{p[2]:.1f} T{p[1]:.1f} B{p[3]:.1f} TL({p[4]:.0f},{p[5]:.0f}) TR({p[6]:.0f},{p[7]:.0f}) BR({p[8]:.0f},{p[9]:.0f}) BL({p[10]:.0f},{p[11]:.0f}) iou{iou:.3f}", flush=True)
        else:
            res.append(dict(i=i, tau=(pts[i] - t0) * 100, L=p[0], T=p[1], R=p[2], B=p[3],
                            tl=p[4], tr=p[5], br=p[6], bl=p[7], ang=(p[8] if ROT else 0.0), iou=iou))
            print(i, f"tau{res[-1]['tau']:.0f} L{p[0]:.1f} R{p[2]:.1f} T{p[1]:.1f} B{p[3]:.1f} r TL{p[4]:.1f} TR{p[5]:.1f} BR{p[6]:.1f} BL{p[7]:.1f} iou{iou:.3f}", flush=True)
        json.dump(res, open(out, 'w'))


if __name__ == '__main__':
    main()
