import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shahlingo/chess_course.dart';
import 'package:shahlingo/main.dart';

void main() {
  testWidgets('board accepts a legal pawn move', (tester) async {
    final game = chess.Chess();
    String? movedFrom;
    String? movedTo;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 320,
              child: ChessBoard(
                game: game,
                enabled: true,
                onMove: (from, to) {
                  movedFrom = from;
                  movedTo = to;
                },
              ),
            ),
          ),
        ),
      ),
    );

    final boardRect = tester.getRect(find.byType(ChessBoard));
    await tester.tapAt(boardRect.topLeft + const Offset(20, 260));
    await tester.pumpAndSettle();
    await tester.tapAt(boardRect.topLeft + const Offset(20, 180));
    await tester.pumpAndSettle();

    expect(movedFrom, 'a2');
    expect(movedTo, 'a4');
  });

  testWidgets('board does not offer a rook move at the start', (tester) async {
    final game = chess.Chess();
    var moveCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 320,
              child: ChessBoard(
                game: game,
                enabled: true,
                onMove: (_, _) => moveCount++,
              ),
            ),
          ),
        ),
      ),
    );

    final boardRect = tester.getRect(find.byType(ChessBoard));
    await tester.tapAt(boardRect.topLeft + const Offset(20, 300));
    await tester.pumpAndSettle();
    await tester.tapAt(boardRect.topLeft + const Offset(20, 220));
    await tester.pumpAndSettle();

    expect(moveCount, 0);
    expect(game.fen, chess.Chess.DEFAULT_POSITION);
  });

  testWidgets('Sergei teaches and Maria replies with playful banter', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: LessonPage(progress: PlayerProgress())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Сергей · учитель'), findsOneWidget);
    expect(find.text('Мария · соперница'), findsOneWidget);
    expect(find.textContaining('Конь ходит буквой'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('assets/images/maria_neutral.png')),
      findsWidgets,
    );

    final incorrectAnswerButton = find.ancestor(
      of: find.text('Только вперёд'),
      matching: find.byType(OutlinedButton),
    );
    await tester.ensureVisible(incorrectAnswerButton);
    await tester.tap(incorrectAnswerButton);
    await tester.pumpAndSettle();

    expect(find.text('Ой, опять промахнулась… блин, класс!'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('assets/images/maria_sad.png')),
      findsWidgets,
    );

    final correctAnswerButton = find.ancestor(
      of: find.text('Буквой «Г»'),
      matching: find.byType(OutlinedButton),
    );
    await tester.ensureVisible(correctAnswerButton);
    await tester.tap(correctAnswerButton);
    await tester.pumpAndSettle();

    expect(find.text('Верно! Отличный ход.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('assets/images/maria_happy.png')),
      findsWidgets,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Продолжить'));
    await tester.pumpAndSettle();

    expect(find.text('ВОПРОС 2 / 3'), findsOneWidget);
  });

  testWidgets('web dashboard shows a lesson map and companion cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WebDashboardPage(progress: PlayerProgress(), onTab: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ТВОЙ ПУТЬ'), findsOneWidget);
    expect(find.text('Первые ходы'), findsOneWidget);
    expect(find.text('ТВОЯ СЕРИЯ'), findsOneWidget);
    expect(find.text('ТВОЯ ЛИГА'), findsOneWidget);
    expect(find.text('МАРИЯ ГОВОРИТ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('web dashboard lesson map adapts to a phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WebDashboardPage(progress: PlayerProgress(), onTab: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ТВОЙ ПУТЬ'), findsOneWidget);
    expect(find.textContaining('МОДУЛЬ 6'), findsOneWidget);
    expect(find.text('Первые ходы'), findsOneWidget);
    final mapRect = tester.getRect(
      find.byKey(const ValueKey('web-learning-map')),
    );
    final rightLessonNode = tester.getRect(
      find.byIcon(Icons.lock_rounded).first,
    );
    expect(rightLessonNode.right, lessThanOrEqualTo(mapRect.right - 8));
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile uses a player avatar instead of Maria', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: ProfilePage(progress: PlayerProgress()..name = 'Аня')),
    );
    await tester.pumpAndSettle();

    expect(find.text('А'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('assets/images/maria_portrait.png')),
      findsNothing,
    );
    expect(find.textContaining('Рейтинг после 5 партий'), findsOneWidget);
    expect(find.textContaining('800 ELO'), findsNothing);
  });

  testWidgets(
    'play screen places one animated character dialogue above a full-width board',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PlayPage(progress: PlayerProgress())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Партия с Марией'), findsOneWidget);
      final dialogue = find.byKey(const ValueKey('offline-game-dialogue'));
      expect(dialogue, findsOneWidget);
      expect(
        find.byKey(const ValueKey('assets/images/sergei_neutral.png')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('assets/images/maria_neutral.png')),
        findsNothing,
      );
      final board = tester.widget<ChessBoard>(find.byType(ChessBoard).first);
      expect(board.darkTheme, isTrue);
      final dialogueRect = tester.getRect(dialogue);
      final boardRect = tester.getRect(find.byType(ChessBoard).first);
      expect(boardRect.width, greaterThan(350));
      expect(dialogueRect.bottom, lessThan(boardRect.top));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('onboarding asks for a name and a chess level', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final progress = PlayerProgress();
    await tester.pumpWidget(
      MaterialApp(home: OnboardingPage(progress: progress)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Привет! Как тебя зовут?'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Аня');
    await tester.tap(find.widgetWithText(FilledButton, 'Продолжить'));
    await tester.pumpAndSettle();

    expect(find.text('Какой у тебя уровень?'), findsOneWidget);
    await tester.tap(find.text('Знаю, как ходят фигуры'));
    await tester.tap(find.widgetWithText(FilledButton, 'Начать обучение'));
    await tester.pumpAndSettle();

    expect(progress.name, 'Аня');
    expect(progress.chessExperience, 'rules');
    expect(progress.onboardingComplete, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('web chess lesson responds to a wrong move and a retry', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final progress = PlayerProgress()..lessonsCompleted = 1;
    await tester.pumpWidget(
      MaterialApp(home: WebLessonPage(progress: progress, lessonIndex: 1)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await _tapSquare(tester, 'a2');
    await _tapSquare(tester, 'a3');
    expect(find.textContaining('Пока не тот ход'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Попробовать ещё'));
    await tester.pumpAndSettle();
    await _tapSquare(tester, 'e2');
    await _tapSquare(tester, 'e4');

    expect(
      find.textContaining('Отличный ход! Пешка занимает центр.'),
      findsOneWidget,
    );
    expect(progress.lessonsCompleted, 2);
    expect(progress.xp, 25);
    expect(tester.takeException(), isNull);
  });

  test('the course contains six increasingly difficult modules', () {
    expect(chessCourse, hasLength(6));
    expect(allChessLessons, hasLength(24));

    for (final lesson in allChessLessons) {
      final game = chess.Chess.fromFEN(lesson.fen);
      expect(
        game.move({
          'from': lesson.from,
          'to': lesson.to,
          if (lesson.to[1] == '1' || lesson.to[1] == '8') 'promotion': 'q',
        }),
        isTrue,
        reason: '${lesson.title} should have a legal solution.',
      );
    }

    expect(chessCourse.first.lessons.first.difficulty, 1);
    expect(chessCourse.last.lessons.last.difficulty, 3);
  });

  test('checkmate lessons end the game', () {
    for (final index in [12, 13, 23]) {
      final lesson = allChessLessons[index];
      final game = chess.Chess.fromFEN(lesson.fen);

      expect(
        game.move({
          'from': lesson.from,
          'to': lesson.to,
          if (lesson.to[1] == '1' || lesson.to[1] == '8') 'promotion': 'q',
        }),
        isTrue,
      );
      expect(game.game_over, isTrue, reason: lesson.title);
    }
  });

  test('the queen puzzle has a legal mate-in-one solution', () {
    final game = chess.Chess.fromFEN('7k/8/5KQ1/8/8/8/8/8 w - - 0 1');

    expect(game.move({'from': 'g6', 'to': 'g7'}), isTrue);
    expect(game.generate_moves(), isEmpty);
  });

  test(
    'rating stays provisional until five online games are complete',
    () async {
      SharedPreferences.setMockInitialValues({});
      final progress = PlayerProgress();

      expect(progress.ratingEstablished, isFalse);
      expect(progress.ratingSummary(false), 'Рейтинг после 5 партий · 0/5');

      for (var index = 0; index < 4; index++) {
        progress.finishOnlineRound(won: null, opponentElo: 0);
      }
      expect(progress.ratingEstablished, isFalse);

      progress.finishOnlineRound(won: null, opponentElo: 0);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(progress.ratingEstablished, isTrue);
      expect(progress.ratingSummary(false), '0 ELO · Новичок');
    },
  );
}

Future<void> _tapSquare(WidgetTester tester, String square) async {
  final rect = tester.getRect(find.byType(ChessBoard));
  final column = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
  final row = 8 - int.parse(square[1]);
  await tester.tapAt(
    rect.topLeft +
        Offset((column + 0.5) * rect.width / 8, (row + 0.5) * rect.height / 8),
  );
  await tester.pumpAndSettle();
}
