import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/course_model.dart';
import '../../state/app_scope.dart';
import '../../widgets/character.dart';
import '../../widgets/duo_button.dart';

enum PanelPhase { idle, correct, wrong }

/// Scrollable step content + the feedback panel pinned to the bottom.
class StepFrame extends StatelessWidget {
  const StepFrame({
    required this.content,
    required this.bottom,
    this.controller,
    super.key,
  });

  final Widget content;
  final Widget bottom;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 24).clamp(0.0, double.infinity),
              ),
              child: content,
            ),
          ),
        ),
      ),
      bottom,
    ],
  );
}

/// Bottom bar: neutral while answering, green when right, red when wrong.
class LessonBottomPanel extends StatelessWidget {
  const LessonBottomPanel({
    required this.phase,
    required this.who,
    this.message,
    this.primaryLabel,
    this.onPrimary,
    this.secondary,
    super.key,
  });

  final PanelPhase phase;
  final Who who;
  final String? message;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final Widget? secondary;

  static const _rightTitles = [
    ('Отлично!', 'Great!'),
    ('Верно!', 'Correct!'),
    ('Так держать!', 'Keep it up!'),
    ('Блестяще!', 'Brilliant!'),
  ];
  static const _wrongTitles = [
    ('Не совсем', 'Not quite'),
    ('Почти!', 'Almost!'),
    ('Подумай ещё', 'Think again'),
  ];

  @override
  Widget build(BuildContext context) {
    final english = context.isEnglish;
    final correct = phase == PanelPhase.correct;
    final wrong = phase == PanelPhase.wrong;
    final background = correct
        ? DuoColors.correctBg
        : wrong
        ? DuoColors.wrongBg
        : DuoColors.bg;
    final accent = correct ? DuoColors.green : DuoColors.red;
    final seed = (message ?? '').length;
    final title = correct
        ? _rightTitles[seed % _rightTitles.length]
        : _wrongTitles[seed % _wrongTitles.length];
    final emotion = correct
        ? Emotion.happy
        : (who == Who.maria ? Emotion.smug : Emotion.thinking);
    final kind = wrong ? DuoButtonKind.red : DuoButtonKind.green;

    Widget actions() {
      if (secondary != null && primaryLabel != null) {
        return Row(
          children: [
            Expanded(child: secondary!),
            const SizedBox(width: 12),
            Expanded(
              child: DuoButton(label: primaryLabel!, onPressed: onPrimary, kind: kind),
            ),
          ],
        );
      }
      if (primaryLabel != null) {
        return DuoButton(label: primaryLabel!, onPressed: onPrimary, kind: kind);
      }
      return secondary ?? const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: background,
        border: Border(
          top: BorderSide(
            color: phase == PanelPhase.idle
                ? DuoColors.border
                : accent.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (phase != PanelPhase.idle) ...[
                      _FeedbackRow(
                        who: who,
                        emotion: emotion,
                        color: accent,
                        title: english ? title.$2 : title.$1,
                        message: message ?? '',
                      ),
                      const SizedBox(height: 14),
                    ],
                    actions(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackRow extends StatelessWidget {
  const _FeedbackRow({
    required this.who,
    required this.emotion,
    required this.color,
    required this.title,
    required this.message,
  });

  final Who who;
  final Emotion emotion;
  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey('$title$message'),
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 380),
    curve: Curves.easeOutBack,
    builder: (context, t, child) => Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.translate(offset: Offset(0, (1 - t) * 14), child: child),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CharacterAvatar(who: who, emotion: emotion, size: 56),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                message,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
