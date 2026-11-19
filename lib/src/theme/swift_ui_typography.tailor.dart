// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'swift_ui_typography.dart';

// **************************************************************************
// TailorAnnotationsGenerator
// **************************************************************************

mixin _$SwiftUiTypographyTailorMixin on ThemeExtension<SwiftUiTypography> {
  TextStyle get largeTitle;
  TextStyle get title;
  TextStyle get body;
  TextStyle get caption;
  TextStyle get serifTitle;

  @override
  SwiftUiTypography copyWith({
    TextStyle? largeTitle,
    TextStyle? title,
    TextStyle? body,
    TextStyle? caption,
    TextStyle? serifTitle,
  }) {
    return SwiftUiTypography(
      largeTitle: largeTitle ?? this.largeTitle,
      title: title ?? this.title,
      body: body ?? this.body,
      caption: caption ?? this.caption,
      serifTitle: serifTitle ?? this.serifTitle,
    );
  }

  @override
  SwiftUiTypography lerp(
    covariant ThemeExtension<SwiftUiTypography>? other,
    double t,
  ) {
    if (other is! SwiftUiTypography) return this as SwiftUiTypography;
    return SwiftUiTypography(
      largeTitle: TextStyle.lerp(largeTitle, other.largeTitle, t)!,
      title: TextStyle.lerp(title, other.title, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      serifTitle: TextStyle.lerp(serifTitle, other.serifTitle, t)!,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SwiftUiTypography &&
            const DeepCollectionEquality().equals(
              largeTitle,
              other.largeTitle,
            ) &&
            const DeepCollectionEquality().equals(title, other.title) &&
            const DeepCollectionEquality().equals(body, other.body) &&
            const DeepCollectionEquality().equals(caption, other.caption) &&
            const DeepCollectionEquality().equals(
              serifTitle,
              other.serifTitle,
            ));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType.hashCode,
      const DeepCollectionEquality().hash(largeTitle),
      const DeepCollectionEquality().hash(title),
      const DeepCollectionEquality().hash(body),
      const DeepCollectionEquality().hash(caption),
      const DeepCollectionEquality().hash(serifTitle),
    );
  }
}
