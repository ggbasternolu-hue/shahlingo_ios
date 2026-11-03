import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// One-shot celebratory confetti rain. Ignores pointer events.
class Confetti extends StatefulWidget {
  const Confetti({this.count = 90, super.key});

  final int count;

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _Piece {
  _Piece(Random r)
    : x = r.nextDouble(),
      delay = r.nextDouble() * 0.35,
      speed = 0.55 + r.nextDouble() * 0.7,
      size = 6 + r.nextDouble() * 7,
      sway = r.nextDouble() * 2 * pi,
      spin = (r.nextDouble() - 0.5) * 14,
      color = _colors[r.nextInt(_colors.length)];

  static const _colors = [
    DuoColors.green,
    DuoColors.blue,
    DuoColors.yellow,
    DuoColors.pink,
    DuoColors.orange,
    DuoColors.purple,
  ];

  final double x;
  final double delay;
  final double speed;
  final double size;
  final double sway;
  final double spin;
  final Color color;
}

class _ConfettiState extends State<Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Piece> _pieces;

  @override
  void initState() {
    super.initState();
    final random = Random(7);
    _pieces = [for (var i = 0; i < widget.count; i++) _Piece(random)];
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_pieces, _controller.value),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter(this.pieces, this.t);

  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final local = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final y = -20 + local * (size.height + 60) * p.speed;
      final x = p.x * size.width + sin(local * 7 + p.sway) * 22;
      final alpha = local > 0.8 ? (1 - local) / 0.2 : 1.0;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(local * p.spin);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.55),
          const Radius.circular(2),
        ),
        Paint()..color = p.color.withValues(alpha: alpha),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
