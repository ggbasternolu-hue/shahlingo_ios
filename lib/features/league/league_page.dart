import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/course_model.dart';
import '../../services/firebase_service.dart';
import '../../state/app_scope.dart';
import '../../widgets/character.dart';
import '../../widgets/common.dart';
import '../../widgets/duo_button.dart';

/// Leaderboard from Firebase, styled as a Duolingo league.
class LeaguePage extends StatelessWidget {
  const LeaguePage({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.progress;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: !progress.firebaseReady
            ? _Offline(message: progress.cloudError)
            : StreamBuilder<List<OnlinePlayer>>(
                stream: FirebaseService.instance.leaderboard(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _Offline(
                      message: PlayerProgress.describeFirebaseError(
                        snapshot.error!,
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: DuoColors.green),
                    );
                  }
                  return _Board(players: snapshot.data!);
                },
              ),
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.players});

  final List<OnlinePlayer> players;

  @override
  Widget build(BuildContext context) {
    final english = context.isEnglish;
    final me = FirebaseService.instance.userId;
    final leader = players.isEmpty ? 0 : players.first.elo;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x66FFC800), Color(0x00FFC800)],
              ),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: DuoColors.yellow,
              size: 60,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.t('Рейтинг игроков', 'Player ranking'),
          textAlign: TextAlign.center,
          style: DuoText.h1,
        ),
        const SizedBox(height: 4),
        Text(
          context.t('Лучшие по рейтингу ЭЛО', 'Top players by ELO'),
          textAlign: TextAlign.center,
          style: DuoText.small,
        ),
        const SizedBox(height: 20),
        if (players.isEmpty)
          DuoPanel(
            child: Row(
              children: [
                const CharacterAvatar(
                  who: Who.maria,
                  emotion: Emotion.smug,
                  size: 52,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    context.t(
                      'Здесь пока никого. Сыграй онлайн и займи первое место!',
                      'Nobody here yet. Play online and take first place!',
                    ),
                    style: DuoText.body,
                  ),
                ),
              ],
            ),
          ),
        for (var i = 0; i < players.length; i++)
          _Row(
            place: i + 1,
            player: players[i],
            mine: players[i].uid == me,
            english: english,
            leader: leader,
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.place,
    required this.player,
    required this.mine,
    required this.english,
    required this.leader,
  });

  final int place;
  final OnlinePlayer player;
  final bool mine;
  final bool english;
  final int leader;

  @override
  Widget build(BuildContext context) {
    final medal = switch (place) {
      1 => DuoColors.yellow,
      2 => const Color(0xFFC0CCD4),
      3 => const Color(0xFFD08A4E),
      _ => null,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: mine ? const Color(0x2658CC02) : DuoColors.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: mine ? DuoColors.green : DuoColors.border,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: medal != null
                ? Icon(Icons.workspace_premium_rounded, color: medal, size: 28)
                : Text(
                    '$place',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: mine ? DuoColors.green : DuoColors.muted,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          InitialAvatar(name: player.name, size: 46),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DuoText.body.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  PlayerProgress.rankFor(player.elo, english),
                  style: DuoText.small.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${player.elo}',
            style: const TextStyle(
              color: DuoColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Offline extends StatelessWidget {
  const _Offline({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CharacterBust(
            who: Who.sergei,
            emotion: Emotion.thinking,
            height: 120,
          ),
          const SizedBox(height: 14),
          Text(
            context.t('Рейтинг недоступен', 'Ranking unavailable'),
            style: DuoText.h2,
          ),
          const SizedBox(height: 8),
          Text(
            message ??
                context.t(
                  'Нет подключения к облаку. Уроки и игра с Марией работают и без него.',
                  'No cloud connection. Lessons and games against Maria still work.',
                ),
            textAlign: TextAlign.center,
            style: DuoText.small,
          ),
          const SizedBox(height: 18),
          DuoButton(
            label: context.t('Попробовать снова', 'Try again'),
            expanded: false,
            onPressed: () => AppScope.read(context).retryFirebase(),
          ),
        ],
      ),
    ),
  );
}
