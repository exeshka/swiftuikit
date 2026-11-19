import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../blur/progressive_blur.dart';
import '../theme/swift_ui_theme.dart';

/// What a [ChromeStyle] is told about the zone it has to fill. The scaffold owns the geometry; the style owns the look.
@immutable
class ChromeSpec {
  const ChromeSpec({
    required this.edge,
    required this.height,
    required this.covered,
    required this.fadeHold,
    required this.intensity,
    required this.background,
  });

  /// The screen edge the zone sits on: its strong side.
  final BlurEdge edge;

  /// The whole height of the zone (the area covered by the bars plus the style's own extension).
  final double height;

  /// The part of [height] the bars themselves cover (the system area plus the bars).
  final double covered;

  /// 0..1 share of [height], from the strong edge, that a gradient should keep fully dense: the area the bars cover.
  final double fadeHold;

  /// 0..1: how much of the effect there is at all. A header that draws an edge effect of its own lowers it to 0.
  final double intensity;

  /// The page background the content leaves into.
  final Color background;

  bool get isTop => edge == BlurEdge.top;
}

/// Builds the layer of a [ChromeSpec]. It is painted over the content and under the bars, must not take touches
/// (wrap in [IgnorePointer]) and must not sit inside its own offscreen layer (`Opacity`, `ShaderMask`): a backdrop blur
/// inside one reads an empty backdrop.
typedef ChromeLayerBuilder = Widget Function(
  BuildContext context,
  ChromeSpec spec,
);

/// How content leaves under the top and bottom bars of a [ChromeScaffold]: the native iOS 26 "scroll edge effect", plus
/// whatever else an app wants there.
///
/// The scaffold decides *where* the zone is; the style decides *how tall* it is beyond the bars ([zoneHeight]) and *what
/// it draws* ([build]). Pick one per edge with [ChromeScaffold.topChrome] / [ChromeScaffold.bottomChrome], for a whole
/// subtree with [ChromeStyleScope] (or the theme), the default is [ChromeStyle.soft].
///
///  * [ChromeStyle.soft]: progressive blur with a gradient (the native `soft` edge effect; the default).
///  * [ChromeStyle.variableBlur]: the exact variable-sigma shader blur (heavy on the GPU, for static screens).
///  * [ChromeStyle.fade]: a gradient into the page colour only, no backdrop filter (the cheapest).
///  * [ChromeStyle.blur]: one uniform backdrop blur.
///  * [ChromeStyle.hard]: the native `hard` edge: a blurred, mostly opaque bar background with a divider line.
///  * [ChromeStyle.solid]: a plain colour (the page background by default).
///  * [ChromeStyle.none]: nothing.
///  * [ChromeStyle.custom]: any widget.
@immutable
abstract class ChromeStyle {
  const ChromeStyle();

  const factory ChromeStyle.soft({
    double? sigma,
    double? tintOpacity,
    double? tintHold,
    double? fadeOpacity,
    Color? tint,
  }) = ProgressiveChromeStyle.soft;

  const factory ChromeStyle.variableBlur({
    double? sigma,
    double? tintOpacity,
    double? tintHold,
    double? fadeOpacity,
    Color? tint,
  }) = ProgressiveChromeStyle.variableBlur;

  const factory ChromeStyle.fade({
    double? sigma,
    double? tintOpacity,
    double? tintHold,
    double? fadeOpacity,
    Color? tint,
  }) = ProgressiveChromeStyle.fade;

  const factory ChromeStyle.blur({
    double? sigma,
    Color? tint,
    double? tintOpacity,
  }) = BlurChromeStyle;

  const factory ChromeStyle.hard({Color? tint}) = BlurChromeStyle.hard;

  const factory ChromeStyle.solid({Color? color, bool? divider}) =
      SolidChromeStyle;

  const factory ChromeStyle.none() = NoChromeStyle;

  const factory ChromeStyle.custom({
    required ChromeLayerBuilder builder,
    double? extent,
  }) = CustomChromeStyle;

  /// The height of the zone on [edge] when the bars (and the system area) cover [covered] logical px. The default is the
  /// native-like one: the zone reaches past the bars by [SwiftUiChromeTheme.blurExtra] (about half of it at the bottom,
  /// where the glass of the bar covers the rest).
  double zoneHeight(BlurEdge edge, double covered, SwiftUiThemeData tokens) =>
      edge == BlurEdge.top
      ? covered + tokens.chrome.blurExtra
      : covered * 0.85 + tokens.chrome.blurExtra / 2;

  /// The layer that fills the zone.
  Widget build(BuildContext context, ChromeSpec spec);
}

/// The blur of [ProgressiveBlur] in one of its three modes. Every value left null comes from the theme.
class ProgressiveChromeStyle extends ChromeStyle {
  const ProgressiveChromeStyle._(
    this.effect, {
    this.sigma,
    this.tintOpacity,
    this.tintHold,
    this.fadeOpacity,
    this.tint,
  });

  /// Masked blur plus gradient: progressive, and cheap enough to scroll under on a phone.
  const ProgressiveChromeStyle.soft({
    double? sigma,
    double? tintOpacity,
    double? tintHold,
    double? fadeOpacity,
    Color? tint,
  }) : this._(
         ChromeEdgeEffect.blur,
         sigma: sigma,
         tintOpacity: tintOpacity,
         tintHold: tintHold,
         fadeOpacity: fadeOpacity,
         tint: tint,
       );

  /// The exact variable-sigma shader blur.
  const ProgressiveChromeStyle.variableBlur({
    double? sigma,
    double? tintOpacity,
    double? tintHold,
    double? fadeOpacity,
    Color? tint,
  }) : this._(
         ChromeEdgeEffect.variableBlur,
         sigma: sigma,
         tintOpacity: tintOpacity,
         tintHold: tintHold,
         fadeOpacity: fadeOpacity,
         tint: tint,
       );

  /// A gradient into the page colour, no backdrop filter.
  const ProgressiveChromeStyle.fade({
    double? sigma,
    double? tintOpacity,
    double? tintHold,
    double? fadeOpacity,
    Color? tint,
  }) : this._(
         ChromeEdgeEffect.fade,
         sigma: sigma,
         tintOpacity: tintOpacity,
         tintHold: tintHold,
         fadeOpacity: fadeOpacity,
         tint: tint,
       );

  final ChromeEdgeEffect effect;

  /// Sigma at the strong edge (null: [SwiftUiChromeTheme.blurSigma]).
  final double? sigma;

  /// Peak opacity of the scrim (null: 0.12 for the masked blur, [SwiftUiChromeTheme.tintOpacity] otherwise).
  final double? tintOpacity;

  /// 0..1: how long the scrim stays dense (see [ProgressiveBlur.tintHold]); null: 0.
  final double? tintHold;

  /// Peak opacity of the page-colour gradient (null: 0.78): below 1 the content stays faintly visible under the bars.
  final double? fadeOpacity;

  /// Scrim colour (null: [SwiftUiChromeTheme.blurTint]).
  final Color? tint;

  @override
  Widget build(BuildContext context, ChromeSpec spec) {
    final t = SwiftUiTheme.of(context);
    return ProgressiveBlur(
      height: spec.height,
      edge: spec.edge,
      maxSigma: sigma ?? t.chrome.blurSigma,
      tint: tint ?? t.chrome.blurTint,
      effect: effect,
      fadeColor: spec.background,
      fadeOpacity: (fadeOpacity ?? 0.78) * spec.intensity,
      intensity: spec.intensity,
      fadeHold: spec.fadeHold,
      tintOpacity:
          tintOpacity ??
          (effect == ChromeEdgeEffect.blur ? 0.12 : t.chrome.tintOpacity),
      tintHold: tintHold ?? 0,
    );
  }
}

/// One uniform backdrop blur over the zone, with a flat tint. The zone ends where the bars end.
class BlurChromeStyle extends ChromeStyle {
  const BlurChromeStyle({this.sigma, this.tint, this.tintOpacity})
    : divider = false;

  /// The native `hard` edge effect: a blurred, mostly opaque background with a hairline under the bars.
  const BlurChromeStyle.hard({this.tint})
    : sigma = 20,
      tintOpacity = 0.7,
      divider = true;

  final double? sigma;

  /// Null: [SwiftUiChromeTheme.blurTint].
  final Color? tint;

  /// Null: 0.35.
  final double? tintOpacity;

  /// A hairline in [SwiftUiColors.separator] on the inner side of the zone.
  final bool divider;

  @override
  double zoneHeight(BlurEdge edge, double covered, SwiftUiThemeData tokens) =>
      covered;

  @override
  Widget build(BuildContext context, ChromeSpec spec) {
    final t = SwiftUiTheme.of(context);
    final s = sigma ?? t.chrome.blurSigma;
    final color = (tint ?? t.chrome.blurTint).withValues(
      alpha: (tintOpacity ?? 0.35) * spec.intensity,
    );
    return IgnorePointer(
      child: SizedBox(
        height: spec.height,
        child: spec.intensity <= 0.01
            ? null
            : ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: s, sigmaY: s),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      border: divider
                          ? Border(
                              top: spec.isTop
                                  ? BorderSide.none
                                  : BorderSide(
                                      color: t.colors.separator,
                                      width: 0.5,
                                    ),
                              bottom: spec.isTop
                                  ? BorderSide(
                                      color: t.colors.separator,
                                      width: 0.5,
                                    )
                                  : BorderSide.none,
                            )
                          : null,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
      ),
    );
  }
}

/// A plain colour behind the bars. The zone ends where the bars end.
class SolidChromeStyle extends ChromeStyle {
  const SolidChromeStyle({this.color, bool? divider})
    : divider = divider ?? false;

  /// Null: the page background.
  final Color? color;

  /// A hairline in [SwiftUiColors.separator] on the inner side of the zone.
  final bool divider;

  @override
  double zoneHeight(BlurEdge edge, double covered, SwiftUiThemeData tokens) =>
      covered;

  @override
  Widget build(BuildContext context, ChromeSpec spec) {
    final t = SwiftUiTheme.of(context);
    final c = color ?? spec.background;
    return IgnorePointer(
      child: SizedBox(
        height: spec.height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.withValues(alpha: c.a * spec.intensity),
            border: divider
                ? Border(
                    top: spec.isTop
                        ? BorderSide.none
                        : BorderSide(color: t.colors.separator, width: 0.5),
                    bottom: spec.isTop
                        ? BorderSide(color: t.colors.separator, width: 0.5)
                        : BorderSide.none,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

/// No effect: the content runs under the bars as it is.
class NoChromeStyle extends ChromeStyle {
  const NoChromeStyle();

  @override
  double zoneHeight(BlurEdge edge, double covered, SwiftUiThemeData tokens) =>
      0;

  @override
  Widget build(BuildContext context, ChromeSpec spec) =>
      const SizedBox.shrink();
}

/// Any widget as the zone: [builder] gets the zone's [ChromeSpec] and fills `spec.height`. The zone reaches [extent] past
/// the bars.
class CustomChromeStyle extends ChromeStyle {
  const CustomChromeStyle({required this.builder, double? extent})
    : extent = extent ?? 0;

  final ChromeLayerBuilder builder;
  final double extent;

  @override
  double zoneHeight(BlurEdge edge, double covered, SwiftUiThemeData tokens) =>
      covered + extent;

  @override
  Widget build(BuildContext context, ChromeSpec spec) => builder(context, spec);
}

/// Sets the [ChromeStyle] of every [ChromeScaffold] below it (a settings switch, an A/B test, an app-wide look). A scaffold
/// with a [ChromeScaffold.topChrome] / [ChromeScaffold.bottomChrome] of its own ignores it. [top] and [bottom] left null keep
/// what an outer scope (or the default, [SwiftUiChromeTheme]) says.
class ChromeStyleScope extends InheritedWidget {
  const ChromeStyleScope({
    super.key,
    this.top,
    this.bottom,
    required super.child,
  });

  /// The same style on both edges.
  const ChromeStyleScope.both({
    super.key,
    required ChromeStyle style,
    required super.child,
  }) : top = style,
       bottom = style;

  final ChromeStyle? top;
  final ChromeStyle? bottom;

  static ChromeStyle topOf(BuildContext context) {
    ChromeStyle? found;
    context.visitAncestorElements((e) {
      final w = e.widget;
      if (w is ChromeStyleScope && w.top != null) {
        found = w.top;
        return false;
      }
      return true;
    });
    // registers the dependency: a changed scope rebuilds the scaffold
    context.dependOnInheritedWidgetOfExactType<ChromeStyleScope>();
    return found ?? SwiftUiTheme.of(context).chrome.top;
  }

  static ChromeStyle bottomOf(BuildContext context) {
    ChromeStyle? found;
    context.visitAncestorElements((e) {
      final w = e.widget;
      if (w is ChromeStyleScope && w.bottom != null) {
        found = w.bottom;
        return false;
      }
      return true;
    });
    context.dependOnInheritedWidgetOfExactType<ChromeStyleScope>();
    return found ?? SwiftUiTheme.of(context).chrome.bottom;
  }

  @override
  bool updateShouldNotify(ChromeStyleScope old) =>
      top != old.top || bottom != old.bottom;
}
