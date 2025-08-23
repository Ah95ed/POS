import 'package:flutter/material.dart';

/// أدوات مساعدة للأجهزة
class DeviceUtils {
  /// التحقق من كون الجهاز هاتف محمول
  static bool isMobile(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < 600;
  }

  /// التحقق من كون الجهاز تابلت
  static bool isTablet(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth >= 600 && screenWidth < 1200;
  }

  /// التحقق من كون الجهاز سطح مكتب
  static bool isDesktop(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth >= 1200;
  }

  /// اختيار قيمة حسب نوع الجهاز
  static T valueDecider<T>(
    BuildContext context, {
    required T onMobile,
    required T onTablet,
    required T onDesktop,
  }) {
    if (isMobile(context)) {
      return onMobile;
    } else if (isTablet(context)) {
      return onTablet;
    } else {
      return onDesktop;
    }
  }

  /// الحصول على نوع الجهاز كنص
  static String getDeviceType(BuildContext context) {
    if (isMobile(context)) {
      return 'mobile';
    } else if (isTablet(context)) {
      return 'tablet';
    } else {
      return 'desktop';
    }
  }

  /// الحصول على عدد الأعمدة المناسب للشبكة
  static int getGridCrossAxisCount(
    BuildContext context, {
    int mobileColumns = 2,
    int tabletColumns = 3,
    int desktopColumns = 4,
  }) {
    return valueDecider(
      context,
      onMobile: mobileColumns,
      onTablet: tabletColumns,
      onDesktop: desktopColumns,
    );
  }

  /// الحصول على المساحة المناسبة للحشو
  static EdgeInsets getResponsivePadding(BuildContext context) {
    return valueDecider(
      context,
      onMobile: const EdgeInsets.all(8.0),
      onTablet: const EdgeInsets.all(16.0),
      onDesktop: const EdgeInsets.all(24.0),
    );
  }

  /// الحصول على حجم الخط المناسب
  static double getResponsiveFontSize(
    BuildContext context, {
    double mobileSize = 14.0,
    double tabletSize = 16.0,
    double desktopSize = 18.0,
  }) {
    return valueDecider(
      context,
      onMobile: mobileSize,
      onTablet: tabletSize,
      onDesktop: desktopSize,
    );
  }
}
