import re, json
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.path import Path
from matplotlib.patches import PathPatch

K=0.5523
def circle(cx,cy,r):
    k=r*K
    return (f"M {cx-r} {cy} C {cx-r} {cy-k} {cx-k} {cy-r} {cx} {cy-r} C {cx+k} {cy-r} {cx+r} {cy-k} {cx+r} {cy} "
            f"C {cx+r} {cy+k} {cx+k} {cy+r} {cx} {cy+r} C {cx-k} {cy+r} {cx-r} {cy+k} {cx-r} {cy} Z")
def rrect(x1,y1,x2,y2,r):
    return (f"M {x1+r} {y1} L {x2-r} {y1} Q {x2} {y1} {x2} {y1+r} L {x2} {y2-r} Q {x2} {y2} {x2-r} {y2} "
            f"L {x1+r} {y2} Q {x1} {y2} {x1} {y2-r} L {x1} {y1+r} Q {x1} {y1} {x1+r} {y1} Z")

BASE=rrect(22,78,78,91,6)
FLARE="M 38 66 C 38 72 34 76 28 79 L 72 79 C 66 76 62 72 62 66 Z"

PIECES={
 'p':{'shapes':[circle(50,29,13), rrect(35,40,65,49,4.5),
        "M 40 47 C 40 58 36 68 30 79 L 70 79 C 64 68 60 58 60 47 Z", BASE],'details':[]},
 'r':{'shapes':["M 27 14 L 40 14 L 40 24 L 45 24 L 45 14 L 55 14 L 55 24 L 60 24 L 60 14 L 73 14 L 73 37 L 64 43 L 64 66 L 70 79 L 30 79 L 36 66 L 36 43 L 27 37 Z", BASE],
      'details':["M 36 43 L 64 43"]},
 'b':{'shapes':[circle(50,14,5.5),
        "M 50 20 C 66 29 70 43 63 53 C 61 56 60 58 60 60 L 40 60 C 40 58 39 56 37 53 C 30 43 34 29 50 20 Z",
        rrect(33,58,67,67,4.5), "M 40 66 C 40 72 36 76 30 79 L 70 79 C 64 76 60 72 60 66 Z", BASE],
      'details':["M 56 30 L 47 43"]},
 'q':{'shapes':["M 23 27 L 31 47 L 37 23 L 44 45 L 50 19 L 56 45 L 63 23 L 69 47 L 77 27 L 71 64 L 29 64 Z",
        circle(23,25,4.5),circle(37,18,4.5),circle(50,13,4.5),circle(63,18,4.5),circle(77,25,4.5),
        rrect(29,62,71,70,4.5), FLARE, BASE],'details':[]},
 'k':{'shapes':[rrect(45.5,5,54.5,27,3.5), rrect(38,11,62,19,3.5),
        "M 50 26 C 67 26 75 37 73 49 C 72 55 67 59 65 62 L 35 62 C 33 59 28 55 27 49 C 25 37 33 26 50 26 Z",
        rrect(29,60,71,69,4.5), FLARE, BASE],'details':["M 50 28 L 50 40"]},
 'n':{'shapes':["M 71 79 C 73 60 71 40 61 28 L 59 13 L 51 21 C 42 23 33 31 26 44 C 22 50 23 56 30 58 C 36 60 41 56 45 53 C 38 61 31 68 29 79 Z", BASE],
      'details':["M 62 31 C 68 44 69 58 67 72"],'dots':[(47,34,3.2),(27.5,50,1.8)]},
}

def parse(d):
    t=d.split(); i=0; verts=[]; codes=[]; cur=None
    while i<len(t):
        c=t[i]; i+=1
        if c=='M': x,y=float(t[i]),float(t[i+1]); i+=2; verts.append((x,y)); codes.append(Path.MOVETO); cur=(x,y)
        elif c=='L': x,y=float(t[i]),float(t[i+1]); i+=2; verts.append((x,y)); codes.append(Path.LINETO)
        elif c=='H': x=float(t[i]); i+=1; verts.append((x,cur[1])); codes.append(Path.LINETO)
        elif c=='Q':
            for _ in range(2): verts.append((float(t[i]),float(t[i+1]))); i+=2
            codes+= [Path.CURVE3]*2
        elif c=='C':
            for _ in range(3): verts.append((float(t[i]),float(t[i+1]))); i+=2
            codes+= [Path.CURVE4]*3
        elif c=='Z': verts.append(verts[0]); codes.append(Path.CLOSEPOLY)
        if verts: cur=verts[-1]
    return Path(verts,codes)

if __name__=='__main__':
    LIGHT=('#E6EEF3','#8FA3B0','#FFFFFF'); DARK=('#5C7482','#2A3A44','#8FA8B6')
    fig,axes=plt.subplots(2,6,figsize=(14,5)); fig.patch.set_facecolor('#18262D')
    for r,(fill,line,_) in enumerate([LIGHT,DARK]):
        for c,k in enumerate('kqrbnp'):
            ax=axes[r][c]; ax.set_xlim(0,100); ax.set_ylim(100,0); ax.set_aspect('equal'); ax.axis('off')
            ax.set_facecolor('#1D2D34')
            for s in PIECES[k]['shapes']:
                ax.add_patch(PathPatch(parse(s),fc='none',ec=line,lw=9,joinstyle='round'))
            for s in PIECES[k]['shapes']:
                ax.add_patch(PathPatch(parse(s),fc=fill,ec='none'))
            for s in PIECES[k]['details']:
                ax.add_patch(PathPatch(parse(s),fc='none',ec=line,lw=2.2,capstyle='round'))
            for (x,y,rad) in PIECES[k].get('dots',[]):
                ax.add_patch(plt.Circle((x,y),rad,fc=line,ec='none'))
    plt.tight_layout(); plt.savefig('pieces_preview.png',dpi=70,facecolor=fig.get_facecolor())
