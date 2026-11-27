import sys,bisect
from PIL import Image
pts=[float(l.split()[1]) for l in open('sl.pts')]
t0=float(sys.argv[2]); taus=[float(x) for x in sys.argv[3].split(',')]
x0,y0,x1,y1=[int(float(v)*3) for v in sys.argv[4].split(',')]
sc=float(sys.argv[5])
ims=[]
for tau in taus:
    t=t0+tau/100; i=min(range(len(pts)),key=lambda k:abs(pts[k]-t))
    ims.append(Image.open(f'sl/f{i:04d}.png').convert('RGB').crop((x0,y0,x1,y1)))
w,h=ims[0].size; W=int(w*sc);H=int(h*sc)
out=Image.new('RGB',(W*len(ims),H))
for k,im in enumerate(ims): out.paste(im.resize((W,H)),(k*W,0))
out.save(sys.argv[1])
