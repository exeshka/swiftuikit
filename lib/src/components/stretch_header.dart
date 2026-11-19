import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/physics.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter/widgets.dart';

import '../chrome/chrome_controller.dart';
import '../chrome/chrome_scaffold.dart';
import '../theme/swift_ui_theme.dart';

/// What a [StretchHeader] builder is told about the header's state.
@immutable
class StretchInfo {
  const StretchInfo({
    required this.t,
    required this.stretch,
    required this.height,
    required this.width,
    required this.topInset,
    required this.pull,
    required this.expanded,
    required this.collapse,
    required this.compactHeight,
    required this.overpull,
  });

  /// 0 at rest .. 1 fully expanded. In [StretchHeaderMode.snap] it follows the snap animation, NOT the finger: it stays 0
  /// while the list is pulled and runs 0 -> 1 in a quick spring once the pull passes the trigger (and 1 -> 0 on the way back),
  /// like Telegram's profile. In [StretchHeaderMode.follow] it follows the finger. Drive every morph with it ([MorphBox],
  /// opacities, positions).
  final double t;

  /// 0..1: how far the pull is towards the trigger ([StretchHeader.triggerDistance]). Use it for what grows while the finger
  /// pulls and before the header opens: the avatar circle gets bigger, it stays a circle.
  final double stretch;

  /// Current height of the header's paint area, from the top edge of the screen (rest height + the pull of a finger).
  final double height;
  final double width;

  /// Status bar + bars the [ChromeScaffold] reserves on top: where the header's own content must not start.
  final double topInset;

  /// How far the finger has pulled the list past its top (>= 0).
  final double pull;

  /// 0 at rest .. 1 when the list has scrolled the header down to its compact height (the bar row with a small title).
  final double collapse;

  /// Height of the compact (scrolled) state, from the top edge of the screen.
  final double compactHeight;

  /// The second stage: 0..1, how far an OPEN header has been pulled towards [StretchHeader.overpullDistance] (what opens
  /// another page). 0 while the header is not open.
  final double overpull;

  /// true once the header has snapped open (`StretchHeaderMode.snap`) and stays so until the list scrolls up.
  final bool expanded;
}

typedef StretchBuilder = Widget Function(
  BuildContext context,
  StretchInfo info,
);

/// How the header answers a pull.
enum StretchHeaderMode {
  /// A pull past [StretchHeader.triggerDistance] and a release snaps the header open (what Telegram's settings page does); it
  /// stays open, pushes the list down, and closes when the list is scrolled up.
  snap,

  /// The header only follows the finger and springs back (a stretchy header).
  follow,
}

/// A header at the top of a scroll view that grows when the list is pulled down: its content morphs (an avatar into a
/// full-bleed photo, a title from the centre to a corner) through [builder] and [MorphBox]. With [StretchHeaderMode.snap] a long
/// enough pull opens it fully and it STAYS open, displacing the list below; scrolling the list up closes it again.
///
/// It is a pinned sliver: scrolling the list up shrinks it from [collapsedHeight] to [compactHeight] (the bar row, where a
/// small title stays, see [StretchInfo.collapse]) and it stays there while the list scrolls under it. Use it as the first
/// sliver of a scroll view inside a [ChromeScaffold]:
///
/// ```dart
/// CustomScrollView(
///   physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
///   slivers: [
///     StretchHeader(collapsedHeight: 270, expandedHeight: 470, builder: (context, info) => ...),
///     // the rest of the list
///   ],
/// )
/// ```
///
/// The header starts at the top edge of the screen (a [CustomScrollView] does not apply the scaffold's top padding), so
/// [collapsedHeight] / [expandedHeight] count from there and [StretchInfo.topInset] says where the bars end. The top edge fade
/// of the scaffold is off while the header is there ([hideEdgeFade]); the header paints its own background and its own
/// soft edge under its lower border ([backgroundColor], [edgeFadeHeight]).
class StretchHeader extends StatefulWidget {
  const StretchHeader({
    super.key,
    required this.builder,
    required this.collapsedHeight,
    required this.expandedHeight,
    this.mode = StretchHeaderMode.snap,
    this.compactHeight,
    this.hideEdgeFade = true,
    this.backgroundColor,
    this.edgeFadeHeight,
    this.fadeOpacity = 0.78,
    this.triggerDistance = 70,
    this.overpullDistance = 90,
    this.onOverpull,
    this.overpullOnRelease = false,
    this.collapseAt = 24,
    this.haptics = true,
    this.onExpandedChanged,
  }) : assert(expandedHeight > collapsedHeight);

  final StretchBuilder builder;

  /// Height at rest, from the top edge of the screen.
  final double collapsedHeight;

  /// Height when snapped open, from the top edge of the screen.
  final double expandedHeight;
  final StretchHeaderMode mode;

  /// Height of the pinned compact state, from the top edge of the screen: what is left when the list scrolls the header
  /// away. Default: the status bar plus the bars of the [ChromeScaffold] ([StretchInfo.topInset]).
  final double? compactHeight;

  /// The scaffold's top edge fade is off while this header is there (default): the header is pinned and draws its own
  /// background, and the fade would dim its compact title.
  final bool hideEdgeFade;

  /// The header is one opaque construction (the bar buttons above it belong to it): this is its background, painted behind
  /// what [builder] draws. Default: the page background ([SwiftUiThemeData.background]).
  final Color? backgroundColor;

  /// Height of the soft edge UNDER the header's lower border, where the list that scrolls under the pinned header fades out
  /// (instead of a gradient lying over the header itself). Its opacity follows [StretchInfo.collapse]: nothing scrolls under
  /// the header at rest. Default: [SwiftUiThemeData.chromeBlurExtra], the length of the scaffold's own fade. 0 turns it off.
  final double? edgeFadeHeight;

  /// Peak opacity of the fade over the list inside the header's own area when it is compact (0..1): below 1 the rows stay
  /// faintly visible under the bar buttons and the title, like under the scaffold's own bars. 0: no fade.
  final double fadeOpacity;

  /// Pull (pt) that a release must have passed to snap the header open.
  final double triggerDistance;

  /// Second stage, in the open state: a pull (a NEW drag, after the one that opened the header) that passes this distance (the scroll
  /// offset, pt) calls [onOverpull], e.g. to open the full profile or the photo viewer (what Telegram does). The header gives a tap
  /// when the pull crosses it and [StretchInfo.overpull] says how far it is.
  final double overpullDistance;

  /// Called when an open header was pulled past [overpullDistance] and released. Not called when null.
  final VoidCallback? onOverpull;

  /// false (default): [onOverpull] fires the moment the pull reaches [overpullDistance], the finger still down. true: only when
  /// the finger is lifted after passing it.
  final bool overpullOnRelease;

  /// Scroll offset (pt) past which an open header closes again.
  final double collapseAt;

  /// A light tap when the pull crosses [triggerDistance].
  final bool haptics;
  final ValueChanged<bool>? onExpandedChanged;

  @override
  State<StretchHeader> createState() => _StretchHeaderState();
}

class _StretchHeaderState extends State<StretchHeader>
    with SingleTickerProviderStateMixin {
  // zeta ~0.8: opens with at most a faint overshoot
  static const _spring = SpringDescription(
    mass: 1,
    stiffness: 240,
    damping: 25,
  );

  late final AnimationController _p = AnimationController(vsync: this);
  ChromeController? _ctl;
  bool _expanded = false;
  bool _overArmed = false;
  bool _overCrossed = false;
  double _peakOver = 0;
  double _overBase = 0; // the pull already made when the second stage was armed in the middle of a drag
  double _compactNow = 0;
  double _peak = 0; // the deepest pull of the current drag: the rubber band already shrinks it when the finger lifts

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = ChromeScaffoldScope.controllerOf(context);
    if (c != _ctl) {
      _detach();
      _ctl = c;
      c.scrollOffset.addListener(_onOffset);
      c.userDragging.addListener(_onDrag);
      _p.addListener(_syncFade);
      // the scaffold settles a scroll that comes to rest inside the collapse range to the nearer end
      c.registerSnapRange(this, () => _expanded ? null : _extent - _compactNow);
      // the scaffold's top fade must be switched off from the very start, not only after the first scroll or animation tick
      // (it is a ValueNotifier of the scaffold: it cannot be set while the tree is building, hence after the frame)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncFade();
      });
    }
  }

  void _detach() {
    final c = _ctl;
    if (c == null) return;
    c.scrollOffset.removeListener(_onOffset);
    c.userDragging.removeListener(_onDrag);
    _p.removeListener(_syncFade);
    c.unregisterSnapRange(this);
    c.topEdgeFade.value = 1;
  }

  @override
  void dispose() {
    _detach();
    _p.dispose();
    super.dispose();
  }

  double get _offset => _ctl?.scrollOffset.value ?? 0;
  double get _extent =>
      lerpDouble(widget.collapsedHeight, widget.expandedHeight, _p.value)!;
  double _t(double height) =>
      ((height - widget.collapsedHeight) /
              (widget.expandedHeight - widget.collapsedHeight))
          .clamp(0.0, 1.0);

  void _syncFade() {
    final c = _ctl;
    if (c == null) return;
    final v = widget.hideEdgeFade
        ? 0.0
        : 1 - _t(_extent + math.max(0.0, -_offset));
    if ((c.topEdgeFade.value - v).abs() > 0.004) c.topEdgeFade.value = v;
  }

  void _onOffset() {
    final o = _offset;
    if (widget.mode == StretchHeaderMode.snap) {
      if (_overArmed && _ctl!.userDragging.value) {
        final over = -o - _overBase;
        _peakOver = math.max(_peakOver, over);
        if (over >= widget.overpullDistance && !_overCrossed) {
          _overCrossed = true;
          if (widget.haptics) HapticFeedback.mediumImpact();
          if (!widget.overpullOnRelease) {
            _overArmed = false; // once per drag
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) widget.onOverpull?.call();
            });
          }
        } else if (over < widget.overpullDistance * 0.85) {
          _overCrossed = false;
        }
      }
      if (_ctl!.userDragging.value) _peak = math.max(_peak, -o);
      // the pull passed the trigger with the finger still down: the header finishes opening on its own (a quick spring), with a tap
      if (_ctl!.userDragging.value &&
          !_expanded &&
          o <= -widget.triggerDistance) {
        if (widget.haptics) HapticFeedback.lightImpact();
        _setExpanded(true);
        // the same finger keeps pulling: the second stage starts from here, no need to lift it and pull again
        _overArmed = true;
        _overBase = -o;
        _peakOver = 0;
        _overCrossed = false;
      }
      if (_expanded && o > widget.collapseAt) _setExpanded(false);
    }
    _syncFade();
  }

  void _onDrag() {
    if (widget.mode != StretchHeaderMode.snap) return;
    final dragging = _ctl!.userDragging.value;
    if (dragging) {
      // a new drag: the second stage is armed only if the header was already open when this finger came down
      _overArmed = _expanded;
      _overBase = 0;
      _peakOver = 0;
      _overCrossed = false;
    } else {
      if (_overArmed && _expanded && _peakOver >= widget.overpullDistance) {
        // not here: this runs inside the scroll notification, i.e. while the viewport lays out, and pushing a route (the
        // usual job of this callback) from there leaves the new page laid out with the wrong constraints
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onOverpull?.call();
        });
      }
      _overArmed = false;
      _peakOver = 0;
      _overCrossed = false;
    }
    if (!dragging && !_expanded && _peak >= widget.triggerDistance) {
      _setExpanded(true);
    }
    if (!dragging || _expanded) _peak = 0;
  }

  void _setExpanded(bool v) {
    if (_expanded == v) return;
    _expanded = v;
    _p.animateWith(SpringSimulation(_spring, _p.value, v ? 1 : 0, 0));
    final cb = widget.onExpandedChanged;
    if (cb != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) cb(v);
      });
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final top = ChromeScaffoldScope.insetsOf(context).top;
    final compact = math.min(
      widget.compactHeight ?? top,
      widget.collapsedHeight,
    );
    _compactNow =
        compact; // read by the scaffold's settle (see registerSnapRange)
    return AnimatedBuilder(
      animation: _p,
      builder: (context, _) {
        final maxH = _extent;
        return SliverPersistentHeader(
          pinned: true,
          delegate: _StretchDelegate(
            maxH: maxH,
            minH: math.min(compact, maxH),
            builder: (context, shrink) => LayoutBuilder(
              builder: (context, c) => ValueListenableBuilder<double>(
                valueListenable: _ctl!.scrollOffset,
                builder: (context, offset, _) {
                  final pull = math.max(0.0, -offset);
                  final h = c.maxHeight + pull;
                  final range = maxH - math.min(compact, maxH);
                  final snap = widget.mode == StretchHeaderMode.snap;
                  final info = StretchInfo(
                    t: snap ? _p.value : _t(h),
                    stretch: snap
                        ? (pull / widget.triggerDistance).clamp(0.0, 1.0)
                        : _t(h),
                    height: h,
                    width: c.maxWidth,
                    topInset: top,
                    pull: pull,
                    expanded: _expanded,
                    collapse: range > 0 ? (shrink / range).clamp(0.0, 1.0) : 0,
                    compactHeight: compact,
                    overpull: _expanded
                        ? (pull / widget.overpullDistance).clamp(0.0, 1.0)
                        : 0,
                  );
                  final tokens = SwiftUiTheme.of(context);
                  final bg = widget.backgroundColor ?? tokens.colors.background;
                  final edgeH =
                      widget.edgeFadeHeight ?? tokens.chrome.blurExtra;
                  final col = info.collapse;
                  final hold = h / (h + edgeH);
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Layers, bottom to top, like the scaffold's own bars: the page background of the header (opaque at
                      // rest, it dissolves as the header compacts so the list shows through) -> the fade over the list
                      // (the whole header area plus the soft edge under it) -> what the builder draws. A pinned sliver stays
                      // at the top of the screen while the list is pulled down, so the header just grows downwards by the pull.
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        height: h,
                        child: ColoredBox(
                          color: bg.withValues(alpha: bg.a * (1 - col)),
                        ),
                      ),
                      if (col > 0 && widget.fadeOpacity > 0)
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          height: h + edgeH,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: _fadeColors(
                                    bg,
                                    col * widget.fadeOpacity,
                                  ),
                                  stops: _fadeStops(hold),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        height: h,
                        child: widget.builder(context, info),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

// The fade under the header: [peak] opacity over the header's own area (the first `hold` of the height) and an eased
// (smoothstep) fall to nothing over the soft edge below it: no visible start line under the header's border.
const _fadeSteps = 8;
List<double> _fadeStops(double hold) => [
  0.0,
  hold,
  for (var i = 1; i <= _fadeSteps; i++) hold + (1 - hold) * i / _fadeSteps,
];
List<Color> _fadeColors(Color bg, double peak) => [
  bg.withValues(alpha: bg.a * peak),
  bg.withValues(alpha: bg.a * peak),
  for (var i = 1; i <= _fadeSteps; i++)
    bg.withValues(
      alpha:
          bg.a *
          peak *
          (1 - (i / _fadeSteps) * (i / _fadeSteps) * (3 - 2 * i / _fadeSteps)),
    ),
];

class _StretchDelegate extends SliverPersistentHeaderDelegate {
  _StretchDelegate({
    required this.maxH,
    required this.minH,
    required this.builder,
  });

  final double maxH;
  final double minH;
  final Widget Function(BuildContext context, double shrink) builder;

  @override
  double get maxExtent => maxH;

  @override
  double get minExtent => minH;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => builder(context, shrinkOffset);

  @override
  bool shouldRebuild(_StretchDelegate old) => true;
}

/// Places [child] in a [Rect] that morphs from [from] to [to] with [t] (0..1), with a corner radius that morphs too: an avatar
/// circle becoming a full-bleed photo. Put it in the [Stack] that a [StretchHeader] builder returns. The default curve is
/// linear: the box then grows as fast as the header does (an eased curve leaves a gap between the box and the list).
class MorphBox extends StatelessWidget {
  const MorphBox({
    super.key,
    required this.from,
    required this.to,
    required this.t,
    required this.child,
    this.fromRadius = 0,
    this.toRadius = 0,
    this.curve = Curves.linear,
  });

  final Rect from;
  final Rect to;
  final double t;
  final double fromRadius;
  final double toRadius;
  final Curve curve;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final e = curve.transform(t.clamp(0.0, 1.0));
    return Positioned.fromRect(
      rect: Rect.lerp(from, to, e)!,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          lerpDouble(fromRadius, toRadius, e)!,
        ),
        child: child,
      ),
    );
  }
}
