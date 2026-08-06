part of '../swift_text.dart';

class _SwiftTextRenderWidget extends LeafRenderObjectWidget {
  const _SwiftTextRenderWidget({
    required this.fromText,
    required this.toText,
    required this.animation,
    required this.curve,
    required this.countsDown,
    required this.textAlign,
    required this.textDirection,
    required this.locale,
    required this.textScaler,
    required this.devicePixelRatio,
    required this.strutStyle,
    required this.softWrap,
    required this.overflow,
    required this.maxLines,
    required this.semanticsLabel,
    required this.transitionId,
    required this.retargetProgress,
    required this.retargetImmediately,
  });

  final TextSpan fromText;
  final TextSpan toText;
  final Animation<double> animation;
  final Curve curve;
  final bool countsDown;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final Locale? locale;
  final TextScaler textScaler;
  final double devicePixelRatio;
  final StrutStyle? strutStyle;
  final bool softWrap;
  final TextOverflow overflow;
  final int? maxLines;
  final String semanticsLabel;
  final int transitionId;
  final double retargetProgress;
  final bool retargetImmediately;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSwiftText(
      fromText: fromText,
      toText: toText,
      animation: animation,
      curve: curve,
      countsDown: countsDown,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      textScaler: textScaler,
      devicePixelRatio: devicePixelRatio,
      strutStyle: strutStyle,
      softWrap: softWrap,
      overflow: overflow,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      transitionId: transitionId,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderSwiftText renderObject) {
    renderObject.retarget(
      transitionId: transitionId,
      previousProgress: retargetProgress,
      immediately: retargetImmediately,
      fromText: fromText,
      toText: toText,
      curve: curve,
      countsDown: countsDown,
    );
    renderObject
      ..animation = animation
      ..textAlign = textAlign
      ..textDirection = textDirection
      ..locale = locale
      ..textScaler = textScaler
      ..devicePixelRatio = devicePixelRatio
      ..strutStyle = strutStyle
      ..softWrap = softWrap
      ..overflow = overflow
      ..maxLines = maxLines
      ..semanticsLabel = semanticsLabel;
  }
}
