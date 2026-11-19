import 'package:flutter/material.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

import 'swift_ui_adaptive_theme.dart';
import 'swift_ui_chrome_theme.dart';
import 'swift_ui_colors.dart';
import 'swift_ui_glass_theme.dart';
import 'swift_ui_metrics.dart';
import 'swift_ui_typography.dart';

part 'swift_ui_theme_data.tailor.dart';

/// Everything a theme of the kit carries, in groups: [colors], [typography], [metrics], [glass], [chrome] and [adaptive]. Build one with
/// [SwiftUiThemeData.light] / [SwiftUiThemeData.dark] and change a group with `copyWith`:
///
/// ```dart
/// final base = SwiftUiThemeData.dark();
/// final mine = base.copyWith(
///   colors: base.colors.copyWith(accent: const Color(0xFF0A84FF)),
///   chrome: base.chrome.copyWith(top: const ChromeStyle.solid()),
/// );
/// ```
@TailorMixin(themeGetter: ThemeGetter.none)
class SwiftUiThemeData extends ThemeExtension<SwiftUiThemeData>
    with _$SwiftUiThemeDataTailorMixin {
  const SwiftUiThemeData({
    required this.brightness,
    required this.colors,
    required this.typography,
    required this.metrics,
    required this.glass,
    required this.chrome,
    this.adaptive = const SwiftUiAdaptiveTheme(),
  });

  factory SwiftUiThemeData.dark() => SwiftUiThemeData(
    brightness: Brightness.dark,
    colors: const SwiftUiColors.dark(),
    typography: SwiftUiTypography.dark(),
    metrics: const SwiftUiMetrics(),
    glass: const SwiftUiGlassTheme.dark(),
    chrome: const SwiftUiChromeTheme.dark(),
  );

  factory SwiftUiThemeData.light() => SwiftUiThemeData(
    brightness: Brightness.light,
    colors: const SwiftUiColors.light(),
    typography: SwiftUiTypography.light(),
    metrics: const SwiftUiMetrics(),
    glass: const SwiftUiGlassTheme.light(),
    chrome: const SwiftUiChromeTheme.light(),
  );

  @override
  final Brightness brightness;
  @override
  @themeExtension
  final SwiftUiColors colors;
  @override
  @themeExtension
  final SwiftUiTypography typography;
  @override
  @themeExtension
  final SwiftUiMetrics metrics;
  @override
  @themeExtension
  final SwiftUiGlassTheme glass;
  @override
  @themeExtension
  final SwiftUiChromeTheme chrome;
  @override
  @themeExtension
  final SwiftUiAdaptiveTheme adaptive;

  bool get isDark => brightness == Brightness.dark;

  /// A copy with some of the [glass] parameters changed (a shortcut for `copyWith(glass: glass.copyWith(...))`).
  SwiftUiThemeData withGlass({
    double? liquidBezel,
    double? liquidRefraction,
    double? liquidBlur,
    double? liquidSaturation,
    double? liquidDispersion,
    double? liquidMagnify,
    double? liquidHdr,
    double? liquidPrefilter,
    double? liquidSpecular,
    double? liquidGlow,
    double? liquidToneLift,
    double? liquidToneGain,
    Color? liquidTint,
    bool? useLiquidGlass,
  }) => copyWith(
    glass: glass.copyWith(
      liquidBezel: liquidBezel,
      liquidRefraction: liquidRefraction,
      liquidBlur: liquidBlur,
      liquidSaturation: liquidSaturation,
      liquidDispersion: liquidDispersion,
      liquidMagnify: liquidMagnify,
      liquidHdr: liquidHdr,
      liquidPrefilter: liquidPrefilter,
      liquidSpecular: liquidSpecular,
      liquidGlow: liquidGlow,
      liquidToneLift: liquidToneLift,
      liquidToneGain: liquidToneGain,
      liquidTint: liquidTint,
      useLiquidGlass: useLiquidGlass,
    ),
  );
}
