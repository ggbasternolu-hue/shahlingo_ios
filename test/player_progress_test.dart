import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shahlingo/state/game_record.dart';
import 'package:shahlingo/state/player_progress.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('new players start at zero ELO', () {
    expect(PlayerProgress().elo, 0);
  });

  test('migrates the old unrated 800 ELO default to zero', () async {
    SharedPreferences.setMockInitialValues({
      'shahlingo_v3_elo': 800,
      'shahlingo_v3_rated_games': 0,
    });
    final progress = PlayerProgress();

    await progress.load();

    expect(progress.elo, 0);
  });

  test('online ELO uses opponent rating and clamps at zero', () {
    expect(
      PlayerProgress.calculateEloChange(rating: 0, opponentRating: 0, score: 1),
      16,
    );
    expect(
      PlayerProgress.calculateEloChange(
        rating: 0,
        opponentRating: 400,
        score: 0.5,
      ),
      13,
    );
  });

  test('online result awards rating, XP, game count, and history', () async {
    final progress = PlayerProgress();
    final record = GameRecord(
      opponent: 'Игрок',
      result: GameResult.win,
      moves: const [],
      playedAtMs: 1,
      playerWhite: true,
    );

    progress.finishOnlineRound(won: true, opponentElo: 0, record: record);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(progress.elo, 16);
    expect(progress.xp, 20);
    expect(progress.ratedGames, 1);
    expect(progress.wins, 1);
  });
}
