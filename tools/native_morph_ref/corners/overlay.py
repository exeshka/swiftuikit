#!/usr/bin/env python3
"""overlay.py FRAMES_DIR FIT.json OUT.png TAU... : evidence (green = glass, dark = not, grey = text) with the fitted contour in red."""
import sys, json
import numpy as np
from PIL import Image
sys.path.insert(0, __file__.rsplit('/', 1)[0])
import fit_corners as fc
d, js, out = sys.argv[1], json.load(open(sys.argv[2])), sys.argv[3]
taus = [float(x) for x in sys.argv[4:]]
bg = fc.load(d, 100); bg[170:330, 820:1170] = 0
tiles = []
for t in taus:
    r = min(js, key=lambda r: abs(r['tau'] - t))
    g = fc.load(d, r['i'])
    sl = (slice(fc.Y0 * 3, fc.Y1 * 3, 2), slice(fc.X0 * 3, fc.X1 * 3, 2))
    gg, bb = g[sl], bg[sl]
    dark = bb < 14
    ev = np.zeros(gg.shape + (3,), np.uint8)
    ev[~dark] = (90, 90, 90)
    ev[dark & (gg - bb > 4)] = (30, 200, 60)
    ev[dark & ~(gg - bb > 4)] = (0, 0, 0)
    ys, xs = np.mgrid[0:gg.shape[0], 0:gg.shape[1]]
    X = fc.X0 + xs * 2 / 3 + 0.5 / 3; Y = fc.Y0 + ys * 2 / 3 + 0.5 / 3
    p = [r['L'], r['T'], r['R'], r['B'], r['tl'], r['tr'], r['br'], r['bl']]
    m = fc.rrect_mask(X, Y, p)
    edge = m & ~(fc.rrect_mask(X + 0.9, Y, p) & fc.rrect_mask(X - 0.9, Y, p) & fc.rrect_mask(X, Y + 0.9, p) & fc.rrect_mask(X, Y - 0.9, p))
    ev[edge] = (255, 40, 40)
    im = Image.fromarray(ev)
    # crop to bbox with margin
    L, T, R, B = [int((v) * 1.5) for v in (r['L'] - fc.X0 - 12, r['T'] - fc.Y0 - 12, r['R'] - fc.X0 + 12, r['B'] - fc.Y0 + 12)]
    im = im.crop((max(L, 0), max(T, 0), R, B)); im = im.resize((int(im.width * 1.6), int(im.height * 1.6)), Image.NEAREST)
    tiles.append((t, r, im))
W = sum(i.width for _, _, i in tiles) + 6 * len(tiles); H = max(i.height for _, _, i in tiles)
canvas = Image.new('RGB', (W, H), (40, 40, 60)); x = 0
for t, r, i in tiles:
    canvas.paste(i, (x, 0)); x += i.width + 6
canvas.save(out)
print([(round(r['tau']), round(r['iou'], 3), [round(r[k], 1) for k in ('tl', 'tr', 'br', 'bl')]) for _, r, _ in tiles])
