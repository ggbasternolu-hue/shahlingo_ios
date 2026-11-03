import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/banter.dart';
import '../../data/course_model.dart';
import '../../state/app_scope.dart';
import '../../widgets/character.dart';
import '../../widgets/duo_button.dart';
import '../../widgets/pop_in.dart';

/// Close button + a pill with material balance and the game clock.
class GameTopBar extends StatelessWidget {
  const GameTopBar({
    required this.onClose,
    required this.balance,
    required this.seconds,
    super.key,
  });

  final VoidCallback onClose;
  final int balance;
  final int seconds;

  @override
  Widget build(BuildContext context) {
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    final color = balance > 0
        ? DuoColors.green
        : (balance < 0 ? DuoColors.red : DuoColors.muted);
    return Row(
      children: [
        IconButton(
          tooltip: context.t('Закрыть', 'Close'),
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded, color: DuoColors.muted, size: 30),
        ),
        Expanded(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: DuoColors.border, width: 2),
              ),
              child: IntrinsicHeight(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 14),
                    Icon(
                      balance >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      color: color,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        context.t('${balance.abs()} очк.', '${balance.abs()} pts'),
                        key: ValueKey(balance),
                        style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const VerticalDivider(width: 2, thickness: 2, color: DuoColors.border),
                    const SizedBox(width: 14),
                    const Icon(Icons.timer_outlined, color: DuoColors.muted, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '$mm:$ss',
                      style: const TextStyle(
                        color: DuoColors.muted,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

/// End-of-game panel: both characters react, XP is shown, buttons follow.
class GameResultPanel extends StatelessWidget {
  const GameResultPanel({
    required this.event,
    required this.title,
    required this.xp,
    required this.onRematch,
    required this.onExit,
    this.rematchLabel,
    super.key,
  });

  final GameEvent event;
  final String title;
  final int xp;
  final VoidCallback? onRematch;
  final VoidCallback onExit;
  final String? rematchLabel;

  @override
  Widget build(BuildContext context) {
    final english = context.isEnglish;
    final color = switch (event) {
      GameEvent.youWin => DuoColors.green,
      GameEvent.draw => DuoColors.blue,
      _ => DuoColors.red,
    };
    final lines = endingLines(event);
    return PopIn(
      curve: Curves.easeOutBack,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DuoColors.panel,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: DuoText.h2.copyWith(color: color),
                  ),
                ),
                if (xp > 0)
                  Text(
                    '+$xp XP',
                    style: const TextStyle(
                      color: DuoColors.yellow,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    CharacterAvatar(who: line.who, emotion: line.emotion, size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${line.who.displayName(english)}: ',
                              style: TextStyle(
                                color: line.who.color,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(text: line.text.of(english)),
                          ],
                        ),
                        style: DuoText.body.copyWith(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: DuoButton(
                    label: context.t('Выйти', 'Exit'),
                    kind: DuoButtonKind.outline,
                    onPressed: onExit,
                  ),
                ),
                if (onRematch != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: DuoButton(
                      label: rematchLabel ?? context.t('Реванш', 'Rematch'),
                      onPressed: onRematch,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bubble + bust for the speaking character during a game.
class GameSpeaker extends StatelessWidget {
  const GameSpeaker({required this.reaction, super.key});

  final Reaction reaction;

  @override
  Widget build(BuildContext context) =>
      _Speaker(who: reaction.who, emotion: reaction.emotion, text: reaction.text.of(context.isEnglish));
}

class _Speaker extends StatelessWidget {
  const _Speaker({required this.who, required this.emotion, required this.text});

  final Who who;
  final Emotion emotion;
  final String text;

  @override
  Widget build(BuildContext context) {
    // Imported lazily to keep this file's imports small.
    return _SpeakerRow(who: who, emotion: emotion, text: text);
  }
}

class _SpeakerRow extends StatelessWidget {
  const _SpeakerRow({required this.who, required this.emotion, required this.text});

  final Who who;
  final Emotion emotion;
  final String text;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 112,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CharacterBust(who: who, emotion: emotion, height: 104),
        const SizedBox(width: 2),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _Bubble(who: who, text: text),
          ),
        ),
      ],
    ),
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.who, required this.text});

  final Who who;
  final String text;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 260),
    switchInCurve: Curves.easeOutBack,
    transitionBuilder: (child, animation) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1).animate(animation),
        alignment: Alignment.centerLeft,
        child: child,
      ),
    ),
    child: Container(
      key: ValueKey(text),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 14, 10),
      decoration: BoxDecoration(
        color: DuoColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DuoColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            who.displayName(context.isEnglish),
            style: TextStyle(color: who.color, fontSize: 12, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(text, style: DuoText.body.copyWith(fontSize: 15)),
        ],
      ),
    ),
  );
}
