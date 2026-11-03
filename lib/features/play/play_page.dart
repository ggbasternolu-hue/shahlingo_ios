import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/course_model.dart';
import '../../state/app_scope.dart';
import '../../state/game_record.dart';
import '../../widgets/character.dart';
import '../../widgets/common.dart';
import '../../widgets/duo_button.dart';
import 'game_screen.dart';
import 'online_game_screen.dart';
import 'replay_page.dart';

enum _Opponent { maria, friend, online }

/// "Games" tab: pick an opponent, start a game, browse the history.
class PlayPage extends StatefulWidget {
  const PlayPage({super.key});

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  _Opponent _opponent = _Opponent.maria;
  int _level = 2;

  void _play() {
    final route = switch (_opponent) {
      _Opponent.maria => duoRoute<bool>(GameScreen(level: _level)),
      _Opponent.friend => duoRoute<bool>(const GameScreen(mode: GameMode.friend)),
      _Opponent.online => duoRoute<bool>(const OnlineGameScreen()),
    };
    Navigator.of(context).push(route);
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.progress;
    final label = switch (_opponent) {
      _Opponent.maria => context.t('Играть с Марией', 'Play Maria'),
      _Opponent.friend => context.t('Играть вдвоём', 'Play together'),
      _Opponent.online => context.t('Искать соперника', 'Find an opponent'),
    };
    final xp = _opponent == _Opponent.online ? 20 : 30;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            Text(context.t('Шахматные партии', 'Chess games'), style: DuoText.h1),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.show_chart_rounded, color: DuoColors.muted, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${context.t('ЭЛО', 'ELO')}: ${progress.elo}',
                  style: DuoText.label,
                ),
                const SizedBox(width: 18),
                const Icon(Icons.check_circle_outline_rounded, color: DuoColors.muted, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${progress.wins} ${context.t('ПОБЕД', 'WINS')}',
                  style: DuoText.label,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _OpponentCard(
                    selected: _opponent == _Opponent.maria,
                    label: context.t('Мария', 'Maria'),
                    onTap: () => setState(() => _opponent = _Opponent.maria),
                    child: const CharacterBust(
                      who: Who.maria,
                      emotion: Emotion.smug,
                      height: 108,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _OpponentCard(
                    selected: _opponent == _Opponent.friend,
                    label: context.t('Друг', 'Friend'),
                    onTap: () => setState(() => _opponent = _Opponent.friend),
                    child: const _IconArt(icon: Icons.people_alt_rounded, color: DuoColors.orange),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _OpponentCard(
                    selected: _opponent == _Opponent.online,
                    label: context.t('Онлайн', 'Online'),
                    onTap: () => setState(() => _opponent = _Opponent.online),
                    child: const _IconArt(icon: Icons.public_rounded, color: DuoColors.blue),
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _opponent == _Opponent.maria
                  ? Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: _LevelPicker(
                        level: _level,
                        onChanged: (value) => setState(() => _level = value),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            const SizedBox(height: 18),
            DuoButton(label: '$label  +$xp XP', onPressed: _play),
            const SizedBox(height: 30),
            Text(
              context.t('ИСТОРИЯ ПАРТИЙ', 'GAME HISTORY'),
              style: DuoText.label,
            ),
            const SizedBox(height: 12),
            if (progress.history.isEmpty)
              DuoPanel(
                child: Row(
                  children: [
                    const CharacterAvatar(who: Who.sergei, emotion: Emotion.thinking, size: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        context.t(
                          'Пока пусто. Сыграй первую партию — я буду рядом.',
                          'Nothing here yet. Play your first game — I’ll be nearby.',
                        ),
                        style: DuoText.body,
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final record in progress.history)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _HistoryTile(record: record),
                ),
          ],
        ),
      ),
    );
  }
}

class _OpponentCard extends StatefulWidget {
  const _OpponentCard({
    required this.selected,
    required this.label,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_OpponentCard> createState() => _OpponentCardState();
}

class _OpponentCardState extends State<_OpponentCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final accent = selected ? DuoColors.teal : DuoColors.border;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _down ? 0.97 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          height: 168,
          decoration: BoxDecoration(
            color: selected ? const Color(0x1A00CD9C) : DuoColors.bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(
                child: Align(alignment: Alignment.bottomCenter, child: widget.child),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9),
                color: selected ? const Color(0x3300CD9C) : DuoColors.panel,
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? DuoColors.teal : DuoColors.muted,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconArt extends StatelessWidget {
  const _IconArt({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 26),
    child: Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 40),
    ),
  );
}

class _LevelPicker extends StatelessWidget {
  const _LevelPicker({required this.level, required this.onChanged});

  final int level;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final names = [
      context.t('Лёгкий', 'Easy'),
      context.t('Средний', 'Medium'),
      context.t('Сложный', 'Hard'),
    ];
    return Row(
      children: [
        for (var i = 1; i <= 3; i++) ...[
          if (i > 1) const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: level == i ? const Color(0x331CB0F6) : DuoColors.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: level == i ? DuoColors.blue : DuoColors.border,
                    width: 2,
                  ),
                ),
                child: Text(
                  names[i - 1],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: level == i ? DuoColors.blue : DuoColors.muted,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.record});

  final GameRecord record;

  @override
  Widget build(BuildContext context) {
    final (icon, color, text) = switch (record.result) {
      GameResult.win => (Icons.check_circle_outline_rounded, DuoColors.green, context.t('Победа', 'Win')),
      GameResult.loss => (Icons.cancel_outlined, DuoColors.red, context.t('Поражение', 'Loss')),
      GameResult.draw => (Icons.drag_handle_rounded, DuoColors.muted, context.t('Ничья', 'Draw')),
    };
    return DuoPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          InitialAvatar(name: record.opponent, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.opponent,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DuoText.body.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(icon, color: color, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      text,
                      style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (record.moves.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.of(context).push(
                duoRoute<void>(ReplayPage(record: record)),
              ),
              child: Text(
                context.t('ПРОСМОТР', 'REPLAY'),
                style: const TextStyle(
                  color: DuoColors.teal,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
