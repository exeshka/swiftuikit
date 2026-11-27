#!/usr/bin/env python3
"""Brightness of the lens rim in a held-tab screenshot (3 px/pt): peak luminance and RGB of the thin bright line around the lens
left/right edge (row of the bar centre) and top/bottom (column of the lens centre), minus the local background.
usage: rim_stats.py <png>"""
import sys
import numpy as np
from PIL import Image
a = np.array(Image.open(sys.argv[1]).convert('RGB')).astype(float)
L = a.mean(2)
y0 = 2300 + 165
row = L[y0 - 3:y0 + 4].mean(0)
loc = np.convolve(row, np.ones(31) / 31, 'same')
pk = row - loc
xs = [x for x in range(380, 830) if pk[x] > 6 and pk[x] == pk[max(0, x - 6):x + 7].max()]
print('left/right rim peaks x', xs[:2], xs[-2:])
for x in (xs[0], xs[-1]):
    print(' x', x, 'peak lum %.0f' % row[x], 'bg %.0f' % loc[x], 'rgb', a[y0, x].round(0))
cx = (xs[0] + xs[-1]) // 2
col = L[:, cx - 8:cx + 9].mean(1)
for name, lo, hi in (('top', 2330, 2395), ('bottom', 2540, 2610)):
    seg = col[lo:hi]; i = int(np.argmax(seg - np.convolve(col, np.ones(31) / 31, 'same')[lo:hi]))
    print(name, 'rim y', lo + i, 'lum %.0f' % seg[i], 'rgb', a[lo + i, cx].round(0))
