import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Reveals text letter by letter without moving the layout (the unrevealed
/// part is laid out but transparent).
class TypewriterText extends StatefulWidget {
  const TypewriterText(
    this.text, {
    this.style = DuoText.body,
    this.msPerChar = 14,
    super.key,
  });

  final String text;
  final TextStyle style;
  final int msPerChar;

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  Duration get _duration =>
      Duration(milliseconds: (widget.text.length * widget.msPerChar).clamp(1, 4000));

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration)
      ..forward();
  }

  @override
  void didUpdateWidget(covariant TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller.duration = _duration;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Text(widget.text, style: widget.style);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final count = (widget.text.length * _controller.value).floor();
        return Text.rich(
          TextSpan(
            style: widget.style,
            children: [
              TextSpan(text: widget.text.substring(0, count)),
              TextSpan(
                text: widget.text.substring(count),
                style: const TextStyle(color: Colors.transparent),
              ),
            ],
          ),
        );
      },
    );
  }
}
