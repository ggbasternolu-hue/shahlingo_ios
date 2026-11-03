import 'package:flutter/material.dart';

import 'piece_paths.dart';

/// Parses the tiny absolute-only SVG path dialect used by [pieceShapes].
Path parseSvgPath(String d) {
  final tokens = d.trim().split(RegExp(r'\s+'));
  final path = Path();
  var i = 0;
  double next() => double.parse(tokens[i++]);
  var y0 = 0.0;
  while (i < tokens.length) {
    final command = tokens[i++];
    if (command == 'M') {
      final x = next();
      y0 = next();
      path.moveTo(x, y0);
    } else if (command == 'L') {
      final x = next();
      y0 = next();
      path.lineTo(x, y0);
    } else if (command == 'H') {
      path.lineTo(next(), y0);
    } else if (command == 'Q') {
      final x1 = next();
      final y1 = next();
      final x = next();
      y0 = next();
      path.quadraticBezierTo(x1, y1, x, y0);
    } else if (command == 'C') {
      final x1 = next();
      final y1 = next();
      final x2 = next();
      final y2 = next();
      final x = next();
      y0 = next();
      path.cubicTo(x1, y1, x2, y2, x, y0);
    } else if (command == 'Z') {
      path.close();
    } else {
      throw FormatException('Unsupported path command: $command');
    }
  }
  return path;
}

class _ParsedShape {
  _ParsedShape(PieceShape source)
    : shapes = [for (final d in source.shapes) parseSvgPath(d)],
      details = [for (final d in source.details) parseSvgPath(d)],
      dots = source.dots;

  final List<Path> shapes;
  final List<Path> details;
  final List<(double, double, double)> dots;
}

final Map<String, _ParsedShape> _cache = {};

_ParsedShape _shapeFor(String key) =>
    _cache.putIfAbsent(key, () => _ParsedShape(pieceShapes[key]!));

/// Draws one chess piece. [key] is p, n, b, r, q or k.
class PieceView extends StatelessWidget {
  const PieceView({
    required this.pieceKey,
    required this.isWhite,
    this.size,
    super.key,
  });

  final String pieceKey;
  final bool isWhite;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final painter = _PiecePainter(pieceKey, isWhite);
    if (size == null) return CustomPaint(painter: painter);
    return CustomPaint(size: Size.square(size!), painter: painter);
  }
}

class _PiecePainter extends CustomPainter {
  const _PiecePainter(this.key, this.isWhite);

  final String key;
  final bool isWhite;

  static const _whiteFill = Color(0xFFE9F2F7);
  static const _whiteLine = Color(0xFF8A9FAD);
  static const _blackFill = Color(0xFF5E7888);
  static const _blackLine = Color(0xFF24363F);

  @override
  void paint(Canvas canvas, Size size) {
    final shape = _shapeFor(key);
    final fill = isWhite ? _whiteFill : _blackFill;
    final line = isWhite ? _whiteLine : _blackLine;
    final unit = size.shortestSide / 100;
    canvas.save();
    canvas.scale(unit);

    // soft contact shadow
    canvas.drawOval(
      const Rect.fromLTWH(20, 86, 60, 9),
      Paint()..color = const Color(0x33000000),
    );

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeJoin = StrokeJoin.round
      ..color = line;
    for (final path in shape.shapes) {
      canvas.drawPath(path, outline);
    }

    const box = Rect.fromLTWH(0, 0, 100, 100);
    canvas.saveLayer(box, Paint());
    final body = Paint()..color = fill;
    for (final path in shape.shapes) {
      canvas.drawPath(path, body);
    }
    canvas.drawRect(
      box,
      Paint()
        ..blendMode = BlendMode.srcATop
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: isWhite ? 0.55 : 0.22),
            Colors.transparent,
            Colors.black.withValues(alpha: isWhite ? 0.16 : 0.26),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(box),
    );
    canvas.restore();

    final detail = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..color = line;
    for (final path in shape.details) {
      canvas.drawPath(path, detail);
    }
    final dot = Paint()..color = line;
    for (final (x, y, r) in shape.dots) {
      canvas.drawCircle(Offset(x, y), r, dot);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PiecePainter old) =>
      old.key != key || old.isWhite != isWhite;
}
