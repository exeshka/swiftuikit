import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'liquid_glass.dart';

/// One action of a [GlassToolbarCapsule]. [id] identifies it across rebuilds: a new id appears, a missing id leaves,
/// a different id in the same place swaps.
class GlassToolbarItem {
  const GlassToolbarItem({
    required this.id,
    required this.child,
    this.onPressed,
  });
  final Object id;
  final Widget child;
  final VoidCallback? onPressed;
}

/// The trailing group of a navigation bar: one interactive glass capsule holding 1..n actions, like the native
/// toolbar. When the actions change the capsule animates:
/// (measured on the native toolbar, frames of a simulator recording at 12.5 fps):
///  * an action appears / leaves: the whole capsule blurs (glass and icons go soft) for ~0.5 s while its width springs to
///    the new size with an overshoot of ~10 %, the icons keep an even spacing inside it and sharpen when it settles
///    (a single action is a 44 pt circle, n >= 2 actions are 52 pt each);
///  * an action is replaced in the same place (an icon swap, `.blurReplace`): the old one blurs and fades out, the new
///    one blurs in and sharpens (the capsule keeps its size).
class GlassToolbarCapsule extends StatefulWidget {
  const GlassToolbarCapsule({
    super.key,
    required this.items,
    this.height = 44,
    this.slotWidth = 52,
    this.presence = 1,
  });

  /// 0..1: the whole capsule scales and fades in / out (drive it with [LiquidGlassPresence]); the layout size is not
  /// changed.
  final double presence;

  final List<GlassToolbarItem> items;
  final double height;
  final double slotWidth;

  @override
  State<GlassToolbarCapsule> createState() => _GlassToolbarCapsuleState();
}

class _Spring {
  _Spring(this.value, this.target);
  double value;
  double target;
  double velocity = 0;

  bool get settled => (value - target).abs() < 0.01 && velocity.abs() < 0.05;

  // semi-implicit Euler: omega = natural frequency (rad/s), zeta = damping ratio
  void step(double dt, double omega, double zeta) {
    final k = omega * omega;
    final c = 2 * zeta * omega;
    velocity += (-k * (value - target) - c * velocity) * dt;
    value += velocity * dt;
  }
}

class _Entry {
  _Entry(this.item, double x, double presence)
    : x = _Spring(x, x),
      presence = _Spring(presence, 1);
  GlassToolbarItem item;
  final _Spring x; // slot center, fraction of the capsule width
  final _Spring presence; // 0 absent .. 1 shown (overshoots a little)
  bool leaving = false;
  double shownX = 0; // last drawn center, pt from the capsule's left edge
  double fromRight = 0; // while leaving: distance of the center from the capsule's right edge (stays put on screen)
  bool replace = false; // swap in place: scale instead of blur
}

class _GlassToolbarCapsuleState extends State<GlassToolbarCapsule>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final List<_Entry> _entries = [];
  late _Spring _width;
  Duration _last = Duration.zero;
  double _blurT = 1; // seconds since the last add / remove; the blur envelope is a half sine over [_blurLen]
  static const _blurLen = 0.4;

  double _widthFor(int n) => n <= 1 ? widget.height : widget.slotWidth * n;
  // slot center as a FRACTION of the capsule width (springs per action, so a change of the count glides instead of jumping)
  double _centerOf(int i, int n) => n <= 1 ? 0.5 : (i + 0.5) / n;

  @override
  void initState() {
    super.initState();
    final n = widget.items.length;
    _width = _Spring(_widthFor(n), _widthFor(n));
    for (var i = 0; i < n; i++) {
      _entries.add(_Entry(widget.items[i], _centerOf(i, n), 1));
    }
  }

  @override
  void didUpdateWidget(GlassToolbarCapsule old) {
    super.didUpdateWidget(old);
    final items = widget.items;
    final n = items.length;
    final byId = {for (final e in _entries) e.item.id: e};
    final next = <_Entry>[];
    final countChanged = old.items.length != n;
    final gone = byId.keys
        .where((id) => !items.any((it) => it.id == id))
        .length;
    final replacing = !countChanged && gone > 0;
    for (var i = 0; i < n; i++) {
      var e = byId.remove(items[i].id);
      if (e == null) {
        // new action: starts hidden at its slot (the slot itself is animated by the neighbours moving away)
        e = _Entry(items[i], _centerOf(i, n), 0)..replace = replacing;
      } else {
        e.item = items[i];
        e.leaving = false;
      }
      e.presence.target = 1;
      e.x.target = _centerOf(i, n);
      next.add(e);
    }
    // missing ones fade out where they are
    for (final e in byId.values) {
      if (!e.leaving) e.fromRight = _width.value - e.shownX;
      e.leaving = true;
      e.replace = replacing;
      e.presence.target = 0;
      next.add(e);
    }
    _entries
      ..clear()
      ..addAll(next);
    _width.target = _widthFor(n);
    if (countChanged) _blurT = 0;
    _kick();
  }

  void _kick() {
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    final steps = (dt / 0.004).ceil().clamp(1, 12);
    final h = dt.clamp(0.0, 0.05) / steps;
    for (var s = 0; s < steps; s++) {
      _width.step(
        h,
        17.5,
        0.47,
      ); // native: peak +~17 % of the travel at ~0.2 s, then settles
      for (final e in _entries) {
        e.x.step(h, 16, 0.8);
        // a swap is slower and without overshoot (native ~0.4 s through a grey blur)
        if (e.replace) {
          e.presence.step(h, 11, 0.95);
        } else if (e.leaving) {
          // a removed action must be gone before the others glide over it (no doubled icons)
          e.presence.step(h, 44, 1.0);
        } else {
          e.presence.step(h, 22, 0.72);
        }
      }
    }
    _blurT += dt.clamp(0.0, 0.05);
    _entries.removeWhere(
      (e) =>
          e.leaving &&
          e.presence.value < 0.01 &&
          e.presence.velocity.abs() < 0.5,
    );
    final settled =
        _blurT >= _blurLen &&
        _width.settled &&
        _entries.every((e) => e.x.settled && e.presence.settled);
    if (settled) {
      _width.value = _width.target;
      for (final e in _entries) {
        e.x.value = e.x.target;
        e.presence.value = e.presence.target;
      }
      _ticker.stop();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.height;
    final w = _width.value;
    final stay = _entries.where((e) => !e.leaving).length;
    // the "hop" of native is the width overshoot (toward the side it grows to); the height only swells a little
    final gh = h * (1 + 0.04 * _blurEnvelope());
    return SizedBox(
      width: w,
      height: h,
      child: OverflowBox(
        minHeight: 0,
        maxHeight: h * 1.3,
        child: LiquidGlass(
          width: w,
          height: gh,
          presence: widget.presence,
          interactive: true,
          // the icons shrink with the plate (it scales by [presence] around its center), blur and fade
          child: _PresenceFx(
            presence: widget.presence,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final e in _entries)
                  Positioned(
                    key: ValueKey(e.item.id),
                    // icons keep an even spacing inside the (overshooting) capsule; a leaving one stays where it was on
                    // screen (measured from the right edge, the capsule shrinks from the left)
                    left: _centerFor(e, w, stay) - widget.slotWidth / 2,
                    width: widget.slotWidth,
                    top: 0,
                    height: gh,
                    child: _item(e),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _centerFor(_Entry e, double w, int stay) {
    final x = e.leaving || stay == 0 ? w - e.fromRight : w * e.x.value;
    return e.shownX = x;
  }

  /// Blur of the whole capsule (native: rises over ~0.08 s, holds ~0.1 s, clears by ~0.4 s).
  double _blurEnvelope() {
    final t = _blurT;
    if (t >= _blurLen) return 0;
    if (t < 0.08) return t / 0.08;
    if (t < 0.18) return 1;
    final u = ((t - 0.18) / (_blurLen - 0.18)).clamp(0.0, 1.0);
    return 1 - u * u * (3 - 2 * u);
  }

  Widget _item(_Entry e) {
    final p = e.presence.value;
    Widget child = Center(child: e.item.child);
    // add / remove: the whole capsule goes soft (half-sine envelope); replace (native `.blurReplace`): the old icon blurs and
    // fades out while the new one blurs in and sharpens
    // native: the blur rises at once, holds ~0.25 s and then clears over ~0.15 s
    final env = _blurEnvelope();
    final blur = e.replace
        ? (1 - p.clamp(0.0, 1.0)) * 6.0
        : env * 7.0 + (1 - p.clamp(0.0, 1.0)) * 3.0;
    if (blur > 0.05) {
      child = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
          tileMode: TileMode.decal,
        ),
        child: child,
      );
    }
    final lo = e.replace ? 0.88 : 0.8;
    child = Opacity(
      // a removed action vanishes almost at once (cubic): its neighbour takes over its slot
      opacity:
          (e.leaving && !e.replace
              ? math.pow(p.clamp(0.0, 1.0), 3).toDouble()
              : p.clamp(0.0, 1.0)) *
          (e.replace ? 1.0 : 1 - 0.5 * env),
      child: Transform.scale(
        scale: lo + (1 - lo) * p.clamp(0.0, 1.3),
        child: child,
      ),
    );
    if (e.leaving || e.item.onPressed == null) {
      return IgnorePointer(child: child);
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: e.item.onPressed,
      child: child,
    );
  }
}

/// Scale + blur + fade of a capsule's content for a [GlassToolbarCapsule.presence] below 1.
class _PresenceFx extends StatelessWidget {
  const _PresenceFx({required this.presence, required this.child});
  final double presence;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = presence.clamp(0.0, 1.0);
    if (p >= 1) return child;
    Widget c = child;
    final blur = (1 - p) * 5;
    if (blur > 0.05) {
      c = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
          tileMode: TileMode.decal,
        ),
        child: c,
      );
    }
    return Opacity(
      opacity: p * p,
      child: Transform.scale(scale: p, child: c),
    );
  }
}
