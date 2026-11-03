import 'package:flutter/material.dart';

/// Scales + fades its child in after an optional delay.
class PopIn extends StatefulWidget {
  const PopIn({
    required this.child,
    this.delay = Duration.zero,
    this.curve = Curves.elasticOut,
    super.key,
  });

  final Widget child;
  final Duration delay;
  final Curve curve;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) {
      final t = widget.curve.transform(_controller.value);
      return Opacity(
        opacity: (_controller.value * 3).clamp(0.0, 1.0),
        child: Transform.scale(scale: t.clamp(0.0, 1.4), child: child),
      );
    },
    child: widget.child,
  );
}
