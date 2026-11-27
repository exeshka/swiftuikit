#!/usr/bin/env python3
"""IoU per time window: window_table.py <nat.json> <ours.json> <dx> -> mean IoU in 0-50/50-100/100-150/150-200 ms and overall (same method as compare_lens.py)"""
import subprocess, sys, re
import numpy as np
res = {}
out = subprocess.run([sys.executable, __file__.replace('window_table', 'compare_lens'), sys.argv[1], sys.argv[2], sys.argv[3], '0', '200'], capture_output=True, text=True).stdout
rows = [(float(m.group(1)), float(m.group(2))) for m in re.finditer(r'^\s*(\d+) ms\s+IoU ([0-9.]+)', out, re.M)]
print(out.splitlines()[0])
for lo, hi in ((0, 50), (50, 100), (100, 150), (150, 205)):
    v = [i for t, i in rows if lo <= t < hi]
    print('%3d-%3d ms: %.3f' % (lo, hi, np.mean(v)) if v else '%d-%d: -' % (lo, hi))
