import io, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.stdout=io.StringIO()   # silence course.py validation prints during import
import course as C
import pieces as P
from minichess import *
sys.stdout=sys.__stdout__
OUT=os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','lib')
def q(s):
    return "'"+s.replace('\\','\\\\').replace("'","\\'").replace('$','\\$').replace('\n','\\n')+"'"
def tr(t): return f"Tr({q(t[0])}, {q(t[1])})"
def strs(a): return '['+', '.join(q(x) for x in a)+']'
def emo(e): return 'Emotion.'+e
def who(w): return 'Who.'+w
def step(st):
    k=st['k']
    if k=='talk':
        lines=',\n          '.join(f"Line({who(l[1])}, {emo(l[2])}, {tr((l[3],l[4]))})" for l in st['lines'])
        return f"TalkStep(\n        lines: [\n          {lines},\n        ],\n        fen: {q(st['fen']) if st['fen'] else 'null'},\n        highlight: {strs(st['hl'])},\n      )"
    if k=='move':
        p=parse(st['fen'])
        if st['goal']=='exact': first=st['line'][0]
        else: first=st['_sols'][0]
        hs=[first[:2],first[2:4]]
        wrong=tr(st['wrong']) if st['wrong'] else 'null'
        return (f"MoveStep(\n        who: {who(st['who'])},\n        emotion: {emo(st['emo'])},\n        prompt: {tr(st['p'])},\n        fen: {q(st['fen'])},\n"
                f"        line: {strs(st['line'])},\n        accept: {strs(st['accept'])},\n        goal: MoveGoal.{st['goal']},\n        hint: {tr(st['hint'])},\n        hintSquares: {strs(hs)},\n        success: {tr(st['ok'])},\n        wrong: {wrong},\n      )")
    if k=='quiz':
        opts=', '.join(tr(o) for o in st['opts'])
        return (f"QuizStep(\n        who: {who(st['who'])},\n        emotion: {emo(st['emo'])},\n        question: {tr(st['p'])},\n        options: [{opts}],\n        correct: {st['correct']},\n        explain: {tr(st['why'])},\n        fen: {q(st['fen']) if st['fen'] else 'null'},\n        highlight: {strs(st['hl'])},\n      )")
    if k=='tap':
        return (f"TapStep(\n        who: {who(st['who'])},\n        emotion: {emo(st['emo'])},\n        prompt: {tr(st['p'])},\n        fen: {q(st['fen'])},\n        expected: {strs(st['expected'])},\n        explain: {tr(st['why'])},\n      )")
def lesson(l):
    steps=',\n      '.join(step(s) for s in l['steps'])
    return (f"Lesson(\n    id: {q(l['id'])},\n    title: {tr(l['title'])},\n    subtitle: {tr(l['sub'])},\n    icon: {q(l['icon'])},\n    kind: LessonKind.{l['kind']},\n    steps: [\n      {steps}\n    ],\n  )")
out=["// GENERATED from tools/course.py — every position, solution, mate and capture was",
     "// validated with an independent rules engine. Edit tools/course.py, not this file.",
     "import 'course_model.dart';","",
     "const List<CourseUnit> courseUnits = ["]
for i,u in enumerate(C.UNITS):
    ls=',\n  '.join(lesson(C.LESSONS[x]) for x in u['lessons'])
    out.append(f"  CourseUnit(\n  id: {q(u['id'])},\n  title: {tr(u['title'])},\n  description: {tr(u['desc'])},\n  colorIndex: {i},\n  chestAfter: {u['chest']},\n  lessons: [\n  {ls}\n  ],\n  ),")
out.append("];\n")
open(OUT+'/data/course_data.dart','w',encoding='utf-8').write('\n'.join(out)) if os.path.isdir(OUT+'/data') else (os.makedirs(OUT+'/data'),open(OUT+'/data/course_data.dart','w',encoding='utf-8').write('\n'.join(out)))
# pieces
os.makedirs(OUT+'/chess',exist_ok=True)
pp=["// GENERATED from tools/pieces.py — vector paths on a 100x100 grid (absolute M/L/H/Q/C/Z only).",
    "class PieceShape {","  const PieceShape({required this.shapes, this.details = const [], this.dots = const []});",
    "  final List<String> shapes;","  final List<String> details;","  final List<(double, double, double)> dots;","}","",
    "const Map<String, PieceShape> pieceShapes = {"]
for k in 'pnbrqk':
    d=P.PIECES[k]
    sh=',\n      '.join(q(s) for s in d['shapes'])
    de=',\n      '.join(q(s) for s in d['details'])
    dots=', '.join(f"({x}, {y}, {r})" for x,y,r in d.get('dots',[]))
    pp.append(f"  {q(k)}: PieceShape(\n    shapes: [\n      {sh},\n    ],\n    details: [{de}],\n    dots: [{dots}],\n  ),")
pp.append("};\n")
open(OUT+'/chess/piece_paths.dart','w').write('\n'.join(pp))
print('generated')
