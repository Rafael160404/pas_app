import 'package:flutter/material.dart';

class ResponsiveHelper {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  static double getFontSize(BuildContext context, {double mobile = 14, double tablet = 16, double desktop = 18}) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }

  static EdgeInsets getPadding(BuildContext context) {
    if (isDesktop(context)) return const EdgeInsets.all(24);
    if (isTablet(context)) return const EdgeInsets.all(16);
    return const EdgeInsets.all(12);
  }

  static double getWidth(BuildContext context, {double mobileFactor = 0.9, double tabletFactor = 0.7, double desktopFactor = 0.5}) {
    final width = MediaQuery.of(context).size.width;
    if (isDesktop(context)) return width * desktopFactor;
    if (isTablet(context)) return width * tabletFactor;
    return width * mobileFactor;
  }
}