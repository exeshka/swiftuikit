#!/usr/bin/env python3
"""Tracks the bottom accessory pill (47.7 pt = 142 px high) in cropped frames (crop starts at y=2100 px, 3 px/pt, 30 fps of a x10
slow-motion recording): top rim T(t) from a column through the pill's right part and right rim R(t) from the row through its centre.
usage: acc_track.py <frames_dir> <first> <last> <out.json> [ms_per_frame]; output [[t_real_ms, T, R], ...] (T in crop px, R in px)"""
import sys, json, glob
import numpy as np
from PIL import Image
fs = sorted(glob.glob(sys.argv[1] + '/f*.png')); a0, a1 = int(sys.argv[2]), int(sys.argv[3])
H = 142
MS = float(sys.argv[5]) if len(sys.argv) > 5 else 3.3333  # real ms per frame (a x10 slow-motion recording sampled at 30 fps)
res = []; T = 105.0; R = 1142.0
for i in range(a0, min(a1, len(fs))):
    a = np.array(Image.open(fs[i]).convert('L')).astype(float)
    col = a[:, 860:900].mean(1)
    pk = col - np.convolve(col, np.ones(21) / 21, 'same')
    cand = [y for y in range(20, 380) if pk[y] > 4 and pk[y] == pk[max(0, y - 4):y + 5].max()]
    best = None
    for y in cand:
        if any(abs(y2 - (y + H)) <= 6 for y2 in cand):
            if best is None or abs(y - T) < abs(best - T): best = y
    if best is not None: T = float(best)
    cy = int(T + H / 2)
    row = a[cy - 4:cy + 5, :].mean(0)
    pr = row - np.convolve(row, np.ones(25) / 25, 'same')
    P = [x for x in range(300, 1190) if pr[x] > 4 and pr[x] == pr[max(0, x - 5):x + 6].max()]
    c = [x for x in P if x >= 900]
    c = [x for x in c if x < 1150]
    if c: R = float(max(c))
    res.append([round((i - a0) * MS, 1), T, R])
json.dump(res, open(sys.argv[4], 'w'))
