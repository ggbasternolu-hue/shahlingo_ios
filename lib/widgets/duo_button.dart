import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';

enum DuoButtonKind { green, blue, red, orange, outline }

/// Chunky 3D button: a face that sinks into its depth edge when pressed.
class DuoButton extends StatefulWidget {
  const DuoButton({
    required this.label,
    required this.onPressed,
    this.kind = DuoButtonKind.green,
    this.icon,
    this.height = 52,
    this.expanded = true,
    this.tone,
    this.textColor,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final DuoButtonKind kind;
  final IconData? icon;
  final double height;
  final bool expanded;

  /// Overrides the colours (used for unit-coloured buttons).
  final DuoTone? tone;

  /// Overrides the label colour (for example dark text on a white button).
  final Color? textColor;

  @override
  State<DuoButton> createState() => _DuoButtonState();
}

class _DuoButtonState extends State<DuoButton> {
  bool _down = false;

  static const double _depth = 4;

  (Color face, Color edge, Color text, Color? border) _palette() {
    if (widget.onPressed == null) {
      return (
        DuoColors.locked,
        DuoColors.lockedDepth,
        const Color(0xFF6C818C),
        null,
      );
    }
    final tone = widget.tone;
    if (tone != null) {
      return (tone.face, tone.depth, widget.textColor ?? Colors.white, null);
    }
    return switch (widget.kind) {
      DuoButtonKind.green => (
        DuoColors.green,
        DuoColors.greenDepth,
        Colors.white,
        null,
      ),
      DuoButtonKind.blue => (
        DuoColors.blue,
        DuoColors.blueDepth,
        Colors.white,
        null,
      ),
      DuoButtonKind.red => (
        DuoColors.red,
        DuoColors.redDepth,
        Colors.white,
        null,
      ),
      DuoButtonKind.orange => (
        DuoColors.orange,
        DuoColors.orangeDepth,
        Colors.white,
        null,
      ),
      DuoButtonKind.outline => (
        DuoColors.bg,
        DuoColors.border,
        DuoColors.blue,
        DuoColors.border,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final (face, edge, textColor, border) = _palette();
    final radius = BorderRadius.circular(16);
    final pressed = _down && enabled;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, color: textColor, size: 22),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            widget.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );

    final button = Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _down = true) : null,
          onTapCancel: enabled ? () => setState(() => _down = false) : null,
          onTapUp: enabled ? (_) => setState(() => _down = false) : null,
          onTap: enabled
              ? () {
                  HapticFeedback.lightImpact();
                  widget.onPressed!();
                }
              : null,
          child: SizedBox(
            height: widget.height + _depth,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: widget.height,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: edge,
                      borderRadius: radius,
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 70),
                  curve: Curves.easeOut,
                  left: 0,
                  right: 0,
                  top: pressed ? _depth : 0,
                  height: widget.height,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: face,
                      borderRadius: radius,
                      border: border == null
                          ? null
                          : Border.all(color: border, width: 2),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: content,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return widget.expanded ? button : SizedBox(width: 220, child: button);
  }
}
