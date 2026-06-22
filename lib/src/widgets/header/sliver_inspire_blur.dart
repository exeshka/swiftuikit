// ignore_for_file: prefer_initializing_formals
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:inspire_blur/inspire_blur.dart';
// ignore: implementation_imports
import 'package:inspire_blur/src/inspire_shaders.dart';

/// A sliver widget that applies an Inspire backdrop blur shader effect.
class SliverInspireBlur extends StatefulWidget {
  const SliverInspireBlur({
    super.key,
    required this.config,
    this.clipBehavior = Clip.antiAlias,
    this.child,
  });

  final InspireBlurConfig config;
  final Clip clipBehavior;
  final Widget? child;

  @override
  State<SliverInspireBlur> createState() => _SliverInspireBlurState();
}

class _SliverInspireBlurState extends State<SliverInspireBlur> {
  ui.FragmentShader? _horizontalShader;
  ui.FragmentShader? _verticalShader;
  ui.Image? _blurGradientMap;
  int _blurGradientMapGeneration = 0;
  int? _blurGradientMapLastSize;
  double? _screenLongestSide;
  Rect? _bounds;
  bool _shadersLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadShaders();
  }

  void _loadShaders() {
    InspireShaders.backdropBlur.then((program) {
      if (!mounted) return;
      setState(() {
        _horizontalShader = program.fragmentShader();
        _verticalShader = program.fragmentShader();
        _shadersLoaded = true;
        _updateShadersUniforms();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newSize = MediaQuery.sizeOf(context).longestSide;
    if (_screenLongestSide != newSize) {
      _screenLongestSide = newSize;
      _regenerateBlurGradientMapIfNeeded();
    }
  }

  @override
  void didUpdateWidget(covariant SliverInspireBlur oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldConfig = oldWidget.config;
    final config = widget.config;

    if (!listEquals(oldConfig.stops, config.stops) ||
        !listEquals(oldConfig.values, config.values) ||
        oldConfig.start != config.start ||
        oldConfig.end != config.end) {
      _regenerateBlurGradientMapIfNeeded(force: true);
    } else {
      _updateShadersUniforms();
    }
  }

  void _regenerateBlurGradientMapIfNeeded({bool force = false}) {
    if (_screenLongestSide == null) return;
    final newSize = (_screenLongestSide! / 2).toInt().clamp(64, 768);
    if (force || _blurGradientMapLastSize != newSize) {
      _blurGradientMapLastSize = newSize;
      _createNewBlurGradientMap(newSize);
    }
  }

  Future<void> _createNewBlurGradientMap(int size) async {
    final gen = ++_blurGradientMapGeneration;
    final newMap = await _createBlurGradient(size, size);

    if (gen != _blurGradientMapGeneration) {
      newMap.dispose();
      return;
    }

    _blurGradientMap?.dispose();
    if (mounted) {
      setState(() {
        _blurGradientMap = newMap;
        _updateShadersUniforms();
      });
    } else {
      _blurGradientMap = newMap;
    }
  }

  Future<ui.Image> _createBlurGradient(int width, int height) async {
    final config = widget.config;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final size = Size(width.toDouble(), height.toDouble());
    final rect = Offset.zero & size;

    final paint = Paint()
      ..shader = LinearGradient(
        colors: config.values
            .map((v) => Color.fromARGB(255, (v * 255).round(), 0, 0))
            .toList(),
        stops: config.stops,
        begin: config.start,
        end: config.end,
      ).createShader(rect);

    canvas.drawRect(rect, paint);
    final picture = recorder.endRecording();
    return picture.toImage(width, height);
  }

  void _updateShadersUniforms() {
    if (_horizontalShader == null ||
        _verticalShader == null ||
        _blurGradientMap == null ||
        _bounds == null) {
      return;
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final sigmaHorizontal = widget.config.overallSigmaHorizontally() ?? 0.0;
    final sigmaVertical = widget.config.overallSigmaVertically() ?? 0.0;

    // Update horizontal shader uniforms
    _horizontalShader!.setImageSampler(1, _blurGradientMap!);
    _horizontalShader!.setFloat(2, sigmaHorizontal);
    _horizontalShader!.setFloat(3, 1.0); // direction X
    _horizontalShader!.setFloat(4, 0.0); // direction Y
    _horizontalShader!.setFloat(5, _bounds!.left * dpr);
    _horizontalShader!.setFloat(6, _bounds!.top * dpr);
    _horizontalShader!.setFloat(7, _bounds!.width * dpr);
    _horizontalShader!.setFloat(8, _bounds!.height * dpr);

    // Update vertical shader uniforms
    _verticalShader!.setImageSampler(1, _blurGradientMap!);
    _verticalShader!.setFloat(2, sigmaVertical);
    _verticalShader!.setFloat(3, 0.0); // direction X
    _verticalShader!.setFloat(4, 1.0); // direction Y
    _verticalShader!.setFloat(5, _bounds!.left * dpr);
    _verticalShader!.setFloat(6, _bounds!.top * dpr);
    _verticalShader!.setFloat(7, _bounds!.width * dpr);
    _verticalShader!.setFloat(8, _bounds!.height * dpr);
  }

  void _updateBounds() {
    if (!mounted) return;
    final renderObject = context.findRenderObject();
    if (renderObject is RenderSliver && renderObject.attached) {
      try {
        final translation = renderObject.getTransformTo(null).getTranslation();
        final double paintExtent = renderObject.geometry?.paintExtent ?? 0.0;
        final Size size = switch (renderObject.constraints.axis) {
          Axis.horizontal => Size(
            paintExtent,
            renderObject.constraints.crossAxisExtent,
          ),
          Axis.vertical => Size(
            renderObject.constraints.crossAxisExtent,
            paintExtent,
          ),
        };
        final newBounds = Offset(translation.x, translation.y) & size;
        if (newBounds != _bounds) {
          final bool wasNull = _bounds == null;
          _bounds = newBounds;
          _updateShadersUniforms();
          if (wasNull) {
            setState(() {});
          } else {
            renderObject.markNeedsPaint();
          }
        }
      } catch (_) {
        // Can throw if not yet laid out/mounted in screen coordinate space
      }
    }
  }

  @override
  void dispose() {
    _horizontalShader?.dispose();
    _verticalShader?.dispose();
    _blurGradientMap?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateBounds());

    final showBlur =
        _shadersLoaded &&
        _blurGradientMap != null &&
        _bounds != null &&
        ui.ImageFilter.isShaderFilterSupported;

    return _SliverInspireBlurRenderWidget(
      horizontalShader: showBlur ? _horizontalShader : null,
      verticalShader: showBlur ? _verticalShader : null,
      clipBehavior: widget.clipBehavior,
      child: widget.child,
    );
  }
}

class _SliverInspireBlurRenderWidget extends SingleChildRenderObjectWidget {
  const _SliverInspireBlurRenderWidget({
    super.child,
    this.horizontalShader,
    this.verticalShader,
    required this.clipBehavior,
  });

  final ui.FragmentShader? horizontalShader;
  final ui.FragmentShader? verticalShader;
  final Clip clipBehavior;

  @override
  RenderSliverInspireBlur createRenderObject(BuildContext context) {
    return RenderSliverInspireBlur(
      horizontalShader: horizontalShader,
      verticalShader: verticalShader,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSliverInspireBlur renderObject,
  ) {
    renderObject
      ..horizontalShader = horizontalShader
      ..verticalShader = verticalShader
      ..clipBehavior = clipBehavior;
  }
}

class RenderSliverInspireBlur extends RenderProxySliver {
  RenderSliverInspireBlur({
    ui.FragmentShader? horizontalShader,
    ui.FragmentShader? verticalShader,
    required Clip clipBehavior,
  }) : _horizontalShader = horizontalShader,
       _verticalShader = verticalShader,
       _clipBehavior = clipBehavior;

  ui.FragmentShader? get horizontalShader => _horizontalShader;
  ui.FragmentShader? _horizontalShader;
  set horizontalShader(ui.FragmentShader? value) {
    if (_horizontalShader == value) return;
    _horizontalShader = value;
    markNeedsPaint();
  }

  ui.FragmentShader? get verticalShader => _verticalShader;
  ui.FragmentShader? _verticalShader;
  set verticalShader(ui.FragmentShader? value) {
    if (_verticalShader == value) return;
    _verticalShader = value;
    markNeedsPaint();
  }

  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior;
  set clipBehavior(Clip value) {
    if (_clipBehavior == value) return;
    _clipBehavior = value;
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null && child!.geometry != null) {
      final SliverGeometry geometry = child!.geometry!;
      if (geometry.visible) {
        final double paintExtent = geometry.paintExtent;
        final Size size = switch (constraints.axis) {
          Axis.horizontal => Size(paintExtent, constraints.crossAxisExtent),
          Axis.vertical => Size(constraints.crossAxisExtent, paintExtent),
        };

        void paintWithShader(
          PaintingContext context,
          Offset offset,
          ui.FragmentShader shader,
          VoidCallback paintChild,
        ) {
          final filter = ui.ImageFilter.shader(shader);
          final backdropLayer = BackdropFilterLayer(filter: filter);
          context.pushLayer(backdropLayer, (
            PaintingContext context,
            Offset offset,
          ) {
            paintChild();
          }, offset);
        }

        context.pushClipRect(needsCompositing, offset, offset & size, (
          PaintingContext context,
          Offset offset,
        ) {
          if (horizontalShader != null && verticalShader != null) {
            paintWithShader(context, offset, horizontalShader!, () {
              paintWithShader(context, offset, verticalShader!, () {
                context.paintChild(child!, offset);
              });
            });
          } else if (horizontalShader != null) {
            paintWithShader(context, offset, horizontalShader!, () {
              context.paintChild(child!, offset);
            });
          } else if (verticalShader != null) {
            paintWithShader(context, offset, verticalShader!, () {
              context.paintChild(child!, offset);
            });
          } else {
            context.paintChild(child!, offset);
          }
        }, clipBehavior: clipBehavior);
        return;
      }
    }
    super.paint(context, offset);
  }
}
