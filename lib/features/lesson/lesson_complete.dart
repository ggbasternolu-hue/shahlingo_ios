import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/course_model.dart';
import '../../state/app_scope.dart';
import '../../widgets/character.dart';
import '../../widgets/confetti.dart';
import '../../widgets/duo_button.dart';
import '../../widgets/pop_in.dart';

class LessonComplete extends StatelessWidget {
  const LessonComplete({
    required this.lesson,
    required this.stars,
    required this.xp,
    required this.mistakes,
    required this.onContinue,
    super.key,
  });

  final Lesson lesson;
  final int stars;
  final int xp;
  final int mistakes;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final gems = 3 + stars;
    final lines = switch (stars) {
      3 => (
        context.t('Без единой ошибки. Впечатляет.', 'Not a single mistake. Impressive.'),
        context.t('Ладно, признаю: сильно.', 'Fine, I admit it: strong.'),
      ),
      2 => (
        context.t('Хорошая работа. Ещё чуть-чуть — и идеально.', 'Good work. Almost perfect.'),
        context.t('Неплохо. Для начала.', 'Not bad. For a start.'),
      ),
      _ => (
        context.t('Главное — ты дошёл до конца.', 'What matters is that you finished.'),
        context.t('Повтори урок — будет легче.', 'Replay the lesson — it’ll get easier.'),
      ),
    };
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const PopIn(
                            child: CharacterBust(
                              who: Who.sergei,
                              emotion: Emotion.happy,
                              height: 130,
                            ),
                          ),
                          const SizedBox(width: 8),
                          PopIn(
                            delay: const Duration(milliseconds: 160),
                            child: CharacterBust(
                              who: Who.maria,
                              emotion: stars >= 2 ? Emotion.happy : Emotion.smug,
                              height: 130,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        context.t('Урок пройден!', 'Lesson complete!'),
                        style: DuoText.h1.copyWith(color: DuoColors.yellow),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr(lesson.title),
                        style: DuoText.small,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < 3; i++)
                            PopIn(
                              delay: Duration(milliseconds: 350 + i * 220),
                              child: Padding(
                                padding: EdgeInsets.only(top: i == 1 ? 0 : 10, left: 4, right: 4),
                                child: Icon(
                                  Icons.star_rounded,
                                  size: i == 1 ? 76 : 60,
                                  color: i < stars ? DuoColors.yellow : DuoColors.border,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              color: DuoColors.yellow,
                              title: context.t('Опыт', 'XP'),
                              icon: Icons.bolt_rounded,
                              value: '+$xp',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              color: DuoColors.blue,
                              title: context.t('Самоцветы', 'Gems'),
                              icon: Icons.diamond_rounded,
                              value: '+$gems',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              color: mistakes == 0 ? DuoColors.green : DuoColors.orange,
                              title: context.t('Ошибки', 'Mistakes'),
                              icon: mistakes == 0 ? Icons.check_circle_rounded : Icons.error_rounded,
                              value: '$mistakes',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _Quote(who: Who.sergei, text: lines.$1),
                      const SizedBox(height: 8),
                      _Quote(who: Who.maria, text: lines.$2),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: DuoButton(
                    label: context.t('Продолжить', 'Continue'),
                    onPressed: onContinue,
                  ),
                ),
              ),
            ),
          ],
        ),
        const Positioned.fill(child: Confetti()),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.color,
    required this.title,
    required this.icon,
    required this.value,
  });

  final Color color;
  final String title;
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
    ),
    padding: const EdgeInsets.only(top: 2, left: 2, right: 2, bottom: 2),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: DuoColors.bg,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: DuoColors.bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Quote extends StatelessWidget {
  const _Quote({required this.who, required this.text});

  final Who who;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      CharacterAvatar(who: who, emotion: Emotion.happy, size: 40),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          '${who.displayName(context.isEnglish)}: $text',
          style: DuoText.body.copyWith(fontSize: 15),
        ),
      ),
    ],
  );
}
