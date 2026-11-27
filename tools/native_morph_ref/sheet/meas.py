import numpy as np,sys,json
from PIL import Image
pts=[float(l.split()[1]) for l in open('sl.pts')]
a0,a1,step=int(sys.argv[1]),int(sys.argv[2]),int(sys.argv[3])
K=15
def box(m,k,pv=False):
    h=k//2
    m=np.pad(m,h,constant_values=pv)
    r=_box(m,k)
    return r[h:-h,h:-h]
def _box(m,k):  # True where full kxk window is True (centre aligned, valid mode padded false)
    c=np.pad(m.astype(np.int32),((1,0),(1,0))).cumsum(0).cumsum(1)
    s=c[k:,k:]-c[:-k,k:]-c[k:,:-k]+c[:-k,:-k]
    r=np.zeros(m.shape,bool); r[k//2:k//2+s.shape[0],k//2:k//2+s.shape[1]]=(s==k*k); return r
def dil(m,k):
    return ~box(~m,k,True)
out=[]
for i in range(a0,a1,step):
    g=np.asarray(Image.open(f'sl/f{i:04d}.png').convert('L'))
    m=g>=26
    m[:450]=False
    m=dil(box(m,K),K)
    ys,xs=np.where(m)
    if len(xs)<50: out.append(dict(i=i,t=pts[i]));continue
    L,R,T,B=xs.min(),xs.max()+1,ys.min(),ys.max()+1
    def off(cx,cy,sx,sy):
        for d in range(0,int(min(R-L,B-T)/2)):
            if m[cy+sy*d,cx+sx*d]: return d
        return -1
    o=[off(L,T,1,1),off(R-1,T,-1,1),off(R-1,B-1,-1,-1),off(L,B-1,1,-1)]
    out.append(dict(i=i,t=pts[i],L=L/3,R=R/3,T=T/3,B=B/3,o=o))
json.dump(out,open(sys.argv[4],'w'))
