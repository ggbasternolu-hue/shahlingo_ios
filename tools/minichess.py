# Minimal chess rules engine used ONLY to validate lesson positions.
FILES='abcdefgh'
def sq(s): return (FILES.index(s[0]), int(s[1])-1)
def name(p): return FILES[p[0]]+str(p[1]+1)
class Pos:
    def __init__(s, board, turn, castle, ep): s.board=board; s.turn=turn; s.castle=castle; s.ep=ep
def parse(fen):
    parts=fen.split(); rows=parts[0].split('/'); board={}
    for i,row in enumerate(rows):
        f=0
        for ch in row:
            if ch.isdigit(): f+=int(ch)
            else: board[(f,7-i)]=('w' if ch.isupper() else 'b', ch.lower()); f+=1
    ep=sq(parts[3]) if len(parts)>3 and parts[3]!='-' else None
    return Pos(board, parts[1], parts[2] if len(parts)>2 else '-', ep)
N=[(1,2),(2,1),(-1,2),(-2,1),(1,-2),(2,-1),(-1,-2),(-2,-1)]
K=[(1,0),(-1,0),(0,1),(0,-1),(1,1),(1,-1),(-1,1),(-1,-1)]
D=[(1,1),(1,-1),(-1,1),(-1,-1)]; R=[(1,0),(-1,0),(0,1),(0,-1)]
def inb(x,y): return 0<=x<8 and 0<=y<8
def attacks(board, p, piece):
    c,t=piece; x,y=p; out=[]
    if t=='p':
        d=1 if c=='w' else -1
        for dx in (-1,1):
            if inb(x+dx,y+d): out.append((x+dx,y+d))
    elif t=='n':
        out=[(x+a,y+b) for a,b in N if inb(x+a,y+b)]
    elif t=='k':
        out=[(x+a,y+b) for a,b in K if inb(x+a,y+b)]
    else:
        dirs={'b':D,'r':R,'q':D+R}[t]
        for a,b in dirs:
            nx,ny=x+a,y+b
            while inb(nx,ny):
                out.append((nx,ny))
                if (nx,ny) in board: break
                nx+=a; ny+=b
    return out
def attacked(board, p, by):
    return any(pc[0]==by and p in attacks(board,q,pc) for q,pc in board.items())
def king_sq(board,c):
    return next(q for q,pc in board.items() if pc==(c,'k'))
def in_check(pos,c=None):
    c=c or pos.turn; return attacked(pos.board,king_sq(pos.board,c),'b' if c=='w' else 'w')
def pseudo(pos):
    b=pos.board; me=pos.turn; res=[]
    for p,pc in list(b.items()):
        if pc[0]!=me: continue
        t=pc[1]; x,y=p
        if t=='p':
            d=1 if me=='w' else -1; start=1 if me=='w' else 6; last=7 if me=='w' else 0
            if inb(x,y+d) and (x,y+d) not in b:
                res.append((p,(x,y+d),'q' if y+d==last else None))
                if y==start and (x,y+2*d) not in b: res.append((p,(x,y+2*d),None))
            for dx in (-1,1):
                t2=(x+dx,y+d)
                if not inb(*t2): continue
                if t2 in b and b[t2][0]!=me: res.append((p,t2,'q' if t2[1]==last else None))
                elif pos.ep==t2: res.append((p,t2,'ep'))
        else:
            for t2 in attacks(b,p,pc):
                if t2 not in b or b[t2][0]!=me: res.append((p,t2,None))
            if t=='k':
                r=0 if me=='w' else 7; en='w' if me=='b' else 'b'
                if p==(4,r) and not attacked(b,p,en):
                    if ('K' if me=='w' else 'k') in pos.castle and b.get((7,r))==(me,'r') and (5,r) not in b and (6,r) not in b \
                       and not attacked(b,(5,r),en) and not attacked(b,(6,r),en): res.append((p,(6,r),'ck'))
                    if ('Q' if me=='w' else 'q') in pos.castle and b.get((0,r))==(me,'r') and all((i,r) not in b for i in (1,2,3)) \
                       and not attacked(b,(3,r),en) and not attacked(b,(2,r),en): res.append((p,(2,r),'cq'))
    return res
def apply(pos,m):
    f,t,fl=m; b=dict(pos.board); pc=b.pop(f); me=pos.turn
    if fl=='ep': b.pop((t[0],f[1]))
    if fl=='ck': b[(5,f[1])]=b.pop((7,f[1]))
    if fl=='cq': b[(3,f[1])]=b.pop((0,f[1]))
    if fl=='q': pc=(me,'q')
    b[t]=pc; ep=None
    if pc[1]=='p' and abs(t[1]-f[1])==2: ep=(f[0],(f[1]+t[1])//2)
    return Pos(b,'b' if me=='w' else 'w',pos.castle,ep)
def legal(pos):
    out=[]
    for m in pseudo(pos):
        n=apply(pos,m)
        if not in_check(n,pos.turn): out.append(m)
    return out
def find(pos,uci):
    f,t=sq(uci[:2]),sq(uci[2:4])
    for m in legal(pos):
        if m[0]==f and m[1]==t: return m
    return None
def is_capture(pos,m): return m[1] in pos.board or m[2]=='ep'
def is_mate(pos): return in_check(pos) and not legal(pos)
def is_stalemate(pos): return not in_check(pos) and not legal(pos)
def dests(pos,frm): return sorted(name(m[1]) for m in legal(pos) if m[0]==sq(frm))
def attacked_squares_of(pos,frm): return sorted(name(q) for q in attacks(pos.board,sq(frm),pos.board[sq(frm)]))
