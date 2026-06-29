import 'dart:ui';

import 'package:flutter/material.dart';

@immutable
final class MorphSurfaceStyle {
  const MorphSurfaceStyle({
    this.color,
    this.borderRadius = BorderRadius.zero,
    this.padding = EdgeInsets.zero,
    this.constraints,
    this.width,
    this.height,
    this.boxShadow,
    this.blurSigma = 0,
    this.clipBehavior = Clip.antiAlias,
  });

  final Color? color;
  final BorderRadiusGeometry borderRadius;
  final EdgeInsetsGeometry padding;
  final BoxConstraints? constraints;
  final double? width;
  final double? height;
  final List<BoxShadow>? boxShadow;
  final double blurSigma;
  final Clip clipBehavior;

  MorphSurfaceStyle copyWith({
    Color? color,
    BorderRadiusGeometry? borderRadius,
    EdgeInsetsGeometry? padding,
    BoxConstraints? constraints,
    double? width,
    double? height,
    List<BoxShadow>? boxShadow,
    double? blurSigma,
    Clip? clipBehavior,
  }) {
    return MorphSurfaceStyle(
      color: color ?? this.color,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      constraints: constraints ?? this.constraints,
      width: width ?? this.width,
      height: height ?? this.height,
      boxShadow: boxShadow ?? this.boxShadow,
      blurSigma: blurSigma ?? this.blurSigma,
      clipBehavior: clipBehavior ?? this.clipBehavior,
    );
  }

  static MorphSurfaceStyle lerp(
    MorphSurfaceStyle begin,
    MorphSurfaceStyle end,
    double t,
  ) {
    return MorphSurfaceStyle(
      color: Color.lerp(begin.color, end.color, t),
      borderRadius: BorderRadiusGeometry.lerp(
        begin.borderRadius,
        end.borderRadius,
        t,
      )!,
      padding: EdgeInsetsGeometry.lerp(begin.padding, end.padding, t)!,
      constraints: BoxConstraints.lerp(begin.constraints, end.constraints, t),
      width: _lerpNullableDouble(begin.width, end.width, t),
      height: _lerpNullableDouble(begin.height, end.height, t),
      boxShadow: BoxShadow.lerpList(begin.boxShadow, end.boxShadow, t),
      blurSigma: _lerpDouble(begin.blurSigma, end.blurSigma, t),
      clipBehavior: t < 0.5 ? begin.clipBehavior : end.clipBehavior,
    );
  }
}

class MorphSurface extends StatelessWidget {
  MorphSurface({
    super.key,
    required this.child,
    MorphSurfaceStyle? style,
    Color? color,
    BorderRadiusGeometry borderRadius = BorderRadius.zero,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    BoxConstraints? constraints,
    double? width,
    double? height,
    List<BoxShadow>? boxShadow,
    double blurSigma = 0,
    Clip clipBehavior = Clip.antiAlias,
  }) : style =
           style ??
           MorphSurfaceStyle(
             color: color,
             borderRadius: borderRadius,
             padding: padding,
             constraints: constraints,
             width: width,
             height: height,
             boxShadow: boxShadow,
             blurSigma: blurSigma,
             clipBehavior: clipBehavior,
           );

  factory MorphSurface.frosted({
    Key? key,
    required Widget child,
    Color color = const Color(0x47000000),
    BorderRadiusGeometry borderRadius = const BorderRadius.all(
      Radius.circular(30),
    ),
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    BoxConstraints? constraints,
    double? width,
    double? height,
    double blurSigma = 18,
    List<BoxShadow>? boxShadow,
    Clip clipBehavior = Clip.antiAlias,
  }) {
    return MorphSurface(
      key: key,
      color: color,
      borderRadius: borderRadius,
      padding: padding,
      constraints: constraints,
      width: width,
      height: height,
      boxShadow:
          boxShadow ??
          const [
            BoxShadow(
              color: Color(0x29000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
      blurSigma: blurSigma,
      clipBehavior: clipBehavior,
      child: child,
    );
  }

  final Widget child;
  final MorphSurfaceStyle style;

  Color? get color => style.color;
  BorderRadiusGeometry get borderRadius => style.borderRadius;
  EdgeInsetsGeometry get padding => style.padding;
  BoxConstraints? get constraints => style.constraints;
  double? get width => style.width;
  double? get height => style.height;
  List<BoxShadow>? get boxShadow => style.boxShadow;
  double get blurSigma => style.blurSigma;
  Clip get clipBehavior => style.clipBehavior;

  @override
  Widget build(BuildContext context) {
    final borderRadius = style.borderRadius.resolve(
      Directionality.maybeOf(context),
    );
    final hasBlur = style.blurSigma > 0;
    Widget content = DecoratedBox(
      decoration: BoxDecoration(
        color: style.color,
        borderRadius: style.borderRadius,
      ),
      child: Padding(padding: style.padding, child: child),
    );

    if (hasBlur) {
      content = BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: style.blurSigma,
          sigmaY: style.blurSigma,
        ),
        child: content,
      );
    }

    return ConstrainedBox(
      constraints: style.constraints ?? const BoxConstraints(),
      child: SizedBox(
        width: style.width,
        height: style.height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: style.borderRadius,
            boxShadow: style.boxShadow,
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            clipBehavior: style.clipBehavior,
            child: content,
          ),
        ),
      ),
    );
  }
}

double _lerpDouble(double begin, double end, double t) {
  return begin * (1 - t) + end * t;
}

double? _lerpNullableDouble(double? begin, double? end, double t) {
  if (begin == null && end == null) {
    return null;
  }

  return (begin ?? 0) * (1 - t) + (end ?? 0) * t;
}
