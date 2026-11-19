import 'dart:ui' show lerpDouble;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

enum ChromeEdge { top, bottom }

class _Anim {
  _Anim(this.value) : _to = value;
  double value;
  double _from = 0;
  double _to;
  Duration? _start;
  Duration _duration = Duration.zero;
  Curve _curve = Curves.easeOutCubic;
  bool active = false;

  double get target => _to;

  void set(
    double v, {
    required bool animate,
    Duration? duration,
    Curve? curve,
  }) {
    if (v == _to && !active) return;
    if (!animate) {
      value = v;
      _to = v;
      active = false;
      return;
    }
    _from = value;
    _to = v;
    _start = null;
    _duration = duration ?? const Duration(milliseconds: 250);
    _curve = curve ?? Curves.easeOutCubic;
    active = true;
  }

  /// Returns true while still animating.
  bool tick(Duration now) {
    if (!active) return false;
    _start ??= now;
    final t = _duration.inMicroseconds == 0
        ? 1.0
        : ((now - _start!).inMicroseconds / _duration.inMicroseconds).clamp(
            0.0,
            1.0,
          );
    if (t >= 1) {
      value = _to;
      active = false;
      return false;
    }
    value = lerpDouble(_from, _to, _curve.transform(t))!;
    return true;
  }
}

/// A registration of one chrome item (bar, footer, sticky header) in a
/// [ChromeController].
///
/// * [height] is how much of the edge the item currently covers. The blur zone
///   is as tall as the sum of all heights (plus the safe area and a fade).
/// * [padding] is how much room the scroll content must leave. Bars have
///   `padding == height`; sticky headers have `padding == 0` because they live
///   inside the scroll content and only grow the blur zone while stuck.
class ChromeInsetEntry {
  ChromeInsetEntry._(
    this._controller,
    this.edge,
    this.label, {
    required double height,
    required double? padding,
    this.minPadding,
    this.sticky = false,
    this.replaceGroup,
  }) : _height = _Anim(height),

       _padding = _Anim(padding ?? height),
       _paddingFollowsHeight = padding == null;

  final ChromeController _controller;
  final ChromeEdge edge;
  final String? label;
  final _Anim _height;
  final _Anim _padding;
  final bool _paddingFollowsHeight;
  bool _released = false;

  /// Extra scroll extent the lists must offer for this item to be able to collapse (a list shorter than the screen could not
  /// scroll away a collapsible section otherwise). Read by `SliverChromeInset.bottom`.
  double scrollSlack = 0;

  /// How far past the collapsible height the scroll runs before the bar counts as collapsed for the snap (a large title keeps
  /// fading out a little after its block is covered; a collapsible section has no such tail).
  double snapExtra = 20;

  /// The scroll offset a scroll position that has just appeared starts at (a bar that starts collapsed), or null.
  double? initialScroll;

  /// Padding left when the item is fully collapsed (large title scrolled away).
  /// null: same as [padding]. The scroll view's pinned inset sliver shrinks to
  /// this, so later sticky headers pin below the collapsed bar.
  double? minPadding;

  /// Sticky entries live inside the scroll content; while stuck they hand a
  /// widget to the scaffold ([setOverlay]) that is painted *above* the blur
  /// zone, at the pin position, so the header stays sharp.
  final bool sticky;

  /// Sticky entries sharing a non-null group replace each other: the blur zone
  /// grows by the tallest one, not by the sum.
  final Object? replaceGroup;
  LayerLink? link;

  /// Returns the header's bottom edge relative to the scaffold, or null if it
  /// cannot be measured (not laid out). Set by the sticky header.
  double? Function(RenderBox scaffold)? measureBottom;
  Widget? overlay;
  double overlayHeight = 0;
  int stickSeq = 0;

  /// Sharp copy of the header, mounted by the scaffold above the blur for as
  /// long as the header exists; it is only *painted* while [stuck].
  void setOverlay(Widget? widget, {double height = 0, LayerLink? link}) {
    if (_released) return;
    overlay = widget;
    overlayHeight = height;
    this.link = link;
    _controller._scheduleNotify();
  }

  /// Painted-state flag, flipped during layout; listeners only repaint (no
  /// rebuild), so the sharp copy appears in the very frame the header sticks.
  final ValueNotifier<bool> stuckNotifier = ValueNotifier<bool>(false);
  bool get stuck => stuckNotifier.value;

  void setStuck(bool v) {
    if (_released || stuckNotifier.value == v) return;
    stickSeq = v ? ++_controller._stickCounter : 0;
    stuckNotifier.value = v;
  }

  double get height => _height.value;
  double get padding => _padding.value;
  double get targetHeight => _height.target;
  double get targetPadding => _padding.target;
  bool get isReleased => _released;

  /// Changes the covered height (and padding unless it was given explicitly at
  /// registration). With [animate] the values ease towards the target using
  /// the frame clock; scroll-driven updates should pass `animate: false`.
  void update({
    double? height,
    double? padding,
    bool animate = false,
    Duration? duration,
    Curve? curve,
  }) {
    if (_released) return;
    if (height != null) {
      _height.set(height, animate: animate, duration: duration, curve: curve);
      if (_paddingFollowsHeight && padding == null) {
        _padding.set(
          height,
          animate: animate,
          duration: duration,
          curve: curve,
        );
      }
    }
    if (padding != null) {
      _padding.set(padding, animate: animate, duration: duration, curve: curve);
    }
    _controller._changed(this);
  }

  /// Removes the registration. With [animate] the item first shrinks to zero.
  void release({bool animate = false, Duration? duration, Curve? curve}) {
    if (_released) return;
    if (animate && (_height.value != 0 || _padding.value != 0)) {
      update(
        height: 0,
        padding: 0,
        animate: true,
        duration: duration,
        curve: curve,
      );
      _controller._removeWhenSettled(this);
    } else {
      _released = true;
      _controller._remove(this);
    }
  }
}

/// Collects the heights of everything that overlays the top and bottom edge of
/// a [ChromeScaffold]. Bars and sticky headers register here; the scaffold
/// reads the sums to size the blur zones and the content padding.
class ChromeController extends ChangeNotifier {
  ChromeController();

  final List<ChromeInsetEntry> _entries = [];
  final List<ChromeInsetEntry> _dying = [];
  int _stickCounter = 0;
  bool _ticking = false;
  bool _notifyScheduled = false;
  bool _disposed = false;

  /// Vertical scroll offset of the scaffold body (fed by the scaffold).
  final ValueNotifier<double> scrollOffset = ValueNotifier<double>(0);

  final Map<Object, double? Function()> _snapRanges = {};

  /// Lets a header that is not a registered inset (a sliver such as `StretchHeader`) take part in the scaffold's settle: when
  /// a scroll comes to rest between 0 and the returned range, the scaffold finishes it to the nearer end (like the large title
  /// does). [range] returns the scroll distance the header collapses over, or null while there is nothing to settle.
  void registerSnapRange(Object owner, double? Function() range) =>
      _snapRanges[owner] = range;

  void unregisterSnapRange(Object owner) => _snapRanges.remove(owner);

  /// The range of the first registered header that has one now (see [registerSnapRange]).
  double? get customSnapRange {
    for (final r in _snapRanges.values) {
      final v = r();
      if (v != null && v > 1) return v;
    }
    return null;
  }

  /// true while a finger drags the scaffold body (false in the ballistic phase after the release; fed by the scaffold).
  final ValueNotifier<bool> userDragging = ValueNotifier<bool>(false);

  /// 0..1 multiplier of the top edge fade/blur: a header that covers the status area (see `StretchHeader`) lowers it so the
  /// fade does not dim its photo.
  final ValueNotifier<double> topEdgeFade = ValueNotifier<double>(1);

  List<ChromeInsetEntry> entries(ChromeEdge edge) => [
    for (final e in _entries)
      if (e.edge == edge) e,
  ];

  ChromeInsetEntry register(
    ChromeEdge edge, {
    required double height,
    double? padding,
    double? minPadding,
    bool sticky = false,
    Object? replaceGroup,
    String? label,
  }) {
    final e = ChromeInsetEntry._(
      this,
      edge,
      label,
      height: height,
      padding: padding,
      minPadding: minPadding,
      sticky: sticky,
      replaceGroup: replaceGroup,
    );
    _entries.add(e);
    _scheduleNotify(defer: true);
    return e;
  }

  /// Current (animated) sum of covered heights on [edge].
  double inset(ChromeEdge edge) => _sumHeights(edge, (e) => e.height);

  /// Current (animated) content padding requested on [edge].
  double padding(ChromeEdge edge) => _sum(edge, (e) => e.padding);

  /// Extra scroll extent requested by collapsible bars (see [ChromeInsetEntry.scrollSlack]).
  double get scrollSlack => _sum(ChromeEdge.top, (e) => e.scrollSlack);

  /// The tail used by the snap of the collapsing bars (see [ChromeInsetEntry.snapExtra]).
  double get snapExtra {
    for (final e in _entries) {
      if (e.edge == ChromeEdge.top &&
          e.padding - (e.minPadding ?? e.padding) > 0)
        return e.snapExtra;
    }
    return 20;
  }

  /// Where a new scroll position starts (see [ChromeInsetEntry.initialScroll]); null: at the top.
  double? get initialScrollOffset {
    double? r;
    for (final e in _entries) {
      if (e.edge == ChromeEdge.top && e.initialScroll != null) {
        r = (r ?? 0) + e.initialScroll!;
      }
    }
    return r;
  }

  /// While a replacing header is pushed out by the next one, its share of the
  /// blur zone leaves with it: [height] follows the part of the header that is
  /// still below the pin [line]. Called after layout, a frame behind the scroll.
  void followPushedHeaders(RenderBox scaffold, double line) {
    for (final e in _entries.toList()) {
      if (e.replaceGroup == null || !e.stuck || e.measureBottom == null)
        continue;
      if (e._height.active) continue; // easing in, do not fight the animation
      final bottom = e.measureBottom!(scaffold);
      if (bottom == null) continue;
      final visible = (bottom - line).clamp(0.0, e.overlayHeight);
      if ((visible - e.height).abs() > 0.25) e.update(height: visible);
    }
  }

  /// Every mounted sticky overlay (painted only while stuck).
  List<ChromeInsetEntry> overlayEntries() => [
    for (final e in _entries)
      if (e.overlay != null) e,
  ];

  /// Height of the non-sticky items (bars): where the first stuck header pins.
  double fixedInset(ChromeEdge edge) {
    var s = 0.0;
    for (final e in _entries) {
      if (e.edge == edge && !e.sticky) s += e.height;
    }
    return s;
  }

  /// Stuck headers' overlays in the order they stuck.
  List<ChromeInsetEntry> stuckOverlays() {
    final l = [
      for (final e in _entries)
        if (e.overlay != null && e.stuck) e,
    ]..sort((a, b) => a.stickSeq.compareTo(b.stickSeq));
    return l;
  }

  /// Content padding when every collapsible item is fully collapsed.
  double minPadding(ChromeEdge edge) => _sum(
    edge,
    (e) =>
        e.minPadding != null ? e.minPadding!.clamp(0.0, e.padding) : e.padding,
  );

  /// Sum of the targets, i.e. where the animation is heading.
  double targetInset(ChromeEdge edge) =>
      _sumHeights(edge, (e) => e.targetHeight);

  double _sumHeights(ChromeEdge edge, double Function(ChromeInsetEntry) f) {
    var s = 0.0;
    final groups = <Object, double>{};
    for (final e in _entries) {
      if (e.edge != edge) continue;
      final g = e.replaceGroup;
      if (g == null) {
        s += f(e);
      } else {
        final v = f(e);
        if (v > (groups[g] ?? 0)) groups[g] = v;
      }
    }
    for (final v in groups.values) {
      s += v;
    }
    return s;
  }

  double _sum(ChromeEdge edge, double Function(ChromeInsetEntry) f) {
    var s = 0.0;
    for (final e in _entries) {
      if (e.edge == edge) s += f(e);
    }
    return s;
  }

  void _changed(ChromeInsetEntry e) {
    if (e._height.active || e._padding.active) _startTicking();
    _scheduleNotify();
  }

  void _remove(ChromeInsetEntry e) {
    _entries.remove(e);
    _dying.remove(e);
    _scheduleNotify();
  }

  void _removeWhenSettled(ChromeInsetEntry e) {
    if (!_dying.contains(e)) _dying.add(e);
  }

  void _startTicking() {
    if (_ticking || _disposed) return;
    _ticking = true;
    SchedulerBinding.instance.scheduleFrameCallback(_tick);
  }

  void _tick(Duration now) {
    if (_disposed) return;
    var any = false;
    for (final e in _entries.toList()) {
      final a = e._height.tick(now);
      final b = e._padding.tick(now);
      any = any || a || b;
    }
    for (final e in _dying.toList()) {
      if (!e._height.active && !e._padding.active) {
        e._released = true;
        _entries.remove(e);
        _dying.remove(e);
      }
    }
    _ticking = false;
    notifyListeners();
    if (any) _startTicking();
  }

  // Registrations happen during build/layout where listeners must not be
  // notified synchronously: defer to the end of the frame in that case.
  void _scheduleNotify({bool defer = false}) {
    if (_disposed) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    // `defer`: registrations may come from the very first mount (runApp builds outside a frame, phase idle), where
    // a synchronous notification marks a ListenableBuilder dirty in the middle of the build.
    if (defer || phase == SchedulerPhase.persistentCallbacks) {
      if (_notifyScheduled) return;
      _notifyScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _notifyScheduled = false;
        if (!_disposed) notifyListeners();
      });
      SchedulerBinding.instance.ensureVisualUpdate();
    } else {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    scrollOffset.dispose();
    userDragging.dispose();
    topEdgeFade.dispose();
    super.dispose();
  }
}

/// Resolved insets handed to the scaffold body.
@immutable
class ChromeInsetsData {
  const ChromeInsetsData({
    required this.top,
    required this.bottom,
    required this.topZone,
    required this.bottomZone,
    required this.topMin,
    this.scrollSlack = 0,
  });

  /// Top padding when collapsible bars are fully collapsed.
  final double topMin;

  /// Extra scroll extent a list must offer so that the collapsible bars can collapse.
  final double scrollSlack;

  /// Content padding to leave at the top / bottom (safe area + chrome).
  final double top;
  final double bottom;

  /// Height of the blur zones.
  final double topZone;
  final double bottomZone;

  EdgeInsets get padding => EdgeInsets.only(top: top, bottom: bottom);

  @override
  bool operator ==(Object other) =>
      other is ChromeInsetsData &&
      other.top == top &&
      other.bottom == bottom &&
      other.topMin == topMin &&
      other.scrollSlack == scrollSlack &&
      other.topZone == topZone &&
      other.bottomZone == bottomZone;

  @override
  int get hashCode => Object.hash(top, bottom, topZone, bottomZone, topMin);
}
