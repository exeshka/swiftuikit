import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../theme/swift_ui_theme.dart';
import 'glass_surface.dart';

/// iOS 26 "liquid glass" plate: the backdrop is refracted at the rim of a
/// convex squircle bezel (light bends there, the middle stays calm), slightly
/// blurred, split per color channel, tinted and lit by a specular rim.
/// One fragment shader (`shaders/liquid_glass.frag`) in one backdrop pass.
///
/// Cost is one offscreen backdrop pass per plate, so use it for the few
/// prominent elements (bar buttons, the pill, a floating toolbar), not for
/// every row. Without Impeller (`flutter test`) it falls back to a flat
/// [GlassSurface]. Like `ProgressiveBlur`, it must not sit inside its own
/// offscreen layer (`Opacity`, `ShaderMask`...).
class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    super.key,
    this.child,
    this.cornerRadius,
    this.width,
    this.height,
    this.shadow = true,
    this.tint,
    this.bezel,
    this.refraction,
    this.clear = false,
    this.presence = 1,
    this.presenceOrigin = Offset.zero,
    this.interactive = false,
    this.highQuality = false,
    this.blur,
    this.toneLift,
    this.flat = false,
  });

  /// Circle: size × size with `cornerRadius == null` (fully round).
  const LiquidGlass.circle({
    super.key,
    this.child,
    required double size,
    this.shadow = true,
    this.tint,
    this.bezel,
    this.refraction,
    this.clear = false,
    this.presence = 1,
    this.presenceOrigin = Offset.zero,
    this.interactive = false,
    this.highQuality = false,
    this.blur,
    this.toneLift,
    this.flat = false,
  }) : width = size,
       height = size,
       cornerRadius = null;

  final Widget? child;

  /// A FLAT plate with the same interaction as the glass: no shader (works everywhere), one solid colour without rim or
  /// shadow, but the same press response with [interactive]: the spring grow, the highlight, the stretch under a drag.
  /// This is the look of `liquid: false`.
  final bool flat;

  /// null: fully round ends (stadium / circle).
  final double? cornerRadius;
  final double? width;
  final double? height;
  final bool shadow;
  final Color? tint;
  final double? bezel;
  final double? refraction;

  /// SwiftUI's `Glass.clear`: almost no blur (~1.6 pt), no desaturation, a
  /// flat +0.08 luminance lift and no shadow, same rim lens. Same in light
  /// and dark. Inside a [LiquidGlassGroup] the group's first plate decides
  /// blur and tone, so keep one variant per group.
  final bool clear;

  /// 0..1: the plate grows from / shrinks into a point (SwiftUI's
  /// `glassEffectTransition(.matchedGeometry/.materialize)` look: inside a
  /// [LiquidGlassGroup] with `spacing` the vanishing plate stays melted to
  /// its neighbour while it shrinks). Normally driven by
  /// [LiquidGlassPresence]. 1 = fully shown, <= 0.01 = not drawn.
  final double presence;

  /// Pivot of the presence scale, as an offset (logical px) from the plate's
  /// center. Point it at the neighbour the plate should melt into
  /// (e.g. `Offset(-100, 0)`); zero scales in place.
  final Offset presenceOrigin;

  /// SwiftUI's `.interactive()` / `buttonStyle(.glass)` press response, fitted
  /// to frames of the native effect (60 fps recording of a simulator touch):
  /// on touch-down the plate springs to 1.05x (peak 1.052 after ~0.18 s,
  /// rests at ~1.047) and the whole plate gets a ~16% white highlight (reaches
  /// it in ~85 ms); on release it springs back with a ~0.6% undershoot and the
  /// highlight fades in ~0.35 s. The native glow is brighter than SDR white
  /// (HDR/EDR); Flutter has no such range, so only the SDR part is matched.
  /// The press is read with a [Listener], taps still reach your own
  /// `GestureDetector` / button.
  final bool interactive;

  /// Adds an engine blur prefilter (`SwiftUiThemeData.liquidPrefilter`) to a plate that is NOT inside a
  /// [LiquidGlassGroup]. Thin features under the glass (1 px lines, small text) then blur as smoothly as in native
  /// glass instead of showing sampling noise, but it costs an extra pass per plate (about 0.5 ms on an iPhone 14 Pro),
  /// so it is off by default for individual plates and always on for groups (bars, headers), where one pass is shared.
  final bool highQuality;

  /// Overrides the blur sigma (pt) of the plate: 1.6 for [clear], `SwiftUiThemeData.liquidBlur` otherwise.
  final double? blur;

  /// Overrides the brightness lift of a [clear] plate (0.078 by default; on a light backdrop that lifts a light gray to white).
  final double? toneLift;

  static ui.FragmentProgram? _program;
  static Future<ui.FragmentProgram>? _loading;

  static Future<void> preload() async {
    if (_program != null) return;
    try {
      _loading ??= ui.FragmentProgram.fromAsset(
        'packages/swiftuikit/shaders/liquid_glass.frag',
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
    LiquidGlassLifecycle.ensure();
    // Like native glass, the plate drops to the flat look while the app is not in the foreground (app switcher, control
    // centre, a system dialog): no backdrop pass is run for a screen nobody interacts with, and the snapshot iOS takes for
    // the switcher is drawn without the shader. [LiquidGlassSuspend] does the same for a subtree on demand.
    return ValueListenableBuilder<bool>(
      valueListenable: LiquidGlassLifecycle.inactive,
      builder: (context, inactive, _) {
        final off = flat || inactive || LiquidGlassSuspend.of(context);
        // One stable tree for both looks, so the content keeps its state and the look can cross-fade. Going flat is instant
        // (the app switcher takes its snapshot right away and no frames may follow); coming back fades the glass in.
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(end: off ? 0.0 : 1.0),
          duration: off ? Duration.zero : const Duration(milliseconds: 260),
          curve: Curves.easeInOut,
          builder: (context, fade, _) {
            if (!interactive) return _buildGlass(context, 0, 0, Offset.zero, Offset.zero, 0, fade);
            return _LiquidPress(
              builder: (context, scale, hi, touch, drag, spread) =>
                  _buildGlass(context, scale, hi, touch, drag, spread, fade),
            );
          },
        );
      },
    );
  }

  /// The plate without the shader: a flat [GlassSurface] of the same shape.
  Widget _flatGlass(BuildContext context) {
    return GlassSurface(
      // explicitly flat: left to the tokens, GlassSurface would build a LiquidGlass again (endless recursion)
      liquid: false,
      fill: tint,
      shape: cornerRadius == null
          ? const StadiumBorder()
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(cornerRadius!),
            ),
      width: width,
      height: height,
      shadow: shadow,
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _buildGlass(
    BuildContext context,
    double press,
    double highlight, [
    Offset touch = Offset.zero,
    Offset drag = Offset.zero,
    double spread = 0,
    double fade = 1,
  ]) {
    final t = SwiftUiTheme.of(context);
    final content = child;
    if (!supported && !flat) {
      if (ui.ImageFilter.isShaderFilterSupported) preload();
      return _flatGlass(context);
    }
    return _LiquidGlassRender(
      program: flat ? null : _program,
      cornerRadius: cornerRadius,
      style: _GlassStyle(
        clear: clear,
        shadowColor: shadow && !clear
            ? t.glass.glassShadow.withValues(
                alpha: (t.isDark ? 0.10 : 0.16) * fade,
              )
            : null,
        fade: fade,
        flat: tint ?? flatFill(t.glass.glassFill, t.colors.background, isDark: t.isDark),
        flatShadow: shadow && !clear
            ? t.glass.glassShadow.withValues(alpha: t.glass.glassShadow.a * (1 - fade))
            : null,
        tint: tint ?? t.glass.liquidTint,
        bezel: bezel ?? t.glass.liquidBezel,
        refraction: refraction ?? t.glass.liquidRefraction,
        blur: blur ?? (clear ? 1.6 : t.glass.liquidBlur),
        saturation: clear ? 1.0 : t.glass.liquidSaturation,
        dispersion: t.glass.liquidDispersion,
        magnify: t.glass.liquidMagnify,
        hdr: t.glass.liquidHdr,
        prefilter: t.glass.liquidPrefilter,
        specular: t.glass.liquidSpecular,
        toneLift: toneLift ?? (clear ? 0.078 : t.glass.liquidToneLift),
        toneGain: clear ? 1.019 : t.glass.liquidToneGain,
        light: !t.isDark,
        devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      ),
      width: width,
      height: height,
      presence: presence,
      presenceOrigin: presenceOrigin,
      press: press,
      highQuality: highQuality,
      highlight: highlight,
      touch: touch,
      drag: drag,
      spread: spread,
      child: content,
    );
  }
}

/// Whether the app is in the foreground, for [LiquidGlass]: while it is not (`inactive`, `hidden`, `paused`, `detached`) every
/// plate draws flat.
class LiquidGlassLifecycle with WidgetsBindingObserver {
  LiquidGlassLifecycle._();
  static final LiquidGlassLifecycle _instance = LiquidGlassLifecycle._();
  static final ValueNotifier<bool> inactive = ValueNotifier<bool>(false);
  static bool _registered = false;

  /// Starts listening to the app lifecycle (idempotent; plates call it themselves).
  static void ensure() {
    if (_registered) return;
    _registered = true;
    final binding = WidgetsBinding.instance;
    binding.addObserver(_instance);
    final s = binding.lifecycleState;
    inactive.value = s != null && s != AppLifecycleState.resumed;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    inactive.value = state != AppLifecycleState.resumed;
  }
}

/// Draws every [LiquidGlass] below it flat (no shader, no backdrop pass) while [suspended] is true. For a subtree that is
/// alive but not worth the GPU for now: covered by an opaque layer that is not a route (Flutter already skips painting routes
/// below an opaque route), scrolled out of use, behind a sheet...
class LiquidGlassSuspend extends InheritedWidget {
  const LiquidGlassSuspend({
    super.key,
    required this.suspended,
    required super.child,
  });

  final bool suspended;

  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<LiquidGlassSuspend>()
          ?.suspended ??
      false;

  @override
  bool updateShouldNotify(LiquidGlassSuspend old) => suspended != old.suspended;
}

/// Style shared by all plates of one pass (from [SwiftUiThemeData]).
class _GlassStyle {
  const _GlassStyle({
    required this.shadowColor,
    required this.tint,
    required this.bezel,
    required this.refraction,
    required this.blur,
    required this.saturation,
    required this.dispersion,
    required this.magnify,
    this.hdr = 1,
    this.prefilter = 0,
    required this.specular,
    required this.toneLift,
    required this.toneGain,
    required this.light,
    required this.devicePixelRatio,
    this.clear = false,
    this.fade = 1,
    this.flat = const Color(0x00000000),
    this.flatShadow,
  });

  final Color? shadowColor;
  final Color tint;
  final double bezel;
  final double refraction;
  final double blur;
  final double saturation;
  final double dispersion;
  final double magnify;
  final double hdr;
  final double prefilter;
  final double specular;
  final double toneLift;
  final double toneGain;
  final bool light;
  final double devicePixelRatio;
  final bool clear;

  /// 0..1: how much of the glass is shown. Below 1 the flat plate ([flat]) shows through, so a plate that drops to the flat
  /// look (app in the background, suspended subtree) and comes back cross-fades instead of popping.
  final double fade;

  /// Colour of the flat plate under a fading glass.
  final Color flat;

  /// Drop shadow of the flat plate (null: none).
  final Color? flatShadow;

  _GlassStyle withPrefilter(double v) => _GlassStyle(
    shadowColor: shadowColor,
    tint: tint,
    bezel: bezel,
    refraction: refraction,
    blur: blur,
    saturation: saturation,
    dispersion: dispersion,
    magnify: magnify,
    specular: specular,
    toneLift: toneLift,
    toneGain: toneGain,
    light: light,
    devicePixelRatio: devicePixelRatio,
    clear: clear,
    hdr: hdr,
    prefilter: v,
    fade: fade,
    flat: flat,
    flatShadow: flatShadow,
  );
}

class _LiquidGlassRender extends SingleChildRenderObjectWidget {
  const _LiquidGlassRender({
    required this.program,
    required this.cornerRadius,
    required this.style,
    required this.width,
    required this.height,
    required this.presence,
    required this.presenceOrigin,
    required this.press,
    required this.highQuality,
    required this.highlight,
    required this.touch,
    required this.drag,
    required this.spread,
    super.child,
  });

  final ui.FragmentProgram? program; // null: a flat plate, no shader
  final double? cornerRadius;
  final _GlassStyle style;
  final double? width;
  final double? height;
  final double presence;
  final Offset presenceOrigin;
  final double press;
  final bool highQuality;
  final double highlight;
  final Offset touch;
  final Offset drag;
  final double spread; // 0..1: how far the press highlight has spread over the plate (latched once a drag starts)

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderLiquidGlass()..update(this);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderLiquidGlass renderObject,
  ) {
    renderObject.update(this);
  }
}

/// How much of the *small plate* material a plate of this size has, 0..1. Native glass has two materials: a plate whose shorter
/// side is below ~68 pt follows an adaptive curve (dark or light glass depending on the content under it), a larger one a
/// plain tone map. The switch is blended over [glassSmallEdge] ± [glassSmallBlend] pt instead of cutting at 68, so a plate that
/// changes size (a text field growing line by line, a plate morphing) does not pop from one material to the other.
double glassSmallness(double shortestSide) {
  const lo = glassSmallEdge - glassSmallBlend;
  const hi = glassSmallEdge + glassSmallBlend;
  final t = ((shortestSide - lo) / (hi - lo)).clamp(0.0, 1.0);
  return 1 - t * t * (3 - 2 * t);
}

/// The shorter side (pt) where native glass switches between its two materials (measured on uniform backdrops).
const glassSmallEdge = 68.0;

/// Half of the width (pt) of the blend between the two materials around [glassSmallEdge].
const glassSmallBlend = 12.0;

/// One plate as seen by a pass: geometry in the pass owner's coordinates.
class _PlateGeom {
  _PlateGeom(
    this.rect,
    this.radius,
    this.bezel,
    this.smallness,
    this.globalTopLeft,
    this.scale, [
    this.highlight = 0,
    this.touch = Offset.zero,
    this.tint = const Color(0x00000000),
    this.glowSigma = 140,
    this.ellipse = false,
    this.melt = true,
  ]);
  final Rect rect; // logical, owner-local
  final double radius; // logical
  final double bezel; // logical
  /// 0..1: how much of the small-plate material (see [glassSmallness]); 1 = small, 0 = large.
  final double smallness;
  final Offset globalTopLeft; // logical
  final double scale; // owner-local -> logical-screen scale
  final double highlight; // 0..1 press highlight
  final Offset touch; // touch offset from the plate center, pt
  final Color tint; // per-plate tint (blended when plates merge)
  final double glowSigma; // gaussian sigma of the press highlight, pt
  final bool ellipse; // circle plate: stretched into an ellipse (not a rounded rectangle) while dragged
  bool melt; // takes part in the smooth union of the pass (see RenderLiquidGlassGroup._meltSet)
}

/// Paints shadows, the clipped backdrop layer (engine blur + shader) and
/// nothing else, for one or several plates in a single pass.
class _GlassPass {
  _GlassPass(this.program);

  static const int maxPlates = 32;

  // float offsets of the shader's uniforms (see shaders/liquid_glass.frag): arrays of maxPlates vec4s, in declaration order
  static const int oRects = 3;
  static const int oPlate = oRects + 4 * maxPlates;
  static const int oScalars =
      oPlate + 4 * maxPlates; // refraction .. lightMode, 13 floats
  static const int oHi = oScalars + 13;
  static const int oHdr = oHi + 4 * maxPlates;
  static const int oBlur = oHdr + 1;
  static const int oTints = oBlur + 1;
  static const int oFade = oTints + 4 * maxPlates;
  static const int oMelt = oFade + 1;
  final ui.FragmentProgram program;
  ui.FragmentShader? _shader;
  List<RRect>? _shadowRRects;
  Path? _shadowOutside;

  BackdropFilterLayer? paint(
    PaintingContext context,
    Offset offset,
    List<_PlateGeom> plates,
    _GlassStyle st,
    bool needsCompositing,
    BackdropFilterLayer? layer, {
    double morph = 0,
  }) {
    final rrects = [
      for (final p in plates)
        RRect.fromRectAndRadius(
          p.rect.shift(offset),
          Radius.circular(p.radius),
        ),
    ];

    // shadows, outside the plates only (inside they would darken the glass)
    if (st.shadowColor != null && RenderLiquidGlass.debugSkip & 1 == 0) {
      final canvas = context.canvas;
      // the "outside the plates" clip only changes when the plates move
      if (_shadowRRects == null || !listEquals(_shadowRRects, rrects)) {
        final union = Path();
        var bounds = rrects.first.outerRect;
        for (final r in rrects) {
          union.addRRect(r);
          bounds = bounds.expandToInclude(r.outerRect);
        }
        _shadowRRects = rrects;
        _shadowOutside = Path.combine(
          PathOperation.difference,
          Path()..addRect(bounds.inflate(48)),
          union,
        );
      }
      canvas.save();
      canvas.clipPath(_shadowOutside!);
      final paint = Paint()
        ..color = st.shadowColor!
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      for (final r in rrects) {
        canvas.drawRRect(r.shift(const Offset(0, 4)), paint);
      }
      canvas.restore();
    }

    // The shader needs the plates' *current* screen positions. Under an
    // animating ancestor (route transition, swipe-back, scrolling) a composited
    // transform moves without repainting us, so positions captured at paint
    // time go stale and the glass gets clipped instead of following. Hence the
    // layer receives plate geometry in its parent's coordinates and maps it to
    // the screen itself every time the scene is built.
    final spec = _GlassSpec(
      program: program,
      shader: _shader ??= program.fragmentShader(),
      style: st,
      morph: morph,
      plates: [
        for (var i = 0; i < plates.length; i++)
          _PlateGeom(
            rrects[i].outerRect,
            plates[i].radius,
            plates[i].bezel,
            plates[i].smallness,
            Offset.zero,
            1,
            plates[i].highlight,
            plates[i].touch,
            plates[i].tint,
            plates[i].glowSigma,
            plates[i].ellipse,
            plates[i].melt,
          ),
      ],
    );
    final glass = layer is _GlassBackdropLayer ? layer : _GlassBackdropLayer();
    glass.spec = spec;
    layer = glass;

    // The shader writes alpha 0 outside the plates (and an anti-aliased edge),
    // so a plain rect clip around them is enough: no path clip.
    var bounds = rrects.first.outerRect;
    for (final r in rrects) {
      bounds = bounds.expandToInclude(r.outerRect);
    }
    context.pushClipRect(needsCompositing, Offset.zero, bounds.inflate(1.5), (
      ctx,
      off,
    ) {
      ctx.pushLayer(glass, (_, _) {}, Offset.zero);
    });
    return glass;
  }

  void dispose() {
    _shader?.dispose();
  }
}

/// Everything the glass layer needs to build its filter, in the coordinates
/// of the layer's parent (logical px).
class _GlassSpec {
  _GlassSpec({
    required this.program,
    required this.shader,
    required this.style,
    required this.morph,
    required this.plates,
  }) {
    key = <double>[
      plates.length.toDouble(),
      style.refraction,
      style.dispersion,
      style.magnify,
      style.saturation,
      style.toneLift,
      style.toneGain,
      style.tint.r,
      style.tint.g,
      style.tint.b,
      style.tint.a,
      style.blur,
      style.specular,
      style.light ? 1.0 : 0.0,
      style.hdr,
      style.devicePixelRatio,
      morph,
      style.prefilter,
      style.fade,
      for (final p in plates) ...[
        p.rect.left,
        p.rect.top,
        p.rect.width,
        p.rect.height,
        p.radius,
        p.bezel,
        p.smallness,
        p.highlight,
        p.touch.dx,
        p.touch.dy,
        p.tint.r,
        p.tint.g,
        p.tint.b,
        p.tint.a,
        p.glowSigma,
        p.ellipse ? 1.0 : 0.0,
        p.melt ? 1.0 : 0.0,
      ],
    ];
  }

  final ui.FragmentProgram program;
  final ui.FragmentShader shader;
  final _GlassStyle style;
  final double morph;
  final List<_PlateGeom> plates;
  late final List<double> key;
}

/// Backdrop filter layer that maps its plates to screen pixels at scene-build
/// time (see [_GlassPass.paint]).
class _GlassBackdropLayer extends BackdropFilterLayer {
  _GlassBackdropLayer();

  _GlassSpec? spec;
  List<double>? _builtKey;
  ui.ImageFilter? _built;

  @override
  bool get alwaysNeedsAddToScene => true;

  // leaf-local -> root (same walk as FollowerLayer: root first). While a layer is being captured to an image
  // ([GlassSnapshot.capture]) the "root" is that layer: its offset is cancelled by the capture and the scene gets the pixel
  // ratio as a scale, so the plates must be placed relative to it, not to the screen.
  Matrix4 _toRoot() {
    final stop = GlassSnapshot._root;
    final chain = <Layer>[this];
    for (ContainerLayer? l = parent; l != null; l = l.parent) {
      chain.add(l);
      if (stop != null && identical(l, stop)) break;
    }
    final captured = stop != null && identical(chain.last, stop);
    final m = captured
        ? Matrix4.diagonal3Values(GlassSnapshot._scale, GlassSnapshot._scale, 1)
        : Matrix4.identity();
    // An ImageFilterLayer above us (`Transform(filterQuality: ...)`, which SwiftSheet's ScaleTransition puts on the page below a
    // sheet: the page is rasterised once and the finished texture is scaled) renders its subtree into an offscreen texture, and
    // the backdrop under the glass is THAT texture: its origin is the top-left of the layer's content (its outermost clip),
    // not the screen's. The matrix of the filter itself is applied to the finished image, so it is correctly not in the chain.
    int? filterIdx;
    if (stop == null) {
      for (var k = 1; k < chain.length; k++) {
        if (chain[k] is ImageFilterLayer) {
          filterIdx = k;
          break;
        }
      }
    }
    Offset? origin;
    // when captured, the capture root's own transform is part of what the capture cancels: start below it
    for (var i = chain.length - (captured ? 2 : 1); i > 0; i--) {
      final l = chain[i] as ContainerLayer;
      l.applyTransform(chain[i - 1], m);
      if (filterIdx != null && i < filterIdx && origin == null) {
        final Rect? b = switch (l) {
          ClipRectLayer(:final clipRect) => clipRect,
          ClipRRectLayer(:final clipRRect) => clipRRect?.outerRect,
          ClipRSuperellipseLayer(:final clipRSuperellipse) => clipRSuperellipse?.outerRect,
          ClipPathLayer(:final clipPath) => clipPath?.getBounds(),
          _ => null,
        };
        // m maps the children's space (where the clip lives) to the root now
        if (b != null) {
          final tl = MatrixUtils.transformRect(m, b).topLeft;
          origin = Offset(math.max(tl.dx, 0), math.max(tl.dy, 0));
        }
      }
    }
    if (origin != null && origin != Offset.zero) {
      return Matrix4.translationValues(-origin.dx, -origin.dy, 0)..multiply(m);
    }
    return m;
  }

  ui.ImageFilter? _filterFor(Matrix4 chainToLeaf) {
    final sp = spec;
    if (sp == null || sp.plates.isEmpty) return null;
    final st = sp.style;
    // chain was applied root-last; we need leaf -> root
    final m = chainToLeaf;
    final s = math.sqrt(
      m.storage[0] * m.storage[0] + m.storage[1] * m.storage[1],
    );
    final key = <double>[
      ...sp.key,
      m.storage[0],
      m.storage[1],
      m.storage[4],
      m.storage[5],
      m.storage[12],
      m.storage[13],
    ];
    if (_built != null && _builtKey != null && listEquals(_builtKey, key)) {
      return _built;
    }
    final sh = sp.shader;
    sh.setFloat(2, sp.plates.length.toDouble());
    // slots past the plate count are never read (the shader loop stops at uCount)
    for (var i = 0; i < sp.plates.length; i++) {
      final p = sp.plates[i];
      final tl = MatrixUtils.transformPoint(m, p.rect.topLeft);
      sh.setFloat(_GlassPass.oRects + i * 4, tl.dx);
      sh.setFloat(_GlassPass.oRects + i * 4 + 1, tl.dy);
      sh.setFloat(_GlassPass.oRects + i * 4 + 2, p.rect.width * s);
      sh.setFloat(_GlassPass.oRects + i * 4 + 3, p.rect.height * s);
      sh.setFloat(_GlassPass.oPlate + i * 4, p.ellipse ? -1 : p.radius * s);
      sh.setFloat(_GlassPass.oPlate + i * 4 + 1, p.bezel * s);
      sh.setFloat(_GlassPass.oPlate + i * 4 + 2, p.smallness);
      sh.setFloat(_GlassPass.oPlate + i * 4 + 3, s);
      sh.setFloat(_GlassPass.oHi + i * 4, p.highlight);
      sh.setFloat(_GlassPass.oHi + i * 4 + 1, p.touch.dx);
      sh.setFloat(_GlassPass.oHi + i * 4 + 2, p.touch.dy);
      sh.setFloat(_GlassPass.oHi + i * 4 + 3, p.glowSigma);
      sh.setFloat(_GlassPass.oTints + i * 4, p.tint.r);
      sh.setFloat(_GlassPass.oTints + i * 4 + 1, p.tint.g);
      sh.setFloat(_GlassPass.oTints + i * 4 + 2, p.tint.b);
      sh.setFloat(_GlassPass.oTints + i * 4 + 3, p.tint.a);
      sh.setFloat(_GlassPass.oMelt + i * 4, p.melt ? 1 : 0);
    }
    final o = _GlassPass.oScalars;
    sh.setFloat(o, st.refraction);
    sh.setFloat(o + 1, st.dispersion);
    sh.setFloat(o + 2, st.magnify);
    sh.setFloat(o + 3, st.saturation);
    sh.setFloat(o + 4, st.toneLift);
    sh.setFloat(o + 5, st.toneGain);
    sh.setFloat(o + 6, st.tint.r);
    sh.setFloat(o + 7, st.tint.g);
    sh.setFloat(o + 8, st.tint.b);
    sh.setFloat(o + 9, st.tint.a);
    sh.setFloat(o + 10, RenderLiquidGlass.debugSkip & 2 == 0 ? st.specular : 0);
    sh.setFloat(o + 11, sp.morph * 1.05 * s);
    sh.setFloat(o + 12, st.light ? 1 : 0);
    sh.setFloat(_GlassPass.oHdr, st.hdr);
    sh.setFloat(_GlassPass.oFade, st.fade);
    // Blur: an engine prefilter (fraction of the sigma, kills aliasing of thin features) plus the shader's own taps for
    // the rest. sigma_total^2 = sigma_pre^2 + sigma_shader^2.
    final total = RenderLiquidGlass.debugSkip & 4 == 0 ? st.blur * s : 0.0;
    final pre = total * st.prefilter.clamp(0.0, 0.95);
    sh.setFloat(
      _GlassPass.oBlur,
      math.sqrt(math.max(total * total - pre * pre, 0)),
    );
    _builtKey = key;
    final shaderFilter = ui.ImageFilter.shader(sh);
    final preLocal = pre / s;
    return _built = preLocal > 0.05
        ? ui.ImageFilter.compose(
            outer: shaderFilter,
            inner: ui.ImageFilter.blur(
              sigmaX: preLocal,
              sigmaY: preLocal,
              tileMode: TileMode.clamp,
            ),
          )
        : shaderFilter;
  }

  @override
  void addToScene(ui.SceneBuilder builder) {
    final f = _filterFor(_toRoot());
    if (f == null) {
      engineLayer = null;
      return;
    }
    engineLayer = builder.pushBackdropFilter(
      f,
      blendMode: blendMode,
      oldLayer: engineLayer as ui.BackdropFilterEngineLayer?,
    );
    addChildrenToScene(builder);
    builder.pop();
  }
}

/// Render object of [LiquidGlass]. Inside a [LiquidGlassGroup] it only paints
/// its rim and child; the group paints one shared backdrop pass for all its
/// plates. Alone it runs its own pass.
///
/// [debugSkip] (bitmask: 1 shadow, 2 rim, 4 engine blur) exists only for cost
/// measurements in the benchmark.
class RenderLiquidGlass extends RenderProxyBox {
  RenderLiquidGlass();

  static int debugSkip = 0;

  // created on first use: a flat plate never needs it
  _GlassPass? _passOrNull;
  _GlassPass get _pass => _passOrNull ??= _GlassPass(_w.program!);
  // ignore: library_private_types_in_public_api
  late _LiquidGlassRender _w;
  RenderLiquidGlassGroup? _group;

  // ignore: library_private_types_in_public_api
  void update(_LiquidGlassRender w) {
    _w = w;
    markNeedsLayout();
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void markNeedsPaint() {
    super.markNeedsPaint();
    _group?.markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    RenderObject? p = parent;
    while (p != null) {
      if (p is RenderLiquidGlassGroup) {
        if (p.register(this)) _group = p;
        break;
      }
      p = p.parent;
    }
  }

  @override
  void detach() {
    _group?.unregister(this);
    _group = null;
    super.detach();
  }

  @override
  void performLayout() {
    final w = _w;
    if (child != null) {
      child!.layout(
        BoxConstraints.tightFor(
          width: w.width,
          height: w.height,
        ).enforce(constraints),
        parentUsesSize: true,
      );
      size = constraints.constrain(child!.size);
    } else {
      size = constraints.constrain(Size(w.width ?? 0, w.height ?? 0));
    }
  }

  // Press response depends on the plate size (native, measured on `.glass`
  // circle buttons of 41..73 pt and a 222x94 capsule): small plates grow by a
  // fixed ~14.5 pt and light up ~42 % white, plates from ~94 pt up barely grow
  // (+3.4 pt) and light up ~16 %.
  // Press / drag response, fitted to native glass (frames of simulator touches and mouse drags, 3x px):
  //  * grow: uniform scale 1 + g(L) / L with L the LONGER side: g ~ 14.4 pt at 41 pt, 16.3 pt at 104 pt, 10 pt at 222 pt
  //    (circles 41..73 pt, a 104x44 toolbar capsule and a 222x94 capsule measured);
  //  * highlight: white mix of 0.42 around the finger (gaussian, sigma 65 pt for plates up to ~104 pt, nearly flat for
  //    big ones at 0.16);
  //  * drag: the plate follows the finger a little (5 pt at 100 pt pull) and stretches along the pull while it narrows
  //    across, a bump that peaks around 100-130 pt (+-9.5 % on the toolbar capsule at 100 pt) and relaxes by ~300 pt;
  //    icons deform with it and, on long pulls, more (+17 % / -12 % at 480 pt on a circle).
  double get _longSide => math.max(size.width, size.height);
  double get _bigT => ((_longSide - 104) / 118).clamp(0.0, 1.0);

  /// Edge displacements (pt, right/down positive) of a plate of size [w] x [h] (already press-scaled) dragged by the
  /// finger. ONE-SIDED, as in native: along each axis the edge on the finger's side moves by `n`, the opposite edge by
  /// only 0.4 n (so the plate stretches toward the finger and its center follows it); across the pull both edges move
  /// inward equally (squeeze, width only). Magnitudes (native toolbar capsule): stretch 0.5/1.4/2.8 pt
  /// at 20/50/100 pt and ~7 pt at 300-450 pt, squeeze of the width up to ~-20 % at 450 pt.
  ({double dl, double dr, double dt, double db})? _edgeDeltas(
    double w,
    double h,
  ) {
    final d = _w.drag;
    final dist = d.distance;
    if (dist < 0.5 || _w.press == 0) return null;
    final u = d / dist;
    final big = 1 - 0.9 * _bigT;
    // aspect: 1 for a circle, >= ~2.2 for a toolbar capsule (the two measured shapes), interpolated in between
    final aspect = math.max(w, h) / math.max(math.min(w, h), 1);
    final roundness = ((2.2 - aspect) / 1.2).clamp(0.0, 1.0);
    // stretch along the pull is an ABSOLUTE length (pt): capsule ~0.5/1.4/2.8 pt at 20/50/100 pt, ~6-7 pt at 300-450 pt;
    // a 44 pt circle saturates higher (9.7 pt at 450 pt)
    final emax = 8.0 + 3.5 * roundness;
    final grow =
        emax *
        (1 - math.exp(-math.pow(dist / (200 + 60 * roundness), 1.2))) *
        big;
    final sq = (1 - math.exp(-math.pow(dist / 380, 1.8))) * big;
    // squeeze across: the width shrinks when pulled along the short axis (capsule -17 % at 450 pt, circle -16 %); the height
    // shrinks when pulled sideways only on round plates (circle -8 % at 250 pt, capsule 0)
    final squeezeW = (0.17 + 0.08 * roundness) * sq;
    final squeezeH = 0.25 * roundness * sq;
    final ax = u.dx.abs();
    final ay = u.dy.abs();
    // size change per axis (smooth in the pull direction) and a SEPARATE center shift along the pull vector, so a finger
    // circling the plate moves the plate's center on a circle ("o"), not along the axes ("+"): the near edge moves by
    // n, the far one by far * n (circle 0.5, capsule 0.3) => size +(1-far) n, center +(1+far)/2 n
    final farShare = 0.3 + 0.2 * roundness;
    final dw = grow * ax * (1 - farShare) - squeezeW * w * ay;
    final dh = grow * ay * (1 - farShare) - squeezeH * h * ax;
    final shift = grow * (1 + farShare) / 2;
    final cx = u.dx * shift;
    final cy = u.dy * shift;
    final x = (cx - dw / 2, cx + dw / 2);
    final y = (cy - dh / 2, cy + dh / 2);
    return (dl: x.$1, dr: x.$2, dt: y.$1, db: y.$2);
  }

  double get _pressScale {
    if (_w.press == 0 || _longSide == 0) return 1;
    final l = _longSide;
    final extra = l <= 104
        ? 14.4 + (l - 41).clamp(0.0, 63.0) * 0.03
        : math.max(16.3 - (l - 104) * 0.053, 6.0);
    return 1 + _w.press * extra / l;
  }

  double get _pressGlow => 0.42 + (0.16 - 0.42) * _bigT;

  /// Gaussian sigma of the press highlight around the finger, pt.
  // While dragging the highlight is flat across the plate (native toolbar capsule: ~0.22 everywhere). The spread is LATCHED
  // (animated 0 -> 1 once the drag starts, kept until release) so pulling out and coming back never re-narrows the glow into a flash.
  double get _glowSigma => (65 + (300 - 65) * _bigT) * (1 + 3 * _w.spread);

  double get _radius =>
      math.min(_w.cornerRadius ?? size.shortestSide / 2, size.shortestSide / 2);

  _PlateGeom _geom(RenderBox owner, Offset offset) {
    final m = getTransformTo(owner);
    final r0 = MatrixUtils.transformRect(m, Offset.zero & size);
    final topLeft = localToGlobal(Offset.zero);
    final bottom = localToGlobal(Offset(0, size.height));
    final scale = size.height == 0
        ? 1.0
        : (bottom.dy - topLeft.dy) / size.height;
    final localScale = size.height == 0 ? 1.0 : r0.height / size.height;
    final k = _w.presence.clamp(0.0, 1.0) * _pressScale;
    var rect = r0;
    if (k != 1) {
      final pivot = rect.center + _w.presenceOrigin * localScale;
      final c = pivot + (rect.center - pivot) * k;
      rect = Rect.fromCenter(
        center: c,
        width: rect.width * k,
        height: rect.height * k,
      );
    }
    final ed = _edgeDeltas(size.width * _pressScale, size.height * _pressScale);
    if (ed != null) {
      rect = Rect.fromLTRB(
        rect.left + ed.dl * localScale,
        rect.top + ed.dt * localScale,
        rect.right + ed.dr * localScale,
        rect.bottom + ed.db * localScale,
      );
    }
    final toScreen = localScale == 0 ? 1.0 : scale / localScale;
    final global = topLeft + (rect.topLeft - r0.topLeft) * toScreen;
    // a full pill (circle / capsule) stays a pill while the drag deforms it: the radius follows the DEFORMED shorter side,
    // otherwise a stretched circle turns into a rounded rectangle with flat sides
    final isPill = _radius >= size.shortestSide / 2 - 0.01;
    final radius = isPill && ed != null
        ? rect.shortestSide / 2
        : _radius * localScale * k;
    return _PlateGeom(
      rect,
      radius,
      math.min(_w.style.bezel, size.shortestSide * 0.3) * localScale * k,
      _w.style.clear ? 0.0 : glassSmallness(size.shortestSide),
      global,
      scale,
      _w.highlight * _pressGlow / 0.16,
      _w.touch,
      _w.style.tint,
      _glowSigma,
      _w.cornerRadius == null && (size.width - size.height).abs() < 1.0,
    );
  }

  static void _drawFlatShadow(Canvas canvas, RRect rrect, Color? color) {
    if (color == null || color.a < 0.004) return;
    canvas.drawRRect(
      rrect.shift(const Offset(0, 5)),
      Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final fade = _w.style.fade;
    if (fade < 0.999 && _w.presence > 0.01 && size.shortestSide > 0) {
      // The flat plate (under a fading glass, or alone). It follows the press exactly like the glass: grows with the spring,
      // stretches under a drag (the same geometry the shader plate uses) and lights up under the finger.
      final flat = _w.style.flat;
      final g = _geom(this, Offset.zero);
      final rrect = RRect.fromRectAndRadius(
        g.rect.shift(offset),
        Radius.circular(g.radius),
      );
      final canvas = context.canvas;
      // inside a group the group draws the flat fill (so neighbouring plates can melt into one), the highlight stays here
      if (_group == null) {
        _drawFlatShadow(canvas, rrect, _w.style.flatShadow);
        canvas.drawRRect(
          rrect,
          Paint()..color = flat.withValues(alpha: flat.a * (1 - fade)),
        );
      }
      final hi = _w.highlight * _pressGlow * (1 - fade);
      if (hi > 0.004) {
        canvas.drawRRect(
          rrect,
          Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: (hi * 0.55).clamp(0.0, 0.5)),
        );
      }
    }
    if (_w.program != null &&
        _group == null &&
        _w.presence > 0.01 &&
        fade > 0.004) {
      layer = _pass.paint(
        context,
        offset,
        [_geom(this, Offset.zero)],
        _w.highQuality ? _w.style : _w.style.withPrefilter(0),
        needsCompositing,
        layer,
      );
    }
    if (child != null) {
      final ps = _pressScale;
      final ed = _edgeDeltas(size.width * ps, size.height * ps);
      if (ps == 1 && ed == null) {
        context.paintChild(child!, offset);
      } else {
        final c = size.center(offset);
        final m = Matrix4.translationValues(c.dx, c.dy, 0);
        if (ed != null) {
          // icons deform exactly like the plate: map the pressed rect onto the dragged one
          final w = size.width * ps;
          final h = size.height * ps;
          m
            ..translateByDouble((ed.dl + ed.dr) / 2, (ed.dt + ed.db) / 2, 0, 1)
            ..scaleByDouble(
              (w + ed.dr - ed.dl) / w,
              (h + ed.db - ed.dt) / h,
              1,
              1,
            );
        }
        m
          ..scaleByDouble(ps, ps, 1, 1)
          ..translateByDouble(-c.dx, -c.dy, 0, 1);
        context.pushTransform(
          needsCompositing,
          Offset.zero,
          m,
          (ctx, off) => ctx.paintChild(child!, offset),
        );
      }
    }
  }

  @override
  BackdropFilterLayer? get layer => super.layer as BackdropFilterLayer?;

  @override
  void dispose() {
    _passOrNull?.dispose();
    layer = null;
    super.dispose();
  }
}

/// Shares one backdrop pass (one engine blur + one shader) between all
/// [LiquidGlass] plates below it (up to 8). [ChromeBar] wraps its content in
/// one, so the buttons of a bar cost one pass, not one each. The plates must
/// be painted above everything the group's backdrop should include (true for
/// bars: they sit over the scroll content).
class LiquidGlassGroup extends StatelessWidget {
  const LiquidGlassGroup({super.key, required this.child, this.spacing = 0});
  final Widget child;

  /// Plates closer than this (logical px) melt into one shape while one of them is pressed, appears or vanishes, like
  /// SwiftUI's `GlassEffectContainer(spacing:)`; their gap bridges at about half of it. At rest every plate keeps its own
  /// shape. 0 keeps plates separate.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    // Without the shader the group still exists: flat plates melt in it too (no shader needed).
    return _LiquidGlassGroupRender(
      program: LiquidGlass.supported ? LiquidGlass._program : null,
      spacing: spacing,
      child: child,
    );
  }
}

class _LiquidGlassGroupRender extends SingleChildRenderObjectWidget {
  const _LiquidGlassGroupRender({
    required this.program,
    required this.spacing,
    super.child,
  });
  final ui.FragmentProgram? program;
  final double spacing;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderLiquidGlassGroup(program)..spacing = spacing;

  @override
  void updateRenderObject(
    BuildContext context,
    RenderLiquidGlassGroup renderObject,
  ) {
    renderObject.program = program;
    renderObject.spacing = spacing;
  }
}

/// Render object of [LiquidGlassGroup].
class RenderLiquidGlassGroup extends RenderProxyBox {
  RenderLiquidGlassGroup(this.program);

  /// null: no shader (flat plates only).
  ui.FragmentProgram? program;
  _GlassPass? _passOrNull;
  _GlassPass get _pass => _passOrNull ??= _GlassPass(program!);
  final List<RenderLiquidGlass> _plates = [];
  double _spacing = 0;
  set spacing(double v) {
    if (v != _spacing) {
      _spacing = v;
      markNeedsPaint();
    }
  }

  static double _activity(RenderLiquidGlass p) {
    final w = p._w;
    return math.max(w.highlight, math.max(w.press, 1 - w.presence));
  }

  /// Which of [ps] (with their current [rects]) melt into one shape. Only the plates that really interact: the ones in motion
  /// (pressed, lit, appearing or vanishing) and the neighbours within [_spacing] of them. A plate further away keeps its own
  /// shape and is not touched by the morph (pressing one bar button must not change how all the others are drawn). With fewer
  /// than two such plates there is nothing to melt and the result is all false.
  List<bool> _meltSet(List<RenderLiquidGlass> ps, List<Rect> rects) {
    final n = ps.length;
    final none = List<bool>.filled(n, false);
    if (_spacing <= 0 || n < 2) return none;
    final active = [for (final p in ps) _activity(p) > 0.004];
    final melt = List<bool>.of(active);
    var any = false;
    for (var i = 0; i < n; i++) {
      if (!active[i]) continue;
      any = true;
      final reach = rects[i].inflate(_spacing);
      for (var j = 0; j < n; j++) {
        if (j != i && !melt[j] && reach.overlaps(rects[j])) melt[j] = true;
      }
    }
    if (!any || melt.where((m) => m).length < 2) return none;
    return melt;
  }

  bool register(RenderLiquidGlass p) {
    if (_plates.length >= _GlassPass.maxPlates) return false;
    _plates.add(p);
    markNeedsPaint();
    return true;
  }

  void unregister(RenderLiquidGlass p) {
    _plates.remove(p);
    if (attached) markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  BackdropFilterLayer? get layer => super.layer as BackdropFilterLayer?;

  /// The flat plates of the group. Like the glass they melt into one shape while one of them is pressed, appears or vanishes:
  /// no shader, the classic "gooey" trick: the plates are blurred together and the alpha is pushed back to a hard edge, so
  /// where two blurs overlap they join into a neck. At rest (or alone) every plate is drawn crisp, as plain rounded rects.
  void _paintFlat(PaintingContext context, Offset offset) {
    final flats = [
      for (final p in _plates)
        if (p.attached &&
            p.hasSize &&
            p.size.shortestSide > 0 &&
            p._w.presence > 0.01 &&
            p._w.style.fade < 0.999)
          p,
    ];
    if (flats.isEmpty) return;
    final rrects = <RRect>[];
    final rects = <Rect>[];
    final colors = <Color>[];
    for (final p in flats) {
      final g = p._geom(this, Offset.zero);
      rects.add(g.rect);
      rrects.add(
        RRect.fromRectAndRadius(g.rect.shift(offset), Radius.circular(g.radius)),
      );
      final flat = p._w.style.flat;
      colors.add(flat.withValues(alpha: flat.a * (1 - p._w.style.fade)));
    }
    // only the plates that really interact melt; the rest stay crisp
    final melt = _meltSet(flats, rects);
    var activity = 0.0;
    for (var i = 0; i < flats.length; i++) {
      if (melt[i]) activity = math.max(activity, _activity(flats[i]));
    }
    final canvas = context.canvas;
    for (var i = 0; i < flats.length; i++) {
      RenderLiquidGlass._drawFlatShadow(
        canvas,
        rrects[i],
        flats[i]._w.style.flatShadow,
      );
    }
    final sigma = _spacing * activity.clamp(0.0, 1.0) * 0.6;
    final meltIdx = [
      for (var i = 0; i < flats.length; i++)
        if (melt[i]) i,
    ];
    if (meltIdx.length < 2 || sigma < 0.4) {
      for (var i = 0; i < rrects.length; i++) {
        canvas.drawRRect(rrects[i], Paint()..color = colors[i]);
      }
      return;
    }
    for (var i = 0; i < rrects.length; i++) {
      if (!melt[i]) canvas.drawRRect(rrects[i], Paint()..color = colors[i]);
    }
    final merged = [for (final i in meltIdx) rrects[i]];
    var bounds = merged.first.outerRect;
    for (final r in merged) {
      bounds = bounds.expandToInclude(r.outerRect);
    }
    bounds = bounds.inflate(sigma * 4 + 2);
    // one colour for the merged shape: the plates are drawn opaque into the layer and the fill's own alpha is applied once
    // to the result (so the overlap does not turn darker)
    final base = colors[meltIdx.first];
    // alpha contrast: the blurred edge turns into a hard one. The threshold is a little below the half, so the shape holds
    // together where two blurs overlap (a neck) instead of staying two separate discs.
    const k = 40.0;
    const threshold = 0.36;
    const offsetA = (0.5 - threshold * k) * 255;
    context.pushOpacity(Offset.zero, (base.a * 255).round().clamp(0, 255), (
      ctx,
      _,
    ) {
      ctx.pushColorFilter(
        Offset.zero,
        const ColorFilter.matrix(<double>[
          1, 0, 0, 0, 0, //
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          0, 0, 0, k, offsetA,
        ]),
        (ctx2, _) {
          ctx2.pushLayer(
            ImageFilterLayer(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: sigma,
                sigmaY: sigma,
                tileMode: TileMode.decal,
              ),
            ),
            (ctx3, _) {
              final paint = Paint()..color = base.withValues(alpha: 1);
              for (final r in merged) {
                ctx3.canvas.drawRRect(r, paint);
              }
            },
            Offset.zero,
            childPaintBounds: bounds,
          );
        },
      );
    });
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _paintFlat(context, offset);
    final live = [
      for (final p in _plates)
        if (p.attached &&
            p.hasSize &&
            p.size.shortestSide > 0 &&
            p._w.presence > 0.01 &&
            p._w.program != null &&
            p._w.style.fade > 0.004)
          p,
    ];
    if (live.isEmpty || program == null) {
      layer = null;
    } else {
      final geoms = [for (final p in live) p._geom(this, offset)];
      // the melt between neighbours belongs to interaction (a press, a plate that appears or vanishes): at rest every plate
      // keeps its own shape instead of bulging toward the plate next to it
      // and only the plates that really interact melt (the one in motion and its neighbours within the spacing): pressing one
      // button must not change how the other plates of the bar are drawn
      final melt = _meltSet(live, [for (final g in geoms) g.rect]);
      var activity = 0.0;
      for (var i = 0; i < live.length; i++) {
        geoms[i].melt = melt[i];
        if (melt[i]) activity = math.max(activity, _activity(live[i]));
      }
      layer = _pass.paint(
        context,
        offset,
        geoms,
        live.first._w.style,
        needsCompositing,
        layer,
        morph: _spacing * activity.clamp(0.0, 1.0),
      );
    }
    super.paint(context, offset);
  }

  @override
  void dispose() {
    _passOrNull?.dispose();
    layer = null;
    super.dispose();
  }
}

/// Animates a [LiquidGlass] in and out: `show` toggles [presence] from 0 to 1
/// (and back) over [duration]; the child fades with it. Build the glass in
/// [builder] and pass it the given `presence`:
///
/// ```dart
/// LiquidGlassPresence(
///   show: open,
///   builder: (context, p) => LiquidGlass.circle(size: 44, presence: p, presenceOrigin: const Offset(-52, 0)),
/// )
/// ```
/// The widget keeps its layout size even at presence 0 (wrap in your own
/// `AnimatedSize` if the space should collapse too).
class LiquidGlassPresence extends StatelessWidget {
  const LiquidGlassPresence({
    super.key,
    required this.show,
    required this.builder,
    this.duration = const Duration(milliseconds: 450),
    this.curve = Curves.easeInOutCubic,
  });

  final bool show;
  final Widget Function(BuildContext context, double presence) builder;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: show ? 1.0 : 0.0),
      duration: duration,
      curve: curve,
      builder: (context, v, _) => builder(context, v),
    );
  }
}

/// Lets a gesture that takes a touch over from interactive [LiquidGlass] plates tell them to let go. The plates read the
/// finger with a plain `Listener` (it never joins the gesture arena), so when a parent claims the drag (a side drawer, a
/// pager, a sheet) they would keep stretching toward the finger as if the glass itself were dragged. Put a
/// [LiquidPressScope] above the plates and call [cancel] when your drag starts.
class LiquidPressCanceller extends ChangeNotifier {
  void cancel() => notifyListeners();
}

/// Delivers a [LiquidPressCanceller] to the interactive plates below it.
class LiquidPressScope extends InheritedWidget {
  const LiquidPressScope({
    super.key,
    required this.canceller,
    required super.child,
  });

  final LiquidPressCanceller canceller;

  static LiquidPressCanceller? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LiquidPressScope>()?.canceller;

  @override
  bool updateShouldNotify(LiquidPressScope old) => canceller != old.canceller;
}

/// Tracks the pointer on its subtree (without joining the gesture arena) and
/// drives the press scale spring, the highlight (fade, weaker once the finger
/// drags, radial around the touch) and the rubber-band drag offset.
class _LiquidPress extends StatefulWidget {
  const _LiquidPress({required this.builder});
  final Widget Function(
    BuildContext context,
    double scale,
    double highlight,
    Offset touch,
    Offset drag,
    double spread,
  )
  builder;

  @override
  State<_LiquidPress> createState() => _LiquidPressState();
}

class _LiquidPressState extends State<_LiquidPress>
    with TickerProviderStateMixin {
  // press: ~10 % overshoot of the settle; release: native capsule undershoots ~27 % of its travel (zeta ~0.4, first extremum
  // at ~0.165 s) before settling, measured from 60 fps frames
  static const _spring = SpringDescription(
    mass: 1,
    stiffness: 730,
    damping: 34,
  ); // native press: omega 27, zeta .63, peak +8 % at .15 s
  static const _springRelease = SpringDescription(
    mass: 1,
    stiffness: 282,
    damping: 11.8,
  ); // native release: omega 16.8, zeta .35 (rest crossing .125 s, min -27 % at .2 s, +9 % at .4 s)
  late final AnimationController _scale = AnimationController.unbounded(
    vsync: this,
    value: 0,
  );
  late final AnimationController _hi = AnimationController(vsync: this);
  late final AnimationController _dragK = AnimationController(
    vsync: this,
  ); // 0 still, 1 dragging
  late final AnimationController _back = AnimationController.unbounded(
    vsync: this,
  ); // drag offset decay
  int _pointers = 0;
  LiquidPressCanceller? _canceller;
  Offset _down0 = Offset.zero;
  Offset _touch = Offset.zero; // from the plate center
  Offset _drag = Offset.zero; // from the touch-down point
  Offset _dragAtRelease = Offset.zero;
  bool _dragging = false;

  // A quick tap must still play the whole press: the release waits until the press has had this long to build up (native
  // shows the grow and glow even for the shortest tap).
  static const _minHold = Duration(milliseconds: 130);
  DateTime _downAt = DateTime.now();
  Timer? _pendingRelease;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = LiquidPressScope.maybeOf(context);
    if (!identical(c, _canceller)) {
      _canceller?.removeListener(_cancelPress);
      _canceller = c?..addListener(_cancelPress);
    }
  }

  /// Another gesture (a drawer, a pager...) took the touch over: the plate lets go at once, springing back, and ignores
  /// the rest of this touch (the finger is still down, but it is no longer pressing the glass).
  void _cancelPress() {
    if (_pointers == 0) return;
    _pendingRelease?.cancel();
    _pendingRelease = null;
    _pointers = 0;
    _release();
  }

  void _onDown(PointerDownEvent e) {
    _pendingRelease?.cancel();
    _pendingRelease = null;
    if (_pointers++ > 0) return;
    _downAt = DateTime.now();
    final box = context.findRenderObject() as RenderBox;
    _down0 = e.localPosition;
    _touch = e.localPosition - box.size.center(Offset.zero);
    _drag = Offset.zero;
    _dragging = false;
    _back.stop();
    _dragK.value = 0;
    _scale.animateWith(
      SpringSimulation(_spring, _scale.value, 1, _scale.velocity),
    );
    _hi.animateTo(
      1,
      duration: const Duration(milliseconds: 85),
      curve: Curves.easeOut,
    );
    setState(() {});
  }

  void _onMove(PointerMoveEvent e) {
    if (_pointers == 0) return;
    final box = context.findRenderObject() as RenderBox;
    _touch = e.localPosition - box.size.center(Offset.zero);
    _drag = e.localPosition - _down0;
    if (!_dragging && _drag.distance > 8) {
      _dragging = true;
      // once the finger drags, the highlight settles to ~0.75 of its press value (radial falloff covers the rest)
      _dragK.animateTo(1, duration: const Duration(milliseconds: 100));
    }
    setState(() {});
  }

  void _onUp() {
    if (_pointers > 0) _pointers--;
    if (_pointers > 0) return;
    final held = DateTime.now().difference(_downAt);
    if (held < _minHold) {
      _pendingRelease?.cancel();
      _pendingRelease = Timer(_minHold - held, () {
        _pendingRelease = null;
        if (mounted && _pointers == 0) _release();
      });
      return;
    }
    _release();
  }

  void _release() {
    _scale.animateWith(
      SpringSimulation(_springRelease, _scale.value, 0, _scale.velocity),
    );
    _hi.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.linear,
    );
    // the rubber band relaxes with the same spring
    _dragAtRelease = _drag;
    _back.value = 1;
    _back.animateWith(SpringSimulation(_springRelease, 1, 0, 0));
    _dragging = false;
    _drag = Offset.zero;
  }

  @override
  void dispose() {
    _canceller?.removeListener(_cancelPress);
    _pendingRelease?.cancel();
    _scale.dispose();
    _hi.dispose();
    _dragK.dispose();
    _back.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onDown,
      onPointerMove: _onMove,
      onPointerUp: (_) => _onUp(),
      onPointerCancel: (_) => _onUp(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_scale, _hi, _dragK, _back]),
        builder: (context, _) {
          final drag = _pointers > 0 ? _drag : _dragAtRelease * _back.value;
          final hi = _hi.value * (1 - 0.37 * _dragK.value);
          return widget.builder(
            context,
            _scale.value,
            hi,
            _touch,
            drag,
            Curves.easeInOut.transform(_dragK.value.clamp(0.0, 1.0)),
          );
        },
      ),
    );
  }
}

/// Capturing a layer to an image (`OffsetLayer.toImageSync`) re-runs the scene build of its subtree, and the glass layers
/// inside place their plates from their position in the layer tree. Wrap the capture in [capture] so they place them
/// relative to the captured layer instead of the screen; without it the plates of a snapshot land in the wrong places.
/// Used by `FreezeUnderRoute`.
class GlassSnapshot {
  GlassSnapshot._();

  static Layer? _root;
  static double _scale = 1;

  static T capture<T>(Layer root, double pixelRatio, T Function() body) {
    final prevRoot = _root;
    final prevScale = _scale;
    _root = root;
    _scale = pixelRatio;
    try {
      return body();
    } finally {
      _root = prevRoot;
      _scale = prevScale;
    }
  }
}
