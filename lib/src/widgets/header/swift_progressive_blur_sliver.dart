// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:inspire_blur/inspire_blur.dart';
// ignore: implementation_imports
import 'package:inspire_blur/src/inspire_shaders.dart';
import 'swift_header_chrome.dart';

/// A sliver that applies a progressive backdrop blur starting from the top of the viewport
/// and stretching over the combined height of all currently pinned headers, fading out
/// over the specified [fadeLength].
///
/// It should be placed right after the headers and before the scrollable content in
/// a [CustomScrollView].
class SwiftProgressiveBlurSliver extends StatefulWidget {
  const SwiftProgressiveBlurSliver({
    super.key,
    this.fadeLength = 40.0,
    this.maxBlurSigma = 20.0,
    this.clipBehavior = Clip.antiAlias,
  });

  /// The distance (in pixels) over which the blur fades from full intensity to zero.
  final double fadeLength;

  /// The maximum blur strength (sigma value) to apply under the headers.
  final double maxBlurSigma;

  /// How the blur region should be clipped.
  final Clip clipBehavior;

  @override
  State<SwiftProgressiveBlurSliver> createState() =>
      _SwiftProgressiveBlurSliverState();
}

class _SwiftProgressiveBlurSliverState extends State<SwiftProgressiveBlurSliver> {
  ui.FragmentShader? _horizontalShader;
  ui.FragmentShader? _verticalShader;
  ui.Image? _blurGradientMap;
  int _blurGradientMapGeneration = 0;
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
    _regenerateBlurGradientMapIfNeeded();
  }

  void _regenerateBlurGradientMapIfNeeded({bool force = false}) {
    // We use a fixed small texture size (64x64) for high-performance updates
    // during animations without frame drops.
    const int textureSize = 64;
    _createNewBlurGradientMap(textureSize);
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

  double _lastAnimatedHeight = -1.0;

  Future<ui.Image> _createBlurGradient(int width, int height) async {
    final double animatedHeight = _lastAnimatedHeight >= 0.0 ? _lastAnimatedHeight : 0.0;
    final double totalBlurHeight = animatedHeight + widget.fadeLength;

    final InspireBlurConfig config;
    if (animatedHeight <= 0.0) {
      config = InspireBlurConfig.directional(
        start: Alignment.topCenter,
        end: Alignment.bottomCenter,
        sigma: 0.0,
      );
    } else {
      final double stop = animatedHeight / totalBlurHeight;
      config = InspireBlurConfig(
        start: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0.0, stop, 1.0],
        values: const [1.0, 1.0, 0.0],
        sigma: widget.maxBlurSigma,
      );
    }

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
    final sigmaHorizontal = widget.maxBlurSigma;
    final sigmaVertical = widget.maxBlurSigma;

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

  void _updateBounds(double animatedHeight) {
    if (!mounted) return;
    final renderObject = context.findRenderObject();
    if (renderObject is RenderSliver && renderObject.attached) {
      try {
        final parent = renderObject.parent;
        if (parent is! RenderObject) return;

        final translationToViewport = renderObject.getTransformTo(parent).getTranslation();
        final translationToScreen = renderObject.getTransformTo(null).getTranslation();

        final double viewportTop = translationToScreen.y - translationToViewport.y;
        final double viewportLeft = translationToScreen.x - translationToViewport.x;

        final double blurHeight = animatedHeight + widget.fadeLength;
        final Size size = switch (renderObject.constraints.axis) {
          Axis.horizontal => Size(blurHeight, renderObject.constraints.crossAxisExtent),
          Axis.vertical => Size(renderObject.constraints.crossAxisExtent, blurHeight),
        };

        final newBounds = Offset(viewportLeft, viewportTop) & size;
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
        // Can throw if not yet laid out/mounted
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
    final controller = SwiftPinnedHeaderChromeScope.maybeOf(context);

    return AnimatedBuilder(
      animation: controller ?? ChangeNotifier(),
      builder: (context, _) {
        final totalHeight = controller?.snapshot.totalHeight ?? 0.0;
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(end: totalHeight),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          builder: (context, animatedHeight, child) {
            if (_lastAnimatedHeight != animatedHeight) {
              _lastAnimatedHeight = animatedHeight;
              _regenerateBlurGradientMapIfNeeded(force: true);
            }
            
            WidgetsBinding.instance.addPostFrameCallback((_) => _updateBounds(animatedHeight));

            final showBlur =
                _shadersLoaded &&
                _blurGradientMap != null &&
                _bounds != null &&
                ui.ImageFilter.isShaderFilterSupported;

            return _SwiftProgressiveBlurSliverRenderWidget(
              horizontalShader: showBlur ? _horizontalShader : null,
              verticalShader: showBlur ? _verticalShader : null,
              clipBehavior: widget.clipBehavior,
              totalHeight: animatedHeight,
              fadeLength: widget.fadeLength,
            );
          },
        );
      },
    );
  }
}

class _SwiftProgressiveBlurSliverRenderWidget extends LeafRenderObjectWidget {
  const _SwiftProgressiveBlurSliverRenderWidget({
    this.horizontalShader,
    this.verticalShader,
    required this.clipBehavior,
    required this.totalHeight,
    required this.fadeLength,
  });

  final ui.FragmentShader? horizontalShader;
  final ui.FragmentShader? verticalShader;
  final Clip clipBehavior;
  final double totalHeight;
  final double fadeLength;

  @override
  RenderSliver createRenderObject(BuildContext context) {
    return _RenderSwiftProgressiveBlurSliver(
      horizontalShader: horizontalShader,
      verticalShader: verticalShader,
      clipBehavior: clipBehavior,
      totalHeight: totalHeight,
      fadeLength: fadeLength,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderSwiftProgressiveBlurSliver renderObject,
  ) {
    renderObject
      ..horizontalShader = horizontalShader
      ..verticalShader = verticalShader
      ..clipBehavior = clipBehavior
      ..totalHeight = totalHeight
      ..fadeLength = fadeLength;
  }
}

class _RenderSwiftProgressiveBlurSliver extends RenderSliver {
  _RenderSwiftProgressiveBlurSliver({
    ui.FragmentShader? horizontalShader,
    ui.FragmentShader? verticalShader,
    required Clip clipBehavior,
    required double totalHeight,
    required double fadeLength,
  }) : _horizontalShader = horizontalShader,
       _verticalShader = verticalShader,
       _clipBehavior = clipBehavior,
       _totalHeight = totalHeight,
       _fadeLength = fadeLength;

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

  double get totalHeight => _totalHeight;
  double _totalHeight;
  set totalHeight(double value) {
    if (_totalHeight == value) return;
    _totalHeight = value;
    markNeedsLayout();
  }

  double get fadeLength => _fadeLength;
  double _fadeLength;
  set fadeLength(double value) {
    if (_fadeLength == value) return;
    _fadeLength = value;
    markNeedsLayout();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void performLayout() {
    geometry = const SliverGeometry(
      scrollExtent: 0.0,
      paintExtent: 0.0,
      layoutExtent: 0.0,
      maxPaintExtent: 0.0,
      hasVisualOverflow: true,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final double blurHeight = totalHeight + fadeLength;
    if (blurHeight <= 0) return;

    final Size size = switch (constraints.axis) {
      Axis.horizontal => Size(blurHeight, constraints.crossAxisExtent),
      Axis.vertical => Size(constraints.crossAxisExtent, blurHeight),
    };

    final Rect rect = switch (constraints.axis) {
      Axis.horizontal => Offset(0.0, offset.dy) & size,
      Axis.vertical => Offset(offset.dx, 0.0) & size,
    };

    void paintWithShader(
      PaintingContext context,
      Offset offset,
      ui.FragmentShader shader,
      VoidCallback paintContent,
    ) {
      final filter = ui.ImageFilter.shader(shader);
      final backdropLayer = BackdropFilterLayer(filter: filter);
      context.pushLayer(
        backdropLayer,
        (PaintingContext context, Offset offset) {
          paintContent();
        },
        offset,
      );
    }

    context.pushClipRect(
      needsCompositing,
      rect.topLeft,
      rect,
      (PaintingContext context, Offset offset) {
        if (horizontalShader != null && verticalShader != null) {
          paintWithShader(context, offset, horizontalShader!, () {
            paintWithShader(context, offset, verticalShader!, () {});
          });
        } else if (horizontalShader != null) {
          paintWithShader(context, offset, horizontalShader!, () {});
        } else if (verticalShader != null) {
          paintWithShader(context, offset, verticalShader!, () {});
        }
      },
      clipBehavior: clipBehavior,
    );
  }
}
