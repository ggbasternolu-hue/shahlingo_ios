import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shahlingo/chess/board_view.dart';
import 'package:shahlingo/features/play/game_screen.dart';
import 'package:shahlingo/services/chess_ai.dart';
import 'package:shahlingo/state/app_scope.dart';

void main() {
  test('Maria returns a legal reply to the first player move', () async {
    final game = chess.Chess();
    expect(game.move({'from': 'e2', 'to': 'e4'}), isTrue);
    expect(game.game_over, isFalse);

    final reply = await pickAiMove(game.fen, 2);

    expect(reply, isNotNull);
    final move = reply!;
    expect(
      game.move({
        'from': move.substring(0, 2),
        'to': move.substring(2, 4),
        'promotion': 'q',
      }),
      isTrue,
    );
    expect(game.game_over, isFalse);
  });

  testWidgets('a normal first move does not immediately end in a draw', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final progress = PlayerProgress();
    await tester.pumpWidget(
      AppScope(
        progress: progress,
        child: const MaterialApp(home: GameScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await _tapSquare(tester, 'e2');
    await _tapSquare(tester, 'e4');
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Ничья'), findsNothing);
    expect(find.text('Мария думает…'), findsNothing);
    expect(find.text('Твой ход'), findsOneWidget);
  });
}

Future<void> _tapSquare(WidgetTester tester, String square) async {
  final rect = tester.getRect(find.byType(ChessBoardView));
  final column = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
  final row = 8 - int.parse(square[1]);
  await tester.tapAt(
    rect.topLeft +
        Offset((column + 0.5) * rect.width / 8, (row + 0.5) * rect.height / 8),
  );
  await tester.pump(const Duration(milliseconds: 100));
}
