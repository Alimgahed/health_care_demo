import 'package:flutter/material.dart';

/// Shared layout values for operational and patient experiences.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
}

abstract final class AppRadius {
  static const double control = 8;
  static const double card = 12;
  static const double panel = 16;
  static const double pill = 100;
}

abstract final class AppLayout {
  static const double desktopSidebar = 240;
  static const double desktopBreakpoint = 1100;
  static const double tabletBreakpoint = 720;
  static const double contentMaxWidth = 1440;
  static const double minTouchTarget = 48;

  static EdgeInsets pagePadding(double width) => EdgeInsets.symmetric(
    horizontal: width < tabletBreakpoint ? AppSpacing.md : AppSpacing.xl,
    vertical: width < tabletBreakpoint ? AppSpacing.md : AppSpacing.xl,
  );
}
