"""Turn Docker's official SVGs into the outline JSON that docker_morph.py reads.

Needs assets/docker/docker_old_full.svg (old whale + wordmark) and docker_new_full.svg (new lockup).
Run:  uv run --with svgpathtools python3 prepare_outlines.py
Writes outlines_v2.json (old body, new whale, container boxes), wordmark_old.json, wordmark.json.
"""
import re, json
from svgpathtools import parse_path
import os
A=os.path.join(os.path.dirname(os.path.abspath(__file__)),"assets","docker")+"/"
N=480
old=re.findall(r' d="([^"]+)"',open(A+"docker_old_full.svg").read())
new_ds=re.findall(r' d="([^"]+)"',open(A+"docker_new_full.svg").read())
subs=parse_path(old[0]).continuous_subpaths()
body=max(subs,key=lambda s:abs(s.area())); boxes=[s for s in subs if s is not body]
mark=parse_path(new_ds[0])
def resample(path,n):
    L=path.length(); return [(lambda p:(p.real,-p.imag))(path.point(path.ilength(L*i/n,s_tol=1e-6))) for i in range(n)]
def area(p): return 0.5*sum(p[i][0]*p[(i+1)%len(p)][1]-p[(i+1)%len(p)][0]*p[i][1] for i in range(len(p)))
def frame(pts,width):
    xs=[p[0] for p in pts]; ys=[p[1] for p in pts]
    return (min(xs)+max(xs))/2,(min(ys)+max(ys))/2,width/(max(xs)-min(xs))
o=resample(body,N); n=resample(mark,N)
if area(o)<0:o=o[::-1]
if area(n)<0:n=n[::-1]
ocx,ocy,os_=frame(o,4.2); ncx,ncy,ns=frame(n,3.4)
o=[((x-ocx)*os_,(y-ocy)*os_) for x,y in o]; n=[((x-ncx)*ns,(y-ncy)*ns) for x,y in n]
best=min(range(N),key=lambda k:sum((o[i][0]-n[(i+k)%N][0])**2+(o[i][1]-n[(i+k)%N][1])**2 for i in range(N)))
n=n[best:]+n[:best]
cont=[]
for s in boxes:
    xs=[s.point(t/20).real for t in range(21)]; ys=[-s.point(t/20).imag for t in range(21)]
    cont.append((((min(xs)+max(xs))/2-ocx)*os_,((min(ys)+max(ys))/2-ocy)*os_,(max(xs)-min(xs))*os_))
def letters(ds,cx,cy,s):
    loops=[]
    for d in ds:
        for sub in parse_path(d).continuous_subpaths():
            L=sub.length(); k=max(32,int(L/(6 if s<0.01 else 2)))
            loops.append([(lambda p:((p.real-cx)*s,(-p.imag-cy)*s))(sub.point(sub.ilength(L*i/k,s_tol=1e-5))) for i in range(k)])
    return loops
old_words=letters(old[2:8],ocx,ocy,os_)
json.dump(dict(old=o,new=n,containers=cont),open(A+"outlines_v2.json","w"))
json.dump(dict(loops=old_words),open(A+"wordmark_old.json","w"))
print("containers",len(cont),"old letter loops",len(old_words))

# new wordmark
ds=re.findall(r' d="([^"]+)"',open(A+"docker_new_full.svg").read())
mark=parse_path(ds[0]); xs=[mark.point(t/200).real for t in range(201)]; ys=[mark.point(t/200).imag for t in range(201)]
cx=(min(xs)+max(xs))/2; cy=(min(ys)+max(ys))/2; s=3.4/(max(xs)-min(xs))
loops=[]
for d in ds[1:]:
    for sub in parse_path(d).continuous_subpaths():
        L=sub.length(); n=max(32,int(L/6))
        pts=[]
        for i in range(n):
            p=sub.point(sub.ilength(L*i/n,s_tol=1e-5)); pts.append(((p.real-cx)*s,-(p.imag-cy)*s))
        loops.append(pts)
json.dump(dict(loops=loops),open(A+"wordmark.json","w")); print(len(loops), sum(len(l) for l in loops))
