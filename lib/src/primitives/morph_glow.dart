import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class MorphGlow extends StatelessWidget {
  const MorphGlow({
    super.key,
    required this.child,
    this.glowColor = Colors.white24,
    this.glowRadius = 1,
    this.hitTestBehavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final Color glowColor;
  final double glowRadius;
  final HitTestBehavior hitTestBehavior;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: hitTestBehavior,
      onPointerDown: (event) => _updateGlow(context, event.localPosition),
      onPointerMove: (event) => _updateGlow(context, event.localPosition),
      onPointerUp: (event) => _removeGlow(context),
      onPointerCancel: (event) => _removeGlow(context),
      child: child,
    );
  }

  void _updateGlow(BuildContext context, Offset position) {
    MorphGlowLayer.maybeOf(
      context,
    )?.updateTouch(position, radius: glowRadius, color: glowColor);
  }

  void _removeGlow(BuildContext context) {
    MorphGlowLayer.maybeOf(context)?.removeTouch();
  }
}

class MorphGlowLayer extends StatefulWidget {
  const MorphGlowLayer({
    super.key,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.clipBehavior = Clip.hardEdge,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final Clip clipBehavior;

  @override
  State<MorphGlowLayer> createState() => MorphGlowLayerState();

  static MorphGlowLayerState? maybeOf(BuildContext context) {
    if (!context.mounted) {
      return null;
    }

    return context.findAncestorStateOfType<MorphGlowLayerState>();
  }
}

class MorphGlowLayerState extends State<MorphGlowLayer>
    with TickerProviderStateMixin {
  late final AnimationController _presenceController;

  late final AnimationController _offsetController;

  bool _dragging = false;
  double _baseRadius = 1;
  Color _baseColor = Colors.transparent;
  Offset _offset = Offset.zero;
  Offset _fromOffset = Offset.zero;
  Offset _toOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _presenceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 420),
    )..addListener(_tick);
    _offsetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..addListener(_tick);
  }

  @override
  void dispose() {
    _presenceController
      ..removeListener(_tick)
      ..dispose();
    _offsetController
      ..removeListener(_tick)
      ..dispose();
    super.dispose();
  }

  void updateTouch(
    Offset offset, {
    required double radius,
    required Color color,
  }) {
    _baseRadius = radius;
    _baseColor = color;
    _offset = offset;
    _toOffset = offset;
    _offsetController.stop();

    if (!_dragging) {
      _dragging = true;
      _presenceController.forward();
    }

    setState(() {});
  }

  void removeTouch() {
    if (!_dragging) {
      return;
    }

    _dragging = false;
    _fromOffset = _offset;
    _toOffset = Offset.zero;
    _offsetController.forward(from: 0);
    _presenceController.reverse();
  }

  void _tick() {
    if (!_dragging && _offsetController.isAnimating) {
      final t = Curves.easeOutCubic.transform(_offsetController.value);
      _offset = Offset.lerp(_fromOffset, _toOffset, t) ?? Offset.zero;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final alpha = Curves.easeOutCubic.transform(_presenceController.value);
    final radius = _baseRadius * (1 + (1 - alpha) * 9);

    return _RenderMorphGlowLayerWidget(
      borderRadius: widget.borderRadius,
      clipBehavior: widget.clipBehavior,
      glowRadius: radius,
      glowColor: _baseColor.withValues(alpha: _baseColor.a * alpha),
      glowOffset: _offset,
      child: widget.child,
    );
  }
}

class _RenderMorphGlowLayerWidget extends SingleChildRenderObjectWidget {
  const _RenderMorphGlowLayerWidget({
    required this.borderRadius,
    required this.clipBehavior,
    required this.glowRadius,
    required this.glowColor,
    required this.glowOffset,
    required super.child,
  });

  final BorderRadius borderRadius;
  final Clip clipBehavior;
  final double glowRadius;
  final Color glowColor;
  final Offset glowOffset;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMorphGlowLayer(
      borderRadius: borderRadius,
      clipBehavior: clipBehavior,
      glowRadius: glowRadius,
      glowColor: glowColor,
      glowOffset: glowOffset,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderMorphGlowLayer renderObject,
  ) {
    renderObject
      ..borderRadius = borderRadius
      ..clipBehavior = clipBehavior
      ..glowRadius = glowRadius
      ..glowColor = glowColor
      ..glowOffset = glowOffset;
  }
}

class _RenderMorphGlowLayer extends RenderProxyBox {
  _RenderMorphGlowLayer({
    required this._borderRadius,
    required this._clipBehavior,
    required this._glowRadius,
    required this._glowColor,
    required this._glowOffset,
  });

  BorderRadius _borderRadius;
  Clip _clipBehavior;
  double _glowRadius;
  Color _glowColor;
  Offset _glowOffset;

  set borderRadius(BorderRadius value) {
    if (_borderRadius == value) {
      return;
    }
    _borderRadius = value;
    markNeedsPaint();
  }

  set clipBehavior(Clip value) {
    if (_clipBehavior == value) {
      return;
    }
    _clipBehavior = value;
    markNeedsPaint();
  }

  set glowRadius(double value) {
    if (_glowRadius == value) {
      return;
    }
    _glowRadius = value;
    markNeedsPaint();
  }

  set glowColor(Color value) {
    if (_glowColor == value) {
      return;
    }
    _glowColor = value;
    markNeedsPaint();
  }

  set glowOffset(Offset value) {
    if (_glowOffset == value) {
      return;
    }
    _glowOffset = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_glowColor.a == 0 || _glowRadius <= 0) {
      super.paint(context, offset);
      return;
    }

    final canvas = context.canvas..save();
    _clipGlow(canvas, offset);
    final glowPosition = offset + _glowOffset;
    final radius = _glowRadius * size.shortestSide;
    final gradient = RadialGradient(
      colors: [_glowColor, _glowColor.withValues(alpha: 0)],
      stops: const [0, 1],
    );
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: glowPosition, radius: radius),
      )
      ..blendMode = BlendMode.plus;

    canvas
      ..drawCircle(glowPosition, radius, paint)
      ..restore();
    super.paint(context, offset);
  }

  void _clipGlow(Canvas canvas, Offset offset) {
    if (_clipBehavior == Clip.none) {
      return;
    }

    final rect = offset & size;
    if (_borderRadius == BorderRadius.zero) {
      canvas.clipRect(rect, doAntiAlias: _clipBehavior != Clip.hardEdge);
      return;
    }

    canvas.clipRRect(
      _borderRadius.toRRect(rect),
      doAntiAlias: _clipBehavior != Clip.hardEdge,
    );
  }
}
