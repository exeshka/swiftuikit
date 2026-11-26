import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../theme/swift_ui_theme.dart';
import 'liquid_glass.dart';

/// Glass plate. With the liquid shader it is real glass (refraction, rim, shadow).
/// Without it (`liquid: false`, no shader support, backdrop blur) the plate is
/// deliberately FLAT: one translucent fill, a touch darker than the theme glass,
/// no outline, no highlight, no shadow. A flat plate that imitates glass (rim,
/// specular arcs, drop shadow) just looks like a bad copy of the real thing.
///
/// The flat plate is one solid primitive (circle / rrect), the cheapest possible
/// draw: the obvious widget version (nested `ShapeDecoration`s + `ClipPath`)
/// measured at ~0.45 ms per button on the raster thread. See README.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    this.child,
    this.shape = const StadiumBorder(),
    this.sigma,
    this.fill,
    this.backdropBlur = false,
    this.liquid,
    this.interactive = false,
    this.shadow = true,
    this.width,
    this.height,
    this.padding,
    this.alignment,
  });

  /// Circle disc convenience.
  const GlassSurface.circle({
    super.key,
    this.child,
    required double size,
    this.sigma,
    this.fill,
    this.backdropBlur = false,
    this.liquid,
    this.interactive = false,
    this.shadow = true,
  }) : shape = const CircleBorder(),
       width = size,
       height = size,
       padding = null,
       alignment = Alignment.center;

  final Widget? child;
  final ShapeBorder shape;
  final double? sigma;
  final Color? fill;

  /// Blur what is behind the plate. Off by default: every backdrop blur is a
  /// separate offscreen pass, which adds up fast with many buttons in a
  /// scrolling list. Not needed inside the chrome zones, where the content
  /// behind is already blurred.
  final bool backdropBlur;

  /// Use the liquid glass shader. null: [SwiftUiThemeData.useLiquidGlass].
  /// Falls back to the flat painter where shaders are unsupported, and for
  /// shapes other than circle / stadium / rounded rectangle.
  final bool? liquid;

  /// Press response of native glass (spring scale, highlight, rubber band), only with the liquid shader.
  final bool interactive;
  final bool shadow;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    Widget content = child ?? const SizedBox.shrink();
    if (padding != null) content = Padding(padding: padding!, child: content);
    if (alignment != null)
      content = Align(alignment: alignment!, child: content);

    if (!backdropBlur &&
        (liquid ?? t.glass.useLiquidGlass) &&
        LiquidGlass.supported) {
      final s = shape;
      if (s is CircleBorder ||
          s is StadiumBorder ||
          s is RoundedRectangleBorder) {
        return LiquidGlass(
          width: width,
          height: height,
          cornerRadius: s is RoundedRectangleBorder
              ? s.borderRadius.resolve(TextDirection.ltr).topLeft.x
              : null,
          shadow: shadow,
          tint: fill,
          interactive: interactive,
          child: content,
        );
      }
    }
    if (!backdropBlur && interactive) {
      final s = shape;
      if (s is CircleBorder ||
          s is StadiumBorder ||
          s is RoundedRectangleBorder) {
        // A flat plate keeps the press response of the glass (grow, highlight, stretch under a drag): LiquidGlass in its
        // flat mode, no shader.
        return LiquidGlass(
          flat: true,
          width: width,
          height: height,
          cornerRadius: s is RoundedRectangleBorder
              ? s.borderRadius.resolve(TextDirection.ltr).topLeft.x
              : null,
          shadow: shadow,
          tint: fill,
          interactive: true,
          child: content,
        );
      }
    }
    final dir = Directionality.maybeOf(context) ?? TextDirection.ltr;
    Widget plate = CustomPaint(
      painter: _FlatPainter(
        shape: shape,
        dir: dir,
        // An explicit fill is the caller's colour and is kept as is; the theme glass is darkened a little.
        fill:
            fill ??
            flatFill(t.glass.glassFill, t.colors.background, isDark: t.isDark),
        shadow: shadow ? t.glass.glassShadow : null,
      ),
      child: content,
    );

    if (backdropBlur) {
      final s = sigma ?? t.glass.glassSigma;
      plate = Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: ClipPath(
              clipper: ShapeBorderClipper(shape: shape, textDirection: dir),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: s, sigmaY: s),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          plate,
        ],
      );
    }
    return SizedBox(width: width, height: height, child: plate);
  }
}

/// Flat plate colour: SOLID, no transparency. Dark theme: the theme glass laid over the page background (the tone the glass
/// has there) and a touch darker. Light theme: plain white (a plate darker than the page looked like a gray stain).
Color flatFill(Color glass, Color background, {bool isDark = true}) {
  if (!isDark) return const Color(0xFFFFFFFF);
  final solid = Color.alphaBlend(glass, background.withValues(alpha: 1));
  return Color.lerp(solid, const Color(0xFF000000), 0.22)!.withValues(alpha: 1);
}

class _FlatPainter extends CustomPainter {
  _FlatPainter({
    required this.shape,
    required this.dir,
    required this.fill,
    this.shadow,
  });

  final ShapeBorder shape;
  final TextDirection dir;
  final Color fill;
  final Color? shadow;

  /// Draws [shape] with a primitive when possible (cheap), else as a path.
  void _draw(Canvas canvas, Rect rect, Paint paint) {
    final s = shape;
    if (s is CircleBorder) {
      canvas.drawCircle(rect.center, rect.shortestSide / 2, paint);
    } else if (s is StadiumBorder) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(rect.shortestSide / 2)),
        paint,
      );
    } else if (s is RoundedRectangleBorder) {
      canvas.drawRRect(s.borderRadius.resolve(dir).toRRect(rect), paint);
    } else {
      canvas.drawPath(s.getOuterPath(rect, textDirection: dir), paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (shadow != null) {
      // the soft drop shadow under the plate (it lifts a flat plate off the page; no rim, no highlight)
      _draw(
        canvas,
        rect.shift(const Offset(0, 5)),
        Paint()
          ..color = shadow!
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
    }
    _draw(canvas, rect, Paint()..color = fill);
  }

  @override
  bool shouldRepaint(_FlatPainter old) =>
      old.shape != shape ||
      old.fill != fill ||
      old.dir != dir ||
      old.shadow != shadow;
}
