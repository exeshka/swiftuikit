// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'swift_ui_metrics.dart';

// **************************************************************************
// TailorAnnotationsGenerator
// **************************************************************************

mixin _$SwiftUiMetricsTailorMixin on ThemeExtension<SwiftUiMetrics> {
  double get circleButtonSize;
  double get avatarSize;
  double get pillHeight;
  double get barHeight;
  double get pageInset;
  double get rowHeight;
  double get pillRadius;
  double get cardRadius;

  @override
  SwiftUiMetrics copyWith({
    double? circleButtonSize,
    double? avatarSize,
    double? pillHeight,
    double? barHeight,
    double? pageInset,
    double? rowHeight,
    double? pillRadius,
    double? cardRadius,
  }) {
    return SwiftUiMetrics(
      circleButtonSize: circleButtonSize ?? this.circleButtonSize,
      avatarSize: avatarSize ?? this.avatarSize,
      pillHeight: pillHeight ?? this.pillHeight,
      barHeight: barHeight ?? this.barHeight,
      pageInset: pageInset ?? this.pageInset,
      rowHeight: rowHeight ?? this.rowHeight,
      pillRadius: pillRadius ?? this.pillRadius,
      cardRadius: cardRadius ?? this.cardRadius,
    );
  }

  @override
  SwiftUiMetrics lerp(
    covariant ThemeExtension<SwiftUiMetrics>? other,
    double t,
  ) {
    if (other is! SwiftUiMetrics) return this as SwiftUiMetrics;
    return SwiftUiMetrics(
      circleButtonSize: const DoubleEncoder().lerp(
        circleButtonSize,
        other.circleButtonSize,
        t,
      ),
      avatarSize: const DoubleEncoder().lerp(avatarSize, other.avatarSize, t),
      pillHeight: const DoubleEncoder().lerp(pillHeight, other.pillHeight, t),
      barHeight: const DoubleEncoder().lerp(barHeight, other.barHeight, t),
      pageInset: const DoubleEncoder().lerp(pageInset, other.pageInset, t),
      rowHeight: const DoubleEncoder().lerp(rowHeight, other.rowHeight, t),
      pillRadius: const DoubleEncoder().lerp(pillRadius, other.pillRadius, t),
      cardRadius: const DoubleEncoder().lerp(cardRadius, other.cardRadius, t),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SwiftUiMetrics &&
            const DeepCollectionEquality().equals(
              circleButtonSize,
              other.circleButtonSize,
            ) &&
            const DeepCollectionEquality().equals(
              avatarSize,
              other.avatarSize,
            ) &&
            const DeepCollectionEquality().equals(
              pillHeight,
              other.pillHeight,
            ) &&
            const DeepCollectionEquality().equals(barHeight, other.barHeight) &&
            const DeepCollectionEquality().equals(pageInset, other.pageInset) &&
            const DeepCollectionEquality().equals(rowHeight, other.rowHeight) &&
            const DeepCollectionEquality().equals(
              pillRadius,
              other.pillRadius,
            ) &&
            const DeepCollectionEquality().equals(
              cardRadius,
              other.cardRadius,
            ));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType.hashCode,
      const DeepCollectionEquality().hash(circleButtonSize),
      const DeepCollectionEquality().hash(avatarSize),
      const DeepCollectionEquality().hash(pillHeight),
      const DeepCollectionEquality().hash(barHeight),
      const DeepCollectionEquality().hash(pageInset),
      const DeepCollectionEquality().hash(rowHeight),
      const DeepCollectionEquality().hash(pillRadius),
      const DeepCollectionEquality().hash(cardRadius),
    );
  }
}
