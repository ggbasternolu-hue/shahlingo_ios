import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';

import '../../../chess/board_view.dart';
import '../../../core/theme.dart';
import '../../../data/course_model.dart';
import '../../../state/app_scope.dart';
import '../../../widgets/character.dart';
import '../../../widgets/speech_bubble.dart';
import '../../../widgets/typewriter_text.dart';
import '../lesson_panel.dart';

/// A dialogue between the characters. Lines appear one by one.
class TalkStepView extends StatefulWidget {
  const TalkStepView({required this.step, required this.onDone, super.key});

  final TalkStep step;
  final VoidCallback onDone;

  @override
  State<TalkStepView> createState() => _TalkStepViewState();
}

class _TalkStepViewState extends State<TalkStepView> {
  final _scroll = ScrollController();
  int _shown = 1;
  chess.Chess? _game;

  @override
  void initState() {
    super.initState();
    final fen = widget.step.fen;
    if (fen != null) _game = chess.Chess.fromFEN(fen);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _advance() {
    if (_shown < widget.step.lines.length) {
      setState(() => _shown++);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutCubic,
          );
        }
      });
    } else {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.step.lines;
    final last = lines[_shown - 1];
    final isLast = _shown >= lines.length;
    final board = _game;
    return StepFrame(
      controller: _scroll,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (board != null) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 340),
              child: ChessBoardView(
                game: board,
                enabled: false,
                flipped: board.turn == chess.Color.BLACK,
                hints: widget.step.highlight.toSet(),
              ),
            ),
            const SizedBox(height: 18),
          ],
          for (var i = 0; i < _shown; i++)
            _ChatLine(key: ValueKey(i), line: lines[i], typing: i == _shown - 1),
        ],
      ),
      bottom: LessonBottomPanel(
        phase: PanelPhase.idle,
        who: last.who,
        primaryLabel: isLast
            ? context.t('Продолжить', 'Continue')
            : context.t('Дальше', 'Next'),
        onPrimary: _advance,
      ),
    );
  }
}

class _ChatLine extends StatelessWidget {
  const _ChatLine({required this.line, required this.typing, super.key});

  final Line line;
  final bool typing;

  @override
  Widget build(BuildContext context) {
    final left = line.who == Who.sergei;
    final text = context.tr(line.text);
    final bubble = Expanded(
      child: Column(
        crossAxisAlignment: left ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 6, right: 6),
            child: Text(
              line.who.displayName(context.isEnglish),
              style: TextStyle(
                color: line.who.color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SpeechBubble(
            tailOnLeft: left,
            child: SizedBox(
              width: double.infinity,
              child: typing
                  ? TypewriterText(text)
                  : Text(
                      text,
                      style: DuoText.body.copyWith(
                        color: DuoColors.text.withValues(alpha: 0.85),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
    final avatar = Padding(
      padding: const EdgeInsets.only(top: 18),
      child: CharacterAvatar(who: line.who, emotion: line.emotion, size: 58),
    );
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 18), child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: left
              ? [avatar, const SizedBox(width: 4), bubble]
              : [bubble, const SizedBox(width: 4), avatar],
        ),
      ),
    );
  }
}
