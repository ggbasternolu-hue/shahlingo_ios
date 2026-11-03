import 'package:chess/chess.dart' as chess;

String squareName(int file, int rank) =>
    '${String.fromCharCode(97 + file)}${rank + 1}';

/// (file, rank), both 0-based, a1 = (0, 0).
(int, int) squareCoords(String square) =>
    (square.codeUnitAt(0) - 97, int.parse(square[1]) - 1);

String uciFrom(String uci) => uci.substring(0, 2);
String uciTo(String uci) => uci.substring(2, 4);

/// Plays a move given as `from`/`to`; pawns reaching the last rank become queens.
bool playMove(chess.Chess game, String from, String to) =>
    game.move({'from': from, 'to': to, 'promotion': 'q'});

bool playUci(chess.Chess game, String uci) =>
    playMove(game, uciFrom(uci), uciTo(uci));

/// Whether moving [from]→[to] would capture something (including en passant).
bool isCaptureMove(chess.Chess game, String from, String to) {
  if (game.get(to) != null) return true;
  final piece = game.get(from);
  return piece != null && piece.type == chess.PieceType.PAWN && from[0] != to[0];
}

/// Square of the king that is currently in check, or null.
String? checkedKingSquare(chess.Chess game) {
  if (!game.in_check) return null;
  for (var file = 0; file < 8; file++) {
    for (var rank = 0; rank < 8; rank++) {
      final name = squareName(file, rank);
      final piece = game.get(name);
      if (piece != null &&
          piece.type == chess.PieceType.KING &&
          piece.color == game.turn) {
        return name;
      }
    }
  }
  return null;
}

/// Material value used for captured-piece bookkeeping (pawn = 1).
int pieceValue(chess.PieceType type) {
  if (type == chess.PieceType.PAWN) return 1;
  if (type == chess.PieceType.KNIGHT || type == chess.PieceType.BISHOP) return 3;
  if (type == chess.PieceType.ROOK) return 5;
  if (type == chess.PieceType.QUEEN) return 9;
  return 0;
}

String pieceKey(chess.PieceType type) {
  if (type == chess.PieceType.KNIGHT) return 'n';
  if (type == chess.PieceType.BISHOP) return 'b';
  if (type == chess.PieceType.ROOK) return 'r';
  if (type == chess.PieceType.QUEEN) return 'q';
  if (type == chess.PieceType.KING) return 'k';
  return 'p';
}

/// Material balance from White's point of view (positive = White is ahead).
int materialBalance(chess.Chess game) {
  var total = 0;
  for (var file = 0; file < 8; file++) {
    for (var rank = 0; rank < 8; rank++) {
      final piece = game.get(squareName(file, rank));
      if (piece == null) continue;
      final value = pieceValue(piece.type);
      total += piece.color == chess.Color.WHITE ? value : -value;
    }
  }
  return total;
}

/// Rebuilds a game from a list of coordinate moves.
chess.Chess gameFromMoves(List<String> moves, [int? upTo]) {
  final game = chess.Chess();
  final count = upTo ?? moves.length;
  for (var i = 0; i < count && i < moves.length; i++) {
    playUci(game, moves[i]);
  }
  return game;
}
