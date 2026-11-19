// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'swift_ui_adaptive_theme.dart';

// **************************************************************************
// TailorAnnotationsGenerator
// **************************************************************************

mixin _$SwiftUiAdaptiveThemeTailorMixin
    on ThemeExtension<SwiftUiAdaptiveTheme> {
  double get regularWidth;
  double get regularHeight;
  double get readableWidth;

  @override
  SwiftUiAdaptiveTheme copyWith({
    double? regularWidth,
    double? regularHeight,
    double? readableWidth,
  }) {
    return SwiftUiAdaptiveTheme(
      regularWidth: regularWidth ?? this.regularWidth,
      regularHeight: regularHeight ?? this.regularHeight,
      readableWidth: readableWidth ?? this.readableWidth,
    );
  }

  @override
  SwiftUiAdaptiveTheme lerp(
    covariant ThemeExtension<SwiftUiAdaptiveTheme>? other,
    double t,
  ) {
    if (other is! SwiftUiAdaptiveTheme) return this as SwiftUiAdaptiveTheme;
    return SwiftUiAdaptiveTheme(
      regularWidth: const DoubleEncoder().lerp(
        regularWidth,
        other.regularWidth,
        t,
      ),
      regularHeight: const DoubleEncoder().lerp(
        regularHeight,
        other.regularHeight,
        t,
      ),
      readableWidth: const DoubleEncoder().lerp(
        readableWidth,
        other.readableWidth,
        t,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SwiftUiAdaptiveTheme &&
            const DeepCollectionEquality().equals(
              regularWidth,
              other.regularWidth,
            ) &&
            const DeepCollectionEquality().equals(
              regularHeight,
              other.regularHeight,
            ) &&
            const DeepCollectionEquality().equals(
              readableWidth,
              other.readableWidth,
            ));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType.hashCode,
      const DeepCollectionEquality().hash(regularWidth),
      const DeepCollectionEquality().hash(regularHeight),
      const DeepCollectionEquality().hash(readableWidth),
    );
  }
}
