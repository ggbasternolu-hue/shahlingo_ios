# Course authoring + validation + Dart generation.
import sys
from minichess import *
S,M='sergei','maria'
START='rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'
def T(ru,en): return (ru,en)
def L(who,emo,ru,en): return ('line',who,emo,ru,en)
def talk(*lines,fen=None,hl=()): return {'k':'talk','lines':lines,'fen':fen,'hl':list(hl)}
def mv(who,emo,ru,en,fen,line=(),goal='exact',accept=(),hint=('',''),ok=('',''),wrong=None,hl=()):
    return {'k':'move','who':who,'emo':emo,'p':(ru,en),'fen':fen,'line':list(line),'goal':goal,'accept':list(accept),'hint':hint,'ok':ok,'wrong':wrong,'hl':list(hl)}
def quiz(who,emo,ru,en,opts,correct,why,fen=None,hl=()):
    return {'k':'quiz','who':who,'emo':emo,'p':(ru,en),'opts':opts,'correct':correct,'why':why,'fen':fen,'hl':list(hl)}
def tap(who,emo,ru,en,fen,why,frm=None,expected=None,wrong=None):
    return {'k':'tap','who':who,'emo':emo,'p':(ru,en),'fen':fen,'frm':frm,'expected':expected,'why':why,'wrong':wrong}

LESSONS={}  # id -> dict
UNITS=[]
def lesson(id,title,sub,icon,steps,kind='steps'):
    LESSONS[id]={'id':id,'title':title,'sub':sub,'icon':icon,'steps':steps,'kind':kind}; return id
def unit(id,title,desc,lessons,chest_after=2): UNITS.append({'id':id,'title':title,'desc':desc,'lessons':lessons,'chest':chest_after})

# ---------------- UNIT 1 ----------------
l=lesson('board',T('Доска и клетки','The board'),T('Вертикали, горизонтали и адреса клеток','Files, ranks and square names'),'grid',[
 talk(L(S,'happy','Привет! Я Сергей. На шахматной доске 64 клетки: 8 вертикалей и 8 горизонталей.','Hi, I’m Sergei. A chessboard has 64 squares: 8 files and 8 ranks.'),
      L(M,'smug','А я Мария. Запомни: белые ходят первыми. Это единственное, в чём я им уступаю.','I’m Maria. Remember: White moves first. It’s the only thing I let them have.'),
      L(S,'neutral','Вертикали обозначают буквами a–h, горизонтали — цифрами 1–8. У каждой клетки свой адрес.','Files are letters a–h, ranks are numbers 1–8. Every square has its own address.'),fen=START),
 tap(S,'neutral','Найди клетку e4 и нажми на неё.','Find the square e4 and tap it.',START,T('Верно: вертикаль e, горизонталь 4 — главная клетка центра.','Right: file e, rank 4 — the key central square.'),expected=['e4']),
 quiz(S,'thinking','Какого цвета клетка в правом нижнем углу, у белых?','What colour is the bottom-right square on White’s side?',[T('Светлая','Light'),T('Тёмная','Dark')],0,T('Правило: «белая клетка — справа». Клетка h1 светлая.','Remember: “light on the right”. The square h1 is light.'),fen=START,hl=['h1']),
 tap(S,'neutral','Нажми на обе клетки вертикали d, где стоят белые фигуры.','Tap both squares on the d-file where White has pieces.',START,T('Да: ферзь на d1 и пешка на d2.','Yes: the queen on d1 and the pawn on d2.'),expected=['d1','d2']),
 quiz(M,'smug','Раз ты такой умный: какая фигура стоит на g1 в начале партии?','Since you’re so clever: which piece starts on g1?',[T('Конь','Knight'),T('Слон','Bishop'),T('Ладья','Rook')],0,T('Конь. Он и правда стоит на g1.','The knight. It does start on g1.'),fen=START,hl=['g1']),
])
l2=lesson('pawn',T('Пешка','The pawn'),T('Ходит вперёд, бьёт по диагонали','Moves forward, captures diagonally'),'p',[
 talk(L(S,'neutral','Пешка — самая простая фигура. Она ходит только вперёд и только на одну клетку.','The pawn is the simplest piece. It only moves forward, one square at a time.'),
      L(M,'smug','Только вперёд? Скучно. Зато пешки превращаются в ферзей — на этом и стоит моя карьера.','Only forward? Boring. But pawns become queens — that’s my whole career plan.'),
      L(S,'happy','С начального места пешка может прыгнуть и на две клетки.','From its starting square a pawn may also jump two squares.'),fen='4k3/8/8/8/8/8/4P3/4K3 w - - 0 1',hl=['e2']),
 tap(S,'neutral','Нажми на клетки, куда может пойти пешка e2.','Tap the squares the e2 pawn can move to.','4k3/8/8/8/8/8/4P3/4K3 w - - 0 1',T('С начальной клетки — на одну или на две клетки вперёд.','From its start square: one or two squares forward.'),frm='e2'),
 mv(S,'neutral','Займи центр: сыграй e2–e4.','Take the centre: play e2–e4.',START,line=['e2e4'],hint=T('Пешка e2 может пройти сразу две клетки.','The e2 pawn can advance two squares at once.'),ok=T('Пешка в центре — отличное начало.','A pawn in the centre — a great start.')),
 talk(L(S,'neutral','Берёт пешка иначе: по диагонали на одну клетку вперёд.','A pawn captures differently: one square diagonally forward.'),
      L(M,'angry','Вот это поворот! Ходит прямо, а бьёт наискосок. Подозрительно.','What a twist! Moves straight, captures sideways. Suspicious.'),fen='4k3/8/8/3p4/4P3/8/8/4K3 w - - 0 1',hl=['e4','d5']),
 mv(S,'happy','Возьми чёрную пешку на d5.','Capture the black pawn on d5.','4k3/8/8/3p4/4P3/8/8/4K3 w - - 0 1',line=['e4d5'],hint=T('Пешка e4 бьёт на d5 и f5.','The e4 pawn attacks d5 and f5.'),ok=T('Вперёд — ходит, наискосок — берёт.','Forward to move, diagonal to capture.')),
 quiz(M,'thinking','Может ли пешка e4 взять фигуру, которая стоит прямо перед ней, на e5?','Can the e4 pawn capture the piece directly in front of it, on e5?',[T('Нет, прямо она только ходит','No — straight ahead it only moves'),T('Да, любую фигуру','Yes, any piece')],0,T('Фигура прямо перед пешкой только блокирует ей путь.','A piece straight ahead just blocks the pawn.'),fen='4k3/8/8/4p3/4P3/8/8/4K3 w - - 0 1',hl=['e4','e5']),
])
l3=lesson('rook',T('Ладья','The rook'),T('Прямые линии на любое расстояние','Straight lines, any distance'),'r',[
 talk(L(S,'neutral','Ладья ходит по прямой: вперёд, назад, влево и вправо — на любое число свободных клеток.','The rook moves in straight lines — forward, back, left, right — over any number of empty squares.'),
      L(M,'smug','Башня на колёсиках. Прямолинейная, как некоторые тренеры.','A tower on wheels. Straightforward, like certain coaches.'),
      L(S,'thinking','Через другие фигуры ладья не перепрыгивает. Чужую она может взять и остановиться.','A rook can’t jump over pieces. It can capture an enemy piece and stop there.'),fen='4k3/8/8/3p4/3R4/8/8/4K3 w - - 0 1',hl=['d4']),
 tap(S,'neutral','Нажми на все клетки, куда может пойти ладья d4.','Tap every square the rook on d4 can go to.','4k3/8/8/3p4/3R4/8/8/4K3 w - - 0 1',T('Верно: вниз до d1, по горизонтали, и взятие на d5 — дальше пройти нельзя.','Right: down to d1, along the rank, and the capture on d5 — it can’t go further.'),frm='d4'),
 mv(S,'happy','Проведи ладью a1 на a8. Дорога свободна.','Slide the rook from a1 to a8. The road is clear.','4k3/8/8/8/8/8/8/R3K3 w - - 0 1',line=['a1a8'],hint=T('Ладья идёт вверх по a-вертикали.','The rook goes straight up the a-file.'),ok=T('Ещё и шах королю по восьмой горизонтали!','And it even gives check along the eighth rank!')),
 mv(M,'smug','Тут что-то плохо лежит. Забери это ладьёй.','Something’s lying around loose. Take it with your rook.','6k1/8/8/8/1p2R3/8/8/4K3 w - - 0 1',goal='capture',hint=T('Посмотри на горизонталь, где стоит ладья.','Look along the rank where your rook stands.'),ok=T('Ладья берёт вдоль горизонтали.','The rook captures along the rank.')),
 quiz(S,'neutral','Как ходит ладья?','How does the rook move?',[T('По прямым линиям','In straight lines'),T('Буквой «Г»','In an L-shape'),T('По диагонали','Diagonally')],0,T('По вертикалям и горизонталям.','Along files and ranks.')),
])
l4=lesson('bishop',T('Слон','The bishop'),T('Только по диагоналям','Diagonals only'),'b',[
 talk(L(S,'neutral','Слон ходит только по диагонали на любое число свободных клеток.','The bishop moves only diagonally, any number of empty squares.'),
      L(M,'smug','Бедняга всю жизнь ходит по клеткам одного цвета.','The poor guy spends his entire life on one colour.'),
      L(S,'happy','Поэтому у каждой стороны два слона: светлопольный и тёмнопольный.','That’s why each side has two: a light-squared one and a dark-squared one.'),fen='4k3/8/8/8/3B4/8/8/4K3 w - - 0 1',hl=['d4']),
 tap(S,'neutral','Нажми на все клетки, куда может пойти слон d4.','Tap every square the bishop on d4 can go to.','4k3/8/8/8/3B4/8/8/4K3 w - - 0 1',T('Четыре диагонали из центра — их тринадцать клеток.','Four diagonals from the centre — thirteen squares.'),frm='d4'),
 mv(S,'neutral','Освободи диагональ и поставь слона на c4: f1–c4.','The diagonal is open — put the bishop on c4: f1–c4.','rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',line=['f1c4'],hint=T('Слон идёт по диагонали f1–e2–d3–c4.','The bishop travels f1–e2–d3–c4.'),ok=T('Слон смотрит прямо на королевский фланг соперника.','The bishop now eyes Black’s kingside.')),
 mv(M,'thinking','Слон может кое-кого съесть. Найди кого.','The bishop can win something. Find it.','4k3/8/8/4n3/8/8/1B6/4K3 w - - 0 1',goal='capture',hint=T('Проверь длинную диагональ b2–h8.','Check the long diagonal b2–h8.'),ok=T('Слон берёт по диагонали на любое расстояние.','A bishop captures along its diagonal from any distance.')),
 quiz(S,'thinking','Может ли слон с белых клеток когда-нибудь встать на чёрную?','Can a light-squared bishop ever land on a dark square?',[T('Нет, никогда','No, never'),T('Да, на каждом втором ходу','Yes, every other move')],0,T('Он всегда остаётся на клетках своего цвета.','It always stays on its own colour.')),
])
unit('u1',T('Знакомство с доской','Meet the board'),T('Клетки, пешка, ладья и слон','Squares, pawn, rook and bishop'),[l,l2,l3,l4])
# ---------------- UNIT 2 ----------------
l=lesson('knight',T('Конь','The knight'),T('Прыгает буквой «Г»','Jumps in an L-shape'),'n',[
 talk(L(S,'happy','Конь самый хитрый: он ходит буквой «Г» — две клетки в одну сторону и одна в сторону.','The knight is the trickiest: it moves in an L — two squares one way, one square sideways.'),
      L(M,'happy','И единственный умеет перепрыгивать через чужие фигуры. Мой любимчик!','And the only one who can jump over other pieces. My favourite!'),fen='4k3/8/8/8/3N4/8/8/4K3 w - - 0 1',hl=['d4']),
 tap(S,'neutral','Нажми на все клетки, куда может пойти конь d4.','Tap every square the knight on d4 can go to.','4k3/8/8/8/3N4/8/8/4K3 w - - 0 1',T('Восемь клеток — по кругу буквой «Г».','Eight squares — in a ring of L-shapes.'),frm='d4'),
 mv(S,'neutral','Выведи коня g1–f3: он перепрыгнет через пешки.','Develop the knight g1–f3: it jumps over the pawns.',START,line=['g1f3'],hint=T('Конь с g1 идёт на f3.','The knight on g1 goes to f3.'),ok=T('Так начинают почти все партии.','Nearly every game starts like this.')),
 mv(M,'smug','Конь уже смотрит на чужую пешку. Не стесняйся.','Your knight is staring at a pawn. Don’t be shy.','4k3/8/8/3p4/8/4N3/8/4K3 w - - 0 1',goal='capture',hint=T('От e3 конь бьёт d5.','From e3 the knight attacks d5.'),ok=T('Конь берёт так же, как и ходит.','The knight captures the way it moves.')),
 quiz(S,'thinking','Какая фигура может перепрыгивать через другие?','Which piece can jump over others?',[T('Конь','Knight'),T('Слон','Bishop'),T('Ладья','Rook')],0,T('Только конь.','Only the knight.'),fen=START,hl=['b1','g1']),
])
l2=lesson('queen',T('Ферзь','The queen'),T('Ладья и слон в одном','Rook and bishop in one'),'q',[
 talk(L(S,'neutral','Ферзь — самая сильная фигура. Он ходит как ладья и как слон вместе.','The queen is the strongest piece. It moves like a rook and a bishop combined.'),
      L(M,'smug','Королева партии. Прошу любить и бояться.','The queen of the game. Please adore and fear.'),
      L(S,'surprised','Но не рвись в бой слишком рано: потерять ферзя очень обидно.','But don’t rush her out too early — losing a queen hurts.'),fen='4k3/8/8/8/3Q4/8/8/4K3 w - - 0 1',hl=['d4']),
 quiz(S,'neutral','По скольким направлениям ходит ферзь?','In how many directions can the queen move?',[T('По восьми: четыре прямых и четыре диагональных','Eight: four straight, four diagonal'),T('По четырём','Four'),T('По двум','Two')],0,T('Вверх, вниз, влево, вправо и четыре диагонали.','Up, down, left, right and four diagonals.')),
 mv(S,'neutral','Проведи ферзя d2–a5 по диагонали.','Slide the queen d2–a5 along the diagonal.','4k3/8/8/8/8/8/3Q4/4K3 w - - 0 1',line=['d2a5'],hint=T('Ферзь идёт по диагонали d2–c3–b4–a5.','The queen goes d2–c3–b4–a5.'),ok=T('Ферзь свободно ходит по диагоналям.','The queen travels diagonals freely.')),
 mv(M,'happy','Покажи, на что способен ферзь: забери пешку.','Show what the queen can do: take the pawn.','6k1/8/8/8/p2Q4/8/8/4K3 w - - 0 1',goal='capture',hint=T('Пешка стоит на одной горизонтали с ферзём.','The pawn is on the queen’s rank.'),ok=T('Ферзь берёт по прямой, как ладья.','The queen captures in a straight line, like a rook.')),
 quiz(M,'smug','Кто сильнее: ладья или ферзь?','Who is stronger: the rook or the queen?',[T('Ферзь','The queen'),T('Ладья','The rook')],0,T('Ферзь = ладья + слон.','Queen = rook + bishop.')),
])
l3=lesson('king',T('Король','The king'),T('Один шаг в любую сторону','One step in any direction'),'k',[
 talk(L(S,'neutral','Король — главная фигура. Он ходит на одну клетку в любую сторону. Потерять его — значит проиграть.','The king is the most important piece. It steps one square in any direction. Lose it and you lose the game.'),
      L(M,'smug','Поэтому его и прячут за пешками. Король, но трусишка.','That’s why he hides behind pawns. A king, but a bit of a coward.'),
      L(S,'angry','Осторожность — не трусость, Мария.','Caution isn’t cowardice, Maria.'),fen='4k3/8/8/8/4K3/8/8/8 w - - 0 1',hl=['e4']),
 tap(S,'neutral','Нажми на все клетки, куда может пойти король e4.','Tap every square the king on e4 can go to.','4k3/8/8/8/4K3/8/8/8 w - - 0 1',T('Все восемь клеток вокруг короля.','All eight squares around the king.'),frm='e4'),
 quiz(S,'thinking','Белый король стоит на e3. Может ли он пойти на e4?','The white king is on e3. Can it step to e4?',[T('Нет — клетка рядом с чёрным королём','No — that square is next to the black king'),T('Да, она свободна','Yes, it’s empty')],0,T('Короли не могут стоять рядом: каждый из них бьёт соседние клетки.','Kings can’t stand next to each other — each controls the neighbouring squares.'),fen='8/8/8/3k4/8/4K3/8/8 w - - 0 1',hl=['e3','e4','d5']),
 mv(M,'happy','Чёрная ладья зашла слишком далеко. Королю есть чем поживиться!','The black rook wandered too far. Your king can feast!','7k/8/8/8/8/8/3r4/4K3 w - - 0 1',goal='capture',hint=T('Ладья стоит рядом с королём.','The rook is right next to your king.'),ok=T('Король может брать фигуры, если они не защищены.','The king can capture unprotected pieces.')),
])
unit('u2',T('Конь, ферзь и король','Knight, queen and king'),T('Остальные фигуры','The remaining pieces'),[l,l2,l3])
# ---------------- UNIT 3 ----------------
l=lesson('capture',T('Взятия и размены','Captures and trades'),T('Сколько стоят фигуры','What the pieces are worth'),'swap',[
 talk(L(S,'neutral','Взятие — ход, которым ты забираешь фигуру соперника. Она уходит с доски навсегда.','A capture removes an enemy piece from the board for good.'),
      L(M,'smug','Моё любимое занятие после рокировки.','My favourite activity after castling.'),
      L(S,'thinking','Но сначала проверь: не защищена ли фигура? Иначе её заберут в ответ.','But first check: is the piece protected? Otherwise you’ll be captured right back.'),fen='4k3/8/8/3p4/4P3/8/8/4K3 w - - 0 1',hl=['d5']),
 quiz(S,'neutral','Что ценнее: ладья или слон?','Which is worth more: a rook or a bishop?',[T('Ладья','The rook'),T('Слон','The bishop')],0,T('Пешка — 1, конь и слон — по 3, ладья — 5, ферзь — 9.','Pawn 1, knight and bishop 3 each, rook 5, queen 9.')),
 mv(S,'neutral','Ферзь может взять ладью или пешку. Забери самое ценное.','Your queen can take a rook or a pawn. Take the more valuable one.','4k3/8/8/2r2p2/8/8/2Q5/4K3 w - - 0 1',line=['c2c5'],hint=T('Ладья стоит дороже пешки.','A rook is worth more than a pawn.'),ok=T('Ладья — 5 очков, пешка — 1.','A rook is 5 points, a pawn only 1.')),
 mv(M,'thinking','Конь b5 защищён пешкой. Найди взятие, после которого ты ничего не теряешь.','The b5 knight is protected by a pawn. Find a capture where you lose nothing.','4k3/6p1/2p5/1n6/8/8/1Q6/4K3 w - - 0 1',line=['b2g7'],hint=T('Подумай, какая из чёрных фигур ничем не защищена.','Which black piece has no protection at all?'),wrong=T('Это взятие защищённой фигуры: ферзя сразу заберут в ответ.','That captures a protected piece — your queen would be taken straight back.'),ok=T('Свободная пешка лучше, чем ферзь за коня.','A free pawn beats a queen for a knight.')),
 quiz(S,'thinking','Ты отдаёшь ладью (5) и берёшь слона (3). Это выгодный размен?','You give a rook (5) and win a bishop (3). Is that a good trade?',[T('Нет, ты теряешь 2 очка','No — you lose 2 points'),T('Да, фигура за фигуру всегда равно','Yes, a piece for a piece is always equal')],0,T('Считай очки: 5 против 3 — такой размен невыгоден.','Count the points: 5 for 3 is a bad trade.')),
])
l2=lesson('check',T('Шах','Check'),T('Три способа защитить короля','Three ways to save the king'),'check',[
 talk(L(S,'surprised','Шах! Король атакован. Это ещё не конец, но игнорировать шах нельзя.','Check! The king is attacked. It’s not over, but you can’t ignore it.'),
      L(M,'happy','Обожаю говорить «шах». Звучит как удар в гонг.','I love saying “check”. It sounds like a gong.'),
      L(S,'neutral','Есть три способа спастись: уйти королём, закрыться фигурой или взять нападающую фигуру.','There are three answers: move the king, block, or capture the attacker.'),fen='4r1k1/8/8/8/8/8/8/4K3 w - - 0 1',hl=['e1','e8']),
 mv(S,'neutral','Первый способ: уйди из-под шаха королём.','First way: move the king out of check.','4r1k1/8/8/8/8/8/8/4K3 w - - 0 1',line=['e1f1'],accept=['e1d1','e1d2','e1f2'],hint=T('Король не должен оставаться на e-вертикали.','The king can’t stay on the e-file.'),ok=T('Король ушёл с линии удара.','The king left the line of fire.')),
 mv(S,'neutral','Второй способ: закройся. Поставь слона между ладьёй и королём.','Second way: block. Put the bishop between the rook and the king.','4r1k1/8/B7/8/8/8/8/4K3 w - - 0 1',line=['a6e2'],hint=T('Слон может дойти до e2 по диагонали.','The bishop can reach e2 along the diagonal.'),ok=T('Фигура перекрыла линию шаха.','A piece now blocks the line of check.')),
 mv(M,'angry','Третий способ — убрать нападающего. Бери ту, что дала шах!','Third way: remove the attacker. Take the piece giving check!','4r1k1/8/8/7B/8/8/8/4K3 w - - 0 1',goal='capture',hint=T('Слон на h5 видит поле e8.','The bishop on h5 sees e8.'),wrong=T('Здесь лучше взять фигуру, которая даёт шах.','Here the best answer is to capture the checking piece.'),ok=T('Нападающая фигура исчезла — шаха нет.','The attacker is gone — no more check.')),
 quiz(S,'thinking','Королю поставили шах. Что делать нельзя?','Your king is in check. What is NOT allowed?',[T('Сделать любой ход, не убирающий шах','Make any move that leaves the check in place'),T('Уйти королём','Move the king'),T('Закрыться фигурой','Block with a piece')],0,T('Шах нужно убрать обязательно — иначе ход запрещён.','You must remove the check — other moves are illegal.')),
])
l3=lesson('mate',T('Мат и пат','Checkmate and stalemate'),T('Как заканчивается партия','How a game ends'),'mate',[
 talk(L(S,'neutral','Если королю поставили шах и спастись нечем — это мат. Партия окончена.','If the king is in check and has no escape, that’s checkmate. The game is over.'),
      L(M,'happy','Мат! Лучшее слово в шахматах.','Checkmate! The best word in chess.'),fen='7k/6Q1/5K2/8/8/8/8/8 b - - 0 1',hl=['g7','h8']),
 mv(S,'neutral','Поставь мат ферзём. Король h8 не должен уйти.','Deliver mate with the queen. The h8 king must have no escape.','7k/8/5KQ1/8/8/8/8/8 w - - 0 1',goal='mate',hint=T('Ферзь под защитой короля на f6 может встать рядом с чужим королём.','With your king on f6 guarding it, the queen can stand next to the enemy king.'),ok=T('Мат! Ферзь защищён королём, а все клетки отхода закрыты.','Checkmate! The queen is guarded and every escape square is covered.')),
 mv(M,'smug','Ладья и ферзь работают вместе. Найди мат.','Rook and queen working together. Find the mate.','7k/5Q2/8/8/8/8/8/K5R1 w - - 0 1',goal='mate',hint=T('Королю закрыты g7, h7 и g8 — ему нужен только шах.','The king’s squares g7, h7, g8 are covered — it just needs a check.'),ok=T('Королю некуда идти.','The king has nowhere to go.')),
 mv(S,'thinking','Король спрятался за своими пешками и сам себя запер. Найди мат.','The king hid behind its own pawns and locked itself in. Find the mate.','6k1/5ppp/8/8/8/8/8/R3K3 w - - 0 1',goal='mate',hint=T('Ладья может пройти на восьмую горизонталь.','The rook can reach the eighth rank.'),ok=T('Это классический мат на последней горизонтали.','A classic back-rank mate.')),
 quiz(S,'surprised','У чёрных нет ходов, но шаха нет. Что это?','Black has no legal moves, but isn’t in check. What is this?',[T('Пат — ничья','Stalemate — a draw'),T('Мат — победа белых','Checkmate — White wins'),T('Чёрные пропускают ход','Black passes')],0,T('Нет шаха и нет ходов — это пат, ничья.','No check and no moves — stalemate, a draw.'),fen='7k/5Q2/6K1/8/8/8/8/8 b - - 0 1',hl=['h8']),
])
unit('u3',T('Взятия и шах','Captures and check'),T('Как играть всерьёз','How to play for real'),[l,l2,l3])
# ---------------- UNIT 4 ----------------
l=lesson('castle',T('Рокировка','Castling'),T('Король прячется, ладья включается','King hides, rook joins in'),'castle',[
 talk(L(S,'neutral','Рокировка — единственный ход, где двигаются две фигуры: король прыгает на две клетки, а ладья перепрыгивает через него.','Castling is the only move with two pieces: the king hops two squares and the rook jumps over it.'),
      L(M,'thinking','Странный ход. Зато король в безопасности, а ладья наконец при деле.','A strange move. But the king is safe and the rook finally has a job.'),
      L(S,'neutral','Нужно, чтобы король и ладья ещё не ходили, между ними не было фигур, а король не стоял под шахом.','Neither piece may have moved, nothing may stand between them, and the king can’t be in check.'),fen='4k3/8/8/8/8/8/8/4K2R w K - 0 1',hl=['e1','h1']),
 mv(S,'neutral','Короткая рокировка: король e1 на g1.','Kingside castling: king e1 to g1.','4k3/8/8/8/8/8/8/4K2R w K - 0 1',line=['e1g1'],hint=T('Двигай короля на две клетки к ладье.','Move the king two squares towards the rook.'),ok=T('Ладья сама встала на f1.','The rook landed on f1 by itself.')),
 mv(S,'happy','Длинная рокировка: король e1 на c1.','Queenside castling: king e1 to c1.','4k3/8/8/8/8/8/8/R3K3 w Q - 0 1',line=['e1c1'],hint=T('Король идёт на две клетки к ладье a1.','The king goes two squares towards the a1 rook.'),ok=T('Теперь ладья на d1.','The rook is now on d1.')),
 quiz(M,'thinking','Можно ли рокироваться, если король под шахом?','Can you castle while your king is in check?',[T('Нет, нельзя','No'),T('Да, это же рокировка','Yes — it’s castling')],0,T('Из-под шаха рокироваться нельзя.','You can’t castle out of check.'),fen='4r1k1/8/8/8/8/8/8/4K2R w K - 0 1',hl=['e1','e8']),
 quiz(S,'neutral','Когда рокировка невозможна?','When is castling not allowed?',[T('Если король уже ходил','If the king has already moved'),T('Если у тебя на одну пешку меньше','If you are a pawn down'),T('Если идёт четвёртый ход','If it’s move four')],0,T('Король и ладья должны оставаться на местах до рокировки.','Both king and rook must still be on their start squares.')),
])
l2=lesson('promotion',T('Превращение','Promotion'),T('Из пешки — в ферзя','From pawn to queen'),'promo',[
 talk(L(S,'neutral','Пешка не умеет ходить назад, но мечтает дойти до последней горизонтали.','A pawn never goes backwards, but it dreams of reaching the last rank.'),
      L(M,'happy','И там превращается в любую фигуру. Почти всегда — в ферзя.','And there it becomes any piece. Almost always a queen.'),
      L(S,'happy','Из скромной пешки — в королеву. Вот это карьера.','From humble pawn to queen. Quite a career.'),fen='7k/P7/8/8/8/8/8/7K w - - 0 1',hl=['a7','a8']),
 mv(S,'neutral','Проведи пешку a7–a8 и получи ферзя.','Advance the pawn a7–a8 and get a queen.','7k/P7/8/8/8/8/8/7K w - - 0 1',line=['a7a8'],hint=T('Пешка делает один шаг вперёд.','The pawn takes one step forward.'),ok=T('Пешка стала ферзём — и сразу дала шах!','The pawn became a queen — and gave check!')),
 mv(M,'smug','Пешка может превратиться и со взятием. Найди такой ход.','A pawn can promote with a capture too. Find it.','1n5k/P7/8/8/8/8/8/7K w - - 0 1',goal='capture',hint=T('Пешка бьёт по диагонали вперёд.','The pawn captures diagonally forward.'),ok=T('Взятие и превращение сразу!','A capture and a promotion at once!')),
 quiz(S,'neutral','Во что чаще всего превращают пешку?','What do players usually promote a pawn to?',[T('В ферзя','A queen'),T('В коня','A knight'),T('В слона','A bishop')],0,T('Ферзь — самая сильная фигура.','The queen is the strongest piece.')),
])
l3=lesson('enpassant',T('Взятие на проходе','En passant'),T('Самое необычное правило','The strangest rule'),'ep',[
 talk(L(S,'neutral','Если пешка соперника прыгнула на две клетки и встала рядом с твоей, ты можешь взять её, будто она сделала один шаг.','If an enemy pawn jumps two squares and lands beside yours, you may capture it as if it had moved one.'),
      L(M,'angry','Нечестно! Я шагнула на две клетки — и меня всё равно съели?','Not fair! I jumped two squares and still got eaten?'),
      L(S,'happy','Но только сразу, на следующем ходу. Потом право пропадает.','But only immediately, on the next move. After that, the right is gone.'),fen='4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1',hl=['e5','d5']),
 mv(S,'neutral','Только что чёрные сыграли d7–d5. Возьми пешку на проходе: e5 на d6.','Black has just played d7–d5. Capture it en passant: e5 to d6.','4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1',line=['e5d6'],hint=T('Пешка идёт на клетку, через которую прыгнула соперница.','Move to the square the enemy pawn jumped over.'),ok=T('Пешка d5 снята с доски, хотя ты встал на d6.','The d5 pawn is gone, though you landed on d6.')),
 quiz(S,'thinking','Когда можно брать на проходе?','When can you capture en passant?',[T('Сразу после двойного хода пешки','Right after the double pawn move'),T('В любой момент партии','At any time in the game'),T('Только ферзём','Only with the queen')],0,T('Только на следующем ходу.','Only on the very next move.')),
])
unit('u4',T('Особые ходы','Special moves'),T('Рокировка, превращение и «на проходе»','Castling, promotion and en passant'),[l,l2,l3])
# ---------------- UNIT 5 ----------------
l=lesson('fork',T('Вилка','The fork'),T('Одна фигура — две цели','One piece, two targets'),'fork',[
 talk(L(S,'neutral','Вилка — удар, при котором одна фигура атакует сразу две цели. Соперник спасёт только одну.','A fork is when one piece attacks two targets. Your opponent can save only one.'),
      L(M,'smug','А вторую заберу я. Обожаю вилки.','And I take the other. I love forks.'),fen='2q3k1/8/8/3N4/8/8/8/K7 w - - 0 1',hl=['d5']),
 mv(S,'neutral','Прыгни конём d5–e7: шах и нападение на ферзя.','Jump the knight d5–e7: check and an attack on the queen.','2q3k1/8/8/3N4/8/8/8/K7 w - - 0 1',line=['d5e7'],hint=T('С e7 конь бьёт g8 и c8.','From e7 the knight hits g8 and c8.'),ok=T('Королю шах, а ферзь под боем — вилка!','Check on the king and the queen is attacked — a fork!')),
 tap(S,'thinking','Нажми на обе фигуры, которые атакует конь на e7.','Tap both pieces attacked by the knight on e7.','2q3k1/4N3/8/8/8/8/8/K7 b - - 0 1',T('Конь e7 бьёт короля g8 и ферзя c8.','The e7 knight attacks the king on g8 and the queen on c8.'),expected=['c8','g8']),
 mv(M,'happy','Теперь без подсказок: найди вилку на короля и ладью.','Now without help: find a fork on the king and the rook.','r3k3/8/8/1N6/8/8/8/7K w - - 0 1',line=['b5c7'],hint=T('Конь должен встать так, чтобы бить e8 и a8.','The knight must attack both e8 and a8.'),ok=T('Король вынужден уйти — ладья наша.','The king must move — the rook is ours.')),
 quiz(S,'neutral','Какая фигура чаще всего ставит вилки?','Which piece makes forks most often?',[T('Конь','The knight'),T('Король','The king')],0,T('Конь бьёт «буквой Г», и этот удар сложно заметить.','The knight’s L-shaped attack is easy to overlook.')),
])
l2=lesson('pin',T('Связка','The pin'),T('Фигура не может уйти','A piece that cannot move'),'pin',[
 talk(L(S,'neutral','Связка: фигура не может ходить, потому что за ней стоит король или более ценная фигура.','A pin: a piece can’t move because the king or a more valuable piece stands behind it.'),
      L(M,'smug','Ходить нельзя, дышать можно. Пока.','No moving. Breathing is allowed. For now.'),fen='4k3/4n3/8/8/8/8/4R3/4K3 b - - 0 1',hl=['e2','e7','e8']),
 quiz(S,'thinking','Может ли связанный чёрный конь e7 пойти на g6?','Can the pinned black knight on e7 go to g6?',[T('Нет — королю будет шах','No — it would expose the king to check'),T('Да, конь ходит буквой «Г»','Yes, knights move in an L')],0,T('Конь связан ладьёй: если он уйдёт, король окажется под шахом.','The rook pins the knight — if it leaves, the king is in check.'),fen='4k3/4n3/8/8/8/8/4R3/4K3 b - - 0 1',hl=['e7']),
 mv(S,'neutral','Свяжи коня c6: поставь слона на b5.','Pin the c6 knight: put the bishop on b5.','4k3/8/2n5/8/8/8/8/4KB2 w - - 0 1',line=['f1b5'],hint=T('Слон должен смотреть на коня и дальше — на короля.','The bishop must see the knight and, behind it, the king.'),ok=T('Конь c6 связан: за ним на диагонали король.','The c6 knight is pinned — the king is behind it on the diagonal.')),
 tap(S,'thinking','Нажми на фигуру, которая сейчас связана.','Tap the piece that is currently pinned.','4k3/8/2n5/1B6/8/8/8/4K3 b - - 0 1',T('Конь c6 связан слоном b5.','The c6 knight is pinned by the b5 bishop.'),expected=['c6']),
])
l3=lesson('mate1',T('Мат в один ход','Mate in one'),T('Тренируем острый взгляд','Sharpen your eye'),'mate1',[
 talk(L(S,'neutral','Теперь потренируемся. Ищи шах, после которого королю некуда идти.','Time to practise. Look for a check where the king has no escape.'),
      L(M,'smug','Если справишься со всеми четырьмя — я признаю, что ты не безнадёжен.','Solve all four and I’ll admit you’re not hopeless.')),
 mv(S,'neutral','Мат №1: король заперт собственными пешками.','Mate #1: the king is boxed in by its own pawns.','6k1/5ppp/8/8/8/8/8/3R2K1 w - - 0 1',goal='mate',hint=T('Ладья должна попасть на восьмую горизонталь.','The rook has to reach the eighth rank.'),ok=T('Мат на последней горизонтали.','Back-rank mate.')),
 mv(S,'neutral','Мат №2: королю белых помогает собственный король.','Mate #2: your own king helps.','7k/8/6K1/8/8/8/8/5R2 w - - 0 1',goal='mate',hint=T('Король g6 закрыл поля g7 и h7.','Your king on g6 covers g7 and h7.'),ok=T('Ладья закрыла последнюю клетку отхода.','The rook closed the last escape square.')),
 mv(M,'happy','Мат №3: две ладьи — лестница.','Mate #3: two rooks — the ladder.','7k/1R6/8/8/8/8/R7/6K1 w - - 0 1',goal='mate',hint=T('Одна ладья держит седьмую линию, вторая даёт шах.','One rook holds the seventh rank, the other gives check.'),ok=T('Две ладьи ставят мат без помощи других фигур.','Two rooks mate without any help.')),
 mv(S,'happy','Мат №4: ферзь и король против короля.','Mate #4: queen and king against a lone king.','k7/8/1K6/8/8/8/7Q/8 w - - 0 1',goal='mate',hint=T('Ферзь может встать на горизонталь короля.','The queen can reach the king’s rank.'),ok=T('Отличная работа!','Excellent work!')),
])
unit('u5',T('Тактика','Tactics'),T('Вилка, связка и мат за один ход','Forks, pins and mate in one'),[l,l2,l3])
# ---------------- UNIT 6 ----------------
l=lesson('opening',T('Дебют','The opening'),T('Центр, развитие, король','Centre, development, king'),'open',[
 talk(L(S,'neutral','Дебют — начало партии. У него три правила: займи центр, развей фигуры и спрячь короля.','The opening has three rules: take the centre, develop your pieces and hide your king.'),
      L(M,'smug','И не ходи ферзём в первые пять ходов. Совет от человека, который выигрывает.','And don’t play the queen in the first five moves. Advice from a winner.'),fen=START),
 mv(S,'neutral','Правило первое: займи центр. Сыграй e2–e4.','Rule one: take the centre. Play e2–e4.',START,line=['e2e4'],accept=['d2d4'],hint=T('Центральные пешки: e и d.','The central pawns are e and d.'),ok=T('Центр захвачен.','The centre is yours.')),
 mv(S,'neutral','Правило второе: развивай фигуры. Выведи слона на c4.','Rule two: develop pieces. Bring the bishop to c4.','r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3',line=['f1c4'],accept=['f1b5'],hint=T('Слон f1 идёт по диагонали.','The f1 bishop travels along its diagonal.'),ok=T('Фигура включена в игру.','Another piece joins the game.')),
 mv(S,'happy','Правило третье: спрячь короля. Сделай рокировку.','Rule three: hide the king. Castle.','r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 5',line=['e1g1'],hint=T('Король e1 идёт на g1.','The king on e1 goes to g1.'),ok=T('Король в безопасности, ладья в игре.','King safe, rook activated.')),
 quiz(M,'smug','Что нарушает правила дебюта?','What breaks the opening rules?',[T('Много раз ходить одним ферзём','Moving the queen again and again'),T('Выводить коней','Developing knights'),T('Играть e4','Playing e4')],0,T('В дебюте важнее развить все фигуры.','In the opening, develop all your pieces first.')),
])
l2=lesson('scholar',T('Детский мат','Scholar’s mate'),T('Как не попасться на ловушку','How to dodge a classic trap'),'trap',[
 talk(L(S,'surprised','Смотри: ферзь и слон белых целятся в f7. Если не защитить пункт, будет мат в два хода — это «детский мат».','Look: White’s queen and bishop aim at f7. Ignore it and it’s mate in two — “scholar’s mate”.'),
      L(M,'smug','Попробуй не попасться. Я попадаюсь. Редко.','Try not to fall for it. I do. Rarely.'),fen='r1bqkbnr/pppp1ppp/2n5/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR b KQkq - 3 3',hl=['h5','c4','f7']),
 mv(S,'thinking','Ты за чёрных. Защити пункт f7 или нападай на ферзя.','You play Black. Defend f7 or attack the queen.','r1bqkbnr/pppp1ppp/2n5/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR b KQkq - 3 3',line=['g8f6'],accept=['g7g6','d8e7','d8f6','g8h6'],hint=T('Конь g8 может сразу напасть на ферзя.','The g8 knight can attack the queen at once.'),ok=T('Угроза снята — мата не будет.','The threat is parried — no mate.')),
 mv(M,'happy','Теперь ты за белых. Чёрные не защитили f7. Поставь мат!','Now you’re White. Black ignored f7. Deliver mate!','r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4',goal='mate',hint=T('Ферзь может взять пешку на f7 — слон c4 его защитит.','The queen can take f7 — the c4 bishop protects her.'),ok=T('Мат! Королю негде спрятаться.','Checkmate! The king has nowhere to hide.')),
 quiz(S,'neutral','Как не попасться на детский мат?','How do you avoid scholar’s mate?',[T('Защитить f7 или напасть на ферзя','Defend f7 or attack the queen'),T('Не обращать внимания','Ignore it'),T('Сразу сдаться','Resign at once')],0,T('Развивай фигуры и следи за пунктом f7.','Develop your pieces and watch the f7 square.')),
])
l3=lesson('game',T('Партия с Марией','A game with Maria'),T('Сыграй полную партию','Play a full game'),'game',[],kind='game')
unit('u6',T('Первая партия','Your first game'),T('Дебют, ловушки и настоящая игра','Openings, traps and a real game'),[l,l2,l3],chest_after=2)

# ---------------- VALIDATION ----------------
errors=[]
def err(m): errors.append(m)
def check_fen(f,ctx):
    try:
        p=parse(f); ks=[pc for pc in p.board.values() if pc[1]=='k']
        assert len(ks)==2, 'kings'
        other='b' if p.turn=='w' else 'w'
        assert not in_check(p,other), 'side NOT to move is in check'
        if in_check(p): print('  note: side to move in check ->',ctx)
        return p
    except Exception as e: err(f'{ctx}: bad fen {f}: {e}')
def hint_sq_for(p,step):
    ctx=step['p'][0]
    return None
for lid,ls in LESSONS.items():
    for i,st in enumerate(ls['steps']):
        ctx=f"{lid}#{i+1}"
        if st['k']=='talk':
            if st['fen']: check_fen(st['fen'],ctx)
        elif st['k']=='move':
            p=check_fen(st['fen'],ctx)
            if not p: continue
            if st['goal']=='exact':
                cur=p
                for j,u in enumerate(st['line']):
                    m=find(cur,u)
                    if not m: err(f'{ctx}: illegal line move {u}'); break
                    cur=apply(cur,m)
                for a in st['accept']:
                    if not find(p,a): err(f'{ctx}: illegal accept {a}')
                if not st['line']: err(f'{ctx}: empty line')
            else:
                legalm=legal(p)
                if st['goal']=='mate':
                    sols=[name(m[0])+name(m[1]) for m in legalm if is_mate(apply(p,m))]
                elif st['goal']=='capture':
                    sols=[name(m[0])+name(m[1]) for m in legalm if is_capture(p,m)]
                if not sols: err(f'{ctx}: no solutions for goal {st["goal"]}')
                st['_sols']=sols
                print(f'  {ctx} goal={st["goal"]} solutions={sols}')
        elif st['k']=='tap':
            p=check_fen(st['fen'],ctx)
            if not p: continue
            if st['frm']:
                st['expected']=dests(p,st['frm']); print(f'  {ctx} tap from {st["frm"]} -> {len(st["expected"])} squares')
            for e in st['expected']:
                pass
        elif st['k']=='quiz':
            if st['fen']: check_fen(st['fen'],ctx)
            assert 0<=st['correct']<len(st['opts'])
# special semantic claims
p=parse('8/8/8/3k4/8/4K3/8/8 w - - 0 1'); assert find(p,'e3e4') is None, 'king claim'
p=parse('4r1k1/8/8/8/8/8/8/4K2R w K - 0 1'); assert in_check(p) and not any(m[2]=='ck' for m in legal(p)), 'castle in check'
p=parse('7k/5Q2/6K1/8/8/8/8/8 b - - 0 1'); assert is_stalemate(p), 'stalemate'
p=parse('4k3/4n3/8/8/8/8/4R3/4K3 b - - 0 1'); assert find(p,'e7g6') is None, 'pin knight'
p=parse('7k/6Q1/5K2/8/8/8/8/8 b - - 0 1'); assert is_mate(p),'mate demo'
p=parse('2q3k1/4N3/8/8/8/8/8/K7 b - - 0 1'); assert attacked_squares_of(p,'e7').count('c8')==1 and 'g8' in attacked_squares_of(p,'e7') and in_check(p)
p=parse('4k3/8/2n5/1B6/8/8/8/4K3 b - - 0 1'); assert find(p,'c6a5') is None and find(p,'c6e5') is None, 'c6 pinned'
# tap expected sanity
tp=[s for s in LESSONS['bishop']['steps'] if s['k']=='tap'][0]; assert len(tp['expected'])==13, len(tp['expected'])
tp=[s for s in LESSONS['knight']['steps'] if s['k']=='tap'][0]; assert len(tp['expected'])==8
tp=[s for s in LESSONS['king']['steps'] if s['k']=='tap'][0]; assert len(tp['expected'])==8
tp=[s for s in LESSONS['pawn']['steps'] if s['k']=='tap'][0]; assert tp['expected']==['e3','e4']
# knight fork claims
p=parse('r3k3/8/8/1N6/8/8/8/7K w - - 0 1'); n=apply(p,find(p,'b5c7')); assert 'e8' in attacked_squares_of(n,'c7') and 'a8' in attacked_squares_of(n,'c7') and in_check(n)
# the queen/ pawn tactic: b2g7 safe, b2b5 recapturable
p=parse('4k3/6p1/2p5/1n6/8/8/1Q6/4K3 w - - 0 1'); print('  capture#3 caps:',[name(m[0])+name(m[1]) for m in legal(p) if is_capture(p,m)])
if errors:
    print('ERRORS:'); [print(' ',e) for e in errors]; sys.exit(1)
print('ALL OK', sum(len(l['steps']) for l in LESSONS.values()),'steps in',len(LESSONS),'lessons')
