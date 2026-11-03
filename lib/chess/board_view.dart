import 'dart:async';
import 'dart:math';

import 'package:chess/chess.dart' as chess;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import 'board_utils.dart';
import 'piece_painter.dart';

/// Interactive chessboard with animated pieces.
///
/// * Move mode (default): tap a piece, then a highlighted square → [onMove].
/// * Tap mode: provide [onSquareTap]; every tap on a square is reported.
///
/// Pieces are tracked by identity, so moves, captures, castling and promotion
/// all glide / fade instead of jumping.
class ChessBoardView extends StatefulWidget {
  const ChessBoardView({
    required this.game,
    this.enabled = true,
    this.flipped = false,
    this.lastMove,
    this.hints = const {},
    this.marked = const {},
    this.onMove,
    this.onSquareTap,
    this.showCoordinates = true,
    super.key,
  });

  final chess.Chess game;
  final bool enabled;
  final bool flipped;

  /// Last move in coordinate notation (`e2e4`), tinted on the board.
  final String? lastMove;

  /// Squares that pulse in blue (hints).
  final Set<String> hints;

  /// Squares marked by the learner in tap mode.
  final Set<String> marked;
  final void Function(String from, String to)? onMove;
  final void Function(String square)? onSquareTap;
  final bool showCoordinates;

  @override
  State<ChessBoardView> createState() => _ChessBoardViewState();
}

class _Sprite {
  _Sprite(this.id, this.key, this.white, this.square, this.z, {required this.pop});

  final int id;
  final String key;
  final bool white;
  String square;
  int z;
  bool dying = false;
  final bool pop;
}

class _ChessBoardViewState extends State<ChessBoardView>
    with SingleTickerProviderStateMixin {
  final List<_Sprite> _sprites = [];
  int _nextId = 0;
  int _z = 0;
  String _fen = '';
  String? _selected;
  Set<String> _targets = const {};
  Set<String> _captures = const {};
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _sync(initial: true);
    _updatePulse();
  }

  @override
  void didUpdateWidget(covariant ChessBoardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.game.fen != _fen) {
      _sync(initial: false);
      _clearSelection();
    } else if (!widget.enabled && oldWidget.enabled) {
      _clearSelection();
    }
    _updatePulse();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _updatePulse() {
    final needs = widget.hints.isNotEmpty;
    if (needs && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!needs && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  void _clearSelection() {
    _selected = null;
    _targets = const {};
    _captures = const {};
  }

  Map<String, chess.Piece> _readBoard() {
    final result = <String, chess.Piece>{};
    for (var file = 0; file < 8; file++) {
      for (var rank = 0; rank < 8; rank++) {
        final name = squareName(file, rank);
        final piece = widget.game.get(name);
        if (piece != null) result[name] = piece;
      }
    }
    return result;
  }

  void _sync({required bool initial}) {
    _fen = widget.game.fen;
    final board = _readBoard();
    if (initial) {
      for (final entry in board.entries) {
        _sprites.add(_make(entry.key, entry.value, pop: false));
      }
      return;
    }

    final alive = _sprites.where((s) => !s.dying).toList();
    final remaining = Map<String, chess.Piece>.of(board);
    final unmatched = <_Sprite>[];

    // 1. pieces that did not move
    for (final sprite in alive) {
      final piece = remaining[sprite.square];
      if (piece != null &&
          pieceKey(piece.type) == sprite.key &&
          (piece.color == chess.Color.WHITE) == sprite.white) {
        remaining.remove(sprite.square);
      } else {
        unmatched.add(sprite);
      }
    }

    // 2. moved pieces: nearest free square holding the same piece
    for (final sprite in unmatched) {
      String? bestSquare;
      var bestDistance = 1 << 30;
      final from = squareCoords(sprite.square);
      for (final entry in remaining.entries) {
        final piece = entry.value;
        if (pieceKey(piece.type) != sprite.key ||
            (piece.color == chess.Color.WHITE) != sprite.white) {
          continue;
        }
        final to = squareCoords(entry.key);
        final distance = (from.$1 - to.$1).abs() + (from.$2 - to.$2).abs();
        if (distance < bestDistance) {
          bestDistance = distance;
          bestSquare = entry.key;
        }
      }
      if (bestSquare != null) {
        sprite.square = bestSquare;
        sprite.z = ++_z;
        remaining.remove(bestSquare);
      } else {
        sprite.dying = true; // captured
      }
    }

    // 3. brand new pieces (promotion, undo)
    for (final entry in remaining.entries) {
      _sprites.add(_make(entry.key, entry.value, pop: true));
    }

    if (_sprites.any((s) => s.dying)) {
      Timer(const Duration(milliseconds: 360), () {
        if (mounted) setState(() => _sprites.removeWhere((s) => s.dying));
      });
    }
  }

  _Sprite _make(String square, chess.Piece piece, {required bool pop}) =>
      _Sprite(
        _nextId++,
        pieceKey(piece.type),
        piece.color == chess.Color.WHITE,
        square,
        ++_z,
        pop: pop,
      );

  // ───────────── input ─────────────

  String _squareAt(Offset position, double cell) {
    final col = (position.dx / cell).floor().clamp(0, 7);
    final row = (position.dy / cell).floor().clamp(0, 7);
    final file = widget.flipped ? 7 - col : col;
    final rank = widget.flipped ? row : 7 - row;
    return squareName(file, rank);
  }

  void _handleTap(Offset position, double cell) {
    final square = _squareAt(position, cell);
    final tapHandler = widget.onSquareTap;
    if (tapHandler != null) {
      HapticFeedback.selectionClick();
      tapHandler(square);
      return;
    }
    if (!widget.enabled || widget.onMove == null) return;

    if (_selected != null && _targets.contains(square)) {
      final from = _selected!;
      setState(_clearSelection);
      widget.onMove!(from, square);
      return;
    }
    final piece = widget.game.get(square);
    if (piece == null || piece.color != widget.game.turn || square == _selected) {
      setState(_clearSelection);
      return;
    }
    HapticFeedback.selectionClick();
    final moves = widget.game.generate_moves({'square': square});
    setState(() {
      _selected = square;
      _targets = {for (final m in moves) m.toAlgebraic};
      _captures = {
        for (final m in moves)
          if (m.captured != null) m.toAlgebraic,
      };
    });
  }

  // ───────────── build ─────────────

  Offset _offsetOf(String square, double cell) {
    final (file, rank) = squareCoords(square);
    final col = widget.flipped ? 7 - file : file;
    final row = widget.flipped ? rank : 7 - rank;
    return Offset(col * cell, row * cell);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : constraints.maxWidth;
        final side = min(constraints.maxWidth, maxHeight);
        final cell = side / 8;
        final sprites = List<_Sprite>.of(_sprites)
          ..sort((a, b) => a.z.compareTo(b.z));
        final last = widget.lastMove;
        final lastSquares = last != null && last.length >= 4
            ? {last.substring(0, 2), last.substring(2, 4)}
            : <String>{};
        final check = checkedKingSquare(widget.game);

        return Center(
          child: SizedBox.square(
            dimension: side,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DuoColors.border, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) => _handleTap(details.localPosition, cell),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _pulse,
                          builder: (context, _) => CustomPaint(
                            painter: _SquaresPainter(
                              flipped: widget.flipped,
                              showCoordinates: widget.showCoordinates,
                              lastSquares: lastSquares,
                              selected: _selected,
                              targets: _targets,
                              captures: _captures,
                              hints: widget.hints,
                              marked: widget.marked,
                              check: check,
                              pulse: Curves.easeInOut.transform(_pulse.value),
                            ),
                          ),
                        ),
                      ),
                      for (final sprite in sprites)
                        _buildSprite(sprite, cell),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSprite(_Sprite sprite, double cell) {
    final offset = _offsetOf(sprite.square, cell);
    final lifted = sprite.square == _selected;
    return AnimatedPositioned(
      key: ValueKey(sprite.id),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      left: offset.dx,
      top: offset.dy,
      width: cell,
      height: cell,
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: sprite.dying ? 0 : 1,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            scale: sprite.dying ? 0.4 : (lifted ? 1.14 : 1),
            child: _PopIn(
              enabled: sprite.pop,
              child: Padding(
                padding: EdgeInsets.all(cell * 0.06),
                child: PieceView(pieceKey: sprite.key, isWhite: sprite.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PopIn extends StatelessWidget {
  const _PopIn({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.elasticOut,
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: child,
    );
  }
}

class _SquaresPainter extends CustomPainter {
  const _SquaresPainter({
    required this.flipped,
    required this.showCoordinates,
    required this.lastSquares,
    required this.selected,
    required this.targets,
    required this.captures,
    required this.hints,
    required this.marked,
    required this.check,
    required this.pulse,
  });

  final bool flipped;
  final bool showCoordinates;
  final Set<String> lastSquares;
  final String? selected;
  final Set<String> targets;
  final Set<String> captures;
  final Set<String> hints;
  final Set<String> marked;
  final String? check;
  final double pulse;

  static const light = Color(0xFF30444F);
  static const dark = Color(0xFF1E2F38);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 8;
    final fill = Paint();
    for (var row = 0; row < 8; row++) {
      for (var col = 0; col < 8; col++) {
        final file = flipped ? 7 - col : col;
        final rank = flipped ? row : 7 - row;
        final name = squareName(file, rank);
        final rect = Rect.fromLTWH(col * cell, row * cell, cell, cell);
        final isLight = (file + rank) % 2 == 1;
        fill.color = isLight ? light : dark;
        canvas.drawRect(rect, fill);

        if (lastSquares.contains(name)) {
          fill.color = DuoColors.yellow.withValues(alpha: 0.20);
          canvas.drawRect(rect, fill);
        }
        if (name == selected) {
          fill.color = DuoColors.green.withValues(alpha: 0.38);
          canvas.drawRect(rect, fill);
        }
        if (name == check) {
          fill.shader = RadialGradient(
            colors: [
              DuoColors.red.withValues(alpha: 0.85),
              DuoColors.red.withValues(alpha: 0.0),
            ],
          ).createShader(rect);
          canvas.drawRect(rect, fill);
          fill.shader = null;
        }
        if (hints.contains(name)) {
          final ring = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * 0.07
            ..color = DuoColors.blue.withValues(alpha: 0.55 + 0.45 * pulse);
          fill.color = DuoColors.blue.withValues(alpha: 0.12 + 0.18 * pulse);
          canvas.drawRect(rect, fill);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              rect.deflate(cell * 0.06),
              Radius.circular(cell * 0.2),
            ),
            ring,
          );
        }
        if (marked.contains(name)) {
          fill.color = DuoColors.green.withValues(alpha: 0.30);
          canvas.drawRect(rect, fill);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              rect.deflate(cell * 0.07),
              Radius.circular(cell * 0.22),
            ),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = cell * 0.07
              ..color = DuoColors.green,
          );
        }
        if (targets.contains(name)) {
          if (captures.contains(name)) {
            canvas.drawCircle(
              rect.center,
              cell * 0.43,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = cell * 0.09
                ..color = DuoColors.green.withValues(alpha: 0.85),
            );
          } else {
            canvas.drawCircle(
              rect.center,
              cell * 0.15,
              Paint()..color = DuoColors.green.withValues(alpha: 0.85),
            );
          }
        }
        if (showCoordinates) {
          final onBottom = row == 7;
          final onLeft = col == 0;
          if (onBottom) {
            _label(canvas, String.fromCharCode(97 + file),
                Offset(rect.right - cell * 0.22, rect.bottom - cell * 0.30),
                cell, isLight);
          }
          if (onLeft) {
            _label(canvas, '${rank + 1}',
                Offset(rect.left + cell * 0.06, rect.top + cell * 0.04),
                cell, isLight);
          }
        }
      }
    }
  }

  void _label(Canvas canvas, String text, Offset at, double cell, bool isLight) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: max(9, cell * 0.2),
          fontWeight: FontWeight.w800,
          color: (isLight ? dark : light).withValues(alpha: 0.95),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at);
  }

  @override
  bool shouldRepaint(covariant _SquaresPainter old) =>
      old.flipped != flipped ||
      old.showCoordinates != showCoordinates ||
      old.selected != selected ||
      old.check != check ||
      old.pulse != pulse ||
      !setEquals(old.lastSquares, lastSquares) ||
      !setEquals(old.targets, targets) ||
      !setEquals(old.captures, captures) ||
      !setEquals(old.hints, hints) ||
      !setEquals(old.marked, marked);
}
