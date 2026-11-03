import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Rounded speech bubble whose tail points left (default) or right.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    required this.child,
    this.tailOnLeft = true,
    this.color = DuoColors.panel,
    this.borderColor = DuoColors.border,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 12),
    super.key,
  });

  final Widget child;
  final bool tailOnLeft;
  final Color color;
  final Color borderColor;
  final EdgeInsets padding;

  static const double tail = 11;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _BubblePainter(tailOnLeft, color, borderColor),
    child: Padding(
      padding: padding.copyWith(
        left: padding.left + (tailOnLeft ? tail : 0),
        right: padding.right + (tailOnLeft ? 0 : tail),
      ),
      child: child,
    ),
  );
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter(this.tailOnLeft, this.color, this.border);

  final bool tailOnLeft;
  final Color color;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (!tailOnLeft) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    const t = SpeechBubble.tail;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(t, 1, size.width - t - 1, size.height - 2),
      const Radius.circular(18),
    );
    final y = (size.height / 2).clamp(18.0, 30.0);
    final fill = Paint()..color = color;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round
      ..color = border;
    canvas.drawRRect(body, fill);
    canvas.drawRRect(body, stroke);
    final cover = Path()
      ..moveTo(t + 1.5, y - 9)
      ..lineTo(1, y)
      ..lineTo(t + 1.5, y + 9)
      ..close();
    canvas.drawPath(cover, fill);
    final edge = Path()
      ..moveTo(t, y - 9)
      ..lineTo(1, y)
      ..lineTo(t, y + 9);
    canvas.drawPath(edge, stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BubblePainter old) =>
      old.tailOnLeft != tailOnLeft || old.color != color || old.border != border;
}
