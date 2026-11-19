import 'package:flutter/material.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

import 'swift_ui_encoders.dart';

part 'swift_ui_adaptive_theme.tailor.dart';

/// Where the size classes of a window begin (logical px). The window is whatever the app is given: an iPhone, an iPad, the
/// outer or the inner display of a foldable (the window is resized when it folds), a split view. Read the result with
/// `SwiftUiWindowInfo.of(context)`.
@tailorMixinComponent
@DoubleEncoder()
class SwiftUiAdaptiveTheme extends ThemeExtension<SwiftUiAdaptiveTheme>
    with _$SwiftUiAdaptiveThemeTailorMixin {
  const SwiftUiAdaptiveTheme({
    this.regularWidth = 600,
    this.regularHeight = 500,
    this.readableWidth = 672,
  });

  /// A window at least this wide has the regular horizontal size class (the outer display of a foldable, 466 pt, is
  /// compact; its inner display, about 669 pt, is regular).
  @override
  final double regularWidth;

  /// A window at least this tall has the regular vertical size class (a phone in portrait is regular, in landscape compact).
  @override
  final double regularHeight;

  /// The comfortable width of text and rows on a wide window (like the readable content guide of iOS).
  @override
  final double readableWidth;
}
