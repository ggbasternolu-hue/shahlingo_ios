import 'dart:math';

import 'package:flutter/material.dart';

import '../../chess/piece_painter.dart';
import '../../core/theme.dart';
import '../../data/course_model.dart';
import '../../widgets/common.dart';

IconData lessonIcon(String key) => switch (key) {
  'grid' => Icons.grid_view_rounded,
  'swap' => Icons.swap_horiz_rounded,
  'check' => Icons.priority_high_rounded,
  'mate' => Icons.emoji_events_rounded,
  'castle' => Icons.shield_rounded,
  'promo' => Icons.workspace_premium_rounded,
  'ep' => Icons.compare_arrows_rounded,
  'fork' => Icons.call_split_rounded,
  'pin' => Icons.push_pin_rounded,
  'mate1' => Icons.looks_one_rounded,
  'open' => Icons.flag_rounded,
  'trap' => Icons.warning_amber_rounded,
  'game' => Icons.sports_esports_rounded,
  _ => Icons.star_rounded,
};

const _pieceKeys = {'p', 'n', 'b', 'r', 'q', 'k'};

enum NodeState { locked, current, done }

/// A round 3D lesson node with the lesson icon, optional pulse and stars.
class LessonNode extends StatelessWidget {
  const LessonNode({
    required this.lesson,
    required this.state,
    required this.tone,
    required this.stars,
    required this.onTap,
    super.key,
  });

  final Lesson lesson;
  final NodeState state;
  final DuoTone tone;
  final int stars;
  final VoidCallback onTap;

  static const double size = 78;
  static const double depth = 8;

  @override
  Widget build(BuildContext context) {
    final locked = state == NodeState.locked;
    final face = locked ? DuoColors.locked : tone.face;
    final edge = locked ? DuoColors.lockedDepth : tone.depth;
    final isPiece = _pieceKeys.contains(lesson.icon);

    final icon = isPiece
        ? Opacity(
            opacity: locked ? 0.45 : 1,
            child: PieceView(pieceKey: lesson.icon, isWhite: true, size: 46),
          )
        : Icon(
            lessonIcon(lesson.icon),
            size: 38,
            color: locked ? const Color(0xFF7E919B) : Colors.white,
          );

    Widget disk = _PressDisk(
      face: face,
      edge: edge,
      onTap: onTap,
      child: icon,
    );
    if (state == NodeState.current) {
      disk = _PulseRing(color: tone.face, child: disk);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state == NodeState.current)
          _StartBadge(tone: tone)
        else
          const SizedBox(height: 0),
        disk,
        SizedBox(
          height: 22,
          child: state == NodeState.done
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Icon(
                        Icons.star_rounded,
                        size: 17,
                        color: i < stars ? DuoColors.yellow : DuoColors.border,
                      ),
                  ],
                )
              : null,
        ),
      ],
    );
  }
}

class _PressDisk extends StatefulWidget {
  const _PressDisk({
    required this.face,
    required this.edge,
    required this.onTap,
    required this.child,
  });

  final Color face;
  final Color edge;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_PressDisk> createState() => _PressDiskState();
}

class _PressDiskState extends State<_PressDisk> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    const size = LessonNode.size;
    const depth = LessonNode.depth;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: SizedBox(
        width: size,
        height: size + depth,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              bottom: 0,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(color: widget.edge, shape: BoxShape.circle),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 80),
              left: 0,
              top: _down ? depth : 0,
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: widget.face, shape: BoxShape.circle),
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseRing extends StatefulWidget {
  const _PulseRing({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    alignment: Alignment.center,
    children: [
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        height: LessonNode.size,
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = Curves.easeOut.transform(_controller.value);
              return OverflowBox(
                maxWidth: 160,
                maxHeight: 160,
                child: Center(
                  child: Opacity(
                    opacity: (1 - t) * 0.7,
                    child: Container(
                      width: LessonNode.size + 34 * t,
                      height: LessonNode.size + 34 * t,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: widget.color, width: 4),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      widget.child,
    ],
  );
}

class _StartBadge extends StatefulWidget {
  const _StartBadge({required this.tone});

  final DuoTone tone;

  @override
  State<_StartBadge> createState() => _StartBadgeState();
}

class _StartBadgeState extends State<_StartBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) => Transform.translate(
      offset: Offset(0, -5 * Curves.easeInOut.transform(_controller.value)),
      child: child,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: DuoColors.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DuoColors.border, width: 2),
          ),
          child: Text(
            'НАЧАТЬ',
            style: TextStyle(
              color: widget.tone.face,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        CustomPaint(size: const Size(18, 9), painter: _ArrowPainter()),
        const SizedBox(height: 4),
      ],
    ),
  );
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = DuoColors.bg);
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..color = DuoColors.border,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum ChestState { locked, ready, opened }

class ChestNode extends StatefulWidget {
  const ChestNode({required this.state, required this.onTap, super.key});

  final ChestState state;
  final VoidCallback onTap;

  @override
  State<ChestNode> createState() => _ChestNodeState();
}

class _ChestNodeState extends State<ChestNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _sync();
  }

  @override
  void didUpdateWidget(covariant ChestNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (widget.state == ChestState.ready) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: widget.onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_controller.value);
          return Transform.translate(
            offset: Offset(0, -6 * t),
            child: Transform.rotate(angle: sin(t * pi) * 0.06, child: child),
          );
        },
        child: ChestIcon(
          size: 72,
          open: widget.state == ChestState.opened,
          locked: widget.state == ChestState.locked,
        ),
      ),
    ),
  );
}
