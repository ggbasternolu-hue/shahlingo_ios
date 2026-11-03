import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/course.dart';
import '../../state/app_scope.dart';
import '../../widgets/duo_button.dart';
import '../../widgets/progress_bar.dart';
import 'lesson_complete.dart';
import 'steps/move_step_view.dart';
import 'steps/quiz_step_view.dart';
import 'steps/talk_step_view.dart';
import 'steps/tap_step_view.dart';

/// Runs a lesson step by step with a progress bar on top.
class LessonPage extends StatefulWidget {
  const LessonPage({required this.lesson, super.key});

  final Lesson lesson;

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  int _index = 0;
  int _mistakes = 0;
  bool _finished = false;
  int _xp = 0;
  int _stars = 3;

  List<LessonStep> get _steps => widget.lesson.steps;

  void _mistake() => _mistakes++;

  Future<void> _next() async {
    if (_index + 1 < _steps.length) {
      setState(() => _index++);
      return;
    }
    final stars = _mistakes == 0 ? 3 : (_mistakes <= 2 ? 2 : 1);
    final progress = AppScope.read(context);
    final gained = await progress.completeLesson(
      widget.lesson.id,
      earnedStars: stars,
    );
    if (!mounted) return;
    setState(() {
      _stars = stars;
      _xp = gained;
      _finished = true;
    });
  }

  Future<void> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t('Выйти из урока?', 'Leave the lesson?'), style: DuoText.h2),
        content: Text(
          context.t(
            'Прогресс этого урока будет потерян.',
            'Your progress in this lesson will be lost.',
          ),
          style: DuoText.body,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actionsAlignment: MainAxisAlignment.center,
        actionsOverflowDirection: VerticalDirection.down,
        actions: [
          DuoButton(
            label: context.t('Остаться', 'Keep going'),
            onPressed: () => Navigator.pop(context, false),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              context.t('ВЫЙТИ', 'LEAVE'),
              style: const TextStyle(
                color: DuoColors.red,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.pop(context, false);
  }

  Widget _buildStep(LessonStep step) {
    return switch (step) {
      TalkStep() => TalkStepView(step: step, onDone: _next),
      MoveStep() => MoveStepView(step: step, onDone: _next, onMistake: _mistake),
      QuizStep() => QuizStepView(step: step, onDone: _next, onMistake: _mistake),
      TapStep() => TapStepView(step: step, onDone: _next, onMistake: _mistake),
    };
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _finished,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: _finished
                  ? LessonComplete(
                      lesson: widget.lesson,
                      stars: _stars,
                      xp: _xp,
                      mistakes: _mistakes,
                      onContinue: () => Navigator.pop(context, true),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 10, 20, 6),
                          child: Row(
                            children: [
                              IconButton(
                                tooltip: context.t('Закрыть', 'Close'),
                                onPressed: _confirmExit,
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: DuoColors.muted,
                                  size: 30,
                                ),
                              ),
                              Expanded(
                                child: DuoProgressBar(
                                  value: _index / _steps.length,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 320),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder: (child, animation) => FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.08, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            ),
                            child: KeyedSubtree(
                              key: ValueKey(_index),
                              child: _buildStep(_steps[_index]),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
