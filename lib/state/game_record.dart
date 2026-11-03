import 'dart:convert';

enum GameResult { win, loss, draw }

/// A finished game, kept locally so it can be replayed from the history list.
class GameRecord {
  const GameRecord({
    required this.opponent,
    required this.result,
    required this.moves,
    required this.playedAtMs,
    required this.playerWhite,
  });

  /// Display name of the opponent, for example "Мария" or an online nickname.
  final String opponent;
  final GameResult result;

  /// Moves in coordinate notation, e.g. `e2e4`, `g1f3`.
  final List<String> moves;
  final int playedAtMs;
  final bool playerWhite;

  String encode() => jsonEncode({
    'o': opponent,
    'r': result.name,
    'm': moves,
    't': playedAtMs,
    'w': playerWhite,
  });

  static GameRecord? decode(String raw) {
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return null;
      final result = GameResult.values.firstWhere(
        (value) => value.name == map['r'],
        orElse: () => GameResult.draw,
      );
      return GameRecord(
        opponent: map['o'] as String? ?? '—',
        result: result,
        moves: [for (final move in (map['m'] as List? ?? const [])) '$move'],
        playedAtMs: (map['t'] as num?)?.toInt() ?? 0,
        playerWhite: map['w'] as bool? ?? true,
      );
    } catch (_) {
      return null;
    }
  }
}
