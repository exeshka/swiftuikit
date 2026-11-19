// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'swift_ui_theme_data.dart';

// **************************************************************************
// TailorAnnotationsGenerator
// **************************************************************************

mixin _$SwiftUiThemeDataTailorMixin on ThemeExtension<SwiftUiThemeData> {
  Brightness get brightness;
  SwiftUiColors get colors;
  SwiftUiTypography get typography;
  SwiftUiMetrics get metrics;
  SwiftUiGlassTheme get glass;
  SwiftUiChromeTheme get chrome;
  SwiftUiAdaptiveTheme get adaptive;
  bool get isDark;

  @override
  SwiftUiThemeData copyWith({
    Brightness? brightness,
    SwiftUiColors? colors,
    SwiftUiTypography? typography,
    SwiftUiMetrics? metrics,
    SwiftUiGlassTheme? glass,
    SwiftUiChromeTheme? chrome,
    SwiftUiAdaptiveTheme? adaptive,
    bool? isDark,
  }) {
    return SwiftUiThemeData(
      brightness: brightness ?? this.brightness,
      colors: colors ?? this.colors,
      typography: typography ?? this.typography,
      metrics: metrics ?? this.metrics,
      glass: glass ?? this.glass,
      chrome: chrome ?? this.chrome,
      adaptive: adaptive ?? this.adaptive,
    );
  }

  @override
  SwiftUiThemeData lerp(
    covariant ThemeExtension<SwiftUiThemeData>? other,
    double t,
  ) {
    if (other is! SwiftUiThemeData) return this as SwiftUiThemeData;
    return SwiftUiThemeData(
      brightness: t < 0.5 ? brightness : other.brightness,
      colors: colors.lerp(other.colors, t),
      typography: typography.lerp(other.typography, t),
      metrics: metrics.lerp(other.metrics, t),
      glass: glass.lerp(other.glass, t),
      chrome: chrome.lerp(other.chrome, t),
      adaptive: adaptive.lerp(other.adaptive, t),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SwiftUiThemeData &&
            const DeepCollectionEquality().equals(
              brightness,
              other.brightness,
            ) &&
            const DeepCollectionEquality().equals(colors, other.colors) &&
            const DeepCollectionEquality().equals(
              typography,
              other.typography,
            ) &&
            const DeepCollectionEquality().equals(metrics, other.metrics) &&
            const DeepCollectionEquality().equals(glass, other.glass) &&
            const DeepCollectionEquality().equals(chrome, other.chrome) &&
            const DeepCollectionEquality().equals(adaptive, other.adaptive) &&
            const DeepCollectionEquality().equals(isDark, other.isDark));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType.hashCode,
      const DeepCollectionEquality().hash(brightness),
      const DeepCollectionEquality().hash(colors),
      const DeepCollectionEquality().hash(typography),
      const DeepCollectionEquality().hash(metrics),
      const DeepCollectionEquality().hash(glass),
      const DeepCollectionEquality().hash(chrome),
      const DeepCollectionEquality().hash(adaptive),
      const DeepCollectionEquality().hash(isDark),
    );
  }
}
