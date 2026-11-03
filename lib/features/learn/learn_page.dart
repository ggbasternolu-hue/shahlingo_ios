import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/course.dart';
import '../../state/app_scope.dart';
import '../../widgets/common.dart';
import '../../widgets/duo_button.dart';
import '../lesson/lesson_page.dart';
import '../play/game_screen.dart';
import 'path_nodes.dart';

/// The learning path: pinned unit banners and a zig-zag of lesson nodes.
class LearnPage extends StatefulWidget {
  const LearnPage({super.key});

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  final _scroll = ScrollController();
  String? _selected; // lesson id or chest id
  bool _scrolled = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToCurrent(PlayerProgress progress) {
    if (_scrolled) return;
    _scrolled = true;
    final current = progress.currentLesson;
    if (current == null) return;
    var offset = 0.0;
    for (final unit in courseUnits) {
      if (unit.lessons.contains(current)) {
        offset += unit.lessons.indexOf(current) * 118.0;
        break;
      }
      offset += 96 + (unit.lessons.length + 1) * 118.0;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final target = (offset - 60).clamp(0.0, _scroll.position.maxScrollExtent);
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _start(Lesson lesson) async {
    setState(() => _selected = null);
    final route = lesson.kind == LessonKind.game
        ? duoRoute<bool>(GameScreen(lessonId: lesson.id))
        : duoRoute<bool>(LessonPage(lesson: lesson));
    await Navigator.of(context).push(route);
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.progress;
    _scrollToCurrent(progress);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            for (var u = 0; u < courseUnits.length; u++) ...[
              SliverPersistentHeader(
                pinned: true,
                delegate: _UnitHeader(
                  unit: courseUnits[u],
                  number: u + 1,
                  done: courseUnits[u].lessons
                      .where((l) => progress.isDone(l.id))
                      .length,
                  english: progress.english,
                ),
              ),
              SliverToBoxAdapter(
                child: _UnitPath(
                  unit: courseUnits[u],
                  selected: _selected,
                  onSelect: (id) =>
                      setState(() => _selected = _selected == id ? null : id),
                  onStart: _start,
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
        ),
      ),
    );
  }
}

class _UnitHeader extends SliverPersistentHeaderDelegate {
  const _UnitHeader({
    required this.unit,
    required this.number,
    required this.done,
    required this.english,
  });

  final CourseUnit unit;
  final int number;
  final int done;
  final bool english;

  @override
  double get minExtent => 104;

  @override
  double get maxExtent => 104;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final tone = unitTones[unit.colorIndex % unitTones.length];
    return Container(
      color: DuoColors.bg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: tone.face,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: tone.depth, offset: const Offset(0, 5))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (english ? 'SECTION $number' : 'РАЗДЕЛ $number'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.9,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    unit.title.of(english),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    unit.description.of(english),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$done/${unit.lessons.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _UnitHeader old) =>
      old.done != done || old.english != english || old.unit != unit;
}

class _UnitPath extends StatelessWidget {
  const _UnitPath({
    required this.unit,
    required this.selected,
    required this.onSelect,
    required this.onStart,
  });

  final CourseUnit unit;
  final String? selected;
  final void Function(String id) onSelect;
  final Future<void> Function(Lesson lesson) onStart;

  static const _pattern = [0.0, -0.55, -0.85, -0.55, 0.0, 0.55, 0.85, 0.55];

  @override
  Widget build(BuildContext context) {
    final progress = context.progress;
    final tone = unitTones[unit.colorIndex % unitTones.length];
    final rows = <Widget>[];
    var position = 0;

    Widget place(Widget child, int slot) => LayoutBuilder(
      builder: (context, constraints) {
        final amplitude = min(86.0, constraints.maxWidth * 0.22);
        return Transform.translate(
          offset: Offset(_pattern[slot % _pattern.length] * amplitude, 0),
          child: child,
        );
      },
    );

    for (var i = 0; i < unit.lessons.length; i++) {
      final lesson = unit.lessons[i];
      final done = progress.isDone(lesson.id);
      final unlocked = progress.isUnlocked(lesson.id);
      final state = done
          ? NodeState.done
          : (unlocked ? NodeState.current : NodeState.locked);
      rows.add(
        place(
          Center(
            child: LessonNode(
              lesson: lesson,
              state: state,
              tone: tone,
              stars: progress.starsFor(lesson.id),
              onTap: () => onSelect(lesson.id),
            ),
          ),
          position++,
        ),
      );
      rows.add(
        _Popup(
          visible: selected == lesson.id,
          child: _LessonCard(
            lesson: lesson,
            tone: tone,
            unlocked: unlocked,
            done: done,
            onStart: () => onStart(lesson),
          ),
        ),
      );

      if (i + 1 == unit.chestAfter && i + 1 < unit.lessons.length) {
        final id = chestId(unit);
        final opened = progress.isChestOpen(id);
        final ready = done && !opened;
        rows.add(
          place(
            Center(
              child: ChestNode(
                state: opened
                    ? ChestState.opened
                    : (ready ? ChestState.ready : ChestState.locked),
                onTap: () async {
                  if (ready) {
                    await progress.openChest(id);
                    onSelect(id);
                  } else {
                    onSelect(id);
                  }
                },
              ),
            ),
            position++,
          ),
        );
        rows.add(
          _Popup(
            visible: selected == id,
            child: _ChestCard(opened: opened, ready: ready),
          ),
        );
      }
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 14),
      child: Column(children: rows),
    );
  }
}

class _Popup extends StatelessWidget {
  const _Popup({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSize(
    duration: const Duration(milliseconds: 280),
    curve: Curves.easeOutCubic,
    alignment: Alignment.topCenter,
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutBack,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1).animate(animation),
          alignment: Alignment.topCenter,
          child: child,
        ),
      ),
      child: visible
          ? Padding(
              key: const ValueKey('open'),
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 14),
              child: child,
            )
          : const SizedBox.shrink(key: ValueKey('closed')),
    ),
  );
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.lesson,
    required this.tone,
    required this.unlocked,
    required this.done,
    required this.onStart,
  });

  final Lesson lesson;
  final DuoTone tone;
  final bool unlocked;
  final bool done;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final face = unlocked ? tone.face : DuoColors.locked;
    final edge = unlocked ? tone.depth : DuoColors.lockedDepth;
    final xp = lesson.kind == LessonKind.game ? 30 : (done ? 5 : 20);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: face,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: edge, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr(lesson.title),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            unlocked
                ? context.tr(lesson.subtitle)
                : context.t(
                    'Сначала пройди предыдущие уроки.',
                    'Finish the previous lessons first.',
                  ),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          DuoButton(
            label: unlocked
                ? (done
                      ? context.t('Повторить  +$xp XP', 'Practise again  +$xp XP')
                      : context.t('Начать  +$xp XP', 'Start  +$xp XP'))
                : context.t('Закрыто', 'Locked'),
            onPressed: unlocked ? onStart : null,
            tone: const DuoTone(Colors.white, Color(0xFFCFDBE2)),
            textColor: unlocked ? tone.depth : null,
          ),
        ],
      ),
    );
  }
}

class _ChestCard extends StatelessWidget {
  const _ChestCard({required this.opened, required this.ready});

  final bool opened;
  final bool ready;

  @override
  Widget build(BuildContext context) => DuoPanel(
    child: Row(
      children: [
        ChestIcon(size: 46, open: opened, locked: !opened && !ready),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            opened
                ? context.t(
                    'Сундук открыт: +15 самоцветов!',
                    'Chest opened: +15 gems!',
                  )
                : context.t(
                    'Пройди урок перед сундуком, чтобы открыть его.',
                    'Finish the lesson before the chest to open it.',
                  ),
            style: DuoText.body,
          ),
        ),
      ],
    ),
  );
}
