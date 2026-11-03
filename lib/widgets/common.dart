import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/course_model.dart';
import 'character.dart';
import 'speech_bubble.dart';
import 'typewriter_text.dart';

/// Bordered panel used for cards across the app.
class DuoPanel extends StatelessWidget {
  const DuoPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = DuoColors.panel,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DuoColors.border, width: 2),
      ),
      child: child,
    );
    if (onTap == null) return box;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: box,
    );
  }
}

/// Character on the left, speech bubble on the right.
class CharacterSays extends StatelessWidget {
  const CharacterSays({
    required this.who,
    required this.emotion,
    required this.text,
    this.height = 104,
    super.key,
  });

  final Who who;
  final Emotion emotion;
  final String text;
  final double height;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      CharacterBust(who: who, emotion: emotion, height: height),
      const SizedBox(width: 2),
      Expanded(
        child: Padding(
          padding: EdgeInsets.only(bottom: height * 0.18),
          child: SpeechBubble(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topLeft,
              child: TypewriterText(text),
            ),
          ),
        ),
      ),
    ],
  );
}

class StatChip extends StatelessWidget {
  const StatChip({
    required this.icon,
    required this.value,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: color, size: 24),
      const SizedBox(width: 5),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Text(
          value,
          key: ValueKey(value),
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  );
}

/// Small treasure chest drawn with paths (no emoji fonts needed).
class ChestIcon extends StatelessWidget {
  const ChestIcon({this.size = 60, this.open = false, this.locked = false, super.key});

  final double size;
  final bool open;
  final bool locked;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _ChestPainter(open, locked),
  );
}

class _ChestPainter extends CustomPainter {
  const _ChestPainter(this.open, this.locked);

  final bool open;
  final bool locked;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;
    canvas.save();
    canvas.scale(u);
    final wood = locked ? const Color(0xFF51656F) : const Color(0xFFB8691A);
    final woodDark = locked ? const Color(0xFF3A4D57) : const Color(0xFF8A4A0E);
    final gold = locked ? const Color(0xFF7A8F9A) : const Color(0xFFFFC800);
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(12, 46, 76, 40),
      const Radius.circular(8),
    );
    canvas.drawRRect(body, Paint()..color = woodDark);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(12, 46, 76, 32), const Radius.circular(8)),
      Paint()..color = wood,
    );
    final lidTop = open ? 14.0 : 24.0;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(12, lidTop, 76, 26),
        topLeft: const Radius.circular(24),
        topRight: const Radius.circular(24),
        bottomLeft: const Radius.circular(4),
        bottomRight: const Radius.circular(4),
      ),
      Paint()..color = wood,
    );
    final band = Paint()..color = gold;
    canvas.drawRect(Rect.fromLTWH(22, lidTop + 2, 8, 70 - lidTop), band);
    canvas.drawRect(Rect.fromLTWH(70, lidTop + 2, 8, 70 - lidTop), band);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(41, 54, 18, 18), const Radius.circular(5)),
      band,
    );
    canvas.drawCircle(const Offset(50, 62), 3, Paint()..color = woodDark);
    if (open) {
      canvas.drawOval(
        const Rect.fromLTWH(22, 38, 56, 12),
        Paint()..color = const Color(0xFFFFE680),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ChestPainter old) =>
      old.open != open || old.locked != locked;
}
