#!/usr/bin/env python3
"""Tracks the glass lens of a tab bar in cropped video frames (bar region, 3 px/pt, crop starts 2300 px).
usage: lens_track.py <frames_dir> <ms_per_frame> <out.json> [first] [last] [L0 R0 T0 B0]
The lens rims are the thin bright lines in a row between the icons and the labels (left/right) and in the column through its
centre (top/bottom). The lens starts as the rest capsule (L0 R0 T0 B0 px, default 210 480 85 246) and every edge follows the
rim candidate that continues its previous position (the bar's own rims at T 73 / B 258 are skipped until the lens reaches them).
Output: [[t_ms, L, R, T, B], ...] in px; slow-motion recordings: pass ms_per_frame already divided by the slow-down factor."""
import sys, json, glob
import numpy as np
from PIL import Image
d, mspf, out = sys.argv[1], float(sys.argv[2]), sys.argv[3]
fs = sorted(glob.glob(d + '/f*.png'))
a0 = int(sys.argv[4]) if len(sys.argv) > 4 else 0
a1 = int(sys.argv[5]) if len(sys.argv) > 5 else len(fs)
L, R, T, B = (float(v) for v in sys.argv[6:10]) if len(sys.argv) > 9 else (210., 480., 85., 246.)
BAR_T, BAR_B = 73, 258
STEP = 5 * mspf + 10
VS = 0.4 * mspf + 8  # vertical equivalent  # the most an edge may travel between two frames (px)
def peaks(sig, lo, hi, thr, win):
    pk = sig - np.convolve(sig, np.ones(25) / 25, 'same')
    return [x for x in range(lo, hi) if pk[x] > thr and pk[x] == pk[max(0, x - win):x + win + 1].max()]
res = []
for i in range(a0, min(a1, len(fs))):
    a = np.array(Image.open(fs[i]).convert('L')).astype(float)
    row = a[184:194].mean(0)
    P = peaks(row, 200, 1010, 5, 5)
    wd = R - L
    cl = [x for x in P if L - 25 <= x <= L + STEP]
    cr = [x for x in P if R - 8 <= x <= R + STEP + 5]
    if cl: L = float(min(cl, key=lambda x: abs(x - L)))
    if cr: R = float(max(cr))
    if cl and not cr: R = L + wd  # a rim that is not found keeps the previous width
    if cr and not cl: L = R - wd
    if not cl and not cr: L, R = L + 0.0, R + 0.0
    cx = int((L + R) / 2)
    col = a[:, cx - 12:cx + 13].mean(1)
    Tc = peaks(col, 40, 100, 3, 4)
    Bc = peaks(col, 235, 300, 3, 4)
    Tc2 = [y for y in Tc if abs(y - BAR_T) > 1.5 or T <= BAR_T + 2]
    c = [y for y in Tc2 if T - VS <= y <= T + 2]
    if c: T = float(min(c, key=lambda y: abs(y - (T - 1.5))))
    Bc2 = [y for y in Bc if abs(y - BAR_B) > 1.5 or B >= BAR_B - 2]
    c = [y for y in Bc2 if B - 2 <= y <= B + VS]
    if c: B = float(max(c) if max(c) - B < VS else min(c, key=lambda y: abs(y - (B + 1.5))))
    res.append([round((i - a0) * mspf, 1), L, R, T, B])
json.dump(res, open(out, 'w'))
