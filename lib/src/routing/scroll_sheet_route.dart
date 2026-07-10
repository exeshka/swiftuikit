import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:swiftuikit/src/services/screen_radius_service.dart';
import 'package:swiftuikit/src/routing/page_transitions.dart';
import 'package:swiftuikit/src/routing/sheet_route.dart';

/// Represents a snap detent (stop) for scroll sheet routes.
abstract class SwiftSheetDetent {
  const SwiftSheetDetent();

  /// Resolves this detent to a relative value between 0.0 and 1.0 of the sheet height.
  double resolve(double sheetHeight);

  /// A detent at a specific fraction of the available sheet height.
  static SwiftSheetDetent fraction(double fraction) => _FractionSwiftSheetDetent(fraction);

  /// A detent at a specific absolute height in logical pixels.
  static SwiftSheetDetent height(double height) => _HeightSwiftSheetDetent(height);

  /// Fully open detent (100% of sheet height).
  static const SwiftSheetDetent large = _LargeSwiftSheetDetent();

  /// Medium open detent (50% of sheet height).
  static const SwiftSheetDetent medium = _MediumSwiftSheetDetent();
}

class _FractionSwiftSheetDetent extends SwiftSheetDetent {
  const _FractionSwiftSheetDetent(this.fraction);
  final double fraction;

  @override
  double resolve(double sheetHeight) => fraction.clamp(0.0, 1.0);
}

class _HeightSwiftSheetDetent extends SwiftSheetDetent {
  const _HeightSwiftSheetDetent(this.height);
  final double height;

  @override
  double resolve(double sheetHeight) {
    if (sheetHeight <= 0.0) return 0.0;
    return (height / sheetHeight).clamp(0.0, 1.0);
  }
}

class _LargeSwiftSheetDetent extends SwiftSheetDetent {
  const _LargeSwiftSheetDetent();

  @override
  double resolve(double sheetHeight) => 1.0;
}

class _MediumSwiftSheetDetent extends SwiftSheetDetent {
  const _MediumSwiftSheetDetent();

  @override
  double resolve(double sheetHeight) => 0.5;
}

List<double> _resolveScrollSheetDetents({
  required double sheetHeight,
  required List<SwiftSheetDetent>? detents,
  required SwiftSheetDetent? initialDetent,
  required List<double> fallbackStops,
  required double fallbackInitialStop,
}) {
  if (detents == null && initialDetent == null) {
    return fallbackStops;
  }

  final double resolvedInitial = initialDetent != null
      ? initialDetent.resolve(sheetHeight)
      : fallbackInitialStop;

  final List<SwiftSheetDetent> effectiveDetents = detents ?? [
    SwiftSheetDetent.fraction(0.0),
    SwiftSheetDetent.large,
  ];

  final values = <double>{
    resolvedInitial.clamp(0.0, 1.0).toDouble(),
    ...effectiveDetents.map((detent) => detent.resolve(sheetHeight).clamp(0.0, 1.0).toDouble()),
  }.toList()..sort();

  if (values.isEmpty) return const [1.0];
  return List.unmodifiable(values);
}

List<double> _normalizeScrollSheetStops({
  required double initialStop,
  required List<double>? stops,
}) {
  final effectiveStops = stops ?? const <double>[0.0, 1.0];
  final values = <double>{
    initialStop.clamp(0.0, 1.0).toDouble(),
    ...effectiveStops.map((stop) => stop.clamp(0.0, 1.0).toDouble()),
  }.toList()..sort();

  if (values.isEmpty) return const [1.0];
  return List.unmodifiable(values);
}

class SwiftScrollSheetController extends ChangeNotifier
    implements ValueListenable<double> {
  SwiftScrollSheetController({double initialValue = 1.0})
    : _value = initialValue.clamp(0.0, 1.0).toDouble();

  DraggableScrollableController? _sheetController;
  List<double> _stops = const <double>[0.0, 1.0];
  double _value;
  double? _pendingJumpTo;

  @override
  double get value => _value;

  double get extent => _value;
  bool get isAttached => _sheetController?.isAttached ?? false;
  List<double> get stops => _stops;

  double get minStop => _stops.first;
  double get maxStop => _stops.last;

  void _attach(
    DraggableScrollableController sheetController, {
    required List<double> stops,
    required double initialValue,
  }) {
    _sheetController = sheetController;
    _stops = stops;
    _setValue(
      sheetController.isAttached ? sheetController.size : initialValue,
      notify: false,
    );

    final pendingJumpTo = _pendingJumpTo;
    _pendingJumpTo = null;
    if (pendingJumpTo != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        jumpTo(pendingJumpTo);
      });
    }
  }

  void _detach(DraggableScrollableController sheetController) {
    if (_sheetController == sheetController) {
      _sheetController = null;
    }
  }

  void _updateStops(List<double> stops, {double? initialValue}) {
    _stops = stops;
    if (initialValue != null) {
      _setValue(initialValue, notify: false);
    }
  }

  void _setValue(double value, {bool notify = true}) {
    final nextValue = value.clamp(0.0, 1.0).toDouble();
    if ((_value - nextValue).abs() <= precisionErrorTolerance) return;
    _value = nextValue;
    if (notify) notifyListeners();
  }

  Future<void> animateTo(
    double value, {
    Duration duration = const Duration(milliseconds: 220),
    Curve curve = Curves.easeOutCubic,
  }) {
    final target = value.clamp(0.0, 1.0).toDouble();
    final sheetController = _sheetController;
    if (sheetController == null || !sheetController.isAttached) {
      _pendingJumpTo = target;
      _setValue(target);
      return Future<void>.value();
    }
    return sheetController.animateTo(target, duration: duration, curve: curve);
  }

  void jumpTo(double value) {
    final target = value.clamp(0.0, 1.0).toDouble();
    final sheetController = _sheetController;
    if (sheetController == null || !sheetController.isAttached) {
      _pendingJumpTo = target;
      _setValue(target);
      return;
    }
    sheetController.jumpTo(target);
    _setValue(target);
  }

  Future<void> snapToNearest({
    Duration duration = const Duration(milliseconds: 220),
    Curve curve = Curves.easeOutCubic,
  }) {
    return animateTo(nearestStop, duration: duration, curve: curve);
  }

  Future<void> expand({
    Duration duration = const Duration(milliseconds: 220),
    Curve curve = Curves.easeOutCubic,
  }) {
    return animateTo(maxStop, duration: duration, curve: curve);
  }

  Future<void> collapse({
    Duration duration = const Duration(milliseconds: 220),
    Curve curve = Curves.easeOutCubic,
  }) {
    return animateTo(minStop, duration: duration, curve: curve);
  }

  double get nearestStop {
    return _stops.reduce((previous, next) {
      return (next - value).abs() < (previous - value).abs() ? next : previous;
    });
  }
}

/// Experimental scroll-driven version of [SwiftSheetRoute].
///
/// This route intentionally lives next to the production route while we test the
/// reference-style architecture: the sheet extent is controlled by a scroll
/// driven sheet, not by manually splitting pointer deltas in the route.
class SwiftScrollSheetRoute<T> extends PageRoute<T>
    with CupertinoRouteTransitionMixin<T> {
  SwiftScrollSheetRoute({
    required this.child,
    required RouteSettings settings,
    this.sheetRadius,
    this.sheetBorderRadius,
    this.sheetMinScale = 0.9,
    this.initialStop = 1.0,
    List<double>? stops,
    this.detents,
    this.initialDetent,
    this.transitionDurationOverride = const Duration(milliseconds: 500),
    this.snapAnimationDuration = const Duration(milliseconds: 220),
    this.stickySnap = true,
    this.dismissOnMinStop = true,
    this.routeCanPop = true,
    SwiftScrollSheetController? sheetController,
  }) : stops = _normalizeScrollSheetStops(
         initialStop: initialStop,
         stops: stops,
       ),
       sheetController =
           sheetController ??
           SwiftScrollSheetController(
             initialValue: initialStop.clamp(0.0, 1.0).toDouble(),
           ),
       _ownsSheetController = sheetController == null,
       super(settings: settings);

  final Widget child;
  final double? sheetRadius;
  final BorderRadius? sheetBorderRadius;
  final double sheetMinScale;
  final double initialStop;
  final List<double> stops;
  final List<SwiftSheetDetent>? detents;
  final SwiftSheetDetent? initialDetent;
  final Duration transitionDurationOverride;
  final Duration snapAnimationDuration;
  final bool stickySnap;
  final bool dismissOnMinStop;
  final bool routeCanPop;
  final SwiftScrollSheetController sheetController;
  final bool _ownsSheetController;

  List<double> _resolvedStops = const [];
  List<double> get resolvedStops => _resolvedStops.isEmpty ? stops : _resolvedStops;

  double? _resolvedInitialStop;
  double get resolvedInitialStop => _resolvedInitialStop ?? initialStop;

  late final ValueNotifier<double> _sheetExtentNotifier = ValueNotifier<double>(
    resolvedInitialStop.clamp(0.0, 1.0).toDouble(),
  );

  ValueListenable<double> get sheetExtentListenable => _sheetExtentNotifier;

  double get sheetExtent => _sheetExtentNotifier.value;

  /// Retrieves the closest [SwiftScrollSheetController] from the context.
  static SwiftScrollSheetController? controllerOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_SwiftScrollSheetScope>();
    return scope?.notifier;
  }

  /// Retrieves the current extent of the scroll sheet and registers the context for rebuilds
  /// when the extent changes.
  static double extentOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_SwiftScrollSheetScope>();
    return scope?.notifier?.value ?? 0.0;
  }

  Route? _nextRoute;

  Route? get nextRoute => _nextRoute;

  Route? previousRoute;

  @override
  void didChangeNext(Route? nextRoute) {
    _nextRoute = nextRoute;
    super.didChangeNext(nextRoute);
    if (nextRoute is SwiftPageRoute) {
      nextRoute.previousRoute = this;
    } else if (nextRoute is SwiftSheetRoute) {
      nextRoute.previousRoute = this;
    } else if (nextRoute is SwiftSheetStackRoute) {
      (nextRoute as SwiftSheetStackRoute).previousRoute = this;
    }
  }

  @override
  void didPopNext(Route nextRoute) {
    _nextRoute = null;
    super.didPopNext(nextRoute);
  }

  @override
  void changedInternalState() {
    super.changedInternalState();
    previousRoute?.changedInternalState();
  }

  @override
  void dispose() {
    _sheetExtentNotifier.dispose();
    if (_ownsSheetController) {
      sheetController.dispose();
    }
    super.dispose();
  }

  @override
  Widget buildContent(BuildContext context) => child;

  @override
  String? get title => null;

  @override
  bool get maintainState => true;

  @override
  bool get opaque => false;

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  String? get barrierLabel => 'Dismiss Sheet';

  @override
  bool get barrierDismissible => true;

  @override
  RoutePopDisposition get popDisposition {
    if (!routeCanPop) return RoutePopDisposition.doNotPop;
    return super.popDisposition;
  }

  @override
  Duration get transitionDuration => transitionDurationOverride;

  @override
  Duration get reverseTransitionDuration => transitionDurationOverride;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _SwiftScrollSheetTransition(
      route: this,
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      sheetRadius: sheetRadius,
      sheetBorderRadius: sheetBorderRadius,
      sheetMinScale: sheetMinScale,
      child: child,
    );
  }
}

class _SwiftScrollSheetTransition extends StatefulWidget {
  const _SwiftScrollSheetTransition({
    required this.route,
    required this.animation,
    required this.secondaryAnimation,
    required this.sheetRadius,
    required this.sheetBorderRadius,
    required this.sheetMinScale,
    required this.child,
  });

  final SwiftScrollSheetRoute route;
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final double? sheetRadius;
  final BorderRadius? sheetBorderRadius;
  final double sheetMinScale;
  final Widget child;

  @override
  State<_SwiftScrollSheetTransition> createState() =>
      _SwiftScrollSheetTransitionState();
}

class _SwiftScrollSheetTransitionState
    extends State<_SwiftScrollSheetTransition> {
  late CurvedAnimation _primaryCurve;
  late CurvedAnimation _secondaryCurve;
  late DraggableScrollableController _sheetController;
  bool _scheduledMinStopDismiss = false;

  @override
  void initState() {
    super.initState();
    _primaryCurve = CurvedAnimation(
      parent: widget.animation,
      curve: Curves.easeOutExpo,
      reverseCurve: Curves.easeInCubic,
    );
    _secondaryCurve = CurvedAnimation(
      parent: widget.secondaryAnimation,
      curve: Curves.linear,
      reverseCurve: Curves.linear,
    );
    _sheetController = DraggableScrollableController()
      ..addListener(_handleSheetExtentChanged);
    widget.route.sheetController._attach(
      _sheetController,
      stops: widget.route.resolvedStops,
      initialValue: widget.route.resolvedInitialStop,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double topPadding = MediaQuery.paddingOf(context).top;
    final double topOffset = math.max(
      SwiftPageTransitions.sheetMinimumTopOffset,
      topPadding + SwiftPageTransitions.sheetTopOffsetPadding,
    );
    final double sheetHeight = screenHeight - topOffset;

    final resolvedStops = _resolveScrollSheetDetents(
      sheetHeight: sheetHeight,
      detents: widget.route.detents,
      initialDetent: widget.route.initialDetent,
      fallbackStops: widget.route.stops,
      fallbackInitialStop: widget.route.initialStop,
    );

    final resolvedInitialStop = widget.route.initialDetent != null
        ? widget.route.initialDetent!.resolve(sheetHeight).clamp(0.0, 1.0)
        : widget.route.initialStop;

    widget.route._resolvedStops = resolvedStops;
    widget.route._resolvedInitialStop = resolvedInitialStop;

    widget.route.sheetController._updateStops(
      resolvedStops,
      initialValue: resolvedInitialStop,
    );
  }

  @override
  void didUpdateWidget(covariant _SwiftScrollSheetTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation ||
        oldWidget.secondaryAnimation != widget.secondaryAnimation) {
      _primaryCurve.dispose();
      _secondaryCurve.dispose();
      _primaryCurve = CurvedAnimation(
        parent: widget.animation,
        curve: Curves.easeOutExpo,
        reverseCurve: Curves.easeInCubic,
      );
      _secondaryCurve = CurvedAnimation(
        parent: widget.secondaryAnimation,
        curve: Curves.linear,
        reverseCurve: Curves.linear,
      );
    }
  }

  @override
  void dispose() {
    widget.route.sheetController._detach(_sheetController);
    _sheetController.removeListener(_handleSheetExtentChanged);
    _sheetController.dispose();
    _primaryCurve.dispose();
    _secondaryCurve.dispose();
    super.dispose();
  }

  void _handleSheetExtentChanged() {
    if (!_sheetController.isAttached) return;
    final size = _sheetController.size;
    final route = widget.route;
    route._sheetExtentNotifier.value = size;
    route.sheetController._setValue(size);

    if (!route.dismissOnMinStop ||
        _scheduledMinStopDismiss ||
        route.resolvedStops.first > precisionErrorTolerance ||
        size > precisionErrorTolerance ||
        !route.isCurrent) {
      return;
    }

    _scheduledMinStopDismiss = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !route.isCurrent) return;
      route.navigator?.maybePop();
    });
  }

  void _snapToNearestStop() {
    final route = widget.route;
    if (!route.stickySnap ||
        !_sheetController.isAttached ||
        !route.isCurrent ||
        _scheduledMinStopDismiss) {
      return;
    }

    final current = _sheetController.size;
    final target = route.resolvedStops.reduce((previous, next) {
      return (next - current).abs() < (previous - current).abs()
          ? next
          : previous;
    });

    if ((target - current).abs() <= precisionErrorTolerance) return;

    unawaited(
      route.sheetController.animateTo(
        target,
        duration: route.snapAnimationDuration,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  double _backgroundProgressFor(double extent) {
    return SwiftPageTransitions.sheetBackgroundProgressFor(extent);
  }

  BorderRadius _sheetBorderRadius(BuildContext context) {
    return SwiftPageTransitions.resolveSheetBorderRadius(
      context,
      radius: widget.sheetRadius,
      borderRadius: widget.sheetBorderRadius,
    );
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final linearTransition = route.popGestureInProgress;
    final primary = linearTransition ? widget.animation : _primaryCurve;
    final secondary = linearTransition
        ? widget.secondaryAnimation
        : _secondaryCurve;

    final screenHeight = MediaQuery.sizeOf(context).height;
    final topPadding = MediaQuery.paddingOf(context).top;
    final topOffset = math.max(
      SwiftPageTransitions.sheetMinimumTopOffset,
      topPadding + SwiftPageTransitions.sheetTopOffsetPadding,
    );
    final sheetHeight = screenHeight - topOffset;

    final depth = _getRouteDepthAbove(route);
    final isOffstage = depth >= 3;

    final nextRoute = route.nextRoute;
    final nextScrollSheetRoute = nextRoute is SwiftScrollSheetRoute
        ? nextRoute
        : null;
    final hasSheetAbove =
        nextRoute is SwiftSheetRoute || nextScrollSheetRoute != null;

    return Offstage(
      offstage: isOffstage,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          primary,
          secondary,
          widget.route.sheetExtentListenable,
          if (nextScrollSheetRoute != null)
            nextScrollSheetRoute.sheetExtentListenable,
          ScreenRadiusService.instance,
        ]),
        builder: (context, child) {
          final nextExtent = nextScrollSheetRoute?.sheetExtent;
          final backgroundProgress = hasSheetAbove
              ? secondary.value * _backgroundProgressFor(nextExtent ?? 1.0)
              : 0.0;

          final secondaryOffsetY =
              -backgroundProgress * SwiftPageTransitions.backgroundOffsetStep;
          final minScale = widget.sheetMinScale.clamp(0.0, 1.0).toDouble();
          final scale = 1.0 - (backgroundProgress * (1.0 - minScale));

          final borderRadius = _sheetBorderRadius(context);
          final effectiveTopOffset = topOffset + secondaryOffsetY;

          final sheetBody = Listener(
            onPointerUp: (_) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _snapToNearestStop();
              });
            },
            onPointerCancel: (_) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _snapToNearestStop();
              });
            },
            child: DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: route.resolvedInitialStop.clamp(0.0, 1.0).toDouble(),
              minChildSize: route.resolvedStops.first,
              maxChildSize: route.resolvedStops.last,
              snap: !route.stickySnap,
              snapSizes: route.resolvedStops,
              snapAnimationDuration: route.snapAnimationDuration,
              expand: true,
              builder: (context, scrollController) {
                Widget content = _SwiftScrollSheetScope(
                  notifier: route.sheetController,
                  child: PrimaryScrollController(
                    controller: scrollController,
                    child: MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: widget.child,
                    ),
                  ),
                );

                if (backgroundProgress > 0) {
                  content = Stack(
                    children: [
                      content,
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: borderRadius,
                              color: Colors.black.withAlpha(
                                (backgroundProgress *
                                        SwiftPageTransitions
                                            .sheetBackgroundDimmingOpacity *
                                        255)
                                    .round(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return content;
              },
            ),
          );

          final sheet = Transform.translate(
            offset: Offset(0, (1.0 - primary.value) * sheetHeight),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: sheetBody,
            ),
          );

          return Padding(
            padding: EdgeInsets.only(top: effectiveTopOffset),
            child: sheet,
          );
        },
      ),
    );
  }
}

int _getRouteDepthAbove(Route? route) {
  var depth = 0;
  Route? current = route;
  while (current != null) {
    Route? next;
    if (current is SwiftScrollSheetRoute) {
      next = current.nextRoute;
    } else if (current is SwiftSheetRoute) {
      next = current.nextRoute;
    } else if (current is SwiftPageRoute) {
      next = current.nextRoute;
    }
    if (next == null) break;
    depth++;
    current = next;
  }
  return depth;
}

class _SwiftScrollSheetScope extends InheritedNotifier<SwiftScrollSheetController> {
  const _SwiftScrollSheetScope({
    required super.notifier,
    required super.child,
  });
}

/// A gesture-directing widget that wraps any child element (like a custom header or drag handle)
/// to make it drag-responsive. Translates vertical swipe gestures directly into size/offset updates
/// for the parent [SwiftScrollSheetRoute] and snaps it on release.
class SwiftScrollSheetDragTarget extends StatelessWidget {
  const SwiftScrollSheetDragTarget({
    super.key,
    required this.child,
  });

  /// The child widget (e.g. a header or drag bar) to make draggable.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = SwiftScrollSheetRoute.controllerOf(context);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragUpdate: (details) {
        if (controller != null && controller.isAttached) {
          final double screenHeight = MediaQuery.sizeOf(context).height;
          final double delta = -details.delta.dy / screenHeight;
          controller.jumpTo((controller.value + delta).clamp(0.0, 1.0));
        }
      },
      onVerticalDragEnd: (details) {
        controller?.snapToNearest();
      },
      child: child,
    );
  }
}
