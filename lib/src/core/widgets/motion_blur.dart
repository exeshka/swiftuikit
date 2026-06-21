import 'dart:ui';

import 'package:flutter/material.dart';

class MotionBlur extends StatelessWidget {
  const MotionBlur({
    super.key,
    required this.child,
    this.opacity = 1,
    this.blurSigma = 0,
    this.smearOffset = Offset.zero,
    this.smearIntensity = 0,
  });

  final Widget child;
  final double opacity;
  final double blurSigma;
  final Offset smearOffset;
  final double smearIntensity;

  @override
  Widget build(BuildContext context) {
    final effectiveOpacity = opacity.clamp(0.0, 1.0);
    if (effectiveOpacity == 0) {
      return const SizedBox.shrink();
    }

    Widget content = _SmearBlur(
      smearOffset: smearOffset,
      smearIntensity: smearIntensity,
      child: child,
    );

    final effectiveBlur = blurSigma.clamp(0.0, double.infinity);
    if (effectiveBlur > 0.01) {
      content = ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: effectiveBlur,
          sigmaY: effectiveBlur,
        ),
        child: content,
      );
    }

    if (effectiveOpacity < 0.999) {
      content = Opacity(opacity: effectiveOpacity, child: content);
    }

    return content;
  }
}

class _SmearBlur extends StatelessWidget {
  const _SmearBlur({
    required this.smearOffset,
    required this.smearIntensity,
    required this.child,
  });

  final Offset smearOffset;
  final double smearIntensity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final intensity = smearIntensity.clamp(0.0, 1.0);
    if (smearOffset == Offset.zero || intensity == 0) {
      return child;
    }

    return Stack(
      fit: StackFit.passthrough,
      children: [
        Transform.translate(
          offset: -smearOffset,
          child: Opacity(opacity: 0.16 * intensity, child: child),
        ),
        Transform.translate(
          offset: smearOffset * -0.45,
          child: Opacity(opacity: 0.22 * intensity, child: child),
        ),
        child,
      ],
    );
  }
}
