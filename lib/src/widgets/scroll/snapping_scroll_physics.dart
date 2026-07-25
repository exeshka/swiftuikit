import 'package:flutter/material.dart';

class SnapSpringConfig {
  final double mass;
  final double stiffness;
  final double damping;

  const SnapSpringConfig({
    this.mass = 0.5,
    this.stiffness = 100,
    this.damping = 20,
  });

  SpringDescription get spring =>
      SpringDescription(mass: mass, stiffness: stiffness, damping: damping);

  static const smooth = SnapSpringConfig(mass: 1, stiffness: 150, damping: 26);

  static const snappy = SnapSpringConfig(
    mass: 0.5,
    stiffness: 200,
    damping: 18,
  );

  static const bouncy = SnapSpringConfig(mass: 0.6, stiffness: 90, damping: 10);
}

class SnappingScrollPhysics extends ScrollPhysics {
  final List<double> snapPoints;

  final SnapSpringConfig springConfig;

  final double? flingVelocityThreshold;

  final double snapThreshold;

  final double? minSnapRange;
  final double? maxSnapRange;

  final bool enabled;

  const SnappingScrollPhysics({
    required this.snapPoints,
    this.springConfig = SnapSpringConfig.smooth,
    this.flingVelocityThreshold,
    this.snapThreshold = 0.5,
    this.minSnapRange,
    this.maxSnapRange,
    this.enabled = true,
    super.parent,
  }) : assert(snapThreshold >= 0 && snapThreshold <= 1);

  @override
  SnappingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SnappingScrollPhysics(
      snapPoints: snapPoints,
      springConfig: springConfig,
      flingVelocityThreshold: flingVelocityThreshold,
      snapThreshold: snapThreshold,
      minSnapRange: minSnapRange,
      maxSnapRange: maxSnapRange,
      enabled: enabled,
      parent: buildParent(ancestor),
    );
  }

  bool _withinSnapRange(double pixels) {
    final lo = minSnapRange ?? snapPoints.first;
    final hi = maxSnapRange ?? snapPoints.last;
    return pixels >= lo && pixels <= hi;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if (!enabled ||
        snapPoints.length < 2 ||
        !_withinSnapRange(position.pixels)) {
      return super.createBallisticSimulation(position, velocity);
    }

    final tolerance = toleranceFor(position);
    final target = _resolveTarget(
      position.pixels,
      velocity,
      tolerance.velocity,
    );
    if (target == position.pixels) return null;

    return ScrollSpringSimulation(
      springConfig.spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }

  double _resolveTarget(
    double pixels,
    double velocity,
    double defaultVelocityThreshold,
  ) {
    double lower = snapPoints.first;
    double upper = snapPoints.last;
    for (var i = 0; i < snapPoints.length - 1; i++) {
      if (pixels >= snapPoints[i] && pixels <= snapPoints[i + 1]) {
        lower = snapPoints[i];
        upper = snapPoints[i + 1];
        break;
      }
    }

    final velocityThreshold =
        flingVelocityThreshold ?? defaultVelocityThreshold;

    if (velocity.abs() >= velocityThreshold) {
      return velocity > 0 ? upper : lower;
    }

    final progress = (pixels - lower) / (upper - lower);
    return progress < snapThreshold ? lower : upper;
  }
}
