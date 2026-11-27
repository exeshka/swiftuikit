import numpy as np,sys,json
from PIL import Image
n='uo'; REF=int(sys.argv[1]); RAT=float(sys.argv[2]); K=int(sys.argv[3]); a=int(sys.argv[4]); b=int(sys.argv[5])
pts=[float(l.split()[1]) for l in open(n+'.pts')]
def _box(m,k):
    c=np.pad(m.astype(np.int32),((1,0),(1,0))).cumsum(0).cumsum(1)
    s=c[k:,k:]-c[:-k,k:]-c[k:,:-k]+c[:-k,:-k]; return s==k*k
def box(m,k,pv=False):
    h=k//2; m=np.pad(m,h,constant_values=pv); return _box(m,k)
def opening(m,k): return ~box(~box(m,k),k,True)
r0=np.asarray(Image.open(f'{n}/f{REF:04d}.png').convert('L'),dtype=float)
out=[]
for i in range(a,b):
    g=np.asarray(Image.open(f'{n}/f{i:04d}.png').convert('L'),dtype=float)
    m=(g<RAT*r0)&(r0>45)
    r=np.zeros_like(m); r[60:681,36:552]=m[60:681,36:552]
    m=opening(r,K)
    ys,xs=np.where(m)
    if len(xs)<30: out.append(dict(i=i,t=pts[i]));continue
    L,R,T,B=xs.min(),xs.max()+1,ys.min(),ys.max()+1
    def off(cx,cy,sx,sy):
        for d in range(0,int(min(R-L,B-T)/2)):
            if m[cy+sy*d,cx+sx*d]: return d
        return -1
    o=[off(L,T,1,1),off(R-1,T,-1,1),off(R-1,B-1,-1,-1),off(L,B-1,1,-1)]
    out.append(dict(i=i,t=pts[i],L=int(L),R=int(R),T=int(T),B=int(B),o=o))
    print(i,round(pts[i],3),L,R,T,B,o)
json.dump(out,open('uo_m.json','w'))
