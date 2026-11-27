#!/bin/zsh
# usage: run_ours.sh <mov> <workdir> <dx> -- tracks our lens in a real-time recording (60 fps) and compares it with nat_track.json
cd "$2"; rm -rf oo; mkdir oo
./cropframes "$1" oo 60 0 40 2300 322 >/dev/null
python3 - <<'P'
from PIL import Image
import numpy as np,glob
fs=sorted(glob.glob('oo/f*.png')); prev=None; first=None
for k,f in enumerate(fs):
    a=np.array(Image.open(f).convert('L')).astype(int)
    if prev is not None and first is None and np.abs(a-prev).mean()>2.0: first=k
    prev=a
open('oo_first.txt','w').write(str(first))
P
F=$(cat oo_first.txt)
python3 "$(dirname $0)/lens_track.py" oo 16.667 ours_track.json $((F-2)) $((F+30)) ${L0:-468} ${R0:-737} 85 246
python3 "$(dirname $0)/compare_lens.py" nat_track.json ours_track.json $3
