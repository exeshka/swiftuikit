import 'package:flutter/material.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

import 'swift_ui_encoders.dart';

part 'swift_ui_glass_theme.tailor.dart';

/// The glass: the flat painter's colours and the parameters of the liquid glass shader (see `LiquidGlass`).
@tailorMixinComponent
@DoubleEncoder()
class SwiftUiGlassTheme extends ThemeExtension<SwiftUiGlassTheme>
    with _$SwiftUiGlassThemeTailorMixin {
  const SwiftUiGlassTheme({
    required this.glassFill,
    required this.glassBorderLight,
    required this.glassBorderDark,
    required this.glassShadow,
    required this.glassIcon,
    required this.glassSigma,
    required this.liquidBezel,
    required this.liquidRefraction,
    required this.liquidBlur,
    required this.liquidSaturation,
    required this.liquidDispersion,
    required this.liquidMagnify,
    required this.liquidHdr,
    required this.liquidPrefilter,
    required this.liquidSpecular,
    required this.liquidGlow,
    required this.liquidToneLift,
    required this.liquidToneGain,
    required this.liquidTint,
    required this.useLiquidGlass,
  });

  const SwiftUiGlassTheme.dark()
    : glassFill = const Color(0x99303034),
      glassBorderLight = const Color(0x4DFFFFFF),
      glassBorderDark = const Color(0x14FFFFFF),
      glassShadow = const Color(0x66000000),
      glassIcon = const Color(0xFFFFFFFF),
      glassSigma = 22,
      liquidBezel = 22,
      liquidRefraction = 1.0,
      liquidBlur = 4.4,
      liquidSaturation = 0.55,
      liquidDispersion = 0.0,
      liquidMagnify = 1.0,
      liquidHdr = 1.0,
      liquidPrefilter = 0.85,
      liquidSpecular = 1.0,
      liquidGlow = 0.03,
      liquidToneLift = 0.1,
      liquidToneGain = 0.257,
      liquidTint = const Color(0x00000000),
      useLiquidGlass = true;

  const SwiftUiGlassTheme.light()
    : glassFill = const Color(0x80FFFFFF),
      glassBorderLight = const Color(0xCCFFFFFF),
      glassBorderDark = const Color(0x14000000),
      glassShadow = const Color(0x26000000),
      glassIcon = const Color(0xFF000000),
      glassSigma = 22,
      liquidBezel = 22,
      liquidRefraction = 1.0,
      liquidBlur = 4.4,
      liquidSaturation = 0.55,
      liquidDispersion = 0.0,
      liquidMagnify = 1.0,
      liquidHdr = 1.0,
      liquidPrefilter = 0.85,
      liquidSpecular = 1.6,
      liquidGlow = 0.10,
      liquidToneLift = 0.686,
      liquidToneGain = 0.298,
      liquidTint = const Color(0x00FFFFFF),
      useLiquidGlass = true;

  // Flat glass (the fallback painter)
  @override
  final Color glassFill;
  @override
  final Color glassBorderLight;
  @override
  final Color glassBorderDark;
  @override
  final Color glassShadow;
  @override
  final Color glassIcon;

  /// Sigma of the flat glass surfaces (buttons).
  @override
  final double glassSigma;

  // Liquid glass
  /// Bezel width in logical px where light bends.
  @override
  final double liquidBezel;

  /// Rim displacement multiplier (1 = native-like: the rim zone shows the content from `liquidBezel` deep).
  @override
  final double liquidRefraction;

  /// Gaussian sigma (logical px) of the blur under the plate.
  @override
  final double liquidBlur;
  @override
  final double liquidSaturation;
  @override
  final double liquidDispersion;

  /// < 1 magnifies the middle of the plate a little.
  @override
  final double liquidMagnify;

  /// Peak brightness of the press highlight and rim, in SDR-white units. 1.0 = SDR only. Set to 1.25 when the app enabled wide
  /// gamut (`FLTEnableWideGamut`) and the EDR flag on the Flutter layer (see docs/hdr-notes.md): the pixel format (BGR10_XR)
  /// tops out at 1.25.
  @override
  final double liquidHdr;

  /// Share of the blur done by an engine blur pass before the shader (0..1). The shader blurs with 40 taps, which aliases thin
  /// features (1 px lines, text strokes); a prefilter of about half the sigma removes that for the price of one extra pass per
  /// plate or group. 0 = shader only (fastest).
  @override
  final double liquidPrefilter;
  @override
  final double liquidSpecular;
  @override
  final double liquidGlow;

  /// Luminance tone map of the glass interior: out = lift + gain * in (fitted to native glass on a gray ramp). Identity: lift
  /// 0, gain 1.
  @override
  final double liquidToneLift;
  @override
  final double liquidToneGain;

  /// Tint laid over the refracted backdrop (alpha = amount).
  @override
  final Color liquidTint;

  /// Glass buttons/plates use the liquid glass shader (when the renderer supports it) instead of the flat glass painter.
  @override
  final bool useLiquidGlass;
}
