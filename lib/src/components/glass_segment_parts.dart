import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../theme/swift_ui_theme.dart';
import 'glass_lens.dart';
import 'liquid_glass.dart';

/// The look shared by the segmented controls (measured on the native iOS 26 segmented control): the frosted track, the
/// white thumb and the glass lens it turns into while it is pressed.
class SegmentVisuals {
  const SegmentVisuals._();

  /// The glass lens is this much bigger than the thumb (+13 wide, ~7 pt past the track at the top and bottom).
  static const growW = 13.0;
  static const growH = 18.0;

  /// The translucent stadium track; it blurs what is behind it (native: the photo shows through, frosted).
  static Widget track(SwiftUiThemeData t) => ClipPath(
    clipper: const SegmentStadiumClip(),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: ColoredBox(
        color: t.isDark ? const Color(0x26000000) : const Color(0x14000000),
      ),
    ),
  );

  /// The track as a liquid glass capsule (messenger-style strips): it shows the backdrop frosted and has the glass rim.
  static Widget glassTrack(double width, double height) => SizedBox(
    width: width,
    height: height,
    child: LiquidGlass(width: width, height: height),
  );

  /// Layers of the thumb for a [Stack] (`clipBehavior: Clip.none`): the lens, its bright band and the white thumb above
  /// them. [left]/[top]/[width]/[height] is the thumb at rest, [k] the press (0..1, may overshoot).
  static List<Widget> thumb(
    SwiftUiThemeData t, {
    required double left,
    required double top,
    required double width,
    required double height,
    required double k,
    Color? restColor,
    double refraction = GlassLens.refraction,
    double? growWidth,
    double? growHeight,
    double lensBlur = 0.6,
    double? darkToneLift,
    double bezel = GlassLens.bezel,
    double magnify = 1.0,
    bool lens = true,
    bool rest = true,
  }) {
    final w = width + (growWidth ?? growW) * k;
    final h = height + (growHeight ?? growH) * k;
    final lensLeft = left - (w - width) / 2;
    final lensTop = top - (h - height) / 2;
    final restOpacity = 1 - glassSmoothstep(0.05, 0.75, k);
    return [
      if (lens && k > 0.02)
        Positioned(
          left: lensLeft,
          top: lensTop,
          child: GlassLens(
            width: w,
            height: h,
            blur: lensBlur,
            magnify: magnify,
            refractionStrength: refraction,
            bezelWidth: bezel,
            toneLift: t.isDark ? darkToneLift : -0.045,
            shadowScale: t.isDark ? 1 : 0.5,
            shadowOpacity: glassSmoothstep(0.2, 0.9, k),
          ),
        ),
      // native: through the lower part of the lens the (white) page below the track shows as a bright band
      if (lens && k > 0.02 && !t.isDark)
        Positioned(
          left: lensLeft,
          top: lensTop,
          width: w,
          height: h,
          child: IgnorePointer(
            child: Opacity(
              opacity: glassSmoothstep(0.3, 1.0, k),
              child: ClipPath(
                clipper: const SegmentStadiumClip(),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: 0.2,
                    widthFactor: 1,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xB3FFFFFF), Color(0x99FFFFFF)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      // the thumb ABOVE the lens: it turns frosted over the full-size lens and then is the thumb (as in the switch)
      if (rest)
        Positioned(
          left: left,
          top: top,
          width: width,
          height: height,
          child: Opacity(
            opacity: restOpacity,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                shape: const StadiumBorder(),
                color:
                    restColor ??
                    (t.isDark
                        ? const Color(0x59FFFFFF)
                        : const Color(0xFFFFFFFF)),
                shadows: (t.isDark || restColor != null)
                    ? null
                    : const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
              ),
            ),
          ),
        ),
    ];
  }

  /// Label text style: [selected] 0..1 fades between the idle and the selected look.
  static TextStyle labelStyle(SwiftUiThemeData t, double selected) =>
      t.typography.body.copyWith(
        fontSize: 15,
        fontWeight: selected > 0.5 ? FontWeight.w600 : FontWeight.w500,
        color: Color.lerp(
          t.colors.foreground.withValues(alpha: 0.75),
          t.colors.foreground,
          selected,
        ),
      );
}

class SegmentStadiumClip extends CustomClipper<Path> {
  const SegmentStadiumClip();
  @override
  Path getClip(Size s) => Path()
    ..addRRect(
      RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(s.height / 2)),
    );
  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}
