import 'dart:math';

import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../chess/board_view.dart';
import '../../../core/theme.dart';
import '../../../data/course_model.dart';
import '../../../state/app_scope.dart';
import '../../../widgets/common.dart';
import '../lesson_panel.dart';

/// Multiple choice question, optionally with a position to look at.
class QuizStepView extends StatefulWidget {
  const QuizStepView({
    required this.step,
    required this.onDone,
    required this.onMistake,
    super.key,
  });

  final QuizStep step;
  final VoidCallback onDone;
  final VoidCallback onMistake;

  @override
  State<QuizStepView> createState() => _QuizStepViewState();
}

class _QuizStepViewState extends State<QuizStepView> {
  late final List<int> _order;
  chess.Chess? _game;
  int? _selected;
  PanelPhase _phase = PanelPhase.idle;
  late Emotion _emotion;

  QuizStep get step => widget.step;

  @override
  void initState() {
    super.initState();
    _order = List.generate(step.options.length, (i) => i)..shuffle(Random());
    _emotion = step.emotion;
    final fen = step.fen;
    if (fen != null) _game = chess.Chess.fromFEN(fen);
  }

  void _check() {
    final selected = _selected;
    if (selected == null) return;
    final right = selected == step.correct;
    HapticFeedback.mediumImpact();
    if (!right) widget.onMistake();
    setState(() {
      _phase = right ? PanelPhase.correct : PanelPhase.wrong;
      _emotion = right
          ? Emotion.happy
          : (step.who == Who.maria ? Emotion.smug : Emotion.thinking);
    });
  }

  void _retry() => setState(() {
    _selected = null;
    _phase = PanelPhase.idle;
    _emotion = step.emotion;
  });

  @override
  Widget build(BuildContext context) {
    final board = _game;
    final checked = _phase != PanelPhase.idle;
    final wrongText = context.t('Правильный ответ: ', 'Correct answer: ') +
        context.tr(step.options[step.correct]);
    final explain = context.tr(step.explain);
    return StepFrame(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CharacterSays(
            who: step.who,
            emotion: _emotion,
            text: context.tr(step.question),
          ),
          if (board != null) ...[
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ChessBoardView(
                game: board,
                enabled: false,
                flipped: board.turn == chess.Color.BLACK,
                hints: step.highlight.toSet(),
              ),
            ),
          ],
          const SizedBox(height: 18),
          for (final index in _order)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OptionTile(
                label: context.tr(step.options[index]),
                selected: _selected == index,
                state: !checked || _selected != index
                    ? _TileState.none
                    : (index == step.correct ? _TileState.right : _TileState.wrong),
                onTap: checked ? null : () => setState(() => _selected = index),
              ),
            ),
        ],
      ),
      bottom: LessonBottomPanel(
        phase: _phase,
        who: step.who,
        message: _phase == PanelPhase.wrong ? '$wrongText. $explain' : explain,
        primaryLabel: switch (_phase) {
          PanelPhase.idle => context.t('Проверить', 'Check'),
          PanelPhase.correct => context.t('Продолжить', 'Continue'),
          PanelPhase.wrong => context.t('Понятно', 'Got it'),
        },
        onPrimary: switch (_phase) {
          PanelPhase.idle => _selected == null ? null : _check,
          PanelPhase.correct => widget.onDone,
          PanelPhase.wrong => _retry,
        },
      ),
    );
  }
}

enum _TileState { none, right, wrong }

class _OptionTile extends StatefulWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.state,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final _TileState state;
  final VoidCallback? onTap;

  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final (border, fill, text) = switch (widget.state) {
      _TileState.right => (
        DuoColors.green,
        const Color(0x3358CC02),
        DuoColors.greenSoft,
      ),
      _TileState.wrong => (
        DuoColors.red,
        const Color(0x33FF4B4B),
        DuoColors.red,
      ),
      _TileState.none when widget.selected => (
        DuoColors.blue,
        const Color(0x331CB0F6),
        DuoColors.blue,
      ),
      _ => (DuoColors.border, DuoColors.bg, DuoColors.text),
    };
    final depth = _down ? 0.0 : 4.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _down = false),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _down = false),
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              widget.onTap!();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        margin: EdgeInsets.only(top: 4 - depth, bottom: depth),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: border, width: 2),
            right: BorderSide(color: border, width: 2),
            top: BorderSide(color: border, width: 2),
            bottom: BorderSide(color: border, width: 2 + depth),
          ),
        ),
        child: Text(
          widget.label,
          style: DuoText.body.copyWith(color: text, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
