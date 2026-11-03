import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'data/course_model.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/shell/app_shell.dart';
import 'state/app_scope.dart';
import 'widgets/character.dart';

class ShahlingoApp extends StatelessWidget {
  const ShahlingoApp({required this.progress, super.key});

  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: progress,
    builder: (context, _) => MaterialApp(
      title: 'Shahlingo',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: Locale(progress.english ? 'en' : 'ru'),
      builder: (context, child) =>
          AppScope(progress: progress, child: child ?? const SizedBox.shrink()),
      home: const _Gate(),
    ),
  );
}

class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) {
    final progress = context.progress;
    final Widget child;
    if (!progress.loaded) {
      child = const _Splash(key: ValueKey('splash'));
    } else if (!progress.onboardingComplete) {
      child = const OnboardingPage(key: ValueKey('onboarding'));
    } else {
      child = const AppShell(key: ValueKey('shell'));
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: child,
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CharacterBust(who: Who.sergei, emotion: Emotion.happy, height: 150),
          SizedBox(height: 12),
          Text(
            'shahlingo',
            style: TextStyle(
              color: DuoColors.green,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    ),
  );
}
