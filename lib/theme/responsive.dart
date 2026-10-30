import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Small helper that keeps every screen proportional on any device.
///
/// All design values were drawn at a 390dp-wide reference phone, so every
/// hard-coded number is passed through [ResponsiveContext.rp] before use.
/// The scale is derived from the shortest side and clamped, so a tablet or a
/// landscape phone gets slightly larger content rather than a blown-up one.
class Responsive {
  const Responsive._();

  static const double baseWidth = 390;

  /// Content never grows wider than this, so tablets stay readable.
  static const double maxContentWidth = 560;

  static double scaleOf(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final double shortest = math.min(size.width, size.height);
    return (shortest / baseWidth).clamp(0.80, 1.25);
  }

  static double contentWidth(BuildContext context) {
    return math.min(MediaQuery.sizeOf(context).width, maxContentWidth);
  }
}

extension ResponsiveContext on BuildContext {
  /// Scale a design value to the current device.
  double rp(double value) => value * Responsive.scaleOf(this);

  /// True on very narrow phones, where labels and paddings get tighter.
  bool get isCompact => MediaQuery.sizeOf(this).width < 360;
}
