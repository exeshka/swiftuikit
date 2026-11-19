import 'package:flutter/material.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

part 'swift_ui_colors.tailor.dart';

/// The semantic colours of the kit, the way iOS names them: a label in three strengths, the page background, the separator and
/// the tint (accent) with the colour of what sits on it. Widgets never hardcode a colour, they read it from here.
@tailorMixinComponent
class SwiftUiColors extends ThemeExtension<SwiftUiColors>
    with _$SwiftUiColorsTailorMixin {
  const SwiftUiColors({
    required this.background,
    required this.foreground,
    required this.foregroundSecondary,
    required this.foregroundTertiary,
    required this.separator,
    required this.accent,
    required this.onAccent,
    required this.pillFill,
    required this.pillForeground,
    required this.pillShadow,
  });

  /// iOS 26 look, dark.
  const SwiftUiColors.dark()
    : background = const Color(0xFF000000),
      foreground = const Color(0xFFFFFFFF),
      foregroundSecondary = const Color(0x99FFFFFF),
      foregroundTertiary = const Color(0x4DFFFFFF),
      separator = const Color(0x1FFFFFFF),
      accent = const Color(0xFF9B59D0),
      onAccent = const Color(0xFFFFFFFF),
      pillFill = const Color(0xFFFFFFFF),
      pillForeground = const Color(0xFF000000),
      pillShadow = const Color(0x66000000);

  /// iOS 26 look, light.
  const SwiftUiColors.light()
    : background = const Color(0xFFF2F2F7),
      foreground = const Color(0xFF000000),
      foregroundSecondary = const Color(0x99000000),
      foregroundTertiary = const Color(0x4D000000),
      separator = const Color(0x1F000000),
      accent = const Color(0xFF9B59D0),
      onAccent = const Color(0xFFFFFFFF),
      pillFill = const Color(0xFFFFFFFF),
      pillForeground = const Color(0xFF000000),
      pillShadow = const Color(0x33000000);

  /// The page background.
  @override
  final Color background;

  /// The primary label (text, icons).
  @override
  final Color foreground;
  @override
  final Color foregroundSecondary;
  @override
  final Color foregroundTertiary;
  @override
  final Color separator;

  /// The tint: the colour of prominent controls.
  @override
  final Color accent;

  /// What sits on the [accent].
  @override
  final Color onAccent;

  /// The floating pill button (the opaque one that stands out of the glass).
  @override
  final Color pillFill;
  @override
  final Color pillForeground;
  @override
  final Color pillShadow;
}
