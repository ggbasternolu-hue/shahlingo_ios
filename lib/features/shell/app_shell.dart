import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/course.dart';
import '../../state/app_scope.dart';
import '../../widgets/character.dart';
import '../../widgets/common.dart';
import '../league/league_page.dart';
import '../learn/learn_page.dart';
import '../play/play_page.dart';
import '../profile/profile_page.dart';

/// Adaptive shell: bottom navigation on phones, side rail + info panel on wide screens.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _Tab {
  const _Tab(this.icon, this.ru, this.en);

  final IconData icon;
  final String ru;
  final String en;
}

const _tabs = [
  _Tab(Icons.home_rounded, 'Обучение', 'Learn'),
  _Tab(Icons.sports_esports_rounded, 'Партии', 'Games'),
  _Tab(Icons.emoji_events_rounded, 'Рейтинг', 'Ranking'),
  _Tab(Icons.person_rounded, 'Профиль', 'Profile'),
];

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final Set<int> _visited = {0};

  void _select(int value) => setState(() {
    _index = value;
    _visited.add(value);
  });

  Widget _page(int i) {
    if (!_visited.contains(i)) return const SizedBox.shrink();
    return switch (i) {
      0 => const LearnPage(),
      1 => const PlayPage(),
      2 => const LeaguePage(),
      _ => const ProfilePage(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 900;
    final pages = IndexedStack(
      index: _index,
      children: [for (var i = 0; i < _tabs.length; i++) _page(i)],
    );

    if (!wide) {
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const _StatsBar(),
              Expanded(child: pages),
              _BottomNav(index: _index, onSelect: _select),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      body: Row(
        children: [
          _SideRail(index: _index, onSelect: _select),
          Expanded(child: pages),
          if (width >= 1180)
            const SizedBox(width: 340, child: _InfoPanel()),
        ],
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  const _StatsBar();

  @override
  Widget build(BuildContext context) {
    final p = context.progress;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DuoColors.border, width: 2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          PlayerAvatar(avatar: p.avatar, name: p.name, size: 38),
          StatChip(icon: Icons.castle_rounded, value: '${p.elo}', color: DuoColors.teal),
          StatChip(
            icon: Icons.local_fire_department_rounded,
            value: '${p.streak}',
            color: p.streak > 0 ? DuoColors.orange : DuoColors.muted,
          ),
          StatChip(icon: Icons.diamond_rounded, value: '${p.gems}', color: DuoColors.blue),
          StatChip(icon: Icons.bolt_rounded, value: '${p.xp}', color: DuoColors.yellow),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: DuoColors.bg,
      border: Border(top: BorderSide(color: DuoColors.border, width: 2)),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            for (var i = 0; i < _tabs.length; i++)
              Expanded(
                child: _NavButton(
                  icon: _tabs[i].icon,
                  label: context.t(_tabs[i].ru, _tabs[i].en),
                  selected: i == index,
                  onTap: () => onSelect(i),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0x221CB0F6) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? DuoColors.blue : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            scale: selected ? 1.15 : 1,
            child: Icon(
              icon,
              size: 28,
              color: selected ? DuoColors.blue : DuoColors.muted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? DuoColors.blue : DuoColors.muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SideRail extends StatelessWidget {
  const _SideRail({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Container(
    width: 250,
    padding: const EdgeInsets.fromLTRB(14, 24, 14, 20),
    decoration: const BoxDecoration(
      border: Border(right: BorderSide(color: DuoColors.border, width: 2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 26),
          child: Text(
            'shahlingo',
            style: TextStyle(
              color: DuoColors.green,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
        for (var i = 0; i < _tabs.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: i == index ? const Color(0x221CB0F6) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: i == index ? DuoColors.blue : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _tabs[i].icon,
                      size: 28,
                      color: i == index ? DuoColors.blue : DuoColors.muted,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      context.t(_tabs[i].ru, _tabs[i].en).toUpperCase(),
                      style: TextStyle(
                        color: i == index ? DuoColors.blue : DuoColors.muted,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// Right-hand column on wide screens: stats and a tip from the characters.
class _InfoPanel extends StatelessWidget {
  const _InfoPanel();

  @override
  Widget build(BuildContext context) {
    final p = context.progress;
    final current = p.currentLesson;
    final unit = current == null ? null : unitOf(current);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 8,
              children: [
                StatChip(icon: Icons.castle_rounded, value: '${p.elo}', color: DuoColors.teal),
                StatChip(
                  icon: Icons.local_fire_department_rounded,
                  value: '${p.streak}',
                  color: p.streak > 0 ? DuoColors.orange : DuoColors.muted,
                ),
                StatChip(icon: Icons.diamond_rounded, value: '${p.gems}', color: DuoColors.blue),
              ],
            ),
            const SizedBox(height: 22),
            DuoPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t('ТВОЙ ПУТЬ', 'YOUR PATH'),
                    style: DuoText.label,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    current == null
                        ? context.t('Курс пройден!', 'Course complete!')
                        : context.tr(current.title),
                    style: DuoText.h2,
                  ),
                  if (unit != null)
                    Text(context.tr(unit.title), style: DuoText.small),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: p.lessonsCompleted / allLessons.length,
                      minHeight: 10,
                      backgroundColor: DuoColors.border,
                      color: DuoColors.green,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${p.lessonsCompleted} / ${allLessons.length}',
                    style: DuoText.small,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            DuoPanel(
              child: Row(
                children: [
                  const CharacterBust(who: Who.sergei, emotion: Emotion.happy, height: 92),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.t(
                        'Занимайся каждый день — даже по одному уроку.',
                        'Practise every day — even one lesson counts.',
                      ),
                      style: DuoText.body.copyWith(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
