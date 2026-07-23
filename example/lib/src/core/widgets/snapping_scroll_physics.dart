import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Конфиг одной "пружины" — можно настроить отдельно под разные переходы,
/// либо использовать один и тот же на весь физику.
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

  /// Плавно, без овершута (критическое затухание)
  static const smooth = SnapSpringConfig(mass: 1, stiffness: 150, damping: 26);

  /// Быстро и туго, лёгкий bounce на подлёте
  static const snappy = SnapSpringConfig(
    mass: 0.5,
    stiffness: 200,
    damping: 18,
  );

  /// Мягко, с заметным овершутом ("желейный" эффект)
  static const bouncy = SnapSpringConfig(mass: 0.6, stiffness: 90, damping: 10);
}

class SnappingScrollPhysics extends ScrollPhysics {
  /// Точки, к которым может "прилипать" скролл. Обязательно отсортированы по возрастанию.
  final List<double> snapPoints;

  /// Пружина для докатывания к точке снапа.
  final SnapSpringConfig springConfig;

  /// Минимальная скорость (px/s), при которой снап идёт "по направлению флика",
  /// а не к ближайшей точке. Если null — используется tolerance.velocity.
  final double? flingVelocityThreshold;

  /// Доля дистанции между двумя точками снапа (0..1), после которой,
  /// при отпускании без импульса, снап идёт к следующей точке, а не к предыдущей.
  /// 0.5 = ровно середина.
  final double snapThreshold;

  /// Если задано — снап работает только внутри этого диапазона [min, max].
  /// За его пределами (например глубокий overscroll или далёкий скролл по списку)
  /// используется physics.parent как есть, без вмешательства.
  final double? minSnapRange;
  final double? maxSnapRange;

  /// Полностью выключить снап (удобно для условного тумблера без пересборки дерева).
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

    final target = _resolveTarget(position.pixels, velocity);
    if (target == position.pixels) return null;

    return ScrollSpringSimulation(
      springConfig.spring,
      position.pixels,
      target,
      velocity,
      tolerance: toleranceFor(position),
    );
  }

  double _resolveTarget(double pixels, double velocity) {
    // находим соседние точки снапа вокруг текущей позиции
    double lower = snapPoints.first;
    double upper = snapPoints.last;
    for (var i = 0; i < snapPoints.length - 1; i++) {
      if (pixels >= snapPoints[i] && pixels <= snapPoints[i + 1]) {
        lower = snapPoints[i];
        upper = snapPoints[i + 1];
        break;
      }
    }

    final velocityThreshold = flingVelocityThreshold ?? tolerance.velocity;

    if (velocity.abs() >= velocityThreshold) {
      // есть импульс — снапаем по направлению флика к соседней точке
      return velocity > 0 ? upper : lower;
    }

    // импульса нет — снапаем по порогу дистанции
    final progress = (pixels - lower) / (upper - lower);
    return progress < snapThreshold ? lower : upper;
  }
}
