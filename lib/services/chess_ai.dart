import 'dart:math';

import 'package:chess/chess.dart' as chess;
import 'package:flutter/foundation.dart' show compute;

import '../chess/board_utils.dart';

/// Picks a move for the side to move in [fen]. [level] is 1 (easy) to 3 (hard).
/// Returns coordinate notation such as `e2e4`, or null when there are no moves.
/// Runs in a background isolate on mobile and desktop.
Future<String?> pickAiMove(String fen, int level) =>
    compute(_search, <Object>[fen, level, DateTime.now().microsecondsSinceEpoch]);

int _nodes = 0;
int _budget = 0;

String? _search(List<Object> args) {
  final fen = args[0] as String;
  final level = (args[1] as int).clamp(1, 3);
  final rnd = Random(args[2] as int);
  final root = chess.Chess.fromFEN(fen);
  final moves = root.generate_moves();
  if (moves.isEmpty) return null;

  if (level == 1 && rnd.nextInt(100) < 18) {
    final move = moves[rnd.nextInt(moves.length)];
    return '${move.fromAlgebraic}${move.toAlgebraic}';
  }

  final depth = level;
  final noise = switch (level) { 1 => 140, 2 => 30, _ => 6 };
  _budget = switch (level) { 1 => 400, 2 => 1500, _ => 3200 };
  _nodes = 0;

  final ordered = _ordered(moves);
  var bestScore = -1 << 30;
  String? best;
  for (final move in ordered) {
    final child = root.copy();
    child.move(_moveMap(move));
    var score = -_negamax(child, depth - 1, -(1 << 29), 1 << 29);
    score += rnd.nextInt(noise * 2 + 1) - noise;
    if (score > bestScore) {
      bestScore = score;
      best = '${move.fromAlgebraic}${move.toAlgebraic}';
    }
  }
  return best;
}

Map<String, String> _moveMap(chess.Move move) => {
  'from': move.fromAlgebraic,
  'to': move.toAlgebraic,
  'promotion': 'q',
};

List<chess.Move> _ordered(List<chess.Move> moves) {
  int rank(chess.Move m) {
    final captured = m.captured;
    var score = captured == null ? 0 : pieceValue(captured) * 10;
    score -= pieceValue(m.piece);
    if (m.promotion != null) score += 80;
    return score;
  }

  final list = List<chess.Move>.of(moves);
  list.sort((a, b) => rank(b).compareTo(rank(a)));
  return list;
}

int _negamax(chess.Chess game, int depth, int alpha, int beta) {
  _nodes++;
  if (depth <= 0 || _nodes > _budget) {
    return (game.turn == chess.Color.WHITE ? 1 : -1) * _evaluate(game.fen);
  }
  final moves = game.generate_moves();
  if (moves.isEmpty) {
    return game.in_check ? -100000 - depth : 0;
  }
  var best = -1 << 30;
  for (final move in _ordered(moves)) {
    final child = game.copy();
    child.move(_moveMap(move));
    final score = -_negamax(child, depth - 1, -beta, -alpha);
    if (score > best) best = score;
    if (best > alpha) alpha = best;
    if (alpha >= beta) break;
  }
  return best;
}

/// Static evaluation from White's point of view, read straight from the FEN.
int _evaluate(String fen) {
  final board = fen.split(' ').first;
  var score = 0;
  var rank = 7;
  var file = 0;
  for (final code in board.codeUnits) {
    final ch = String.fromCharCode(code);
    if (ch == '/') {
      rank--;
      file = 0;
      continue;
    }
    final digit = int.tryParse(ch);
    if (digit != null) {
      file += digit;
      continue;
    }
    final white = ch == ch.toUpperCase();
    final lower = ch.toLowerCase();
    var value = switch (lower) {
      'p' => 100,
      'n' => 320,
      'b' => 330,
      'r' => 500,
      'q' => 900,
      _ => 0,
    };
    final centre = 10 - ((3.5 - file).abs() + (3.5 - rank).abs()).round() * 3;
    if (lower == 'p') {
      value += centre + (white ? rank - 1 : 6 - rank) * 6;
    } else if (lower == 'n' || lower == 'b') {
      value += centre * 2;
    } else if (lower == 'q') {
      value += centre;
    }
    score += white ? value : -value;
    file++;
  }
  return score;
}
