import 'package:flutter/material.dart';

/// Set this to a bundled font family (for example 'Nunito' or 'DIN Round')
/// after adding the font under `flutter: fonts:` in pubspec.yaml.
const String? kFontFamily = null;

/// Duolingo-like dark palette. Every colour used in the app lives here.
abstract final class DuoColors {
  static const bg = Color(0xFF131F24);
  static const panel = Color(0xFF1B2A31);
  static const panelHigh = Color(0xFF22343C);
  static const border = Color(0xFF37464F);
  static const text = Color(0xFFF1F7FB);
  static const muted = Color(0xFF8FA3AE);
  static const locked = Color(0xFF3A4D57);
  static const lockedDepth = Color(0xFF2A3A43);

  static const green = Color(0xFF58CC02);
  static const greenDepth = Color(0xFF46A302);
  static const greenSoft = Color(0xFF89E219);
  static const blue = Color(0xFF1CB0F6);
  static const blueDepth = Color(0xFF1899D6);
  static const red = Color(0xFFFF4B4B);
  static const redDepth = Color(0xFFEA2B2B);
  static const orange = Color(0xFFFF9600);
  static const orangeDepth = Color(0xFFCC7900);
  static const yellow = Color(0xFFFFC800);
  static const yellowDepth = Color(0xFFCE9700);
  static const purple = Color(0xFFCE82FF);
  static const purpleDepth = Color(0xFFA568CC);
  static const pink = Color(0xFFFF86D0);
  static const pinkDepth = Color(0xFFD869AF);
  static const teal = Color(0xFF00CD9C);
  static const tealDepth = Color(0xFF00A47C);

  static const correctBg = Color(0xFF1F3A12);
  static const wrongBg = Color(0xFF3D1A1C);
}

/// A face colour plus its darker "depth" edge.
class DuoTone {
  const DuoTone(this.face, this.depth);

  final Color face;
  final Color depth;
}

/// One tone per course unit (cycles when there are more units than tones).
const List<DuoTone> unitTones = [
  DuoTone(DuoColors.teal, DuoColors.tealDepth),
  DuoTone(DuoColors.blue, DuoColors.blueDepth),
  DuoTone(DuoColors.purple, DuoColors.purpleDepth),
  DuoTone(DuoColors.orange, DuoColors.orangeDepth),
  DuoTone(DuoColors.red, DuoColors.redDepth),
  DuoTone(DuoColors.pink, DuoColors.pinkDepth),
];

abstract final class DuoText {
  static const h1 = TextStyle(
    color: DuoColors.text,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );
  static const h2 = TextStyle(
    color: DuoColors.text,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    height: 1.25,
  );
  static const body = TextStyle(
    color: DuoColors.text,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );
  static const small = TextStyle(
    color: DuoColors.muted,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  static const label = TextStyle(
    color: DuoColors.muted,
    fontSize: 13,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.9,
  );
}

ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    primary: DuoColors.green,
    onPrimary: Colors.white,
    secondary: DuoColors.blue,
    surface: DuoColors.panel,
    onSurface: DuoColors.text,
    error: DuoColors.red,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: DuoColors.bg,
    canvasColor: DuoColors.bg,
    fontFamily: kFontFamily,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: DuoColors.blue,
      selectionColor: Color(0x551CB0F6),
    ),
    dividerColor: DuoColors.border,
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: DuoColors.panelHigh,
      contentTextStyle: DuoText.body,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: DuoColors.panel,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
  );
}

/// Soft fade + slide-up route used for lessons and games.
Route<T> duoRoute<T>(Widget page) => PageRouteBuilder<T>(
  transitionDuration: const Duration(milliseconds: 320),
  reverseTransitionDuration: const Duration(milliseconds: 220),
  pageBuilder: (context, animation, secondary) => page,
  transitionsBuilder: (context, animation, secondary, child) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  },
);
