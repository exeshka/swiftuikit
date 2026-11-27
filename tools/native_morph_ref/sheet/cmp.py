import json,numpy as np
d=[r for r in json.load(open('un_m.json')) if 'L' in r and 34<=r['i']<=75]
# drop dup frames (identical bbox as previous)
rows=[];prev=None
for r in d:
    k=(r['L'],r['R'],r['T'],r['B'])
    if k!=prev: rows.append(r)
    prev=k
s=1.252;X0=45.0;Y0=404.2
t=np.array([r['t'] for r in rows])*1000
E_={k:np.array([(r[k]-X0)/s if k in 'LR' else (r[k]+Y0)/s for r in rows]) for k in 'LRTB'}
P=dict(L=(55.3,161.9,-0.448,0.0188,0.81,-5.09,31),R=(55.2,240.4,0.362,0.0187,0.82,4.53,128),T=(30.6,771.1,-0.623,0.0181,0.81,-8.5,54),B=(73.1,800.0,-0.352,0.0192,0.79,-0.94,177))
rest=dict(L=177.,R=225.,T=798.,B=846.);fin=dict(L=8.,R=394.,T=415.,B=866.)
def model(k,tau):
    t0,x0,v0,w,z,d,ts=P[k];xr,xf=rest[k],fin[k]
    s_=np.maximum(tau-t0,0);wd=w*np.sqrt(1-z*z);dd=x0-xf
    sp=xf+np.exp(-z*w*s_)*(dd*np.cos(wd*s_)+(v0+z*w*dd)/wd*np.sin(wd*s_))+d*np.exp(-s_/ts)
    sm=np.clip(tau/t0,0,1);pre=xr+(x0-xr)*sm*sm*(3-2*sm)
    return np.where(tau<=t0,pre,sp)
best=None
for kk in np.arange(0.6,1.6,0.05):
  for tr in np.arange(500,700,2):
    e=0
    for k in 'LRT':
        m=(t-tr)>=0
        e+=np.mean((model(k,(t-tr)/kk)-E_[k])**2*(1 if True else 1))
    if best is None or e<best[0]: best=(e,kk,tr)
print('rms',np.sqrt(best[0]/3),'scale of time (real/slow-derived)',best[1],'t_rel ms',best[2])
for tr_,kk in ((best[2],1.0),(best[2],best[1])):
    print('k',kk, 'rms', np.sqrt(np.mean([np.mean((model(k,(t-tr_)/kk)-E_[k])**2) for k in 'LRT'])))
print('i t L R T B | model')
for j,r in enumerate(rows):
    tau=t[j]-646
    print(r['i'],int(tau),*(round(E_[k][j],1) for k in 'LRTB'),'|',*(round(float(model(k,np.array(tau))),1) for k in 'LRTB'))
