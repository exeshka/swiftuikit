import 'package:flutter/material.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

import 'swift_ui_encoders.dart';

part 'swift_ui_metrics.tailor.dart';

/// Sizes, radii and insets (logical px).
@tailorMixinComponent
@DoubleEncoder()
class SwiftUiMetrics extends ThemeExtension<SwiftUiMetrics>
    with _$SwiftUiMetricsTailorMixin {
  const SwiftUiMetrics({
    this.circleButtonSize = 44,
    this.avatarSize = 48,
    this.pillHeight = 48,
    this.barHeight = 52,
    this.pageInset = 20,
    this.rowHeight = 49,
    this.pillRadius = 999,
    this.cardRadius = 28,
  });

  @override
  final double circleButtonSize;
  @override
  final double avatarSize;
  @override
  final double pillHeight;

  /// Height of a navigation bar.
  @override
  final double barHeight;

  /// Horizontal page margin.
  @override
  final double pageInset;
  @override
  final double rowHeight;
  @override
  final double pillRadius;
  @override
  final double cardRadius;
}
