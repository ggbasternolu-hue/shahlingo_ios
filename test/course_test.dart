import 'package:chess/chess.dart' as chess;
import 'package:flutter_test/flutter_test.dart';
import 'package:shahlingo/chess/board_utils.dart';
import 'package:shahlingo/data/course.dart';

/// Re-checks every lesson position with the app's own chess library, so a bad
/// edit to the course is caught by `flutter test`.
void main() {
  test('course has unique lesson ids and a game lesson at the end', () {
    final ids = allLessons.map((l) => l.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(allLessons.last.kind, LessonKind.game);
  });

  for (final lesson in allLessons) {
    test('lesson ${lesson.id} is playable', () {
      for (final step in lesson.steps) {
        switch (step) {
          case TalkStep():
            if (step.fen != null) chess.Chess.fromFEN(step.fen!);
          case QuizStep():
            expect(step.correct, inInclusiveRange(0, step.options.length - 1));
            if (step.fen != null) chess.Chess.fromFEN(step.fen!);
          case TapStep():
            chess.Chess.fromFEN(step.fen);
            expect(step.expected, isNotEmpty);
          case MoveStep():
            final game = chess.Chess.fromFEN(step.fen);
            if (step.goal == MoveGoal.exact) {
              for (final accepted in step.accept) {
                final copy = chess.Chess.fromFEN(step.fen);
                expect(playUci(copy, accepted), isTrue, reason: accepted);
              }
              for (final uci in step.line) {
                expect(playUci(game, uci), isTrue, reason: '${step.fen} $uci');
              }
            } else {
              var found = false;
              for (final move in game.generate_moves()) {
                final copy = chess.Chess.fromFEN(step.fen);
                final from = move.fromAlgebraic;
                final to = move.toAlgebraic;
                final capture = isCaptureMove(copy, from, to);
                playMove(copy, from, to);
                if (step.goal == MoveGoal.mate && copy.in_checkmate) found = true;
                if (step.goal == MoveGoal.capture && capture) found = true;
                if (step.goal == MoveGoal.check && copy.in_check) found = true;
              }
              expect(found, isTrue, reason: step.fen);
            }
        }
      }
    });
  }
}
