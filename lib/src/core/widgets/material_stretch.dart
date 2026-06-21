import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class MorphStretch extends StatefulWidget {
  const MorphStretch({
    super.key,
    required this.child,
    this.interactionScale = 1.05,
    this.stretch = 0.5,
    this.resistance = 0.08,
    this.hitTestBehavior = HitTestBehavior.opaque,
    this.releaseDuration = const Duration(milliseconds: 360),
  });

  final Widget child;
  final double interactionScale;
  final double stretch;
  final double resistance;
  final HitTestBehavior hitTestBehavior;
  final Duration releaseDuration;

  @override
  State<MorphStretch> createState() => _MorphStretchState();
}

class _MorphStretchState extends State<MorphStretch>
    with SingleTickerProviderStateMixin {
  AnimationController? _releaseController;

  int? _pointer;
  Offset _start = Offset.zero;
  Offset _drag = Offset.zero;
  Offset _releaseStart = Offset.zero;

  bool get _isInteracting => _pointer != null;

  @override
  void initState() {
    super.initState();
    _releaseController = AnimationController(
      vsync: this,
      duration: widget.releaseDuration,
    )..addListener(_tickRelease);
  }

  @override
  void didUpdateWidget(MorphStretch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.releaseDuration != widget.releaseDuration) {
      _releaseController?.duration = widget.releaseDuration;
    }
  }

  @override
  void dispose() {
    final releaseController = _releaseController;
    _releaseController = null;
    if (releaseController != null) {
      releaseController
        ..removeListener(_tickRelease)
        ..dispose();
    }
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_pointer != null) {
      return;
    }

    _releaseController?.stop();
    setState(() {
      _pointer = event.pointer;
      _start = event.localPosition;
      _drag = Offset.zero;
    });
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (event.pointer != _pointer) {
      return;
    }

    setState(() {
      _drag = (event.localPosition - _start).withResistance(widget.resistance);
    });
  }

  void _handlePointerEnd(PointerEvent event) {
    if (event.pointer != _pointer) {
      return;
    }

    _pointer = null;
    _releaseStart = _drag;
    _releaseController?.forward(from: 0);
    setState(() {});
  }

  void _tickRelease() {
    final releaseController = _releaseController;
    if (releaseController == null) {
      return;
    }

    final t = Curves.easeOutCubic.transform(releaseController.value);
    setState(() {
      _drag = Offset.lerp(_releaseStart, Offset.zero, t) ?? Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stretch == 0 && widget.interactionScale == 1) {
      return widget.child;
    }

    return Listener(
      behavior: widget.hitTestBehavior,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerEnd,
      onPointerCancel: _handlePointerEnd,
      child: AnimatedScale(
        scale: _isInteracting ? widget.interactionScale : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: RawMorphStretch(
          stretchPixels: _drag * widget.stretch,
          child: widget.child,
        ),
      ),
    );
  }
}

class RawMorphStretch extends SingleChildRenderObjectWidget {
  const RawMorphStretch({
    super.key,
    required this.stretchPixels,
    required super.child,
  });

  final Offset stretchPixels;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderRawMorphStretch(stretchPixels: stretchPixels);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderRawMorphStretch renderObject,
  ) {
    renderObject.stretchPixels = stretchPixels;
  }
}

class RenderRawMorphStretch extends RenderProxyBox {
  RenderRawMorphStretch({required this._stretchPixels});

  Offset _stretchPixels;

  Offset get stretchPixels => _stretchPixels;
  set stretchPixels(Offset value) {
    if (_stretchPixels == value) {
      return;
    }

    _stretchPixels = value;
    markNeedsPaint();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    return hitTestChildren(result, position: position);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final transform = _effectiveTransform();
    if (transform == null) {
      return super.hitTestChildren(result, position: position);
    }

    return result.addWithPaintTransform(
      transform: transform,
      position: position,
      hitTest: (result, position) {
        return super.hitTestChildren(result, position: position);
      },
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      return;
    }

    final transform = _effectiveTransform();
    if (transform == null) {
      super.paint(context, offset);
      return;
    }

    if (transform.determinant() == 0 || !transform.determinant().isFinite) {
      layer = null;
      return;
    }

    layer = context.pushTransform(
      needsCompositing,
      offset,
      transform,
      super.paint,
      oldLayer: layer is TransformLayer ? layer as TransformLayer? : null,
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final effectiveTransform = _effectiveTransform();
    if (effectiveTransform != null) {
      transform.multiply(effectiveTransform);
    }
  }

  Matrix4? _effectiveTransform() {
    if (_stretchPixels == Offset.zero || size.isEmpty) {
      return null;
    }

    final scale = _scaleFor(stretchPixels: _stretchPixels, size: size);

    return Matrix4.identity()
      ..scaleByDouble(scale.dx, scale.dy, 1, 1)
      ..translateByDouble(_stretchPixels.dx, _stretchPixels.dy, 0, 1);
  }

  Offset _scaleFor({required Offset stretchPixels, required Size size}) {
    final stretchX = stretchPixels.dx.abs();
    final stretchY = stretchPixels.dy.abs();
    final relativeStretchX = size.width > 0 ? stretchX / size.width : 0.0;
    final relativeStretchY = size.height > 0 ? stretchY / size.height : 0.0;

    final baseScaleX = 1 + relativeStretchX;
    final baseScaleY = 1 + relativeStretchY;
    final magnitude = math.sqrt(
      relativeStretchX * relativeStretchX + relativeStretchY * relativeStretchY,
    );
    final targetVolume = 1 + magnitude * 0.5;
    final currentVolume = baseScaleX * baseScaleY;
    final volumeCorrection = math.sqrt(targetVolume / currentVolume);

    return Offset(baseScaleX * volumeCorrection, baseScaleY * volumeCorrection);
  }
}

extension OffsetResistanceExtension on Offset {
  Offset withResistance(double resistance) {
    if (resistance == 0) {
      return this;
    }

    final magnitude = distance;
    if (magnitude == 0) {
      return Offset.zero;
    }

    final resistedMagnitude = magnitude / (1 + magnitude * resistance);
    return this * (resistedMagnitude / magnitude);
  }
}

typedef LiquidStretch = MorphStretch;
typedef RawLiquidStretch = RawMorphStretch;
