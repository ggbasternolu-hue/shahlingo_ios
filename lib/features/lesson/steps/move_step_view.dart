import 'dart:async';

import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';

import '../../../chess/board_utils.dart';
import '../../../chess/board_view.dart';
import '../../../data/course_model.dart';
import '../../../state/app_scope.dart';
import '../../../widgets/common.dart';
import '../../../widgets/duo_button.dart';
import '../lesson_panel.dart';

/// The learner plays a move (or a short sequence) on the board.
class MoveStepView extends StatefulWidget {
  const MoveStepView({
    required this.step,
    required this.onDone,
    required this.onMistake,
    super.key,
  });

  final MoveStep step;
  final VoidCallback onDone;
  final VoidCallback onMistake;

  @override
  State<MoveStepView> createState() => _MoveStepViewState();
}

class _MoveStepViewState extends State<MoveStepView> {
  late chess.Chess _game;
  late String _checkpoint;
  late final bool _flipped;
  late Emotion _emotion;
  String? _lastMove;
  String? _lastBefore;
  int _ply = 0;
  int _hintLevel = 0;
  bool _busy = false;
  PanelPhase _phase = PanelPhase.idle;
  String _message = '';

  MoveStep get step => widget.step;

  @override
  void initState() {
    super.initState();
    _game = chess.Chess.fromFEN(step.fen);
    _checkpoint = step.fen;
    _flipped = _game.turn == chess.Color.BLACK;
    _emotion = step.emotion;
  }

  bool _expected(String uci) {
    if (step.goal != MoveGoal.exact) return false;
    if (_ply == 0) return uci == step.line[0] || step.accept.contains(uci);
    return uci == step.line[_ply];
  }

  void _onMove(String from, String to) {
    if (_busy || _phase != PanelPhase.idle) return;
    final uci = '$from$to';
    final capture = isCaptureMove(_game, from, to);
    final before = _lastMove;
    final expectedExact = _expected(uci);
    if (!playMove(_game, from, to)) return;

    final bool ok = switch (step.goal) {
      MoveGoal.exact => expectedExact,
      MoveGoal.mate => _game.in_checkmate,
      MoveGoal.capture => capture,
      MoveGoal.check => _game.in_check,
    };

    setState(() {
      _lastBefore = before;
      _lastMove = uci;
      _hintLevel = 0;
    });

    if (!ok) {
      widget.onMistake();
      setState(() {
        _phase = PanelPhase.wrong;
        _emotion = step.who == Who.maria ? Emotion.smug : Emotion.thinking;
        _message = step.wrong != null ? context.tr(step.wrong!) : _genericWrong();
      });
      return;
    }

    if (step.goal == MoveGoal.exact && _ply + 1 < step.line.length) {
      final replyIndex = _ply + 1;
      _busy = true;
      setState(() {
        _emotion = Emotion.happy;
        _ply = replyIndex + 1;
      });
      Timer(const Duration(milliseconds: 550), () {
        if (!mounted) return;
        final reply = step.line[replyIndex];
        playUci(_game, reply);
        setState(() {
          _lastMove = reply;
          _checkpoint = _game.fen;
          _busy = false;
          _emotion = step.emotion;
          if (_ply >= step.line.length) _succeed();
        });
      });
      return;
    }
    setState(_succeed);
  }

  void _succeed() {
    _phase = PanelPhase.correct;
    _emotion = Emotion.happy;
    _message = context.tr(step.success);
  }

  String _genericWrong() => switch (step.goal) {
    MoveGoal.exact => context.t(
      'Это не тот ход. Попробуй ещё раз — можно взять подсказку.',
      'That’s not the move we need. Try again — a hint can help.',
    ),
    MoveGoal.mate => context.t(
      'Это ещё не мат. Проверь, куда может уйти король.',
      'That isn’t mate yet. Check where the king can run.',
    ),
    MoveGoal.capture => context.t(
      'Здесь нужно взять фигуру соперника.',
      'Here you need to capture an enemy piece.',
    ),
    MoveGoal.check => context.t('Нужен шах.', 'You need to give check.'),
  };

  void _retry() {
    setState(() {
      _game = chess.Chess.fromFEN(_checkpoint);
      _lastMove = _lastBefore;
      _phase = PanelPhase.idle;
      _emotion = step.emotion;
    });
  }

  Set<String> get _hintSquares {
    if (_hintLevel == 0) return const {};
    if (_hintLevel == 1) return {step.hintSquares.first};
    return step.hintSquares.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final text = _hintLevel > 0 && _phase == PanelPhase.idle
        ? context.tr(step.hint)
        : context.tr(step.prompt);
    final idle = _phase == PanelPhase.idle;
    return StepFrame(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CharacterSays(who: step.who, emotion: _emotion, text: text),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 440),
            child: ChessBoardView(
              game: _game,
              flipped: _flipped,
              enabled: idle && !_busy,
              lastMove: _lastMove,
              hints: _hintSquares,
              onMove: _onMove,
            ),
          ),
        ],
      ),
      bottom: LessonBottomPanel(
        phase: _phase,
        who: step.who,
        message: _message,
        primaryLabel: switch (_phase) {
          PanelPhase.idle => null,
          PanelPhase.correct => context.t('Продолжить', 'Continue'),
          PanelPhase.wrong => context.t('Понятно', 'Got it'),
        },
        onPrimary: _phase == PanelPhase.correct ? widget.onDone : _retry,
        secondary: idle
            ? DuoButton(
                label: context.t('Подсказка', 'Hint'),
                kind: DuoButtonKind.outline,
                icon: Icons.lightbulb_outline_rounded,
                onPressed: _busy || _hintLevel >= 2
                    ? null
                    : () => setState(() => _hintLevel++),
              )
            : null,
      ),
    );
  }
}
