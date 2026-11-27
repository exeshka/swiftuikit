import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// The edge lens of liquid glass over its own content: the content within [bezel] of the rim of a rounded rectangle is read from
/// deeper inside along the normal (stretched towards the rim) and everything outside the rounded rectangle is cut away. The child
/// is laid out to the rectangle's size (the parent constrains it); the corner radii are [radii] (logical px). Without a shader
/// (no Impeller, a test) the child is just clipped by the contour.
class ContentLens extends StatelessWidget {
  const ContentLens({
    super.key,
    required this.radii,
    required this.child,
    this.bezel = 14,
    this.strength = 1,
  });

  final BorderRadius radii;
  final double bezel;
  final double strength;
  final Widget child;

  static ui.FragmentProgram? _program;
  static Future<ui.FragmentProgram>? _loading;

  static Future<void> preload() async {
    if (_program != null) return;
    try {
      _loading ??= ui.FragmentProgram.fromAsset(
        'packages/swiftuikit/shaders/content_lens.frag',
      );
      _program = await _loading;
    } catch (_) {
      _loading = null;
    }
  }

  static bool get supported =>
      ui.ImageFilter.isShaderFilterSupported && _program != null;

  @override
  Widget build(BuildContext context) {
    final clipped = ClipRRect(borderRadius: radii, child: child);
    if (!supported || strength <= 0) return clipped;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    // a new shader (and so a new filter) per build: the engine snapshots the uniforms when the filter is created
    final sh = _program!.fragmentShader();
    // uniforms 0, 1 (size) are filled in by the engine
    sh
      ..setFloat(2, radii.topLeft.x * dpr)
      ..setFloat(3, radii.topRight.x * dpr)
      ..setFloat(4, radii.bottomRight.x * dpr)
      ..setFloat(5, radii.bottomLeft.x * dpr)
      ..setFloat(6, bezel * dpr)
      ..setFloat(7, strength);
    return ImageFiltered(
      imageFilter: ui.ImageFilter.shader(sh),
      child: ClipRect(child: child),
    );
  }
}
