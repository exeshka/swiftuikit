import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Which edge of the [ProgressiveBlur] rectangle carries the strongest blur.
enum BlurEdge { top, bottom }

/// How content leaves under a bar.
///
/// [fade]: the content fades into the background colour with an eased gradient. No backdrop filter, so it is nearly free
/// for the GPU (every backdrop pass costs ~1 ms and a lot of memory traffic on iPhone, see docs/).
/// [blur]: one plain `BackdropFilter(ImageFilter.blur)` per zone, faded out by a gradient alpha mask painted inside the filter's
/// layer (the way a masked `UIVisualEffectView` does it): it looks progressive and, measured on an iPhone, does not heat it up like
/// [variableBlur] does (see the `backdrop_blur_repro` runs: 120 fps and no thermal throttling in 17 minutes).
/// [variableBlur]: a real variable-sigma blur (two shader passes of `ImageFilter.shader`, composed). The most exact look, but on
/// an iPhone it drives the GPU into thermal throttling within ~3 minutes of continuous scrolling: use it for static screens.
enum ChromeEdgeEffect { fade, blur, variableBlur }

/// Progressive blur zone: blurs whatever is painted *behind* it, strongest on
/// [edge], fading to zero at the opposite side. Draws a soft [tint] gradient
/// on top. Does not hit-test.
class ProgressiveBlur extends StatefulWidget {
  const ProgressiveBlur({
    super.key,
    required this.height,
    required this.edge,
    required this.maxSigma,
    this.tint,
    this.tintOpacity = 0.5,
    this.tintHold = 0,
    this.effect = ChromeEdgeEffect.blur,
    this.fadeColor,
    this.fadeHold = 0,
    this.fadeOpacity = 1,
    this.intensity = 1,
  });

  final double height;

  /// [ChromeEdgeEffect.blur] (default here) or [ChromeEdgeEffect.fade]: a gradient of [fadeColor] instead of the blur.
  final ChromeEdgeEffect effect;

  /// Colour the content fades into in [ChromeEdgeEffect.fade] (the page background); falls back to [tint].
  final Color? fadeColor;

  /// 0..1 share of the height (from the strong edge) where the fade stays fully opaque: the area the bar itself covers.
  /// The gradient eases out over the rest.
  final double fadeHold;

  /// 0..1 peak opacity of the fade at the strong edge: below 1 the content stays faintly visible under the bar.
  final double fadeOpacity;
  final BlurEdge edge;

  /// Sigma (logical px) at the strong edge.
  final double maxSigma;
  final Color? tint;
  final double tintOpacity;

  /// 0..1: how long the tint stays dense before fading out (0 = the soft default, 1 = native navigation bar: the content
  /// right under the bar is still clearly dimmed and the scrim fades out over the extension).
  final double tintHold;

  /// 0..1: how much of the blur effect there is at all (a header that draws its own edge effect lowers it to 0: no blur layer
  /// is built). Scales the mask of the blur and its scrim.
  final double intensity;

  static ui.FragmentProgram? _program;
  static Future<ui.FragmentProgram>? _loading;

  /// Loads the blur shader. Call before `runApp` to avoid a first frame on the
  /// uniform fallback.
  static Future<void> preload() async {
    if (_program != null) return;
    try {
      _loading ??= ui.FragmentProgram.fromAsset(
        'packages/swiftuikit/shaders/variable_blur.frag',
      );
      _program = await _loading;
    } catch (_) {
      _loading = null;
    }
  }

  /// False without Impeller (e.g. `flutter test`): the zone then falls back to
  /// one uniform blur, not progressive.
  static bool get shaderSupported => ui.ImageFilter.isShaderFilterSupported;

  @override
  State<ProgressiveBlur> createState() => _ProgressiveBlurState();
}

class _ProgressiveBlurState extends State<ProgressiveBlur> {
  @override
  Widget build(BuildContext context) {
    final top = widget.edge == BlurEdge.top;
    final tint = widget.tint;
    if (widget.effect == ChromeEdgeEffect.fade) {
      final c = widget.fadeColor ?? tint ?? const Color(0xFF000000);
      return IgnorePointer(
        child: SizedBox(
          height: widget.height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: top ? Alignment.topCenter : Alignment.bottomCenter,
                end: top ? Alignment.bottomCenter : Alignment.topCenter,
                colors: _fadeColors(c, widget.fadeHold, widget.fadeOpacity),
                stops: _fadePositions(widget.fadeHold),
              ),
            ),
            child: const SizedBox.expand(),
          ),
        ),
      );
    }
    final program = ProgressiveBlur._program;

    if (widget.effect != ChromeEdgeEffect.fade && widget.intensity <= 0.01) {
      return SizedBox(height: widget.height);
    }
    Widget blur;
    if (widget.effect == ChromeEdgeEffect.blur) {
      // no explicit tileMode: since Flutter 3.29 a backdrop blur defaults to `mirror`, which keeps the blur steady at the screen
      // edge while the content scrolls under it (an explicit `clamp` smears the edge pixel and flashes: flutter/flutter#110318,
      // `decal` treats the outside as transparent black and darkens the edge)
      blur = BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: widget.maxSigma,
          sigmaY: widget.maxSigma,
        ),
        // the mask is painted INSIDE the filter's layer (dstIn): the blurred backdrop keeps its alpha only where the gradient is
        child: CustomPaint(
          // full strength over the area the bar itself covers (fadeHold), eased out only over the extension below it
          painter: _BlurMaskPainter(
            strongAtTop: top,
            hold: (0.7 * widget.fadeHold / 0.6).clamp(0.0, 1.0),
            intensity: widget.intensity,
          ),
          child: const SizedBox.expand(),
        ),
      );
    } else if (ProgressiveBlur.shaderSupported && program != null) {
      blur = _ShaderBlurZone(
        program: program,
        edge: widget.edge,
        sigma: widget.maxSigma,
        devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      );
    } else {
      if (ProgressiveBlur.shaderSupported) {
        ProgressiveBlur.preload().then((_) {
          if (mounted) setState(() {});
        });
      }
      final s = widget.maxSigma * 0.6;
      blur = BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: s, sigmaY: s),
        child: const SizedBox.expand(),
      );
    }

    return IgnorePointer(
      child: SizedBox(
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRect(child: blur),
            // the masked blur goes with the fade gradient of the same edge (the content darkens into the page colour as it
            // goes under the bar), the way the native bars do it
            if (widget.effect == ChromeEdgeEffect.blur)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: top ? Alignment.topCenter : Alignment.bottomCenter,
                    end: top ? Alignment.bottomCenter : Alignment.topCenter,
                    colors: _fadeColors(
                      widget.fadeColor ?? tint ?? const Color(0xFF000000),
                      widget.fadeHold,
                      // half of the pure fade's density: the blur does part of the job
                      widget.fadeOpacity * 0.5,
                    ),
                    stops: _fadePositions(widget.fadeHold),
                  ),
                ),
              ),
            if (tint != null && widget.tintOpacity * widget.intensity > 0)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: top ? Alignment.topCenter : Alignment.bottomCenter,
                    end: top ? Alignment.bottomCenter : Alignment.topCenter,
                    colors: _tintStops(
                      tint,
                      widget.tintOpacity * widget.intensity,
                      widget.tintHold,
                    ),
                    stops: _tintPositions,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static const _tintPositions = [0.0, 0.25, 0.5, 0.75, 1.0];

  // Fade: opaque over [hold] (the bar's own area), then eased (smoothstep) down to transparent at the inner side.
  static const _fadeSteps = 8;
  static List<double> _fadePositions(double hold) {
    final h = hold.clamp(0.0, 0.98);
    return [
      0.0,
      if (h > 0) h,
      for (var i = 1; i <= _fadeSteps; i++) h + (1 - h) * i / _fadeSteps,
    ];
  }

  static List<Color> _fadeColors(Color c, double hold, double opacity) {
    final h = hold.clamp(0.0, 0.98);
    final peak = c.withValues(alpha: c.a * opacity.clamp(0.0, 1.0));
    return [
      peak,
      if (h > 0) peak,
      for (var i = 1; i <= _fadeSteps; i++)
        c.withValues(
          alpha:
              c.a *
              opacity.clamp(0.0, 1.0) *
              (1 -
                  (i / _fadeSteps) *
                      (i / _fadeSteps) *
                      (3 - 2 * i / _fadeSteps)),
        ),
    ];
  }

  // Eased fade, so the tint has no visible start line.
  static List<Color> _tintStops(Color c, double a, double hold) {
    const soft = [1.0, 0.72, 0.38, 0.1, 0.0];
    const dense = [1.0, 1.0, 0.8, 0.42, 0.0];
    final h = hold.clamp(0.0, 1.0);
    return [
      for (var i = 0; i < soft.length; i++)
        c.withValues(alpha: a * (soft[i] + (dense[i] - soft[i]) * h)),
    ];
  }
}

/// Multiplies the alpha of what is painted before it in the same layer (the blurred backdrop of a `BackdropFilter`) by an eased
/// gradient: 1 at the strong edge, 0 at the inner side.
class _BlurMaskPainter extends CustomPainter {
  const _BlurMaskPainter({
    required this.strongAtTop,
    required this.hold,
    this.intensity = 1,
  });
  final bool strongAtTop;

  /// 0..1 share of the height (from the strong edge) that keeps the full blur.
  final double hold;

  /// 0..1 multiplier of the mask's alpha.
  final double intensity;

  static const _n = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final h = hold.clamp(0.0, 0.98);
    final k = intensity.clamp(0.0, 1.0);
    final colors = <Color>[Color.fromRGBO(0, 0, 0, k)];
    final stops = <double>[0];
    if (h > 0) {
      colors.add(Color.fromRGBO(0, 0, 0, k));
      stops.add(h);
    }
    for (var i = 1; i <= _n; i++) {
      final t = i / _n;
      // smootherstep: a gentler start and end than smoothstep, so the edge of the blur is not a visible line
      colors.add(
        Color.fromRGBO(0, 0, 0, 1 - t * t * t * (t * (t * 6 - 15) + 10)),
      );
      stops.add(h + (1 - h) * t);
    }
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          strongAtTop ? rect.topCenter : rect.bottomCenter,
          strongAtTop ? rect.bottomCenter : rect.topCenter,
          colors,
          stops,
        )
        ..blendMode = BlendMode.dstIn,
    );
  }

  @override
  bool shouldRepaint(_BlurMaskPainter old) =>
      old.strongAtTop != strongAtTop ||
      old.hold != hold ||
      old.intensity != intensity;
}

/// Paints one `BackdropFilterLayer` whose filter is the two-pass variable blur
/// shader. A render object (not a widget tree of `BackdropFilter`) because the
/// shader needs the zone's position inside the backdrop layer, which is only
/// known at paint time.
class _ShaderBlurZone extends LeafRenderObjectWidget {
  const _ShaderBlurZone({
    required this.program,
    required this.edge,
    required this.sigma,
    required this.devicePixelRatio,
  });

  final ui.FragmentProgram program;
  final BlurEdge edge;
  final double sigma;
  final double devicePixelRatio;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderShaderBlurZone(program, edge, sigma, devicePixelRatio);

  @override
  void updateRenderObject(BuildContext context, _RenderShaderBlurZone r) {
    r
      ..edge = edge
      ..sigma = sigma
      ..devicePixelRatio = devicePixelRatio;
  }
}

class _RenderShaderBlurZone extends RenderBox {
  _RenderShaderBlurZone(this.program, this._edge, this._sigma, this._dpr);

  final ui.FragmentProgram program;
  BlurEdge _edge;
  double _sigma;
  double _dpr;

  ui.FragmentShader? _h;
  ui.FragmentShader? _v;
  List<double>? _key;

  set edge(BlurEdge v) {
    if (v != _edge) {
      _edge = v;
      markNeedsPaint();
    }
  }

  set sigma(double v) {
    if (v != _sigma) {
      _sigma = v;
      markNeedsPaint();
    }
  }

  set devicePixelRatio(double v) {
    if (v != _dpr) {
      _dpr = v;
      markNeedsPaint();
    }
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  bool hitTestSelf(Offset position) => false;

  @override
  BackdropFilterLayer? get layer => super.layer as BackdropFilterLayer?;

  void _ensureFilter(double top, double height, double scale) {
    final sig = _sigma * _dpr * scale;
    final key = <double>[top, height, sig, _edge == BlurEdge.bottom ? 1 : 0];
    if (_key != null && listEquals(_key, key) && layer?.filter != null) return;
    _key = key;
    // A new shader pair per geometry: the engine snapshots the uniforms when
    // the filter is created, and equal filters would not repaint.
    _h?.dispose();
    _v?.dispose();
    final h = _h = program.fragmentShader();
    final v = _v = program.fragmentShader();
    final bottom = _edge == BlurEdge.bottom ? 1.0 : 0.0;
    // uniforms 0,1 (size) are filled in by the engine
    h
      ..setFloat(2, 1)
      ..setFloat(3, 0)
      ..setFloat(4, sig)
      ..setFloat(5, bottom)
      ..setFloat(6, top)
      ..setFloat(7, height);
    v
      ..setFloat(2, 0)
      ..setFloat(3, 1)
      ..setFloat(4, sig)
      ..setFloat(5, bottom)
      ..setFloat(6, top)
      ..setFloat(7, height);
    layer ??= BackdropFilterLayer();
    layer!.filter = ui.ImageFilter.compose(
      outer: ui.ImageFilter.shader(v),
      inner: ui.ImageFilter.shader(h),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // Measure through the full transform, so ancestors that scale (FittedBox,
    // Transform.scale) are accounted for.
    final top = localToGlobal(Offset.zero).dy * _dpr;
    final bottom = localToGlobal(Offset(0, size.height)).dy * _dpr;
    layer ??= BackdropFilterLayer();
    _ensureFilter(top, bottom - top, (bottom - top) / (size.height * _dpr));
    context.pushLayer(layer!, (_, _) {}, offset);
  }

  @override
  void dispose() {
    _h?.dispose();
    _v?.dispose();
    layer = null;
    super.dispose();
  }
}
