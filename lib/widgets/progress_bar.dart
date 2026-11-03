import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Duolingo-style rounded bar with a glossy stripe that fills smoothly.
class DuoProgressBar extends StatelessWidget {
  const DuoProgressBar({
    required this.value,
    this.color = DuoColors.green,
    this.height = 16,
    super.key,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: value.clamp(0.0, 1.0)),
    duration: const Duration(milliseconds: 550),
    curve: Curves.easeOutCubic,
    builder: (context, animated, _) => ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: DuoColors.border)),
            FractionallySizedBox(
              widthFactor: animated,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(height),
                ),
                alignment: Alignment.topCenter,
                padding: EdgeInsets.only(
                  top: height * 0.22,
                  left: height * 0.4,
                  right: height * 0.4,
                ),
                child: animated < 0.04
                    ? null
                    : Container(
                        height: height * 0.26,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(height),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
