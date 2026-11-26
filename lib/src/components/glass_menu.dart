import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../theme/swift_ui_theme.dart';
import 'glass_sheet.dart' show GlassSheetOriginController, GlassOriginSnapshot;
import 'liquid_glass.dart';
import 'press_tracker.dart';
import 'glass_surface.dart';

/// An entry of a [showGlassMenu] / [GlassMenuButton] menu.
sealed class GlassMenuEntry {
  const GlassMenuEntry();
}

/// A tappable row: optional [leading] widget (icon), label, optional check mark.
class GlassMenuItem extends GlassMenuEntry {
  const GlassMenuItem({
    required this.label,
    this.leading,
    this.destructive = false,
    this.checked = false,
    this.onSelected,
  });

  final String label;
  final Widget? leading;

  /// Red label and icon (delete, sign out...).
  final bool destructive;
  final bool checked;
  final VoidCallback? onSelected;
}

/// Thick separator between groups of items (native menus group with an 8 pt gap).
class GlassMenuDivider extends GlassMenuEntry {
  const GlassMenuDivider();
}

const _kItemHeight = 44.0;
const _kDividerHeight = 8.0;
const _kPad = 6.0;

/// Native-style menu (UIMenu / SwiftUI Menu): a glass panel that pops out of the widget [context] belongs to, scaling
/// from the anchor corner with a spring, and dismisses on a tap outside or on an item.
///
/// With [origin] (a [GlassSheetOriginController] on the control, or on the whole group of buttons it sits in) the menu does
/// what a native one does on a glass button: it grows out of the control's glass, which is hidden while the menu is open. The
/// panel starts as the control's rectangle, grows to its size with a small overshoot, keeps the control's top corner and
/// shows its rows as it grows; closing shrinks it back. Without [origin] the menu pops from the anchor corner.
Future<void> showGlassMenu(
  BuildContext context, {
  required List<GlassMenuEntry> entries,
  double width = 254,
  GlassSheetOriginController? origin,
}) async {
  final box = context.findRenderObject() as RenderBox;
  final anchor = origin?.rect ?? (box.localToGlobal(Offset.zero) & box.size);
  await origin?.capture();
  origin?.hideForPresentation();
  final route = _GlassMenuRoute(
    anchor: anchor,
    entries: entries,
    width: width,
    morph: origin != null,
    origin: origin,
    // the button that was pressed: the droplet comes out of it, not out of the middle of the group
    focus: origin?.lastTouch ?? box.localToGlobal(box.size.center(Offset.zero)),
  );
  try {
    await Navigator.of(context, rootNavigator: true).push(route);
    // the push completes when the menu is popped, not when it has shrunk back: the control stays hidden until then
    final a = route.animation;
    if (a != null && a.status != AnimationStatus.dismissed) {
      final done = Completer<void>();
      void listener(AnimationStatus st) {
        if (st == AnimationStatus.dismissed && !done.isCompleted) {
          // the control is back before the droplet's last frame is gone: no frame with neither
          origin?.showNow();
          done.complete();
        }
      }

      a.addStatusListener(listener);
      await done.future;
    }
  } finally {
    origin?.showAfterPresentation();
  }
}

/// Gives [builder] an `open` callback that shows the menu anchored to the widget it returns. Hand `open` to your button:
///
/// ```dart
/// GlassMenuButton(
///   entries: [...],
///   builder: (context, open) => GlassCircleButton(icon: RavelIcon(RavelIconKind.menu), onPressed: open),
/// )
/// ```
/// (use it as `onLongPress` of anything for a context menu).
class GlassMenuButton extends StatelessWidget {
  const GlassMenuButton({
    super.key,
    required this.builder,
    required this.entries,
    this.width = 254,
    this.origin,
  });

  final Widget Function(BuildContext context, VoidCallback open) builder;
  final List<GlassMenuEntry> entries;
  final double width;

  /// See [showGlassMenu]: the menu grows out of this control's glass.
  final GlassSheetOriginController? origin;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (c) => builder(
        c,
        () => showGlassMenu(c, entries: entries, width: width, origin: origin),
      ),
    );
  }
}

class _GlassMenuRoute extends PopupRoute<void> {
  _GlassMenuRoute({
    required this.anchor,
    required this.entries,
    required this.width,
    required this.morph,
    this.origin,
    this.focus,
  });

  final GlassSheetOriginController? origin;
  final Offset? focus;
  final Rect anchor;
  final List<GlassMenuEntry> entries;
  final double width;

  /// The menu grows out of [anchor] instead of popping from its corner.
  final bool morph;

  @override
  Color? get barrierColor => null;
  @override
  bool get barrierDismissible => true;
  @override
  String? get barrierLabel => 'Dismiss';
  @override
  Duration get transitionDuration =>
      Duration(milliseconds: morph ? _kMenuOpenMs.round() : 380);
  @override
  Duration get reverseTransitionDuration =>
      Duration(milliseconds: morph ? _kMenuCloseMs.round() : 180);

  double get _height =>
      _kPad * 2 +
      entries.fold<double>(
        0,
        (h, e) => h + (e is GlassMenuDivider ? _kDividerHeight : _kItemHeight),
      );

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
  ) {
    final size = MediaQuery.sizeOf(context);
    final safe = MediaQuery.paddingOf(context);
    final h = _height;
    const margin = 12.0;
    if (morph) return _buildMorph(context, animation, size, safe, h, margin);
    // under the anchor when it fits, above it otherwise; aligned to the anchor's near screen edge
    final below = anchor.bottom + 8 + h <= size.height - safe.bottom - margin;
    final top = below
        ? anchor.bottom + 8
        : math.max(safe.top + margin, anchor.top - 8 - h);
    final alignRight = anchor.center.dx > size.width / 2;
    var left = alignRight ? anchor.right - width : anchor.left;
    left = left.clamp(margin, size.width - width - margin);
    final origin = Alignment(
      ((anchor.center.dx - left) / width * 2 - 1).clamp(-1.0, 1.0),
      below ? -1 : 1,
    );
    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          width: width,
          height: h,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final scale =
                  0.55 +
                  0.45 *
                      Curves.easeOutBack.transform(
                        animation.value.clamp(0.0, 1.0),
                      );
              return Opacity(
                opacity: Curves.easeOut.transform(
                  (animation.value * 1.6).clamp(0.0, 1.0),
                ),
                child: Transform.scale(
                  scale: scale,
                  alignment: origin,
                  child: child,
                ),
              );
            },
            child: _MenuPanel(entries: entries),
          ),
        ),
      ],
    );
  }
}

/// One edge of the morphing plate: a smooth step from where the edge rests to [x0] over [t0] ms, then a damped spring to its
/// final value (all numbers measured on the native menu of a toolbar group, see tools/native_morph_ref/MORPH_SPEC.md).
class _EdgeSpring {
  const _EdgeSpring(this.t0, this.v0, this.omega, this.zeta);
  final double t0; // ms
  final double v0; // pt / ms
  final double omega; // rad / ms
  final double zeta;

  double at(
    double tau, {
    required double rest,
    required double x0,
    required double xf,
  }) {
    if (tau <= t0) {
      final s = (tau / t0).clamp(0.0, 1.0);
      return rest + (x0 - rest) * s * s * (3 - 2 * s);
    }
    final s = tau - t0;
    final wd = omega * math.sqrt(1 - zeta * zeta);
    final d = x0 - xf;
    return xf +
        math.exp(-zeta * omega * s) *
            (d * math.cos(wd * s) +
                (v0 + zeta * omega * d) / wd * math.sin(wd * s));
  }
}

// opening: capsule -> menu (L, R, T, B)
const _kOpenL = _EdgeSpring(43.1, -1.840, 0.0174, 0.76);
const _kOpenR = _EdgeSpring(36.8, 0.222, 0.0139, 0.83);
const _kOpenT = _EdgeSpring(61.2, 0.828, 0.0174, 0.69);
const _kOpenB = _EdgeSpring(31.5, 2.329, 0.0201, 0.64);
// closing: menu -> capsule
const _kCloseL = _EdgeSpring(18.8, 0.077, 0.0194, 0.68);
const _kCloseR = _EdgeSpring(52.1, -0.734, 0.0156, 0.62);
const _kCloseT = _EdgeSpring(2.7, 1.127, 0.0214, 0.41);
const _kCloseB = _EdgeSpring(12.0, 1.449, 0.0159, 0.70);

/// Real milliseconds of the opening and closing timelines (the route's animation runs over them).
const _kMenuOpenMs = 700.0;
const _kMenuCloseMs = 450.0;

extension on _GlassMenuRoute {
  /// The menu grown out of the anchor as the native one does it (tools/native_morph_ref/MORPH_SPEC.md, measured from pixels):
  /// one glass plate whose four edges follow their own damped springs (so the menu overshoots, its top dips and comes back), the
  /// control's picture is cut by the shrinking plate and fades in 55 ms, the rows are in the plate from the start, a little
  /// enlarged and blurred, and sharpen from 100 ms on. Closing has its own springs and timings, it is not the opening played back.
  Widget _buildMorph(
    BuildContext context,
    Animation<double> animation,
    Size size,
    EdgeInsets safe,
    double h,
    double margin,
  ) {
    final alignRight = anchor.center.dx > size.width / 2;
    var left = alignRight ? anchor.right - width : anchor.left;
    left = left.clamp(margin, size.width - width - margin);
    var top = anchor.top;
    top = top.clamp(
      safe.top + 4,
      math.max(safe.top + 4, size.height - safe.bottom - margin - h),
    );
    final end = Rect.fromLTWH(left, top, width, h);
    // everything is computed for a menu that hangs from the right edge; a left one is mirrored
    final cx = anchor.center.dx;
    Rect flip(Rect r) => alignRight
        ? r
        : Rect.fromLTRB(2 * cx - r.right, r.top, 2 * cx - r.left, r.bottom);
    final cap = flip(anchor);
    final menu = flip(end);

    Rect openRect(double tau) => Rect.fromLTRB(
      _kOpenL.at(tau, rest: cap.left, x0: cap.left + 27.1, xf: menu.left),
      _kOpenT.at(tau, rest: cap.top, x0: cap.top + 14.1, xf: menu.top),
      _kOpenR.at(tau, rest: cap.right, x0: cap.right - 21.1, xf: menu.right),
      _kOpenB.at(tau, rest: cap.bottom, x0: cap.bottom + 4.2, xf: menu.bottom),
    );
    Rect closeRect(double tau) => Rect.fromLTRB(
      _kCloseL.at(tau, rest: menu.left, x0: menu.left + 6.8, xf: cap.left),
      _kCloseT.at(tau, rest: menu.top, x0: menu.top + 1.0, xf: cap.top),
      _kCloseR.at(tau, rest: menu.right, x0: menu.right - 3.9, xf: cap.right),
      _kCloseB.at(
        tau,
        rest: menu.bottom,
        x0: menu.bottom + 2.6,
        xf: cap.bottom,
      ),
    );
    const restRadius = 31.0;
    final r190 = (() {
      final r = openRect(190);
      return math.min(r.width, r.height) / 2;
    })();

    return Stack(
      children: [
        AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final closing = animation.status == AnimationStatus.reverse;
            final p = animation.value.clamp(0.0, 1.0);
            final double tau;
            final Rect r;
            double radius;
            final double rowsAlpha;
            final double rowsBlur;
            final double rowsScale;
            final double iconAlpha;
            double trScale = 1;
            double brScale = 1;
            if (!closing) {
              tau = p * _kMenuOpenMs;
              r = openRect(tau);
              final half = math.min(r.width, r.height) / 2;
              radius = tau < 190
                  ? half
                  : restRadius +
                        (r190 - restRadius) * math.exp(-(tau - 190) / 56);
              radius = math.min(radius, half);
              rowsAlpha = _smoothStep((tau - 100) / 100);
              rowsBlur = tau < 120 ? 3 : 3 * math.exp(-(tau - 140) / 38);
              rowsScale = tau < 190
                  ? 1.27
                  : 1 + 0.27 * math.exp(-(tau - 190) / 70);
              iconAlpha = 1 - _smoothStep(tau / 57);
              // the native blob is not symmetric (measured on the frames, tools/native_morph_ref): its top-right corner is tighter
              // than the top-left one, which sags into a long slope, so the droplet leans towards the pressed button
              final lean =
                  _smoothStep((tau - 45) / 55) *
                  (1 - _smoothStep((tau - 200) / 200));
              trScale = 1 - 0.5 * lean;
              brScale = 1 - 0.15 * lean;
            } else {
              tau = (1 - p) * _kMenuCloseMs;
              r = closeRect(tau);
              radius = math.min(
                math.min(r.width, r.height) / 2,
                restRadius + 0.75 * tau,
              );
              rowsAlpha = 1 - _smoothStep(tau / 80);
              rowsBlur = 2 * _smoothStep(tau / 80);
              rowsScale = 1;
              iconAlpha = _smoothStep((tau - 130) / 140);
              final lean =
                  _smoothStep(tau / 60) * (1 - _smoothStep((tau - 150) / 110));
              trScale = 1 - 0.5 * lean;
              brScale = 1 - 0.15 * lean;
            }
            final cur = flip(r);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fromRect(
                  rect: cur,
                  child: _MenuPanel(
                    entries: entries,
                    radius: radius,
                    contentOpacity: rowsAlpha,
                    contentWidth: width,
                    contentHeight: h,
                    alignRight: alignRight,
                    cornerScaleTR: alignRight ? trScale : 1,
                    cornerScaleBR: alignRight ? brScale : 1,
                    contentScaleX: rowsScale,
                    contentScaleY: rowsScale,
                    contentBlur: rowsBlur < 0.3 || rowsAlpha < 0.02
                        ? 0
                        : rowsBlur,
                  ),
                ),
                Positioned.fromRect(
                  rect: cur,
                  child: GlassOriginSnapshot(
                    origin: origin,
                    alpha: iconAlpha,
                    blur: 0,
                    topLeft: anchor.topLeft - cur.topLeft,
                    radius: BorderRadius.only(
                      topLeft: Radius.circular(radius),
                      topRight: Radius.circular(
                        radius * (alignRight ? trScale : 1),
                      ),
                      bottomLeft: Radius.circular(radius),
                      bottomRight: Radius.circular(
                        radius * (alignRight ? brScale : 1),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MenuPanel extends StatelessWidget {
  const _MenuPanel({
    required this.entries,
    this.radius = 26,
    this.contentOpacity = 1,
    this.contentWidth,
    this.contentHeight,
    this.alignRight = false,
    this.contentScaleX = 1,
    this.contentScaleY = 1,
    this.contentBlur = 0,
    this.opacity = 1,
    this.cornerScaleTR = 1,
    this.cornerScaleBR = 1,
  });
  final List<GlassMenuEntry> entries;
  final double cornerScaleTR;
  final double cornerScaleBR;
  final double radius;
  final double contentOpacity;

  /// When set, the rows keep this size and are clipped by the (growing) panel.
  final double? contentWidth;
  final double? contentHeight;
  final bool alignRight;

  /// The rows are scaled by this and blurred by [contentBlur] (sigma) while the panel is still a droplet.
  final double contentScaleX;
  final double contentScaleY;
  final double contentBlur;

  /// Fades the glass plate itself (not through an [Opacity]: that would take its backdrop away).
  final double opacity;

  Widget _fitted(BuildContext context, SwiftUiThemeData t) {
    Widget c = rows(context, t);
    if ((contentScaleX - 1).abs() > 0.001 ||
        (contentScaleY - 1).abs() > 0.001) {
      // the rows keep their layout and are scaled around the middle of the panel
      c = Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(contentScaleX, contentScaleY, 1),
        child: c,
      );
    }
    if (contentBlur > 0.3) {
      c = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: contentBlur,
          sigmaY: contentBlur,
          tileMode: TileMode.decal,
        ),
        child: c,
      );
    }
    return c;
  }

  Widget rows(BuildContext context, SwiftUiThemeData t) =>
      PressTracker<GlassMenuItem>(
        // the row under the finger is the lit one, whichever the finger came down on; the one it is lifted over is chosen
        onActivate: (item) {
          Navigator.of(context).pop();
          item.onSelected?.call();
        },
        builder: (context, hot, keyOf) => Padding(
          padding: const EdgeInsets.symmetric(vertical: _kPad),
          child: Column(
            children: [
              for (final e in entries)
                switch (e) {
                  GlassMenuDivider() => Container(
                    height: _kDividerHeight,
                    color: t.colors.foreground.withValues(alpha: 0.08),
                  ),
                  final GlassMenuItem item => _MenuRow(
                    key: keyOf(item),
                    item: item,
                    pressed: identical(hot, item),
                  ),
                },
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    // the route sits above the app's Material: without this default, Text gets the yellow double underline
    final morphing = contentWidth != null;
    if (LiquidGlass.supported && t.glass.useLiquidGlass) {
      // a real glass plate (when it grows out of a control its size and radius follow the morph), with the touch response of
      // glass: it grows on a press, stretches under the finger and lights up around it
      return DefaultTextStyle(
        style: t.typography.body.copyWith(decoration: TextDecoration.none),
        child: LiquidGlass(
          cornerRadius: radius,
          opacity: opacity,
          interactive: true,
          glowSigma: 70,
          glowStrength: 0.7,
          stretch: 3,
          cornerScaleTR: cornerScaleTR,
          cornerScaleBR: cornerScaleBR,
          child: !morphing
              ? rows(context, t)
              : ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.center,
                    minWidth: contentWidth,
                    maxWidth: contentWidth,
                    minHeight: contentHeight,
                    maxHeight: contentHeight,
                    child: Opacity(
                      opacity: contentOpacity,
                      child: _fitted(context, t),
                    ),
                  ),
                ),
        ),
      );
    }
    return DefaultTextStyle(
      style: t.typography.body.copyWith(decoration: TextDecoration.none),
      child: GlassSurface(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        backdropBlur: true,
        sigma: 28,
        fill: t.isDark ? const Color(0xE62C2C2E) : const Color(0xE6F2F2F7),
        child: contentWidth == null
            ? rows(context, t)
            : ClipRect(
                child: OverflowBox(
                  alignment: alignRight
                      ? Alignment.topRight
                      : Alignment.topLeft,
                  minWidth: contentWidth,
                  maxWidth: contentWidth,
                  minHeight: contentHeight,
                  maxHeight: contentHeight,
                  // the rows are not wrapped around the glass: only they fade, the panel itself is already there
                  child: Opacity(
                    opacity: contentOpacity,
                    child: _fitted(context, t),
                  ),
                ),
              ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({super.key, required this.item, required this.pressed});
  final GlassMenuItem item;

  /// The finger is on this row (the menu's tracker moves it as the finger moves).
  final bool pressed;

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final color = item.destructive
        ? const Color(0xFFFF453A)
        : t.colors.foreground;
    return Container(
      height: _kItemHeight,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: pressed
            ? t.colors.foreground.withValues(alpha: 0.16)
            : const Color(0x00000000),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          if (item.checked)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: CustomPaint(
                size: const Size(16, 16),
                painter: _CheckPainter(color),
              ),
            ),
          // iOS 26: the icon comes first
          if (item.leading != null)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: IconTheme(
                data: IconThemeData(color: color, size: 22),
                child: DefaultTextStyle(
                  style: TextStyle(color: color),
                  child: item.leading!,
                ),
              ),
            ),
          Expanded(
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.typography.body.copyWith(fontSize: 17, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(s.width * 0.12, s.height * 0.55)
        ..lineTo(s.width * 0.4, s.height * 0.82)
        ..lineTo(s.width * 0.9, s.height * 0.2),
      p,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.color != color;
}

double _smoothStep(double x) {
  final t = x.clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}
