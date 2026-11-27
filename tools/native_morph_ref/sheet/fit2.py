import sys,json,numpy as np
kind=sys.argv[1]
js=json.load(open(f'data/native_fit_{kind}.json'))
T=np.array([r['tau'] for r in js]);o=np.argsort(T);T=T[o]
D={k:np.array([r[k] for r in js])[o] for k in 'LRTB'}
btn=dict(L=177.,R=225.,T=798.,B=846.);sh=dict(L=8.,R=394.,T=415.,B=866.)
rest,fin=(btn,sh) if kind=='open' else (sh,btn)
tmax=float(sys.argv[2])
def model(p,t,xr,xf):
    td,v0,w,z,d,ts=p
    s=np.maximum(t-td,0);wd=w*np.sqrt(1-z*z);dd=xr-xf
    return xf+np.exp(-z*w*s)*(dd*np.cos(wd*s)+(v0+z*w*dd)/wd*np.sin(wd*s))+d*np.exp(-s/ts)*(1-np.exp(-s/8))
rng=np.random.default_rng(5)
for k in 'LRTB':
    m=(T>=-5)&(T<=tmax);t=T[m];y=D[k][m];xr,xf=rest[k],fin[k]
    res={}
    for tail in (False,True):
        best=None
        for _ in range(25):
            p=np.array([rng.uniform(0,40),rng.uniform(-1,1),rng.uniform(0.01,0.03),rng.uniform(0.4,0.95),rng.uniform(-5,5) if tail else 0,rng.uniform(40,300)])
            err=lambda q:np.sqrt(np.mean((model(q,t,xr,xf)-y)**2))
            e0=err(p);st=np.array([6,0.4,0.004,0.08,2.0 if tail else 0,40])
            for it in range(2500):
                q=p+rng.normal(size=6)*st*(0.992**(it/20));q[0]=max(q[0],0);q[2]=max(q[2],0.004);q[3]=min(max(q[3],0.2),0.98);q[5]=max(q[5],10)
                e1=err(q)
                if e1<e0:p,e0=q,e1
            if best is None or e0<best[0]:best=(e0,p)
        res[tail]=best
    print(kind,k,'plain rms %.2f td=%.1f v0=%.3f w=%.4f z=%.2f'%((res[False][0],)+tuple(res[False][1][:4])),'| tail rms %.2f td=%.1f v0=%.3f w=%.4f z=%.2f d=%.2f ts=%.0f'%((res[True][0],)+tuple(res[True][1])))
