import 'dart:math';

import 'package:flutter/material.dart';

import '../data/course_model.dart';
import '../core/theme.dart';

extension WhoInfo on Who {
  String displayName(bool english) => switch (this) {
    Who.sergei => english ? 'Sergei' : 'Сергей',
    Who.maria => english ? 'Maria' : 'Мария',
  };

  Color get color => switch (this) {
    Who.sergei => const Color(0xFF7BC96F),
    Who.maria => const Color(0xFFFF86D0),
  };

  Color get backdrop => switch (this) {
    Who.sergei => const Color(0xFF2E4A36),
    Who.maria => const Color(0xFF4B2F45),
  };
}

/// Which artwork shows a given emotion. Missing expressions fall back to the
/// closest one that exists in the sprite sheet.
String characterAsset(Who who, Emotion emotion) {
  final name = who == Who.sergei ? 'sergei' : 'maria';
  final available = who == Who.sergei
      ? const {
          Emotion.neutral: 'neutral',
          Emotion.happy: 'happy',
          Emotion.angry: 'angry',
          Emotion.surprised: 'surprised',
          Emotion.thinking: 'thinking',
          Emotion.smug: 'smug',
        }
      : const {
          Emotion.neutral: 'neutral',
          Emotion.happy: 'happy',
          Emotion.angry: 'angry',
          Emotion.sad: 'sad',
          Emotion.thinking: 'thinking',
          Emotion.smug: 'smug',
        };
  final fallback = switch (emotion) {
    Emotion.sad => Emotion.thinking, // Sergei has no sad face
    Emotion.surprised => Emotion.neutral, // Maria has no surprised face
    _ => Emotion.neutral,
  };
  final key = available[emotion] ?? available[fallback] ?? 'neutral';
  return 'assets/characters/${name}_$key.png';
}

/// A character bust that pops when the emotion changes and gently breathes.
class CharacterBust extends StatelessWidget {
  const CharacterBust({
    required this.who,
    required this.emotion,
    this.height = 110,
    this.idle = true,
    this.flip = false,
    super.key,
  });

  final Who who;
  final Emotion emotion;
  final double height;
  final bool idle;
  final bool flip;

  @override
  Widget build(BuildContext context) {
    final image = AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.bottomCenter,
        children: [...previous, if (current != null) current],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          alignment: Alignment.bottomCenter,
          scale: Tween<double>(begin: 0.82, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: Image.asset(
        characterAsset(who, emotion),
        key: ValueKey('${who.name}-${emotion.name}'),
        height: height,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        filterQuality: FilterQuality.high,
        semanticLabel: who.displayName(false),
      ),
    );
    final framed = SizedBox(
      width: height * 0.92,
      height: height,
      child: Transform.flip(flipX: flip, child: image),
    );
    return idle ? _Breathing(child: framed) : framed;
  }
}

class _Breathing extends StatefulWidget {
  const _Breathing({required this.child});

  final Widget child;

  @override
  State<_Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<_Breathing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final wave = sin(_controller.value * 2 * pi);
        return Transform.scale(
          alignment: Alignment.bottomCenter,
          scaleY: 1 + wave * 0.012,
          scaleX: 1 - wave * 0.006,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Round framed portrait (chat lines, profile, lists).
class CharacterAvatar extends StatelessWidget {
  const CharacterAvatar({
    required this.who,
    required this.emotion,
    this.size = 56,
    super.key,
  });

  final Who who;
  final Emotion emotion;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: who.backdrop,
      shape: BoxShape.circle,
      border: Border.all(color: who.color.withValues(alpha: 0.7), width: 2),
    ),
    clipBehavior: Clip.antiAlias,
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutBack,
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: Align(
        key: ValueKey('${who.name}-${emotion.name}'),
        alignment: Alignment.bottomCenter,
        child: Transform.scale(
          scale: 1.18,
          alignment: Alignment.bottomCenter,
          child: Image.asset(
            characterAsset(who, emotion),
            height: size,
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    ),
  );
}

/// Avatar that can be the player's own: a character or a coloured initial.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    required this.avatar,
    required this.name,
    this.size = 44,
    super.key,
  });

  final String avatar;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (avatar == 'sergei' || avatar == 'maria') {
      return CharacterAvatar(
        who: avatar == 'sergei' ? Who.sergei : Who.maria,
        emotion: Emotion.happy,
        size: size,
      );
    }
    return InitialAvatar(name: name, size: size);
  }
}

class InitialAvatar extends StatelessWidget {
  const InitialAvatar({required this.name, this.size = 44, super.key});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    const colors = [
      DuoColors.blue,
      DuoColors.purple,
      DuoColors.orange,
      DuoColors.pink,
      DuoColors.teal,
      DuoColors.yellow,
    ];
    final seed = name.codeUnits.fold<int>(0, (a, b) => a + b);
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors[seed % colors.length],
        shape: BoxShape.circle,
      ),
      child: Text(
        letter,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.45,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
