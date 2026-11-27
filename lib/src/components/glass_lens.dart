import 'package:flutter/material.dart' show Theme;
import 'package:flutter/widgets.dart';

import '../theme/swift_ui_theme.dart';
import 'liquid_glass.dart';

/// The glass "bubble" a thumb turns into while it is pressed (switch, segmented control, slider): a clear liquid glass
/// capsule (thin rim lens, the track shows through minified inside, bright hairline) with a soft shadow in [shadowColor].
/// Fitted to the native switch thumb; see `GlassSwitch`.
class GlassLens extends StatelessWidget {
  const GlassLens({
    super.key,
    required this.width,
    required this.height,
    this.shadowColor,
    this.cornerRadius,
    this.blur = 0.5,
    this.toneLift,
    this.shadowScale = 1,
    this.shadowOpacity = 1,
    this.magnify = magnifyDefault,
    this.bezelWidth = bezel,
    this.refractionStrength = refraction,
    this.specularStrength = specular,
  });

  /// Brightness of the rim's hairline highlight.
  final double specularStrength;

  /// How strongly the rim bends what is behind it (a lens over a high-contrast backdrop, like a bar's edge, wants less).
  final double refractionStrength;

  /// Scale of what is seen through the lens centre (>1 minifies); 1 gives no inner edge.
  final double magnify;
  final double bezelWidth;

  /// See [LiquidGlass.toneLift].
  final double? toneLift;

  /// Multiplies the shadow strength (a light backdrop wants a softer one).
  final double shadowScale;

  /// 0..1, fades the shadow only (the glass is drawn as is): lets it vanish before the lens does while the thumb shrinks back.
  final double shadowOpacity;

  /// Blur of the glass interior (soft backdrops need more to avoid aliased refracted edges).
  final double blur;

  final double width;
  final double height;
  final Color? shadowColor;

  /// null: fully round.
  final double? cornerRadius;

  static const magnifyDefault = 1.5;
  static const refraction = 1.4;
  static const bezel = 7.0;
  static const specular = 1.6;

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final shape = cornerRadius == null
        ? const StadiumBorder()
        : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cornerRadius!),
          );
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // clear glass draws no shadow of its own; the glass covers this inside, so it only shows around the lens
          // clipped to the outside of the lens: on a light background the shadow would otherwise show through the clear glass
          Positioned(
            left: -40,
            top: -40,
            right: -40,
            bottom: -40,
            child: ClipPath(
              clipper: _OutsideClip(
                RRect.fromRectAndRadius(
                  Rect.fromLTWH(40, 40, width, height),
                  Radius.circular(cornerRadius ?? height / 2),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: shape,
                    shadows: [
                      BoxShadow(
                        color: (shadowColor ?? const Color(0xFF000000))
                            .withValues(
                              alpha: 0.30 * shadowScale * shadowOpacity,
                            ),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: const Color(
                          0xFF000000,
                        ).withValues(alpha: 0.2 * shadowScale * shadowOpacity),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Theme(
              data: Theme.of(context).copyWith(
                extensions: [
                  t.copyWith(
                    glass: t.glass.copyWith(
                      liquidMagnify: magnify,
                      liquidSpecular: specularStrength,
                    ),
                  ),
                ],
              ),
              child: LiquidGlass(
                width: width,
                height: height,
                cornerRadius: cornerRadius,
                clear: true,
                blur: blur,
                toneLift: toneLift,
                refraction: refractionStrength,
                bezel: bezelWidth,
                shadow: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 0..1 smoothstep, shared by the thumbs that cross-fade between their rest look and the lens.
double glassSmoothstep(double a, double b, double x) {
  final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// Everything inside the layer except the given rounded rect.
class _OutsideClip extends CustomClipper<Path> {
  const _OutsideClip(this.hole);
  final RRect hole;
  @override
  Path getClip(Size size) => Path.combine(
    PathOperation.difference,
    Path()..addRect(Offset.zero & size),
    Path()..addRRect(hole),
  );
  @override
  bool shouldReclip(covariant _OutsideClip old) => old.hole != hole;
}
