// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'swift_ui_colors.dart';

// **************************************************************************
// TailorAnnotationsGenerator
// **************************************************************************

mixin _$SwiftUiColorsTailorMixin on ThemeExtension<SwiftUiColors> {
  Color get background;
  Color get foreground;
  Color get foregroundSecondary;
  Color get foregroundTertiary;
  Color get separator;
  Color get accent;
  Color get onAccent;
  Color get pillFill;
  Color get pillForeground;
  Color get pillShadow;

  @override
  SwiftUiColors copyWith({
    Color? background,
    Color? foreground,
    Color? foregroundSecondary,
    Color? foregroundTertiary,
    Color? separator,
    Color? accent,
    Color? onAccent,
    Color? pillFill,
    Color? pillForeground,
    Color? pillShadow,
  }) {
    return SwiftUiColors(
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      foregroundSecondary: foregroundSecondary ?? this.foregroundSecondary,
      foregroundTertiary: foregroundTertiary ?? this.foregroundTertiary,
      separator: separator ?? this.separator,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      pillFill: pillFill ?? this.pillFill,
      pillForeground: pillForeground ?? this.pillForeground,
      pillShadow: pillShadow ?? this.pillShadow,
    );
  }

  @override
  SwiftUiColors lerp(covariant ThemeExtension<SwiftUiColors>? other, double t) {
    if (other is! SwiftUiColors) return this as SwiftUiColors;
    return SwiftUiColors(
      background: Color.lerp(background, other.background, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      foregroundSecondary: Color.lerp(
        foregroundSecondary,
        other.foregroundSecondary,
        t,
      )!,
      foregroundTertiary: Color.lerp(
        foregroundTertiary,
        other.foregroundTertiary,
        t,
      )!,
      separator: Color.lerp(separator, other.separator, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      pillFill: Color.lerp(pillFill, other.pillFill, t)!,
      pillForeground: Color.lerp(pillForeground, other.pillForeground, t)!,
      pillShadow: Color.lerp(pillShadow, other.pillShadow, t)!,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SwiftUiColors &&
            const DeepCollectionEquality().equals(
              background,
              other.background,
            ) &&
            const DeepCollectionEquality().equals(
              foreground,
              other.foreground,
            ) &&
            const DeepCollectionEquality().equals(
              foregroundSecondary,
              other.foregroundSecondary,
            ) &&
            const DeepCollectionEquality().equals(
              foregroundTertiary,
              other.foregroundTertiary,
            ) &&
            const DeepCollectionEquality().equals(separator, other.separator) &&
            const DeepCollectionEquality().equals(accent, other.accent) &&
            const DeepCollectionEquality().equals(onAccent, other.onAccent) &&
            const DeepCollectionEquality().equals(pillFill, other.pillFill) &&
            const DeepCollectionEquality().equals(
              pillForeground,
              other.pillForeground,
            ) &&
            const DeepCollectionEquality().equals(
              pillShadow,
              other.pillShadow,
            ));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType.hashCode,
      const DeepCollectionEquality().hash(background),
      const DeepCollectionEquality().hash(foreground),
      const DeepCollectionEquality().hash(foregroundSecondary),
      const DeepCollectionEquality().hash(foregroundTertiary),
      const DeepCollectionEquality().hash(separator),
      const DeepCollectionEquality().hash(accent),
      const DeepCollectionEquality().hash(onAccent),
      const DeepCollectionEquality().hash(pillFill),
      const DeepCollectionEquality().hash(pillForeground),
      const DeepCollectionEquality().hash(pillShadow),
    );
  }
}
