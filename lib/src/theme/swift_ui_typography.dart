import 'package:flutter/material.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

part 'swift_ui_typography.tailor.dart';

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
      color: foreground,
    ),
    body: TextStyle(
      fontSize: 17,
      height: 1.3,
      fontWeight: FontWeight.w400,
      color: foreground,
    ),
    caption: TextStyle(
      fontSize: 15,
      height: 1.3,
      fontWeight: FontWeight.w400,
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
