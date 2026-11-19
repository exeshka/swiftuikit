import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../blur/progressive_blur.dart';
import 'chrome_style.dart';
import '../components/liquid_glass.dart';
import '../theme/swift_ui_theme.dart';
import '../scaffold/swift_ui_shell.dart' show SwiftUiShellScope;
import '../util/route_freeze.dart';
import '../util/size_reporter.dart';
import 'chrome_controller.dart';

class _ChromeScope extends InheritedWidget {
  const _ChromeScope({required this.controller, required super.child});
  final ChromeController controller;
  @override
  bool updateShouldNotify(_ChromeScope old) => old.controller != controller;
}

class _ChromeInsetsScope extends InheritedWidget {
  const _ChromeInsetsScope({required this.data, required super.child});
  final ChromeInsetsData data;
  @override
  bool updateShouldNotify(_ChromeInsetsScope old) => old.data != data;
}

/// Static accessors for the nearest [ChromeScaffold].
class ChromeScaffoldScope {
  const ChromeScaffoldScope._();

  /// The controller of the enclosing [ChromeScaffold] (does not listen).
  static ChromeController controllerOf(BuildContext context) {
    final s = context.getInheritedWidgetOfExactType<_ChromeScope>();
    assert(s != null, 'No ChromeScaffold found in context');
    return s!.controller;
  }

  static ChromeController? maybeControllerOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_ChromeScope>()?.controller;

  /// Resolved insets; rebuilds the caller whenever they change.
  static ChromeInsetsData insetsOf(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<_ChromeInsetsScope>();
    assert(s != null, 'No ChromeScaffold found in context');
    return s!.data;
  }
}

/// Scaffold whose top and bottom edges are blur zones driven by the heights
/// that bars and sticky headers register in its [ChromeController].
///
/// Layers, bottom to top: [body] (scrolls under the zones) → progressive blur
/// top/bottom → [topBar] / [bottomBar] (sharp). The body receives the resolved
/// content padding through `MediaQuery.padding` (so `ListView` pads itself) and
/// through [ChromeScaffoldScope.insetsOf].
class ChromeScaffold extends StatefulWidget {
  const ChromeScaffold({
    super.key,
    required this.body,
    this.topBar,
    this.bottomBar,
    this.controller,
    this.backgroundColor,
    this.overlay,
    this.topChrome,
    this.bottomChrome,
    this.bottomBlur = true,
    this.bottomBarSafeAreaShare,
    this.minTopInset = 12,
    this.freezeUnderRoute = false,
    this.snapLargeTitle = true,
    this.blockZoneTouches = false,
    this.scrollDepth = 0,
  });

  final Widget body;

  /// How content leaves under the top / bottom bars (see [ChromeStyle]). Null: the one of the surrounding
  /// [ChromeStyleScope], else [ChromeStyle.soft]. Native iOS 26 knows two ("soft" and "hard"); a style can also be a plain
  /// container or any widget ([ChromeStyle.custom]).
  final ChromeStyle? topChrome;
  final ChromeStyle? bottomChrome;

  /// false: no blur zone at the bottom edge (the content scrolls under the bottom bar / home indicator unblurred).
  final bool bottomBlur;

  /// 0..1: the share of the bottom safe area (the home indicator, 34 pt on a modern iPhone) kept below [bottomBar]. 1 lifts
  /// the bar by the whole inset, 0 presses it to the very edge. Null: [SwiftUiChromeTheme.bottomBarSafeAreaShare] (0.3: the bar sits about 10 pt above the edge). Without a
  /// bottom bar the content keeps the whole inset.
  final double? bottomBarSafeAreaShare;

  /// The least space (pt) above the top bar. A screen under the status bar already has more (the system inset wins); a sheet or
  /// a dialog without a safe area has none, and the bar would sit against its edge: this keeps a little air there.
  final double minTopInset;

  /// true: while another route moves over this page it is drawn as a snapshot (see [FreezeUnderRoute]): cheaper for the GPU
  /// during the transition, but the page does not update under it. Default false: the page stays live.
  final bool freezeUnderRoute;

  /// Native large-title behaviour: when a scroll ends while the large title (or a [CollapsibleBar] section) is half collapsed,
  /// the content settles to fully open or fully collapsed, whichever is nearer.
  final bool snapLargeTitle;

  /// true: the blur zones swallow touches, so content that is under a zone (blurred, half hidden behind a bar) cannot be
  /// pressed through it. The bars and stuck headers above the zones stay interactive. A scroll that starts in a zone does
  /// not move the list either. false (default): touches pass through the zones to the content beneath.
  final bool blockZoneTouches;

  /// How many scrollables sit between the body and the vertical list that drives the bars: 0 for a plain list, 1 when the
  /// body is a horizontal pager of lists (`PageView`).
  final int scrollDepth;

  /// Placed under the status bar. Wrap in [ChromeBar] (or a widget that
  /// registers itself, like `LargeTitleHeader`) so the scaffold learns its
  /// height.
  final Widget? topBar;
  final Widget? bottomBar;
  final ChromeController? controller;
  final Color? backgroundColor;

  /// Extra widget above everything (e.g. a drawer shade).
  final Widget? overlay;

  @override
  State<ChromeScaffold> createState() => _ChromeScaffoldState();
}

class _ChromeScaffoldState extends State<ChromeScaffold> {
  ChromeController? _own;
  ChromeController get _controller =>
      widget.controller ?? (_own ??= ChromeController());

  @override
  void didUpdateWidget(ChromeScaffold old) {
    super.didUpdateWidget(old);
  }

  @override
  void dispose() {
    _settleLock?.cancel();
    _watching.forEach((pos, l) {
      try {
        pos.isScrollingNotifier.removeListener(l);
      } catch (_) {}
    });
    _watching.clear();
    _own?.dispose();
    super.dispose();
  }

  final _stackKey = GlobalKey();
  bool _followScheduled = false;

  // The position the user is dragging (or last dragged): only its end settles the half-collapsed bars. Positions moved by the
  // app (pages of a pager kept in step with each other, the collapsed start) must not start a snap of their own.
  ScrollPosition? _userPosition;

  // Scroll positions that already got their starting offset (or were touched by the user): the collapsed start of a bar.
  final _startDone = Expando<bool>();
  bool _firstStart = true;

  ScrollPosition? _positionOf(BuildContext? ctx) {
    if (ctx == null) return null;
    final state = ctx is StatefulElement && ctx.state is ScrollableState
        ? ctx.state as ScrollableState
        : Scrollable.maybeOf(ctx);
    return state?.position;
  }

  /// Puts a scroll position that has just appeared where the collapsible bars start (collapsed), and keeps trying while the
  /// insets are still being registered; the first user touch ends it.
  void _startOffset(BuildContext? ctx) {
    final initial = _controller.initialScrollOffset;
    if (initial == null) return;
    final pos = _positionOf(ctx);
    if (pos == null || _startDone[pos] == true) return;
    // the first list starts collapsed; the ones that come later (pages) follow the state the bars are in
    final target = _firstStart
        ? initial
        : _controller.scrollOffset.value.clamp(0.0, initial);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _startDone[pos] == true || !pos.hasPixels) return;
      // keep it there while the layout is still settling (insets register, the list gets its scroll room); only the user's
      // first touch ends it
      if ((pos.pixels - target).abs() > 0.5 &&
          pos.maxScrollExtent >= target - 0.5) {
        pos.jumpTo(target);
        _firstStart = false;
      }
    });
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth == widget.scrollDepth && n.metrics.axis == Axis.vertical) {
      if (n is ScrollStartNotification && n.dragDetails != null) {
        final pos = _positionOf(n.context);
        if (pos != null) {
          _startDone[pos] = true; // the user took over
          _userPosition = pos;
        }
      }
      if (n is ScrollStartNotification) {
        _controller.userDragging.value = n.dragDetails != null;
        if (n.dragDetails != null) _trackStart(n.metrics.pixels);
      } else if (n is ScrollUpdateNotification) {
        _controller.userDragging.value = n.dragDetails != null;
        if (n.dragDetails != null) _track(n.metrics.pixels);
      } else if (n is ScrollEndNotification) {
        _controller.userDragging.value = false;
      }
      // the finger has just left the screen: decide at once where the fling is going to end and settle there (not after it
      // has come to rest)
      if (_wasDragging &&
          widget.snapLargeTitle &&
          ((n is ScrollUpdateNotification && n.dragDetails == null) ||
              n is ScrollEndNotification)) {
        _wasDragging = false;
        _onLift(n);
      }
      if (n is ScrollUpdateNotification || n is ScrollEndNotification) {
        _controller.scrollOffset.value = n.metrics.pixels;
        _scheduleFollow();
      }
      // the settle itself is driven by the position's isScrollingNotifier (see _watch), like CupertinoSliverNavigationBar does
      if (widget.snapLargeTitle && n is ScrollStartNotification) {
        final pos = _positionFrom(n.context);
        if (pos != null) _watch(pos);
      }
      // a backup of the listener above: the end of a scroll asks for a settle too (a settle already running ignores it)
      if (widget.snapLargeTitle && n is ScrollEndNotification) {
        final pos = _positionFrom(n.context);
        if (pos != null) _onScrollingChanged(pos);
      }
    }
    return false;
  }

  ScrollPosition? _positionFrom(BuildContext? ctx) {
    if (ctx == null) return null;
    // the notification's context is the Scrollable itself (maybeOf only looks at its ancestors)
    final state = ctx is StatefulElement && ctx.state is ScrollableState
        ? ctx.state as ScrollableState
        : Scrollable.maybeOf(ctx);
    return state?.position;
  }

  /// The scroll distance the half-collapsed bars settle over: the registered bars (large title, collapsible bar) or else a
  /// sliver header that reports its own range. 0 when there is nothing to settle.
  double get _settleRange {
    final c = _controller;
    // the large title is gone and the small one has faded in ~20 pt after the content has covered the title block
    final collapsible =
        c.padding(ChromeEdge.top) - c.minPadding(ChromeEdge.top);
    final double? own = collapsible > 1 ? collapsible + c.snapExtra : null;
    return own ?? c.customSnapRange ?? 0.0;
  }

  // ---- the finger leaves the screen -------------------------------------------------------------------------------------
  // The velocity of the drag is measured here (the scroll position's own one is not public), the landing point of the fling is
  // asked from the view's own physics (so it is the real one, bouncing or clamping), and when it falls inside the settle range
  // the position is animated to the end the user was heading to, straight away.
  VelocityTracker _vt = VelocityTracker.withKind(PointerDeviceKind.touch);
  final _clock = Stopwatch()..start();
  bool _wasDragging = false;

  void _trackStart(double pixels) {
    _vt = VelocityTracker.withKind(PointerDeviceKind.touch);
    _wasDragging = true;
    _track(pixels);
  }

  void _track(double pixels) =>
      _vt.addPosition(_clock.elapsed, Offset(0, pixels));

  void _onLift(ScrollNotification n) {
    final pos0 = _positionOf(n.context);
    if (pos0 != null && _userPosition != null && pos0 != _userPosition) return;
    final position = _positionFrom(n.context);
    final range = _settleRange;
    if (position == null || range <= 1 || !position.hasPixels) return;
    final p = position.pixels;
    if (p <= 0.5 || p >= range - 0.5) return;
    // scroll pixels per second: positive = the content moves up (towards the collapsed state)
    final v = _vt.getVelocity().pixelsPerSecond.dy;
    final sim = position.physics.createBallisticSimulation(position, v);
    final end = sim == null ? p : sim.x(5.0);
    // the fling carries past the settle range (or back to the top): it needs no help, let it run
    if (end >= range - 0.5 || end <= 0.5) return;
    // it would stop inside the range: a real fling goes the way it was thrown, a gentle one to the nearer end
    final target = v.abs() > 250
        ? (v > 0 ? range : 0.0)
        : (end < range / 2 ? 0.0 : range);
    _settling = true; // the position's own idle (see _watch) must not start a second settle
    _unlockSettle();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !position.hasPixels) {
        _settling = false;
        return;
      }
      position
          .animateTo(
            target,
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastEaseInToSlowEaseOut,
          )
          .whenComplete(() => _settling = false);
    });
  }

  // The settle of the half-collapsed bars follows what CupertinoSliverNavigationBar does: it listens to the scroll position's
  // `isScrollingNotifier` and, as soon as the position goes idle (a drag that ends in place, a fling that has run out, an
  // animation), animates to the nearer end of the range. No timers and no dependence on the end notification, which
  // came late or not at all for some inputs. (Our own addition is _onLift: a fling that would stop inside the range is settled
  // from the moment the finger leaves.)
  final _watching = <ScrollPosition, VoidCallback>{};
  // our own settle animation is running: its end must not start another one
  bool _settling = false;

  // The flag is also released by a timer: if the animation's future never completed (the app went to the background in the
  // middle of it, say) the settle would otherwise stay locked for good and the header would hang half collapsed.
  Timer? _settleLock;
  void _unlockSettle() {
    _settleLock?.cancel();
    _settleLock = Timer(
      const Duration(milliseconds: 600),
      () => _settling = false,
    );
  }

  void _watch(ScrollPosition pos) {
    if (_watching.containsKey(pos)) return;
    void listener() => _onScrollingChanged(pos);
    pos.isScrollingNotifier.addListener(listener);
    _watching[pos] = listener;
  }

  void _onScrollingChanged(ScrollPosition pos) {
    // an idle position cannot be dragged: no need to ask whether the finger is down (that flag could be stale)
    if (!mounted || pos.isScrollingNotifier.value || _settling) return;
    if (_userPosition != null && pos != _userPosition) return;
    _settleLater(pos);
  }

  void _settleLater(ScrollPosition position) {
    final range = _settleRange;
    if (range <= 1 || !position.hasPixels) return;
    final px = position.pixels;
    if (px <= 0.5 || px >= range - 0.5) return;
    // after the notification has been dispatched: the position goes idle right after it and would cancel the animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !position.hasPixels || _settling) return;
      final p = position.pixels;
      if (p <= 0.5 || p >= range - 0.5) return;
      _settling = true;
      _unlockSettle();
      position
          .animateTo(
            p < range / 2 ? 0.0 : range,
            // the same as CupertinoSliverNavigationBar's snap (eyeballed there on an iPhone)
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastEaseInToSlowEaseOut,
          )
          .whenComplete(() => _settling = false);
    });
  }

  // After the frame is laid out, let pushed-out sticky headers take their part
  // of the blur zone with them.
  void _scheduleFollow() {
    if (_followScheduled) return;
    _followScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _followScheduled = false;
      if (!mounted) return;
      final box = _stackKey.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return;
      final c = _controller;
      final line =
          math.max(MediaQuery.of(context).padding.top, widget.minTopInset) +
          c.fixedInset(ChromeEdge.top);
      c.followPushedHeaders(box, line);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = SwiftUiTheme.of(context);
    final mq = MediaQuery.of(context);
    final controller = _controller;
    return _ChromeScope(
      controller: controller,
      child: FreezeUnderRoute(
        enabled: widget.freezeUnderRoute,
        child: ColoredBox(
          color: widget.backgroundColor ?? tokens.colors.background,
          child: ListenableBuilder(
            listenable: Listenable.merge([controller, controller.topEdgeFade]),
            builder: (context, _) {
              _scheduleFollow();
              final safeTop = math.max(mq.padding.top, widget.minTopInset);
              // The keyboard: the bottom bar rides on top of it (set `resizeToAvoidBottomInset: false` on an outer Scaffold so it
              // does not shrink us as well); the home-indicator inset is covered by the keyboard.
              // with a bottom bar only a share of the home-indicator inset is kept below it (the bar sits closer to the edge)
              final safeBottom = math.max(
                widget.bottomBar != null
                    ? mq.padding.bottom *
                          (widget.bottomBarSafeAreaShare ??
                              tokens.chrome.bottomBarSafeAreaShare)
                    : mq.padding.bottom,
                mq.viewInsets.bottom,
              );
              final topStyle =
                  widget.topChrome ?? ChromeStyleScope.topOf(context);
              final bottomStyle =
                  widget.bottomChrome ?? ChromeStyleScope.bottomOf(context);
              final background =
                  widget.backgroundColor ?? tokens.colors.background;
              final topInset = controller.inset(ChromeEdge.top);
              // a bar of the surrounding SwiftUiShell (the tab bar) lifts everything at the bottom and is covered by the zone
              final external = SwiftUiShellScope.bottomOf(context);
              final bottomInset =
                  controller.inset(ChromeEdge.bottom) + external;
              final data = ChromeInsetsData(
                top: safeTop + controller.padding(ChromeEdge.top),
                bottom:
                    safeBottom +
                    controller.padding(ChromeEdge.bottom) +
                    external,
                topMin: safeTop + controller.minPadding(ChromeEdge.top),
                scrollSlack: controller.scrollSlack,
                // no bar on an edge: only the system area (status bar / home indicator) is blurred, without the fade extension
                topZone: topInset > 0
                    ? topStyle.zoneHeight(
                        BlurEdge.top,
                        safeTop + topInset,
                        tokens,
                      )
                    : safeTop,
                // the bottom effect is much shorter than the top one: it starts a bit below the top of the bottom bars (the glass
                // of the bar covers the rest) and eases out over a third of the usual extension
                bottomZone: bottomInset > 0
                    ? bottomStyle.zoneHeight(
                        BlurEdge.bottom,
                        safeBottom + bottomInset,
                        tokens,
                      )
                    : safeBottom,
              );
              final body = MediaQuery(
                data: mq.copyWith(
                  padding: mq.padding.copyWith(
                    top: data.top,
                    bottom: data.bottom,
                  ),
                ),
                // metrics too: a position restored or clamped without a scroll (first layout, content that changed size) must
                // reach the bars as well
                child: NotificationListener<ScrollMetricsNotification>(
                  onNotification: (n) {
                    if (n.depth == widget.scrollDepth &&
                        n.metrics.axis == Axis.vertical &&
                        n.metrics.hasPixels) {
                      _startOffset(n.context);
                      final p = n.metrics.pixels;
                      if ((p - controller.scrollOffset.value).abs() > 0.01) {
                        controller.scrollOffset.value = p;
                        _scheduleFollow();
                      }
                    }
                    return false;
                  },
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _onScroll,
                    child: widget.body,
                  ),
                ),
              );
              return _ChromeInsetsScope(
                data: data,
                child: Stack(
                  key: _stackKey,
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(child: body),
                    // no bar on the edge: nothing to read over the effect, so none is drawn (the content runs under the system
                    // area as it is)
                    if (data.topZone > 0 && topInset > 0)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        // the effect fades in as the content starts to move under the bar: at rest nothing is under it, so
                        // the first rows stay sharp (the scroll edge effect of iOS 26)
                        child: ValueListenableBuilder<double>(
                          valueListenable: controller.scrollOffset,
                          builder: (context, offset, _) {
                            final ramp = tokens.chrome.topEdgeRamp;
                            final moved =
                                offset - (controller.initialScrollOffset ?? 0);
                            final k = ramp <= 0
                                ? 1.0
                                : (moved / ramp).clamp(0.0, 1.0);
                            return topStyle.build(
                              context,
                              ChromeSpec(
                                edge: BlurEdge.top,
                                height: data.topZone,
                                covered: safeTop + topInset,
                                // a header that draws its own edge effect (StretchHeader) switches the scaffold's one off
                                intensity: controller.topEdgeFade.value * k,
                                fadeHold:
                                    (0.6 * (safeTop + topInset) / data.topZone)
                                        .clamp(0.0, 0.5),
                                background: background,
                              ),
                            );
                          },
                        ),
                      ),
                    if (widget.bottomBlur &&
                        data.bottomZone > 0 &&
                        bottomInset > 0)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: bottomStyle.build(
                          context,
                          ChromeSpec(
                            edge: BlurEdge.bottom,
                            height: data.bottomZone,
                            covered: safeBottom + bottomInset,
                            intensity: 1,
                            // at most 0.45: the gradient eases out over more than half of this short zone, like the top one (with
                            // a larger hold the bottom effect ends in a visible line)
                            fadeHold:
                                (0.6 *
                                        (safeBottom + bottomInset) /
                                        data.bottomZone)
                                    .clamp(0.0, 0.45),
                            background: background,
                          ),
                        ),
                      ),
                    if (widget.blockZoneTouches && data.topZone > 0)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: data.topZone,
                        child: const AbsorbPointer(),
                      ),
                    if (widget.blockZoneTouches &&
                        widget.bottomBlur &&
                        data.bottomZone > 0)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: data.bottomZone,
                        child: const AbsorbPointer(),
                      ),
                    ..._stuckOverlays(controller, safeTop),
                    if (widget.topBar != null)
                      Positioned(
                        top: safeTop,
                        left: 0,
                        right: 0,
                        child: widget.topBar!,
                      ),
                    if (widget.bottomBar != null)
                      Positioned(
                        bottom: safeBottom + external,
                        left: 0,
                        right: 0,
                        child: widget.bottomBar!,
                      ),
                    if (widget.overlay != null)
                      Positioned.fill(child: widget.overlay!),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Sharp copies of stuck headers, above the blur. Each follows the real
  /// header through a [LayerLink], so it moves exactly with the scroll
  /// (including being pushed out by the next header). Clipped at the pin line.
  List<Widget> _stuckOverlays(ChromeController c, double safeTop) {
    final list = c.overlayEntries();
    if (list.isEmpty) return const [];
    final line = safeTop + c.fixedInset(ChromeEdge.top);
    return [
      Positioned.fill(
        child: ClipRect(
          clipper: _FromLineClipper(line),
          child: Stack(
            children: [
              for (final e in list)
                Positioned(
                  key: ObjectKey(e),
                  top: 0,
                  left: 0,
                  right: 0,
                  child: CompositedTransformFollower(
                    link: e.link!,
                    showWhenUnlinked: false,
                    child: PaintWhenStuck(
                      entry: e,
                      child: SizedBox(
                        height: e.overlayHeight,
                        child: e.overlay!,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ];
  }
}

/// Measures [child] and registers its height as an inset of [edge] while
/// mounted. Use for ordinary bars / footers.
class ChromeBar extends StatefulWidget {
  const ChromeBar({
    super.key,
    required this.child,
    this.edge = ChromeEdge.top,
    this.animate = true,
    this.label,
    this.glassSpacing = 14,
  });

  final Widget child;
  final ChromeEdge edge;

  /// Glass morph distance of the plates in the bar (see [LiquidGlassGroup.spacing]): neighbours closer than this melt into
  /// one shape while one of them is pressed, like a native glass container. 0 keeps every plate separate.
  final double glassSpacing;

  /// Animate height changes (including the first registration).
  final bool animate;
  final String? label;

  @override
  State<ChromeBar> createState() => _ChromeBarState();
}

class _ChromeBarState extends State<ChromeBar> {
  ChromeInsetEntry? _entry;
  ChromeController? _controller;
  double _height = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = ChromeScaffoldScope.controllerOf(context);
    if (c != _controller) {
      _entry?.release();
      _entry = null;
      _controller = c;
      _height = -1;
    }
  }

  void _onSize(double h) {
    if (h == _height) return;
    final first = _entry == null;
    _height = h;
    if (first) {
      _entry = _controller!.register(
        widget.edge,
        height: h,
        label: widget.label,
      );
    } else {
      _entry!.update(height: h, animate: widget.animate);
    }
  }

  @override
  void dispose() {
    _entry?.release(animate: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeReporter(
      onSize: _onSize,
      child: LiquidGlassGroup(
        spacing: widget.glassSpacing,
        child: widget.child,
      ),
    );
  }
}

/// First sliver of a `CustomScrollView` living in a [ChromeScaffold]. Takes
/// the top (or bottom) content padding and is pinned, so later pinned headers
/// stick *below* the chrome instead of under the status bar.
class SliverChromeInset extends StatelessWidget {
  const SliverChromeInset.top({super.key}) : edge = ChromeEdge.top;
  const SliverChromeInset.bottom({super.key}) : edge = ChromeEdge.bottom;
  final ChromeEdge edge;

  @override
  Widget build(BuildContext context) {
    final insets = ChromeScaffoldScope.insetsOf(context);
    if (edge == ChromeEdge.bottom) {
      if (insets.scrollSlack > 0) {
        // a collapsible bar needs the list to be able to scroll by its height even when it is short: fill the screen, then
        // leave the height of the collapsible part on top
        return SliverMainAxisGroup(
          slivers: [
            const SliverFillRemaining(
              hasScrollBody: false,
              child: SizedBox.shrink(),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: insets.scrollSlack + insets.bottom),
            ),
          ],
        );
      }
      return SliverToBoxAdapter(child: SizedBox(height: insets.bottom));
    }
    return SliverPersistentHeader(
      pinned: true,
      delegate: _InsetDelegate(insets.top, insets.topMin),
    );
  }
}

class _InsetDelegate extends SliverPersistentHeaderDelegate {
  _InsetDelegate(this.extent, this.min);
  final double extent;
  final double min;
  @override
  double get minExtent => min;
  @override
  double get maxExtent => extent;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => SizedBox(height: extent);
  @override
  bool shouldRebuild(_InsetDelegate old) =>
      old.extent != extent || old.min != min;
}

class _FromLineClipper extends CustomClipper<Rect> {
  _FromLineClipper(this.line);
  final double line;
  @override
  Rect getClip(Size size) => Rect.fromLTRB(0, line, size.width, size.height);
  @override
  bool shouldReclip(_FromLineClipper old) => old.line != line;
}

/// Paints (and hit-tests) [child] only while [entry] is stuck, or only while it
/// is *not* stuck with [invert]. Reads the flag at paint time, so a change made
/// during layout takes effect in the same frame.
class PaintWhenStuck extends SingleChildRenderObjectWidget {
  const PaintWhenStuck({
    super.key,
    required this.entry,
    this.invert = false,
    super.child,
  });
  final ChromeInsetEntry entry;
  final bool invert;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderPaintWhenStuck(entry, invert);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderPaintWhenStuck renderObject,
  ) {
    renderObject
      ..entry = entry
      ..invert = invert;
  }
}

/// Render object of [PaintWhenStuck].
class RenderPaintWhenStuck extends RenderProxyBox {
  RenderPaintWhenStuck(this._entry, this._invert);
  ChromeInsetEntry _entry;
  bool _invert;

  set entry(ChromeInsetEntry v) {
    if (v == _entry) return;
    if (attached) _entry.stuckNotifier.removeListener(markNeedsPaint);
    _entry = v;
    if (attached) _entry.stuckNotifier.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  set invert(bool v) {
    if (v == _invert) return;
    _invert = v;
    markNeedsPaint();
  }

  bool get _visible => _entry.stuck != _invert;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _entry.stuckNotifier.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _entry.stuckNotifier.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_visible) super.paint(context, offset);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) =>
      _visible && super.hitTest(result, position: position);
}

/// The bottom of a page in the native iOS 26 layout, for [ChromeScaffold.bottomBar]: up to three stacked slots,
///
///  * [floating]: loose glass bubbles / buttons above the composer (suggestions, a "scroll to bottom" button...). The
///    content makes room for them, but the blur zone does not cover them: they float over the content;
///  * [composer]: the text field row (a [GlassTextField] with its buttons). It follows the keyboard;
///  * [navBar]: a tab / navigation bar at the very bottom. It slides away while the keyboard is up (the composer then
///    sits right on the keyboard).
///
/// Every slot is optional and animates in and out. The dock registers itself in the scaffold: the content padding is the
/// whole stack, the blur zone covers composer + navBar. All plates inside share one glass pass.
class BottomDock extends StatefulWidget {
  const BottomDock({
    super.key,
    this.floating,
    this.composer,
    this.navBar,
    this.hideNavBarWithKeyboard = true,
    this.gap = 8,
    this.navGap = 10,
  });

  final Widget? floating;
  final Widget? composer;
  final Widget? navBar;

  /// Slide [navBar] away while the keyboard is open.
  final bool hideNavBarWithKeyboard;

  /// Space between [floating] and the composer.
  final double gap;

  /// Space between the composer and [navBar] (native: ~18 pt together with the composer's own bottom padding).
  final double navGap;

  @override
  State<BottomDock> createState() => _BottomDockState();
}

class _BottomDockState extends State<BottomDock> {
  ChromeInsetEntry? _entry;
  ChromeController? _controller;
  double _hFloating = 0;
  double _hComposer = 0;
  double _hNav = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = ChromeScaffoldScope.controllerOf(context);
    if (c != _controller) {
      _entry?.release(animate: false);
      _entry = null;
      _controller = c;
    }
  }

  void _sync() {
    // the covered zone: composer + nav bar; the content padding: everything
    final covered = _hComposer + _hNav;
    final padding = covered + _hFloating;
    if (_entry == null) {
      _entry = _controller!.register(
        ChromeEdge.bottom,
        height: covered,
        padding: padding,
        label: 'BottomDock',
      );
    } else {
      // the slots animate their own size, so the registration just follows
      _entry!.update(height: covered, padding: padding, animate: false);
    }
  }

  @override
  void dispose() {
    _entry?.release(animate: false);
    super.dispose();
  }

  Widget _slot(
    Widget? child,
    bool show,
    ValueChanged<double> onSize, {
    double bottomGap = 0,
    double topGap = 0,
  }) {
    return SizeReporter(
      onSize: onSize,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: Alignment.bottomCenter,
        child: ClipRect(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: show && child != null ? 1 : 0,
            child: show && child != null
                ? Padding(
                    padding: EdgeInsets.only(bottom: bottomGap, top: topGap),
                    child: child,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;
    final showNav =
        widget.navBar != null && !(widget.hideNavBarWithKeyboard && keyboardUp);
    return LiquidGlassGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _slot(widget.floating, true, (h) {
            _hFloating = h;
            _sync();
          }, bottomGap: widget.gap),
          _slot(widget.composer, true, (h) {
            _hComposer = h;
            _sync();
          }),
          _slot(widget.navBar, showNav, topGap: widget.navGap, (h) {
            _hNav = h;
            _sync();
          }),
        ],
      ),
    );
  }
}
