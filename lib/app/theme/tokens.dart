import 'dart:math';

import 'package:flutter/material.dart';

class AppColors {
  // Dawn (light)
  static const bgDawn = Color(0xFFFBF4EC);
  static const bgGradientADawn = Color(0xFFFFE9D6);
  static const bgGradientBDawn = Color(0xFFE9E0FF);
  static const surfaceDawn = Color(0xB3FFFFFF); // 72%
  static const surfaceAltDawn = Color(0xFFF3E8DD);
  static const inkDawn = Color(0xFF3B3548);
  static const inkSoftDawn = Color(0xFF6E6780);
  static const lineDawn = Color(0xFFE6DACB);
  static const accentDawn = Color(0xFF8E7CC3);
  static const accent2Dawn = Color(0xFFF2A488);
  static const successDawn = Color(0xFF7FB89A);
  static const dangerDawn = Color(0xFFD98A8A);

  // Dusk (dark)
  static const bgDusk = Color(0xFF1C1A2B);
  static const bgGradientADusk = Color(0xFF232042);
  static const bgGradientBDusk = Color(0xFF171527);
  static const surfaceDusk = Color(0xCC2A2744); // 80%
  static const surfaceAltDusk = Color(0xFF34304F);
  static const inkDusk = Color(0xFFEDE8F7);
  static const inkSoftDusk = Color(0xFFA9A3BF);
  static const lineDusk = Color(0xFF3C3858);
  static const accentDusk = Color(0xFFB3A1F0);
  static const accent2Dusk = Color(0xFFF0B08F);
  static const successDusk = Color(0xFF8FD1AB);
  static const dangerDusk = Color(0xFFE5A0A0);

  // Moonlit (low-stimulation)
  static const bgMoonlit = Color(0xFF0F0E16);
  static const bgGradientAMoonlit = Color(0xFF14121C);
  static const bgGradientBMoonlit = Color(0xFF0C0B12);
  static const surfaceMoonlit = Color(0xE6181622); // 90%
  static const surfaceAltMoonlit = Color(0xFF1E1B2A);
  static const inkMoonlit = Color(0xFFCFC8DD);
  static const inkSoftMoonlit = Color(0xFF8E88A3);
  static const lineMoonlit = Color(0xFF262333);
  static const accentMoonlit = Color(0xFF8F83B8);
  static const accent2Moonlit = Color(0xFFB08C7E);
  static const successMoonlit = Color(0xFF6E9C86);
  static const dangerMoonlit = Color(0xFFA87878);
}

enum AppThemeMode { auto, dawn, dusk, moonlit }

class ThemeColors {
  final Color bg;
  final Color bgGradientA;
  final Color bgGradientB;
  final Color surface;
  final Color surfaceAlt;
  final Color ink;
  final Color inkSoft;
  final Color line;
  final Color accent;
  final Color accent2;
  final Color success;
  final Color danger;

  const ThemeColors({
    required this.bg,
    required this.bgGradientA,
    required this.bgGradientB,
    required this.surface,
    required this.surfaceAlt,
    required this.ink,
    required this.inkSoft,
    required this.line,
    required this.accent,
    required this.accent2,
    required this.success,
    required this.danger,
  });

  static ThemeColors dawn() => const ThemeColors(
    bg: AppColors.bgDawn,
    bgGradientA: AppColors.bgGradientADawn,
    bgGradientB: AppColors.bgGradientBDawn,
    surface: AppColors.surfaceDawn,
    surfaceAlt: AppColors.surfaceAltDawn,
    ink: AppColors.inkDawn,
    inkSoft: AppColors.inkSoftDawn,
    line: AppColors.lineDawn,
    accent: AppColors.accentDawn,
    accent2: AppColors.accent2Dawn,
    success: AppColors.successDawn,
    danger: AppColors.dangerDawn,
  );

  static ThemeColors dusk() => const ThemeColors(
    bg: AppColors.bgDusk,
    bgGradientA: AppColors.bgGradientADusk,
    bgGradientB: AppColors.bgGradientBDusk,
    surface: AppColors.surfaceDusk,
    surfaceAlt: AppColors.surfaceAltDusk,
    ink: AppColors.inkDusk,
    inkSoft: AppColors.inkSoftDusk,
    line: AppColors.lineDusk,
    accent: AppColors.accentDusk,
    accent2: AppColors.accent2Dusk,
    success: AppColors.successDusk,
    danger: AppColors.dangerDusk,
  );

  static ThemeColors moonlit() => const ThemeColors(
    bg: AppColors.bgMoonlit,
    bgGradientA: AppColors.bgGradientAMoonlit,
    bgGradientB: AppColors.bgGradientBMoonlit,
    surface: AppColors.surfaceMoonlit,
    surfaceAlt: AppColors.surfaceAltMoonlit,
    ink: AppColors.inkMoonlit,
    inkSoft: AppColors.inkSoftMoonlit,
    line: AppColors.lineMoonlit,
    accent: AppColors.accentMoonlit,
    accent2: AppColors.accent2Moonlit,
    success: AppColors.successMoonlit,
    danger: AppColors.dangerMoonlit,
  );

  ThemeColors lerp(ThemeColors other, double t) => ThemeColors(
    bg: Color.lerp(bg, other.bg, t)!,
    bgGradientA: Color.lerp(bgGradientA, other.bgGradientA, t)!,
    bgGradientB: Color.lerp(bgGradientB, other.bgGradientB, t)!,
    surface: Color.lerp(surface, other.surface, t)!,
    surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
    ink: Color.lerp(ink, other.ink, t)!,
    inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
    line: Color.lerp(line, other.line, t)!,
    accent: Color.lerp(accent, other.accent, t)!,
    accent2: Color.lerp(accent2, other.accent2, t)!,
    success: Color.lerp(success, other.success, t)!,
    danger: Color.lerp(danger, other.danger, t)!,
  );
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
  static const screenPadding = 20.0;
  static const minTouchTarget = 48.0;
}

class AppRadii {
  static const chip = 12.0;
  static const card = 24.0;
  static const sheet = 28.0;
  static const pill = 999.0;
  static const gameGlass = 20.0;
}

class AppElevation {
  static BoxShadow get cardShadow => BoxShadow(
    color: Color(0x143B3548), // ink @ 8%
    blurRadius: 24,
    offset: Offset(0, 8),
  );
  static BoxShadow get pressedShadow => BoxShadow(
    color: Color(0x1F3B3548), // ink @ 12%
    blurRadius: 12,
    offset: Offset(0, 4),
  );
  static const glassBlur = 18.0;
}

class AppMotion {
  static const instant = Duration(milliseconds: 90);
  static const fast = Duration(milliseconds: 160);
  static const base = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 480);
  static const ambient = Duration(milliseconds: 900);
  static const breathe = Duration(milliseconds: 4000);

  static const calmOut = Cubic(0.16, 1.0, 0.3, 1.0);
  static const calmInOut = Cubic(0.65, 0.0, 0.35, 1.0);
  static const softIn = Cubic(0.32, 0.0, 0.67, 0.0);
}

class AppSprings {
  // mass = 1; z = c / (2 * sqrt(k * m))
  static const uiSpring = SpringConfig(k: 260, c: 26); // z = 0.81
  static const bouncy = SpringConfig(k: 180, c: 14); // z = 0.52
  static const float = SpringConfig(k: 90, c: 18); // z = 0.95
  static const heavy = SpringConfig(k: 60, c: 16); // z = 1.03
}

class SpringConfig {
  final double k;
  final double c;
  final double m = 1.0;

  const SpringConfig({required this.k, required this.c});

  double get z => c / (2 * sqrt(k * m));
}
