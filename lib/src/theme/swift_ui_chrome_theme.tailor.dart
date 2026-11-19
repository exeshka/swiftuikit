// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'swift_ui_chrome_theme.dart';

// **************************************************************************
// TailorAnnotationsGenerator
// **************************************************************************

mixin _$SwiftUiChromeThemeTailorMixin on ThemeExtension<SwiftUiChromeTheme> {
  ChromeStyle get top;
  ChromeStyle get bottom;
  Color get blurTint;
  double get blurSigma;
  double get blurExtra;
  double get tintOpacity;
  double get bottomBarSafeAreaShare;
  double get topEdgeRamp;

  @override
  SwiftUiChromeTheme copyWith({
    ChromeStyle? top,
    ChromeStyle? bottom,
    Color? blurTint,
    double? blurSigma,
    double? blurExtra,
    double? tintOpacity,
    double? bottomBarSafeAreaShare,
    double? topEdgeRamp,
  }) {
    return SwiftUiChromeTheme(
      top: top ?? this.top,
      bottom: bottom ?? this.bottom,
      blurTint: blurTint ?? this.blurTint,
      blurSigma: blurSigma ?? this.blurSigma,
      blurExtra: blurExtra ?? this.blurExtra,
      tintOpacity: tintOpacity ?? this.tintOpacity,
      bottomBarSafeAreaShare:
          bottomBarSafeAreaShare ?? this.bottomBarSafeAreaShare,
      topEdgeRamp: topEdgeRamp ?? this.topEdgeRamp,
    );
  }

  @override
  SwiftUiChromeTheme lerp(
    covariant ThemeExtension<SwiftUiChromeTheme>? other,
    double t,
  ) {
    if (other is! SwiftUiChromeTheme) return this as SwiftUiChromeTheme;
    return SwiftUiChromeTheme(
      top: const ChromeStyleEncoder().lerp(top, other.top, t),
      bottom: const ChromeStyleEncoder().lerp(bottom, other.bottom, t),
      blurTint: Color.lerp(blurTint, other.blurTint, t)!,
      blurSigma: const DoubleEncoder().lerp(blurSigma, other.blurSigma, t),
      blurExtra: const DoubleEncoder().lerp(blurExtra, other.blurExtra, t),
      tintOpacity: const DoubleEncoder().lerp(
        tintOpacity,
        other.tintOpacity,
        t,
      ),
      bottomBarSafeAreaShare: const DoubleEncoder().lerp(
        bottomBarSafeAreaShare,
        other.bottomBarSafeAreaShare,
        t,
      ),
      topEdgeRamp: const DoubleEncoder().lerp(
        topEdgeRamp,
        other.topEdgeRamp,
        t,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SwiftUiChromeTheme &&
            const DeepCollectionEquality().equals(top, other.top) &&
            const DeepCollectionEquality().equals(bottom, other.bottom) &&
            const DeepCollectionEquality().equals(blurTint, other.blurTint) &&
            const DeepCollectionEquality().equals(blurSigma, other.blurSigma) &&
            const DeepCollectionEquality().equals(blurExtra, other.blurExtra) &&
            const DeepCollectionEquality().equals(
              tintOpacity,
              other.tintOpacity,
            ) &&
            const DeepCollectionEquality().equals(
              bottomBarSafeAreaShare,
              other.bottomBarSafeAreaShare,
            ) &&
            const DeepCollectionEquality().equals(
              topEdgeRamp,
              other.topEdgeRamp,
            ));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType.hashCode,
      const DeepCollectionEquality().hash(top),
      const DeepCollectionEquality().hash(bottom),
      const DeepCollectionEquality().hash(blurTint),
      const DeepCollectionEquality().hash(blurSigma),
      const DeepCollectionEquality().hash(blurExtra),
      const DeepCollectionEquality().hash(tintOpacity),
      const DeepCollectionEquality().hash(bottomBarSafeAreaShare),
      const DeepCollectionEquality().hash(topEdgeRamp),
    );
  }
}
