import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/course_model.dart';
import '../../state/app_scope.dart';
import '../../widgets/common.dart';
import '../../widgets/duo_button.dart';
import '../../widgets/progress_bar.dart';

/// Three friendly steps: meet the characters, choose a name, pick experience.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _name = TextEditingController();
  int _step = 0;
  String _experience = 'new';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _nameOk => _name.text.trim().isNotEmpty && _name.text.trim().length <= 20;

  Future<void> _next() async {
    if (_step < 2) {
      setState(() => _step++);
      return;
    }
    setState(() => _saving = true);
    await AppScope.read(context).finishOnboarding(
      playerName: _name.text,
      experience: _experience,
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.progress;
    final (who, emotion, text) = switch (_step) {
      0 => (
        Who.sergei,
        Emotion.happy,
        context.t(
          'Привет! Я Сергей, и я научу тебя играть в шахматы — шаг за шагом.',
          'Hi! I’m Sergei, and I’ll teach you chess — step by step.',
        ),
      ),
      1 => (
        Who.maria,
        Emotion.smug,
        context.t(
          'А я Мария. Как тебя зовут? Надо же знать, кого я буду обыгрывать.',
          'I’m Maria. What’s your name? I should know who I’m about to beat.',
        ),
      ),
      _ => (
        Who.sergei,
        Emotion.thinking,
        context.t(
          'Расскажи, как хорошо ты знаешь шахматы. Я подберу темп.',
          'Tell me how well you know chess. I’ll pick the pace.',
        ),
      ),
    };
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 12, 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _step == 0 ? null : () => setState(() => _step--),
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: _step == 0 ? Colors.transparent : DuoColors.muted,
                        ),
                      ),
                      Expanded(child: DuoProgressBar(value: (_step + 1) / 3)),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: progress.toggleLanguage,
                        child: Text(
                          progress.english ? 'RU' : 'EN',
                          style: const TextStyle(
                            color: DuoColors.blue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CharacterSays(who: who, emotion: emotion, text: text, height: 130),
                        const SizedBox(height: 26),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: KeyedSubtree(
                            key: ValueKey(_step),
                            child: _body(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                  child: DuoButton(
                    label: _step == 2
                        ? context.t('Начать обучение', 'Start learning')
                        : context.t('Продолжить', 'Continue'),
                    onPressed: _saving || (_step == 1 && !_nameOk) ? null : _next,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_step == 0) {
      return DuoPanel(
        child: Column(
          children: [
            for (final (icon, ru, en) in const [
              (Icons.school_rounded, 'Короткие уроки с заданиями на доске', 'Short lessons with puzzles on the board'),
              (Icons.sports_esports_rounded, 'Партии с Марией и онлайн-соперниками', 'Games against Maria and online players'),
              (Icons.local_fire_department_rounded, 'Серии дней и награды за успехи', 'Daily streaks and rewards'),
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(icon, color: DuoColors.green, size: 28),
                    const SizedBox(width: 14),
                    Expanded(child: Text(context.t(ru, en), style: DuoText.body)),
                  ],
                ),
              ),
          ],
        ),
      );
    }
    if (_step == 1) {
      return TextField(
        controller: _name,
        autofocus: true,
        maxLength: 20,
        textCapitalization: TextCapitalization.words,
        style: DuoText.body.copyWith(fontSize: 18),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) {
          if (_nameOk) _next();
        },
        decoration: InputDecoration(
          hintText: context.t('Твоё имя', 'Your name'),
          hintStyle: DuoText.small.copyWith(fontSize: 18),
          filled: true,
          fillColor: DuoColors.panel,
          contentPadding: const EdgeInsets.all(18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: DuoColors.border, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: DuoColors.border, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: DuoColors.blue, width: 2),
          ),
        ),
      );
    }
    final options = [
      ('new', context.t('Я только начинаю', 'I’m just starting'), Icons.eco_rounded),
      ('some', context.t('Знаю, как ходят фигуры', 'I know how pieces move'), Icons.extension_rounded),
      ('club', context.t('Играю регулярно', 'I play regularly'), Icons.emoji_events_rounded),
    ];
    return Column(
      children: [
        for (final (key, label, icon) in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => setState(() => _experience = key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: _experience == key ? const Color(0x331CB0F6) : DuoColors.bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _experience == key ? DuoColors.blue : DuoColors.border,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: _experience == key ? DuoColors.blue : DuoColors.muted,
                      size: 26,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        label,
                        style: DuoText.body.copyWith(
                          color: _experience == key ? DuoColors.blue : DuoColors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
