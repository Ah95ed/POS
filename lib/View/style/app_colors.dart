import 'package:flutter/material.dart';
import 'package:pos/Helper/Service/Service.dart';

class AppColors {
  // Persisted dark-mode flag (via SharedPreferences)
  static bool get isDark => shared.getBool('access_isDarkMode') ?? false;

  // ===== Light palette (modern, high-contrast but calm) =====
  static final Color lightBackground = const Color(
    0xFFF7F8FA,
  ); // subtle off-white
  static final Color lightCard = const Color(0xFFFFFFFF); // pure white cards
  static final Color lightAccent = const Color(0xFF0EA5A5); // teal/cyan 600
  static final Color lightTextMain = const Color(0xFF1F2937); // slate 800
  static final Color lightShadow = const Color(0x14000000); // 8% black

  // Soft gradients for decorative curves
  static final Color lightCurveTop1 = const Color(0xFFE6FFFA); // mint
  static final Color lightCurveTop2 = const Color(0xFFD1FAE5); // emerald 100
  static final Color lightCurveBottom1 = const Color(0xFFEFF6FF); // indigo 50
  static final Color lightCurveBottom2 = const Color(0xFFDBEAFE); // indigo 100

  static final Color lightSliderActive = lightAccent;

  // Semantic colors (light)
  static final Color lightSuccess = const Color(0xFF10B981); // emerald 500
  static final Color lightWarning = const Color(0xFFF59E0B); // amber 500
  static final Color lightError = const Color(0xFFEF4444); // red 500

  // ===== Dark palette (balanced, comfortable for eyes) =====
  static final Color darkBackground = const Color(0xFF0F172A); // slate 900
  static final Color darkCard = const Color(0xFF111827); // gray 900
  static final Color darkAccent = const Color(0xFF22D3EE); // cyan 400
  static final Color darkTextMain = const Color(0xFFE5E7EB); // gray 200
  static final Color darkShadow = const Color(0x66000000); // 40% black

  // Soft gradients for decorative curves (dark)
  static final Color darkCurveTop1 = const Color(0xFF0B1220);
  static final Color darkCurveTop2 = const Color(0xFF0E1626);
  static final Color darkCurveBottom1 = const Color(0xFF111827);
  static final Color darkCurveBottom2 = const Color(0xFF1F2937);

  static final Color darkSliderActive = darkAccent;

  // Semantic colors (dark)
  static final Color darkSuccess = const Color(0xFF34D399); // emerald 400
  static final Color darkWarning = const Color(0xFFFBBF24); // amber 400
  static final Color darkError = const Color(0xFFF87171); // red 400

  // ===== Accessors used across UI =====
  static Color get background => isDark ? darkBackground : lightBackground;
  static Color get card => isDark ? darkCard : lightCard;
  static Color get accent => isDark ? darkAccent : lightAccent;
  static Color get textMain => isDark ? darkTextMain : lightTextMain;
  static Color get shadow => isDark ? darkShadow : lightShadow;

  static Color get curveTop1 => isDark ? darkCurveTop1 : lightCurveTop1;
  static Color get curveTop2 => isDark ? darkCurveTop2 : lightCurveTop2;
  static Color get curveBottom1 =>
      isDark ? darkCurveBottom1 : lightCurveBottom1;
  static Color get curveBottom2 =>
      isDark ? darkCurveBottom2 : lightCurveBottom2;

  static Color get sliderActive =>
      isDark ? darkSliderActive : lightSliderActive;

  // Semantic getters
  static Color get success => isDark ? darkSuccess : lightSuccess;
  static Color get warning => isDark ? darkWarning : lightWarning;
  static Color get error => isDark ? darkError : lightError;

  // Helpers for dividers/borders that adapt to theme
  static Color get divider => textMain.withOpacity(0.12);
  static Color get border => textMain.withOpacity(0.08);
}
