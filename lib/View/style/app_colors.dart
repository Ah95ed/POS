import 'package:flutter/material.dart';
import 'package:pos/Helper/Service/Service.dart';

class AppColors {
  // Light Theme Colors
    static bool get isDark => shared.getBool('access_isDarkMode') ?? false;

  // Light theme colors
  static final Color lightBackground = Colors.white;
  static final Color lightCurveTop1 = const Color(0xFFB2DFDB);
  static final Color lightCurveTop2 = const Color(0xFFE0F7FA);
  static final Color lightCurveBottom1 = const Color(0xFFE0F2F1);
  static final Color lightCurveBottom2 = const Color(0xFFB2DFDB);
  static final Color lightCard = Colors.white;
  static final Color lightShadow = Colors.teal;
  static final Color lightAccent = const Color(0xFF80CBC4);
  static final Color lightTextMain = const Color.fromARGB(255, 25, 41, 49);
  static final Color lightSliderActive = Colors.teal;

  // Dark theme colors
  static final Color darkBackground = Color(0xFF121212);
  static final Color darkCurveTop1 = const Color.fromARGB(255, 91, 88, 88);
  static final Color darkCurveTop2 = const Color.fromARGB(255, 91, 88, 88);
  static final Color darkCurveBottom1 = const Color.fromARGB(255, 91, 88, 88);
  static final Color darkCurveBottom2 = const Color.fromARGB(255, 91, 88, 88);
  static final Color darkCard = const Color.fromARGB(255, 70, 66, 66);
  static final Color darkShadow = Colors.tealAccent;
  static final Color darkAccent = Colors.tealAccent;
  static final Color darkTextMain = Colors.white;
  static final Color darkSliderActive = Colors.tealAccent;

  // Current theme accessors
  static Color get background => isDark ? darkBackground : lightBackground;
  static Color get curveTop1 => isDark ? darkCurveTop1 : lightCurveTop1;
  static Color get curveTop2 => isDark ? darkCurveTop2 : lightCurveTop2;
  static Color get curveBottom1 =>
      isDark ? darkCurveBottom1 : lightCurveBottom1;
  static Color get curveBottom2 =>
      isDark ? darkCurveBottom2 : lightCurveBottom2;
  static Color get card => isDark ? darkCard : lightCard;
  static Color get shadow => isDark ? darkShadow : lightShadow;
  static Color get accent => isDark ? darkAccent : lightAccent;
  static Color get textMain => isDark ? darkTextMain : lightTextMain;
  static Color get sliderActive =>
      isDark ? darkSliderActive : lightSliderActive;

}
