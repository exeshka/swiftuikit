import 'package:flutter/material.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

part 'swift_ui_typography.tailor.dart';

/// The tracking (letter spacing, in points) iOS applies to San Francisco at [size]: tighter for the text sizes, a little open for
/// the display ones. Flutter does not apply it on its own, and without it text is visibly wider than native.
double iosTracking(double size) {
  // measured against native text in an iOS 26 sheet: Flutter's glyph advances come out a little wider than SwiftUI's at the text
  // sizes, 0.3 pt of extra tightening per character puts the widths of a button label / a nav title within 1 % of native
  final fit = size < 19.5 ? -0.3 : 0.0;
  return fit + _tracking(size);
}

double _tracking(double size) {
  const table = <(double, double)>[
    (11, 0.07),
    (12, 0),
    (13, -0.08),
    (15, -0.24),
    (16, -0.32),
    (17, -0.41),
    (19, -0.45),
    (20, 0.38),
    (22, 0.35),
    (28, 0.36),
    (34, 0.37),
  ];
  if (size <= table.first.$1) return table.first.$2;
  for (var i = 1; i < table.length; i++) {
    if (size <= table[i].$1) {
      // the table has a step between 19 and 20 (the font switches from Text to Display), do not interpolate over it
      if (table[i - 1].$1 == 19) return table[i].$2;
      final a = table[i - 1], b = table[i];
      return a.$2 + (b.$2 - a.$2) * (size - a.$1) / (b.$1 - a.$1);
    }
  }
  return table.last.$2;
}

/// Text styles of the kit.
@tailorMixinComponent
class SwiftUiTypography extends ThemeExtension<SwiftUiTypography>
    with _$SwiftUiTypographyTailorMixin {
  const SwiftUiTypography({
    required this.largeTitle,
    required this.title,
    required this.body,
    required this.caption,
    required this.serifTitle,
  });

  /// The text styles in [foreground] / [secondary] colours (the dark theme uses white, the light one black).
  factory SwiftUiTypography.of({
    required Color foreground,
    required Color secondary,
  }) => SwiftUiTypography(
    largeTitle: TextStyle(
      fontSize: 34,
      height: 1.15,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.37,
      color: foreground,
    ),
    title: TextStyle(
      fontSize: 20,
      height: 1.2,
      fontWeight: FontWeight.w600,
      letterSpacing: iosTracking(20),
      color: foreground,
    ),
    body: TextStyle(
      fontSize: 17,
      height: 1.3,
      fontWeight: FontWeight.w400,
      letterSpacing: iosTracking(17),
      color: foreground,
    ),
    caption: TextStyle(
      fontSize: 15,
      height: 1.3,
      fontWeight: FontWeight.w400,
      letterSpacing: iosTracking(15),
      color: secondary,
    ),
    serifTitle: TextStyle(
      fontFamily: 'Georgia',
      fontFamilyFallback: const ['Times New Roman', 'serif'],
      fontSize: 26,
      height: 1.2,
      fontWeight: FontWeight.w500,
      color: foreground,
    ),
  );

  factory SwiftUiTypography.dark() => SwiftUiTypography.of(
    foreground: const Color(0xFFFFFFFF),
    secondary: const Color(0x99FFFFFF),
  );

  factory SwiftUiTypography.light() => SwiftUiTypography.of(
    foreground: const Color(0xFF000000),
    secondary: const Color(0x99000000),
  );

  @override
  final TextStyle largeTitle;
  @override
  final TextStyle title;
  @override
  final TextStyle body;
  @override
  final TextStyle caption;
  @override
  final TextStyle serifTitle;
}
