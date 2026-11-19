import 'package:flutter/material.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

import '../chrome/chrome_style.dart';
import 'swift_ui_encoders.dart';

part 'swift_ui_chrome_theme.tailor.dart';

/// The bars' edge effect: what is drawn under the top and bottom bars and how the scaffold behaves around them.
///
/// [top] and [bottom] are the slot for the look: a [ChromeStyle] (soft blur with a gradient by default, or a plain container,
/// a uniform blur, any widget). A [ChromeScaffold] can override them with its own `topChrome` / `bottomChrome`, a subtree with
/// a [ChromeStyleScope].
@tailorMixinComponent
@DoubleEncoder()
@ChromeStyleEncoder()
class SwiftUiChromeTheme extends ThemeExtension<SwiftUiChromeTheme>
    with _$SwiftUiChromeThemeTailorMixin {
  const SwiftUiChromeTheme({
    this.top = const ChromeStyle.soft(),
    this.bottom = const ChromeStyle.soft(),
    required this.blurTint,
    this.blurSigma = 10,
    this.blurExtra = 36,
    this.tintOpacity = 0.35,
    this.bottomBarSafeAreaShare = 0.3,
    this.topEdgeRamp = 16,
  });

  const SwiftUiChromeTheme.dark() : this(blurTint: const Color(0xFF000000));

  const SwiftUiChromeTheme.light() : this(blurTint: const Color(0xFFF2F2F7));

  /// The style of the top / bottom edge.
  @override
  final ChromeStyle top;
  @override
  final ChromeStyle bottom;

  /// The scrim colour of the blur styles.
  @override
  final Color blurTint;

  /// Max sigma of the progressive blur at the very screen edge.
  @override
  final double blurSigma;

  /// How far (logical px) the zone extends past the last bar.
  @override
  final double blurExtra;

  /// Opacity of the scrim laid over the zone (the styles that need a stronger one than the masked blur's 0.12).
  @override
  final double tintOpacity;

  /// 0..1: the share of the bottom safe area (the home indicator) kept below the bottom bar. 1 lifts the bar by the whole inset,
  /// 0 presses it to the very edge. The default 0.3 puts the bar about 10 pt above the edge.
  @override
  final double bottomBarSafeAreaShare;

  /// Scroll distance (logical px) over which the top edge effect fades in once the content starts to move under the bar. At
  /// rest (nothing under the bar yet) there is no effect, so the first rows are not blurred or dimmed; like the scroll edge
  /// effect of iOS 26. 0 keeps the effect on all the time.
  @override
  final double topEdgeRamp;
}
