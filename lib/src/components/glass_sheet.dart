import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../services/screen_radius_service.dart';
import '../theme/swift_ui_theme.dart';
import 'liquid_glass.dart';

// An iOS 26 `.sheet`: a resizable modal sheet. At a partial detent (`.medium`) it is a floating card of liquid glass inset from the
// edges of the screen; dragged up it grows to the full width and turns into an opaque page at `.large`. The page behind is not
// scaled, it only dims, in proportion to the height of the sheet.
//
// Three ways to use it, one sheet:
//  * `showGlassSheet(context, ...)`: from anywhere, like `showModalBottomSheet`;
//  * `GlassSheetRoute` and the router adapters (`GlassSheetAutoRoute`, `GlassSheetPage`): the sheet IS a route of the page you list
//    in the router, the page widget is its content;
//  * `GlassSheetPresenter`: declarative, inside the page (`.sheet(isPresented:)`), driven by the page's own state, with optional
//    interaction with the page behind it.

/// A height the sheet can rest at, `PresentationDetent` of SwiftUI.
abstract class GlassSheetDetent {
  const GlassSheetDetent._();

  /// The height of the sheet (logical px) at this detent. [container] is the height of the area the sheet lives in, [max] the height of
  /// the largest sheet (the container minus the gap above it).
  double resolve(double container, double max);

  /// `.medium`: about half of the screen (as native, measured on an iPhone 17 Pro: the card's top is at 52.5 % of the height).
  static const GlassSheetDetent medium = _FractionDetent(0.525);

  /// `.large`: the full sheet, up to the gap under the status bar.
  static const GlassSheetDetent large = _LargeDetent();

  /// `.fraction(f)`: a share of the height of the container.
  const factory GlassSheetDetent.fraction(double f) = _FractionDetent;

  /// `.height(h)`: an exact height in logical px.
  const factory GlassSheetDetent.height(double h) = _HeightDetent;
}

class _FractionDetent extends GlassSheetDetent {
  const _FractionDetent(this.f) : super._();
  final double f;
  @override
  double resolve(double container, double max) => math.min(f * container, max);
}

class _HeightDetent extends GlassSheetDetent {
  const _HeightDetent(this.h) : super._();
  final double h;
  @override
  double resolve(double container, double max) => math.min(h, max);
}

class _LargeDetent extends GlassSheetDetent {
  const _LargeDetent() : super._();
  @override
  double resolve(double container, double max) => max;
}

/// Drives a [GlassSheet] from code: move it between detents, read where it is, close it.
class GlassSheetController extends ChangeNotifier {
  _GlassSheetState? _state;

  /// Where the sheet is, as a share of the height of the area it lives in (0..1).
  double get extent => _state?._extent.value ?? 0;

  /// Whether a sheet is attached.
  bool get isAttached => _state != null;

  /// Moves the sheet to [detent] (it must be one of the sheet's detents, or anything the sheet can reach).
  Future<void> animateTo(
    GlassSheetDetent detent, {
    Duration duration = const Duration(milliseconds: 360),
    Curve curve = Curves.easeOutCubic,
  }) async => _state?._animateToDetent(detent, duration, curve);

  /// To the largest detent.
  Future<void> expand() => animateTo(GlassSheetDetent.large);

  /// To the smallest detent (not closing it).
  Future<void> collapse() async => _state?._animateToSmallest();

  /// Asks the owner (route or presenter) to close the sheet, as the drag down or a tap outside does.
  void dismiss() => _state?._requestDismiss();

  void _attach(_GlassSheetState s) {
    _state = s;
  }

  void _detach(_GlassSheetState s) {
    if (identical(_state, s)) _state = null;
  }

  void _changed() => notifyListeners();
}

class _GlassSheetScope extends InheritedWidget {
  const _GlassSheetScope({
    required this.controller,
    required this.scrollController,
    required this.extent,
    required super.child,
  });

  final GlassSheetController controller;
  final ScrollController scrollController;
  final ValueListenable<double> extent;

  @override
  bool updateShouldNotify(_GlassSheetScope old) =>
      controller != old.controller ||
      scrollController != old.scrollController ||
      extent != old.extent;
}

typedef GlassSheetBuilder = Widget Function(
  BuildContext context,
  ScrollController scrollController,
);

/// The sheet itself: a dim barrier and the resizable card, filling the area it is placed in (a route puts it over the app,
/// [GlassSheetPresenter] over a page). Most code uses [showGlassSheet], [GlassSheetRoute] or [GlassSheetPresenter] instead of this.
class GlassSheet extends StatefulWidget {
  const GlassSheet({
    super.key,
    this.child,
    this.builder,
    required this.present,
    this.onDismissed,
    this.detents = const [GlassSheetDetent.medium, GlassSheetDetent.large],
    this.initialDetent,
    this.controller,
    this.dismissible = true,
    this.modal = true,
    this.showGrabber = true,
    this.scrollable = true,
    this.backgroundColor,
    this.dimColor = const Color(0x52000000),
    this.liquid,
    this.topGap,
    this.cornerRadius,
    this.inset = 8,
    this.origin,
  }) : assert(child != null || builder != null);

  /// The control the sheet grows out of (and shrinks back into): see [GlassSheetOrigin]. Null: the sheet slides up from the bottom.
  final GlassSheetOriginController? origin;

  /// The content. By default it sits in a scroll view that the sheet drags (so dragging the content moves the sheet and, once it is
  /// full, scrolls). If it has its own scrollable, pass `scrollable: false` and give that scrollable the controller of
  /// [GlassSheet.scrollControllerOf].
  final Widget? child;

  /// The content as a builder that receives the scroll controller of the sheet (give it to your `ListView`).
  final GlassSheetBuilder? builder;

  /// 0 (out of sight) .. 1 (in place): the slide in and out, driven by the owner.
  final Animation<double> present;

  /// The user closed the sheet (dragged it down, tapped outside, [GlassSheetController.dismiss]). The owner removes it.
  final VoidCallback? onDismissed;

  /// The heights the sheet rests at, smallest to largest in any order.
  final List<GlassSheetDetent> detents;

  /// Where it opens; the first of [detents] when null.
  final GlassSheetDetent? initialDetent;
  final GlassSheetController? controller;

  /// false: it cannot be dragged away or dismissed by a tap outside; it rests at its smallest detent at the least.
  final bool dismissible;

  /// true: a dim barrier covers the page and swallows its touches. false: the page behind stays usable around the sheet.
  final bool modal;

  /// The drag indicator (`presentationDragIndicator(.visible)`).
  final bool showGrabber;

  /// See [child].
  final bool scrollable;

  /// The page colour of the opaque (large) sheet. Null: the native system background of the theme.
  final Color? backgroundColor;

  /// The dim of the page behind at the largest detent; it grows with the height of the sheet.
  final Color dimColor;

  /// Liquid glass at the partial detents. null: the theme setting (and the shader support). false: an opaque card.
  final bool? liquid;

  /// The gap between the top of the largest sheet and the top of the area. Null: the status bar inset (native: the large sheet starts right under it).
  final double? topGap;

  /// One radius for all four corners. Null (default): native. The bottom corners have the radius of the screen, the top ones are
  /// dynamic (38.7 pt on a floating card, 35.7 pt on the full sheet, measured on iOS 26.5).
  final double? cornerRadius;

  /// The margin of the floating card from the sides and the bottom of the screen.
  final double inset;

  /// The scroll controller of the sheet, for a content that scrolls by itself. Throws outside a sheet.
  static ScrollController scrollControllerOf(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<_GlassSheetScope>();
    assert(
      s != null,
      'GlassSheet.scrollControllerOf called outside a GlassSheet',
    );
    return s!.scrollController;
  }

  /// The controller of the sheet that contains [context].
  static GlassSheetController controllerOf(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<_GlassSheetScope>();
    assert(s != null, 'GlassSheet.controllerOf called outside a GlassSheet');
    return s!.controller;
  }

  /// The current height of the sheet as a share of its area (0..1); the context rebuilds as the sheet is dragged.
  static double extentOf(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<_GlassSheetScope>();
    return s?.extent.value ?? 0;
  }

  @override
  State<GlassSheet> createState() => _GlassSheetState();
}

class _GlassSheetState extends State<GlassSheet>
    with SingleTickerProviderStateMixin {
  final _drag = DraggableScrollableController();
  late final ValueNotifier<double> _extent = ValueNotifier<double>(0);
  GlassSheetController? _ownController;
  GlassSheetController get _controller =>
      widget.controller ?? (_ownController ??= GlassSheetController());
  bool _dismissing = false;
  final _areaKey = GlobalKey();
  // the content moves between wrappers while the sheet grows out of a control: the key keeps its state
  final _contentKey = GlobalKey();
  double? _reverseFrom;
  Rect? _chaseFrom;
  double _container = 0;
  List<double> _extents = const [];
  double _maxExtent = 1;

  @override
  void initState() {
    super.initState();
    _spring = createTicker(_springTick);
    widget.origin?.capture();
    widget.origin?._hideSoon();
    _drag.addListener(_onDrag);
    _controller._attach(this);
  }

  @override
  void didUpdateWidget(GlassSheet old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      (old.controller ?? _ownController)?._detach(this);
      _controller._attach(this);
    }
  }

  @override
  void dispose() {
    widget.origin?._showSoon();
    _spring.dispose();
    _controller._detach(this);
    _drag.removeListener(_onDrag);
    _drag.dispose();
    _extent.dispose();
    _ownController?.dispose();
    super.dispose();
  }

  void _onDrag() {
    if (!_drag.isAttached) return;
    final s = _drag.size;
    if (_extent.value != s) {
      _extent.value = s;
      _controller._changed();
    }
    if (widget.dismissible && !_dismissing && s <= 0.01) {
      _dismissing = true;
      widget.onDismissed?.call();
      _restoreIfKept();
    }
  }

  void _requestDismiss() {
    if (_dismissing) return;
    _dismissing = true;
    widget.onDismissed?.call();
    _restoreIfKept();
  }

  // the owner may keep the sheet (it ignored the dismissal): bring it back instead of leaving an invisible sheet
  void _restoreIfKept() {
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (!mounted || widget.present.status != AnimationStatus.completed)
        return;
      _dismissing = false;
      if (_drag.isAttached && _drag.size < 0.02 && _extents.isNotEmpty) {
        _drag.animateTo(
          _extents.first,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  double _extentOf(GlassSheetDetent d) {
    if (_container <= 0) return 1;
    return (d.resolve(_container, _container * _maxExtent) / _container).clamp(
      0.0,
      _maxExtent,
    );
  }

  Future<void> _animateToDetent(
    GlassSheetDetent d,
    Duration duration,
    Curve curve,
  ) async {
    if (!_drag.isAttached) return;
    await _drag.animateTo(_extentOf(d), duration: duration, curve: curve);
  }

  Future<void> _animateToSmallest() async {
    if (!_drag.isAttached || _extents.isEmpty) return;
    await _drag.animateTo(
      _extents.first,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  // dragging the grabber moves the sheet whatever the content's scroll offset is
  void _grabberDrag(double dy) {
    if (!_drag.isAttached || _container <= 0) return;
    final min = widget.dismissible ? 0.0 : _extents.first;
    _drag.jumpTo((_drag.size - dy / _container).clamp(min, _maxExtent));
  }

  void _grabberEnd(double velocity) => _settle(velocity);

  // The release: a spring from where the finger let go (with its velocity) to the nearest rest, as native. The sheet's own snap is
  // a fixed-duration tween that throws the velocity away, which is what made it feel unphysical.
  late final Ticker _spring;
  SpringSimulation? _sim;
  Duration _simStart = Duration.zero;
  double _simMin = 0;

  void _stopSpring() {
    if (_spring.isActive) _spring.stop();
    _sim = null;
  }

  void _settle(double velocity) {
    if (!_drag.isAttached || _container <= 0 || _extents.isEmpty) return;
    final size = _drag.size;
    // where the sheet would coast to, then the nearest rest (a detent or, when it can go, closed)
    final projected = (size - velocity * 0.2 / _container).clamp(
      0.0,
      _maxExtent,
    );
    final stops = [if (widget.dismissible) 0.0, ..._extents];
    var best = stops.first;
    for (final s in stops) {
      if ((s - projected).abs() < (best - projected).abs()) best = s;
    }
    if ((size - best).abs() < 1e-3 && velocity.abs() < 20) return;
    _simMin = widget.dismissible ? 0.0 : _extents.first;
    // a touch under critical damping: a hint of settle at the end, no wobble
    _sim = SpringSimulation(
      const SpringDescription(mass: 1, stiffness: 260, damping: 29),
      size,
      best,
      -velocity / _container,
    );
    _simStart = Duration.zero;
    _spring.stop();
    _spring.start();
  }

  void _springTick(Duration elapsed) {
    final sim = _sim;
    if (sim == null || !_drag.isAttached) {
      _stopSpring();
      return;
    }
    if (_simStart == Duration.zero) _simStart = elapsed;
    final t = (elapsed - _simStart).inMicroseconds / 1e6;
    _drag.jumpTo(sim.x(t).clamp(_simMin, _maxExtent));
    if (sim.isDone(t)) _stopSpring();
  }

  static double _smooth(double x) {
    final t = x.clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final mq = MediaQuery.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        final h = c.maxHeight.isFinite ? c.maxHeight : mq.size.height;
        _container = h;
        final gap = widget.topGap ?? mq.padding.top;
        _maxExtent = ((h - gap) / h).clamp(0.1, 1.0);
        final values = <double>{
          for (final d in widget.detents)
            (d.resolve(h, h * _maxExtent) / h).clamp(0.05, _maxExtent),
        }.toList()..sort();
        if (values.isEmpty) values.add(_maxExtent);
        _extents = values;
        final top = values.last;
        final initial = widget.initialDetent == null
            ? values.first
            : (widget.initialDetent!.resolve(h, h * _maxExtent) / h).clamp(
                values.first,
                top,
              );
        final min = widget.dismissible ? 0.0 : values.first;
        // known before the first drag notification, so the first frame already has its height (no listeners exist yet)
        if (_extent.value == 0) _extent.value = initial;
        final snaps = [
          for (final v in values)
            if (v > min + 1e-3 && v < top - 1e-3) v,
        ];
        final screenRadius = ScreenRadiusService.instance.radiusValue > 0
            ? ScreenRadiusService.instance.radiusValue
            : 60.0;
        final glass =
            (widget.liquid ?? t.glass.useLiquidGlass) && LiquidGlass.supported;
        final solid =
            widget.backgroundColor ??
            (t.isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF));

        return Stack(
          key: _areaKey,
          fit: StackFit.expand,
          children: [
            if (widget.modal)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: Listenable.merge([widget.present, _extent]),
                  builder: (context, _) {
                    final share =
                        (_extent.value / top).clamp(0.0, 1.0) *
                        widget.present.value.clamp(0.0, 1.0);
                    final dim = widget.dimColor;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.dismissible ? _requestDismiss : null,
                      child: ColoredBox(
                        color: dim.withValues(alpha: dim.a * share),
                      ),
                    );
                  },
                ),
              ),
            AnimatedBuilder(
              animation: widget.present,
              builder: (context, child) {
                // grown out of a control: the surface itself moves (below), nothing slides
                if (widget.origin != null) return child!;
                final p = Curves.easeOutCubic.transform(
                  widget.present.value.clamp(0.0, 1.0),
                );
                return Transform.translate(
                  offset: Offset(0, (1 - p) * (h * _extent.value + 24)),
                  child: child,
                );
              },
              child: Listener(
                onPointerDown: (_) => _stopSpring(),
                child: NotificationListener<ScrollEndNotification>(
                  onNotification: (n) {
                    // a drag that moved the sheet ended on the content: let it settle with the finger's velocity
                    if (n.depth == 0 && n.dragDetails != null) {
                      _settle(n.dragDetails!.primaryVelocity ?? 0);
                    } else if (n.depth == 0) {
                      _settle(0);
                    }
                    return false;
                  },
                  child: DraggableScrollableSheet(
                    controller: _drag,
                    initialChildSize: initial,
                    minChildSize: min,
                    maxChildSize: top,
                    expand: true,
                    snap: false,
                    snapSizes: snaps,
                    snapAnimationDuration: const Duration(milliseconds: 280),
                    shouldCloseOnMinExtent: false,
                    builder: (context, scroll) {
                      final content = widget.builder != null
                          ? widget.builder!(context, scroll)
                          : (widget.scrollable
                                ? SingleChildScrollView(
                                    controller: scroll,
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    child: widget.child,
                                  )
                                : widget.child!);
                      // No bounce at the top of the content: the drag has to pass to the sheet there, as native (a bouncing list would
                      // take it for an overscroll on iOS). Lists inside the sheet inherit this.
                      // The sheet always starts under the status bar, its content has no top inset (a ChromeScaffold or a SafeArea inside
                      // would otherwise leave a status-bar sized gap).
                      final scrolling = KeyedSubtree(
                        key: _contentKey,
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(
                            physics: const ClampingScrollPhysics(),
                            overscroll: false,
                          ),
                          child: MediaQuery.removePadding(
                            context: context,
                            removeTop: true,
                            child: content,
                          ),
                        ),
                      );
                      return _GlassSheetScope(
                        controller: _controller,
                        scrollController: scroll,
                        extent: _extent,
                        child: ValueListenableBuilder<double>(
                          valueListenable: _extent,
                          builder: (context, e, _) {
                            // how far the sheet is from a floating card to the full page: 0 at the partial detents, 1 at the full
                            // height. A sheet whose largest detent is a partial one (a `.medium` only) stays a floating card.
                            final full = _smooth(
                              (e - (_maxExtent - 0.18)) / 0.18,
                            );
                            final inset = widget.inset * (1 - full);
                            // native (measured): the bottom corners are the screen's, the top ones are dynamic
                            final topRadius =
                                widget.cornerRadius ?? (38.7 - 3.0 * full);
                            final bottomRadius =
                                widget.cornerRadius ?? screenRadius;
                            // Below the smallest detent the content does not shrink any more: it keeps the size it has there and the
                            // whole sheet slides down (its bottom edge leaves the screen), as native.
                            final boxHeight = h * math.max(e, values.first);
                            final origin = widget.origin;
                            if (origin != null) {
                              return AnimatedBuilder(
                                animation: widget.present,
                                child: scrolling,
                                builder: (context, content) {
                                  // A glass button becomes the sheet as the native one does (tools/native_morph_ref/MORPH_SPEC.md, 10): no
                                  // separate droplet, the four edges of one plate follow their own springs from the button's edges to the
                                  // sheet's, the button's picture fades out in the middle of it, the content is a miniature of the final
                                  // layout (scaled by the plate's width) that sharpens, closing has its own springs.
                                  final v = widget.present.value.clamp(
                                    0.0,
                                    1.0,
                                  );
                                  final reversing =
                                      widget.present.status ==
                                      AnimationStatus.reverse;
                                  if (reversing) {
                                    _reverseFrom ??= v;
                                  } else {
                                    _reverseFrom = null;
                                    _chaseFrom = null;
                                  }
                                  final chasing =
                                      reversing &&
                                      (_reverseFrom ?? 1) < _kSheetChaseBelow;
                                  final closing = reversing && !chasing;
                                  final finalRect = Rect.fromLTWH(
                                    inset,
                                    0,
                                    c.maxWidth - 2 * inset,
                                    boxHeight - inset,
                                  );
                                  // the control, in the coordinates of this box (the box starts h * (1 - e) down the sheet)
                                  final areaBox =
                                      _areaKey.currentContext
                                              ?.findRenderObject()
                                          as RenderBox?;
                                  final areaOffset =
                                      areaBox != null && areaBox.hasSize
                                      ? areaBox.localToGlobal(Offset.zero)
                                      : Offset.zero;
                                  final from = (origin.rect ?? finalRect).shift(
                                    Offset(
                                      -areaOffset.dx,
                                      -areaOffset.dy - h * (1 - e),
                                    ),
                                  );
                                  final dBtn = from.shortestSide;
                                  Rect openRect(double tau) => Rect.fromLTRB(
                                    _sheetEdge(
                                      25.2,
                                      0.02,
                                      0.0161,
                                      0.78,
                                      tau,
                                      from.left,
                                      finalRect.left,
                                    ),
                                    _sheetEdge(
                                      6.7,
                                      -0.02,
                                      0.0157,
                                      0.78,
                                      tau,
                                      from.top,
                                      finalRect.top,
                                    ),
                                    _sheetEdge(
                                      27.0,
                                      0.03,
                                      0.0162,
                                      0.78,
                                      tau,
                                      from.right,
                                      finalRect.right,
                                    ),
                                    _sheetEdge(
                                      20.7,
                                      -0.04 * dBtn,
                                      0.0164,
                                      0.72,
                                      tau,
                                      from.bottom,
                                      finalRect.bottom,
                                    ),
                                  );
                                  // closing: the springs run to the button; what is left at the end of the timeline is closed by a smooth step
                                  Rect closeRaw(double tau) => Rect.fromLTRB(
                                    _sheetEdge(
                                      0,
                                      0.155,
                                      0.0186,
                                      0.78,
                                      tau,
                                      finalRect.left,
                                      from.left,
                                    ),
                                    _sheetEdge(
                                      0,
                                      0.09,
                                      0.0123,
                                      0.59,
                                      tau,
                                      finalRect.top,
                                      from.top,
                                    ),
                                    _sheetEdge(
                                      0,
                                      -0.145,
                                      0.0186,
                                      0.78,
                                      tau,
                                      finalRect.right,
                                      from.right,
                                    ),
                                    _sheetEdge(
                                      14.5,
                                      -2.24,
                                      0.0150,
                                      0.48,
                                      tau,
                                      finalRect.bottom,
                                      from.bottom,
                                    ),
                                  );
                                  Rect cur;
                                  double tr;
                                  double br;
                                  double tau;
                                  final double contentAlpha;
                                  final double contentBlur;
                                  final double iconAlpha;
                                  final double iconScale;
                                  if (chasing) {
                                    // dismissed before the sheet has settled: keep the position and speed, settle onto the button with a
                                    // spring that takes the time that is left (no jump onto the closing curves)
                                    final f0 = _reverseFrom!;
                                    final tau0 = f0 * _kSheetOpenMs;
                                    _chaseFrom ??= openRect(tau0);
                                    final prev = openRect(
                                      math.max(0.0, tau0 - 3),
                                    );
                                    final a0 = _chaseFrom!;
                                    final total = math.max(
                                      60.0,
                                      f0 * _kSheetCloseMs,
                                    );
                                    final sMs = (f0 - v) * _kSheetCloseMs;
                                    tau = sMs;
                                    final w = 5 / (0.7 * total);
                                    double edge(
                                      double x0,
                                      double v0,
                                      double xf,
                                    ) {
                                      const z = 0.7;
                                      final wd = w * math.sqrt(1 - z * z);
                                      final dd = x0 - xf;
                                      return xf +
                                          math.exp(-z * w * sMs) *
                                              (dd * math.cos(wd * sMs) +
                                                  (v0 + z * w * dd) /
                                                      wd *
                                                      math.sin(wd * sMs));
                                    }

                                    final end = _smooth(
                                      (sMs / total - 0.85) / 0.15,
                                    );
                                    double fin(double x, double target) =>
                                        x + (target - x) * end;
                                    cur = Rect.fromLTRB(
                                      fin(
                                        edge(
                                          a0.left,
                                          (a0.left - prev.left) / 3,
                                          from.left,
                                        ),
                                        from.left,
                                      ),
                                      fin(
                                        edge(
                                          a0.top,
                                          (a0.top - prev.top) / 3,
                                          from.top,
                                        ),
                                        from.top,
                                      ),
                                      fin(
                                        edge(
                                          a0.right,
                                          (a0.right - prev.right) / 3,
                                          from.right,
                                        ),
                                        from.right,
                                      ),
                                      fin(
                                        edge(
                                          a0.bottom,
                                          (a0.bottom - prev.bottom) / 3,
                                          from.bottom,
                                        ),
                                        from.bottom,
                                      ),
                                    );
                                    final half =
                                        math.min(cur.width, cur.height) / 2;
                                    final rt0 = math.min(half, topRadius);
                                    tr = math.min(
                                      half,
                                      rt0 + (1000 - rt0) * _smooth(sMs / 80),
                                    );
                                    br = math.min(
                                      half,
                                      bottomRadius +
                                          (1000 - bottomRadius) *
                                              _smooth(sMs / 80),
                                    );
                                    final a1 = _smooth((tau0 - 85) / 115);
                                    contentAlpha = a1 * (1 - _smooth(sMs / 50));
                                    contentBlur = 2 * _smooth(sMs / 50);
                                    final ic0 = 1 - _smooth(tau0 / 100);
                                    iconAlpha =
                                        ic0 +
                                        (1 - ic0) *
                                            _smooth((sMs / total - 0.2) / 0.5);
                                    iconScale = 1;
                                  } else if (closing) {
                                    tau = (1 - v) * _kSheetCloseMs;
                                    final raw = closeRaw(tau);
                                    final endR = closeRaw(_kSheetCloseMs);
                                    final k = _smooth(
                                      (tau - 0.7 * _kSheetCloseMs) /
                                          (0.3 * _kSheetCloseMs),
                                    );
                                    cur = Rect.fromLTRB(
                                      raw.left + (from.left - endR.left) * k,
                                      raw.top + (from.top - endR.top) * k,
                                      raw.right + (from.right - endR.right) * k,
                                      raw.bottom +
                                          (from.bottom - endR.bottom) * k,
                                    );
                                    final half =
                                        math.min(cur.width, cur.height) / 2;
                                    final rt = tau < 85
                                        ? topRadius + 22.6 * _smooth(tau / 85)
                                        : topRadius + 22.6 - 0.19 * (tau - 85);
                                    final rb = tau < 85
                                        ? bottomRadius + 12 * _smooth(tau / 85)
                                        : bottomRadius + 12 - 0.30 * (tau - 85);
                                    tr = math.min(half, rt);
                                    br = math.min(half, rb);
                                    contentAlpha = 1 - _smooth((tau - 90) / 60);
                                    contentBlur = 2 * _smooth((tau - 90) / 60);
                                    iconAlpha = _smooth((tau - 130) / 30);
                                    iconScale =
                                        1.3 - 0.3 * _smooth((tau - 130) / 100);
                                  } else {
                                    tau = v * _kSheetOpenMs;
                                    cur = openRect(tau);
                                    final half =
                                        math.min(cur.width, cur.height) / 2;
                                    final rt =
                                        topRadius +
                                        41 * (1 - _smooth((tau - 120) / 130));
                                    final rb =
                                        bottomRadius +
                                        30 * (1 - _smooth((tau - 115) / 165));
                                    tr = tau < 95 ? half : math.min(half, rt);
                                    br = tau < 95 ? half : math.min(half, rb);
                                    contentAlpha = _smooth((tau - 85) / 115);
                                    contentBlur =
                                        3 * (1 - _smooth((tau - 100) / 100));
                                    iconAlpha = 1 - _smooth(tau / 100);
                                    iconScale = 1 + 0.0085 * math.min(tau, 40);
                                  }
                                  // the plate is the button's size again: the real control takes its place under it (the two overlap for a few
                                  // frames; a gap with neither would flash)
                                  if (reversing && v < 0.1) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback(
                                          (_) => origin.showNow(),
                                        );
                                  }
                                  // how far the plate has grown: 0 the button, 1 the sheet
                                  final mm =
                                      ((cur.width - from.width) /
                                              math.max(
                                                1.0,
                                                finalRect.width - from.width,
                                              ))
                                          .clamp(0.0, 1.0);
                                  // the content is a miniature of its final layout, as wide as the plate
                                  final cs = (cur.width / finalRect.width)
                                      .clamp(0.0, 1.5);
                                  return Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Positioned.fromRect(
                                        rect: cur,
                                        child: _Surface(
                                          topRadius: tr,
                                          bottomRadius: br,
                                          glass:
                                              glass &&
                                              (full < 0.999 || mm < 0.999),
                                          fill: solid.withValues(
                                            alpha:
                                                (glass
                                                    ? solid.a * full
                                                    : solid.a) *
                                                mm *
                                                mm,
                                          ),
                                          grabber: widget.showGrabber
                                              ? Opacity(
                                                  opacity: contentAlpha,
                                                  child: _Grabber(
                                                    color: t.colors.foreground
                                                        .withValues(
                                                          alpha: 0.28,
                                                        ),
                                                    onDrag: _grabberDrag,
                                                    onEnd: _grabberEnd,
                                                  ),
                                                )
                                              : null,
                                          morph: _Morph(
                                            size: finalRect.size,
                                            scale: Offset(cs, cs),
                                            opacity: contentAlpha,
                                            blur: contentBlur < 0.4
                                                ? 0
                                                : contentBlur,
                                          ),
                                          child: content!,
                                        ),
                                      ),
                                      Positioned.fromRect(
                                        rect: cur,
                                        child: GlassOriginSnapshot(
                                          origin: origin,
                                          alpha: iconAlpha,
                                          blur: 0,
                                          zoom: iconScale,
                                          radius: BorderRadius.only(
                                            topLeft: Radius.circular(tr),
                                            topRight: Radius.circular(tr),
                                            bottomLeft: Radius.circular(br),
                                            bottomRight: Radius.circular(br),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                            return OverflowBox(
                              alignment: Alignment.topCenter,
                              minHeight: boxHeight,
                              maxHeight: boxHeight,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  inset,
                                  0,
                                  inset,
                                  inset,
                                ),
                                child: _Surface(
                                  topRadius: topRadius,
                                  bottomRadius: bottomRadius,
                                  glass: glass && full < 0.999,
                                  fill: solid.withValues(
                                    alpha: glass ? solid.a * full : solid.a,
                                  ),
                                  grabber: widget.showGrabber
                                      ? _Grabber(
                                          color: t.colors.foreground.withValues(
                                            alpha: 0.28,
                                          ),
                                          onDrag: _grabberDrag,
                                          onEnd: _grabberEnd,
                                        )
                                      : null,
                                  child: scrolling,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

Widget _blurred(double sigma, Widget child) => sigma <= 0
    ? child
    : ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: sigma,
          sigmaY: sigma,
          tileMode: TileMode.decal,
        ),
        child: child,
      );

/// Real milliseconds of the sheet's morph timelines (the route's animation runs over them) and the opening progress below which a
/// dismissed sheet is still moving.
const _kSheetOpenMs = 520.0;
const _kSheetCloseMs = 280.0;
const _kSheetChaseBelow = 0.5;

/// One edge of the morphing plate: a damped spring from [xr] to [xf] that starts after [td] ms with speed [v0] (pt / ms).
double _sheetEdge(
  double td,
  double v0,
  double omega,
  double zeta,
  double tau,
  double xr,
  double xf,
) {
  final s = tau - td;
  if (s <= 0) return xr;
  final wd = omega * math.sqrt(1 - zeta * zeta);
  final d = xr - xf;
  return xf +
      math.exp(-zeta * omega * s) *
          (d * math.cos(wd * s) +
              (v0 + zeta * omega * d) / wd * math.sin(wd * s));
}

class _Morph {
  const _Morph({
    required this.size,
    required this.scale,
    required this.opacity,
    required this.blur,
  });
  final Size size;
  final Offset scale;
  final double opacity;
  final double blur;
}

/// The card: liquid glass under, the opaque fill fading in over it toward the full page, the content clipped to the shape.
class _Surface extends StatelessWidget {
  const _Surface({
    required this.topRadius,
    required this.bottomRadius,
    required this.glass,
    required this.fill,
    required this.grabber,
    required this.child,
    this.morph,
  });

  /// While the sheet grows out of a control: the content keeps its final layout and is scaled into the card.
  final _Morph? morph;
  final double topRadius;
  final double bottomRadius;
  final bool glass;
  final Color fill;
  final Widget? grabber;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      topLeft: Radius.circular(topRadius),
      topRight: Radius.circular(topRadius),
      bottomLeft: Radius.circular(bottomRadius),
      bottomRight: Radius.circular(bottomRadius),
    );
    final shape = RoundedRectangleBorder(borderRadius: radius);
    return Stack(
      fit: StackFit.expand,
      children: [
        // Every child has a key: the glass layer comes and goes while the sheet is dragged, and without keys the children after it
        // would be matched by position, the content (a list and its scroll position, the drag in progress) would be rebuilt from
        // scratch the moment the sheet leaves the large detent.
        if (glass)
          Positioned.fill(
            key: const ValueKey('glass'),
            child: LiquidGlass(
              cornerRadius: topRadius,
              bottomCornerRadius: bottomRadius,
              shadow: false,
              child: const SizedBox.expand(),
            ),
          ),
        Positioned.fill(
          key: const ValueKey('fill'),
          child: DecoratedBox(
            decoration: ShapeDecoration(color: fill, shape: shape),
          ),
        ),
        Positioned.fill(
          key: const ValueKey('content'),
          // hardEdge on purpose: an anti-aliased clip makes a backdrop blur inside it ignore the rounded corners
          child: ClipRRect(
            borderRadius: radius,
            clipBehavior: Clip.hardEdge,
            child: morph == null
                ? child
                : OverflowBox(
                    alignment: Alignment.topLeft,
                    minWidth: morph!.size.width,
                    maxWidth: morph!.size.width,
                    minHeight: morph!.size.height,
                    maxHeight: morph!.size.height,
                    child: _blurred(
                      morph!.blur,
                      Transform(
                        alignment: Alignment.topLeft,
                        transform: Matrix4.diagonal3Values(
                          morph!.scale.dx,
                          morph!.scale.dy,
                          1,
                        ),
                        child: Opacity(opacity: morph!.opacity, child: child),
                      ),
                    ),
                  ),
          ),
        ),
        if (grabber != null)
          Positioned(
            key: const ValueKey('grabber'),
            top: 0,
            left: 0,
            right: 0,
            child: grabber!,
          ),
      ],
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber({
    required this.color,
    required this.onDrag,
    required this.onEnd,
  });

  final Color color;
  final void Function(double dy) onDrag;
  final void Function(double velocity) onEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragUpdate: (d) => onDrag(d.delta.dy),
      onVerticalDragEnd: (d) => onEnd(d.velocity.pixelsPerSecond.dy),
      child: SizedBox(
        height: 24,
        child: Align(
          alignment: const Alignment(0, -0.35),
          child: Container(
            width: 36,
            height: 5,
            decoration: ShapeDecoration(
              color: color,
              shape: const StadiumBorder(),
            ),
          ),
        ),
      ),
    );
  }
}

/// A sheet as a route of the nearest [Navigator]: drag it down, tap outside or pop to close. Used by [showGlassSheet], the router
/// adapters (`GlassSheetAutoRoute` for auto_route, `GlassSheetPage` for go_router) and directly with `Navigator.push`.
class GlassSheetRoute<T> extends PopupRoute<T> {
  GlassSheetRoute({
    super.settings,
    this.child,
    this.builder,
    this.detents = const [GlassSheetDetent.medium, GlassSheetDetent.large],
    this.initialDetent,
    this.sheetController,
    this.dismissible = true,
    this.showGrabber = true,
    this.scrollable = true,
    this.backgroundColor,
    this.dimColor = const Color(0x52000000),
    this.liquid,
    this.topGap,
    this.cornerRadius,
    this.inset = 8,
    this.origin,
  }) : assert(child != null || builder != null);

  /// The control the sheet grows out of, see [GlassSheetOrigin].
  final GlassSheetOriginController? origin;
  final Widget? child;
  final GlassSheetBuilder? builder;
  final List<GlassSheetDetent> detents;
  final GlassSheetDetent? initialDetent;
  final GlassSheetController? sheetController;
  final bool dismissible;
  final bool showGrabber;
  final bool scrollable;
  final Color? backgroundColor;
  final Color dimColor;
  final bool? liquid;
  final double? topGap;
  final double? cornerRadius;
  final double inset;

  // grown out of a control: a droplet that grows into the sheet takes a little longer going out than coming back (160 ms)
  @override
  Duration get transitionDuration =>
      Duration(milliseconds: origin == null ? 420 : _kSheetOpenMs.round());

  @override
  Duration get reverseTransitionDuration =>
      Duration(milliseconds: origin == null ? 300 : _kSheetCloseMs.round());

  // the sheet draws its own dim, in proportion to its height
  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  bool get opaque => false;

  @override
  RoutePopDisposition get popDisposition =>
      dismissible ? super.popDisposition : RoutePopDisposition.doNotPop;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return GlassSheet(
      present: animation,
      onDismissed: () {
        if (isCurrent && navigator != null) navigator!.pop();
      },
      detents: detents,
      initialDetent: initialDetent,
      controller: sheetController,
      dismissible: dismissible,
      showGrabber: showGrabber,
      scrollable: scrollable,
      backgroundColor: backgroundColor,
      dimColor: dimColor,
      liquid: liquid,
      topGap: topGap,
      cornerRadius: cornerRadius,
      inset: inset,
      origin: origin,
      child: child,
      builder: builder,
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

/// Opens a sheet over the app, like `showModalBottomSheet`, and completes when it is closed (with the value given to `pop`).
Future<T?> showGlassSheet<T>(
  BuildContext context, {
  Widget? child,
  GlassSheetBuilder? builder,
  List<GlassSheetDetent> detents = const [
    GlassSheetDetent.medium,
    GlassSheetDetent.large,
  ],
  GlassSheetDetent? initialDetent,
  GlassSheetController? controller,
  bool dismissible = true,
  bool showGrabber = true,
  bool scrollable = true,
  Color? backgroundColor,
  bool? liquid,
  bool useRootNavigator = true,
  GlassSheetOriginController? origin,
}) {
  assert(child != null || builder != null);
  return Navigator.of(context, rootNavigator: useRootNavigator).push(
    GlassSheetRoute<T>(
      child: child,
      builder: builder,
      detents: detents,
      initialDetent: initialDetent,
      sheetController: controller,
      dismissible: dismissible,
      showGrabber: showGrabber,
      scrollable: scrollable,
      backgroundColor: backgroundColor,
      liquid: liquid,
      origin: origin,
    ),
  );
}

/// The sheet inside a page, `.sheet(isPresented:)`: wrap the page, give it a bool and a content. The sheet slides over the page
/// while [isPresented] is true; when the user closes it ([onDismissed]) the page sets the bool back.
///
/// ```dart
/// GlassSheetPresenter(
///   isPresented: _open,
///   onDismissed: () => setState(() => _open = false),
///   sheet: (context, scroll) => ListView(controller: scroll, children: [...]),
///   child: Scaffold(...),
/// )
/// ```
/// With `modal: false` the page behind stays usable beside the sheet (`presentationBackgroundInteraction`), a persistent sheet.
class GlassSheetPresenter extends StatefulWidget {
  const GlassSheetPresenter({
    super.key,
    required this.child,
    required this.isPresented,
    this.onDismissed,
    this.sheet,
    this.sheetChild,
    this.detents = const [GlassSheetDetent.medium, GlassSheetDetent.large],
    this.initialDetent,
    this.controller,
    this.dismissible = true,
    this.modal = true,
    this.showGrabber = true,
    this.scrollable = true,
    this.backgroundColor,
    this.dimColor = const Color(0x52000000),
    this.liquid,
    this.topGap,
    this.cornerRadius,
    this.inset = 8,
    this.origin,
  }) : assert(sheet != null || sheetChild != null);

  /// The control the sheet grows out of, see [GlassSheetOrigin].
  final GlassSheetOriginController? origin;

  /// The page.
  final Widget child;
  final bool isPresented;

  /// The user closed the sheet: set [isPresented] to false.
  final VoidCallback? onDismissed;

  /// The content of the sheet as a builder that gets the scroll controller of the sheet.
  final GlassSheetBuilder? sheet;

  /// The content of the sheet as a widget.
  final Widget? sheetChild;
  final List<GlassSheetDetent> detents;
  final GlassSheetDetent? initialDetent;
  final GlassSheetController? controller;
  final bool dismissible;
  final bool modal;
  final bool showGrabber;
  final bool scrollable;
  final Color? backgroundColor;
  final Color dimColor;
  final bool? liquid;
  final double? topGap;
  final double? cornerRadius;
  final double inset;

  @override
  State<GlassSheetPresenter> createState() => _GlassSheetPresenterState();
}

class _GlassSheetPresenterState extends State<GlassSheetPresenter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _present = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds: widget.origin == null ? 420 : _kSheetOpenMs.round(),
    ),
    reverseDuration: Duration(
      milliseconds: widget.origin == null ? 300 : _kSheetCloseMs.round(),
    ),
  );
  late bool _visible = widget.isPresented;
  // a new key per presentation: the sheet starts at its initial detent every time it opens
  Key _sheetKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _present.addStatusListener((s) {
      if (s == AnimationStatus.dismissed &&
          _visible &&
          !widget.isPresented &&
          mounted)
        setState(() => _visible = false);
    });
    if (widget.isPresented) _present.value = 1;
  }

  @override
  void didUpdateWidget(GlassSheetPresenter old) {
    super.didUpdateWidget(old);
    if (widget.isPresented && !old.isPresented) {
      _sheetKey = UniqueKey();
      setState(() => _visible = true);
      _present.forward(from: 0);
    } else if (!widget.isPresented && old.isPresented) {
      _present.reverse();
    }
  }

  @override
  void dispose() {
    _present.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        if (_visible)
          Positioned.fill(
            child: GlassSheet(
              key: _sheetKey,
              present: _present,
              onDismissed: widget.onDismissed,
              detents: widget.detents,
              initialDetent: widget.initialDetent,
              controller: widget.controller,
              dismissible: widget.dismissible,
              modal: widget.modal,
              showGrabber: widget.showGrabber,
              scrollable: widget.scrollable,
              backgroundColor: widget.backgroundColor,
              dimColor: widget.dimColor,
              liquid: widget.liquid,
              topGap: widget.topGap,
              cornerRadius: widget.cornerRadius,
              inset: widget.inset,
              origin: widget.origin,
              builder: widget.sheet,
              child: widget.sheetChild,
            ),
          ),
      ],
    );
  }
}

/// Marks a control a [GlassSheet] grows out of: while the sheet is open the control is hidden and the card starts as its shape
/// (a capsule or a circle of liquid glass), grows into the sheet and, when it is closed, shrinks back into the control. This is the
/// morph of an iOS 26 glass button into a sheet / popover, done with the sheet's own geometry, no `Hero`.
///
/// ```dart
/// final origin = GlassSheetOriginController();
/// GlassSheetOrigin(controller: origin, child: GlassButton.circle(icon: clip, onPressed: () => showGlassSheet(context, origin: origin, child: ...)))
/// ```
class GlassSheetOriginController extends ChangeNotifier {
  _GlassSheetOriginState? _state;
  bool _hidden = false;
  double _reveal = 1;

  /// Whether the control is hidden because its sheet is open.
  bool get hidden => _hidden;

  /// How much of the control is shown, 0..1 (1 unless a presenter is fading it back in, see [fadeBackIn]).
  double get reveal => _reveal;

  /// The control's rectangle on the screen now; null when it is not on screen.
  Rect? get rect {
    final box = _state?.context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// Where the control was last touched (global); a presenter takes the droplet out of that button of a group.
  Offset? lastTouch;

  /// A picture of the control, taken when a presenter starts ([capture]): what rides inside the droplet it turns into.
  ui.Image? snapshot;
  double _snapshotScale = 1;

  /// Takes the picture of the control (it has to be on screen and shown).
  Future<void> capture() async {
    final st = _state;
    final ro = st?._boundary.currentContext?.findRenderObject();
    if (st == null || ro is! RenderRepaintBoundary || !ro.attached) return;
    try {
      final ratio = View.of(st.context).devicePixelRatio;
      final img = await ro.toImage(pixelRatio: ratio);
      snapshot?.dispose();
      snapshot = img;
      _snapshotScale = ratio;
    } catch (_) {}
  }

  void _set(bool v) {
    if (_hidden == v && _reveal == (v ? 0 : 1)) return;
    _hidden = v;
    _reveal = v ? 0 : 1;
    notifyListeners();
  }

  /// Shows the control at [v] (0..1) while something that grew out of it shrinks back into it: the control is uncovered by a
  /// round window that grows from its [fromRight] (or left) end, where the shrinking thing arrives (an [Opacity] would take the
  /// glass off its backdrop). A presenter calls this on every frame of the closing and ends with [showAfterPresentation].
  void fadeBackIn(double v, {bool fromRight = true}) {
    final r = v.clamp(0.0, 1.0);
    if (_reveal == r && _hidden == (r <= 0) && _fromRight == fromRight) return;
    _reveal = r;
    _fromRight = fromRight;
    _hidden = r <= 0;
    notifyListeners();
  }

  bool _fromRight = true;

  /// Hides the control (after this frame) while something that grew out of it is open: a sheet, a menu. Call [showAfterPresentation]
  /// when that closes.
  void hideForPresentation() => _hideSoon();

  /// Shows the control again, see [hideForPresentation].
  void showAfterPresentation() => _showSoon();

  /// Shows the control at once (not after the frame), for a presenter that is about to disappear: the droplet and the control
  /// must overlap for a frame, a gap of one frame is seen as a flash.
  void showNow() => _set(false);

  // after the frame: the sheet asks while the tree is being built or torn down
  void _hideSoon() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => _set(true));
  void _showSoon() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => _set(false));
}

/// See [GlassSheetOriginController].
class GlassSheetOrigin extends StatefulWidget {
  const GlassSheetOrigin({
    super.key,
    required this.controller,
    required this.child,
  });

  final GlassSheetOriginController controller;
  final Widget child;

  @override
  State<GlassSheetOrigin> createState() => _GlassSheetOriginState();
}

class _GlassSheetOriginState extends State<GlassSheetOrigin> {
  final _boundary = GlobalKey();
  @override
  void initState() {
    super.initState();
    widget.controller._state = this;
    widget.controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(GlassSheetOrigin old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_changed);
      if (old.controller._state == this) old.controller._state = null;
      widget.controller._state = this;
      widget.controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    if (widget.controller._state == this) widget.controller._state = null;
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Visibility, not Opacity: an Opacity layer would put a glass child into an offscreen layer and it would lose its backdrop
    final r = widget.controller.reveal;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) => widget.controller.lastTouch = e.position,
      child: ClipRRect(
        clipper: _RevealClipper(r, widget.controller._fromRight),
        clipBehavior: r >= 0.999 ? Clip.none : Clip.hardEdge,
        child: Visibility(
          visible: !widget.controller.hidden,
          maintainState: true,
          maintainSize: true,
          maintainAnimation: true,
          child: RepaintBoundary(key: _boundary, child: widget.child),
        ),
      ),
    );
  }
}

/// The picture of an origin control, painted inside the droplet that grew out of it (see [GlassSheetOriginController.capture]):
/// centred, as large as the control, cut by the droplet's shape. For presenters (sheet, menu); not part of the public API.
class GlassOriginSnapshot extends StatelessWidget {
  const GlassOriginSnapshot({
    super.key,
    required this.origin,
    required this.alpha,
    required this.blur,
    required this.radius,
    this.topLeft,
    this.zoom = 1,
  });

  /// Scales the picture around its own middle.
  final double zoom;

  /// Where the picture's top-left corner sits relative to this widget's (the control's place); null: centred.
  final Offset? topLeft;
  final GlassSheetOriginController? origin;
  final double alpha;
  final double blur;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final img = origin?.snapshot;
    if (img == null || alpha <= 0.01) return const SizedBox.shrink();
    Widget w = CustomPaint(
      painter: _SnapshotPainter(
        img,
        origin!._snapshotScale,
        alpha,
        topLeft,
        zoom,
      ),
      size: Size.infinite,
    );
    if (blur > 0.3) {
      w = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: w,
      );
    }
    return IgnorePointer(
      child: ClipRRect(borderRadius: radius, child: w),
    );
  }
}

class _SnapshotPainter extends CustomPainter {
  _SnapshotPainter(this.image, this.scale, this.alpha, this.topLeft, this.zoom);

  final double zoom;

  final Offset? topLeft;

  final ui.Image image;
  final double scale;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    final w = image.width / scale;
    final h = image.height / scale;
    final dst0 = topLeft != null
        ? Rect.fromLTWH(topLeft!.dx, topLeft!.dy, w, h)
        : Rect.fromCenter(
            center: size.center(Offset.zero),
            width: w,
            height: h,
          );
    final dst = Rect.fromCenter(
      center: dst0.center,
      width: dst0.width * zoom,
      height: dst0.height * zoom,
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      dst,
      Paint()
        ..color = Color.fromRGBO(255, 255, 255, alpha.clamp(0.0, 1.0))
        ..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_SnapshotPainter old) =>
      old.image != image ||
      old.alpha != alpha ||
      old.scale != scale ||
      old.topLeft != topLeft ||
      old.zoom != zoom;
}

/// The window through which a control is uncovered: a round shape growing from one end of the control to all of it.
class _RevealClipper extends CustomClipper<RRect> {
  _RevealClipper(this.t, this.fromRight);

  final double t;
  final bool fromRight;

  @override
  RRect getClip(Size size) {
    final full = Offset.zero & size;
    if (t >= 0.999)
      return RRect.fromRectAndRadius(
        full,
        Radius.circular(size.shortestSide / 2),
      );
    final d = size.shortestSide * 0.9;
    final seed = Rect.fromCenter(
      center: Offset(
        fromRight
            ? size.width - size.shortestSide * 0.6
            : size.shortestSide * 0.6,
        size.height / 2,
      ),
      width: d,
      height: d,
    );
    final e = Curves.easeOutCubic.transform(t);
    final r = Rect.lerp(seed, full, e)!;
    return RRect.fromRectAndRadius(r, Radius.circular(r.shortestSide / 2));
  }

  @override
  bool shouldReclip(_RevealClipper old) =>
      old.t != t || old.fromRight != fromRight;
}
