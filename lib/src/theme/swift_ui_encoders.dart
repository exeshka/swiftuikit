import 'dart:ui' show lerpDouble;

import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

import '../chrome/chrome_style.dart';

/// Interpolates doubles linearly (the generator only knows `Color` and `TextStyle` by itself).
class DoubleEncoder extends ThemeEncoder<double> {
  const DoubleEncoder();

  @override
  double lerp(double a, double b, double t) => lerpDouble(a, b, t)!;
}

/// A [ChromeStyle] cannot be interpolated: the theme switches to the other one half way through an animated change.
class ChromeStyleEncoder extends ThemeEncoder<ChromeStyle> {
  const ChromeStyleEncoder();

  @override
  ChromeStyle lerp(ChromeStyle a, ChromeStyle b, double t) => t < 0.5 ? a : b;
}
