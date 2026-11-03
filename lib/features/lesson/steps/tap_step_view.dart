import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../chess/board_view.dart';
import '../../../data/course_model.dart';
import '../../../state/app_scope.dart';
import '../../../widgets/common.dart';
import '../lesson_panel.dart';

/// The learner taps squares on the board; the marked set must match exactly.
class TapStepView extends StatefulWidget {
  const TapStepView({
    required this.step,
    required this.onDone,
    required this.onMistake,
    super.key,
  });

  final TapStep step;
  final VoidCallback onDone;
  final VoidCallback onMistake;

  @override
  State<TapStepView> createState() => _TapStepViewState();
}

class _TapStepViewState extends State<TapStepView> {
  late final chess.Chess _game;
  final Set<String> _marked = {};
  PanelPhase _phase = PanelPhase.idle;
  String _message = '';
  late Emotion _emotion;

  TapStep get step => widget.step;

  @override
  void initState() {
    super.initState();
    _game = chess.Chess.fromFEN(step.fen);
    _emotion = step.emotion;
  }

  void _toggle(String square) {
    if (_phase != PanelPhase.idle) return;
    setState(() {
      if (!_marked.remove(square)) _marked.add(square);
    });
  }

  void _check() {
    final expected = step.expected.toSet();
    final missing = expected.difference(_marked).length;
    final extra = _marked.difference(expected).length;
    HapticFeedback.mediumImpact();
    if (missing == 0 && extra == 0) {
      setState(() {
        _phase = PanelPhase.correct;
        _emotion = Emotion.happy;
        _message = context.tr(step.explain);
      });
      return;
    }
    widget.onMistake();
    final parts = <String>[
      if (missing > 0)
        context.t('Не отмечено клеток: $missing.', 'Squares you missed: $missing.'),
      if (extra > 0)
        context.t('Лишних клеток: $extra.', 'Extra squares: $extra.'),
    ];
    setState(() {
      _phase = PanelPhase.wrong;
      _emotion = step.who == Who.maria ? Emotion.smug : Emotion.thinking;
      _message = parts.join(' ');
    });
  }

  void _retry() => setState(() {
    _marked.clear();
    _phase = PanelPhase.idle;
    _emotion = step.emotion;
  });

  @override
  Widget build(BuildContext context) {
    return StepFrame(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CharacterSays(
            who: step.who,
            emotion: _emotion,
            text: context.tr(step.prompt),
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 440),
            child: ChessBoardView(
              game: _game,
              flipped: _game.turn == chess.Color.BLACK,
              marked: _marked,
              onSquareTap: _toggle,
            ),
          ),
        ],
      ),
      bottom: LessonBottomPanel(
        phase: _phase,
        who: step.who,
        message: _message,
        primaryLabel: switch (_phase) {
          PanelPhase.idle => context.t('Проверить', 'Check'),
          PanelPhase.correct => context.t('Продолжить', 'Continue'),
          PanelPhase.wrong => context.t('Понятно', 'Got it'),
        },
        onPrimary: switch (_phase) {
          PanelPhase.idle => _marked.isEmpty ? null : _check,
          PanelPhase.correct => widget.onDone,
          PanelPhase.wrong => _retry,
        },
      ),
    );
  }
}
