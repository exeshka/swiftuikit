import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_physics/flutter_physics.dart';

import 'package:swiftuikit/src/services/screen_radius_service.dart';

const _zoomBackgroundScaleReduction = 0.06;
const _zoomBackgroundDimmingOpacity = 0.1;
const _zoomFallbackScale = 0.94;
const _zoomMaxDragScaleReduction = 0.14;
const _zoomDismissThreshold = 0.42;
const _zoomMinFlingVelocity = 500.0;
const _zoomFallbackRadius = 38.0;
const _zoomPushSourceFadeEnd = 0.38;
const _zoomPopSourceFadeStart = 0.62;
const _zoomDefaultTransitionDuration = Duration(milliseconds: 560);
final _zoomForwardSpring = Spring.withDamping(
  dampingFraction: 0.84,
  duration: _zoomDefaultTransitionDuration,
);
final _zoomReverseSpring = Spring.withDamping(
  dampingFraction: 0.87,
  duration: _zoomDefaultTransitionDuration,
);
final _zoomSnapSpring = Spring.withDamping(
  dampingFraction: 0.92,
  duration: const Duration(milliseconds: 500),
);
final Curve _zoomFlightCurve = _ClampedCurve(_zoomForwardSpring);
final Curve _zoomHeroReverseCurve = _ClampedCurve(_zoomReverseSpring.flipped);

Curve _createZoomReverseCurve(
  Duration duration, {
  double initialVelocity = 0.0,
}) {
  return _ClampedCurve(
    Spring.withDamping(
      dampingFraction: 0.87,
      duration: duration > Duration.zero
          ? duration
          : const Duration(milliseconds: 1),
      initialVelocity: initialVelocity,
    ).flipped,
  );
}

class _ClampedCurve extends Curve {
  const _ClampedCurve(this.parent);

  final Curve parent;

  @override
  double transformInternal(double t) {
    return parent.transform(t).clamp(0.0, 1.0).toDouble();
  }
}

/// Controls which gesture axis can dismiss a [SwiftZoomRoute].
enum SwiftZoomDismissDirection {
  /// Accepts horizontal drags and vertical drags in either direction.
  any,

  /// Keeps vertical starts available for scroll views and vertical PageViews.
  ///
  /// After a horizontal start wins, the page still follows both axes.
  horizontal,

  /// Accepts only downward vertical drags.
  downward,
}

/// A reusable element-to-element zoom participant.
///
/// Place matching IDs around a source element and the complete destination
/// page. The destination ID can change while the route is open, allowing a
/// PageView to dismiss into the source for its currently selected item.
class SwiftZoomHero extends StatefulWidget {
  const SwiftZoomHero({
    super.key,
    required this.id,
    required this.child,
    this.namespace,
    this.active = true,
    this.borderRadius = BorderRadius.zero,
  });

  final Object id;
  final Object? namespace;
  final Widget child;
  final bool active;
  final BorderRadius borderRadius;

  @override
  State<SwiftZoomHero> createState() => _SwiftZoomHeroState();
}

class _SwiftZoomHeroState extends State<SwiftZoomHero> {
  final GlobalKey _renderKey = GlobalKey();
  final GlobalKey _flightChildKey = GlobalKey();
  _SwiftZoomTag? _registeredSourceTag;
  SwiftZoomRoute<dynamic>? _destinationRoute;
  bool _sourceSuppressed = false;
  bool _visualUpdateScheduled = false;
  bool _destinationUpdateScheduled = false;
  int _heroGeneration = 0;
  int _activeFlights = 0;
  bool _protectActiveFlight = false;
  bool _flightProtectionScheduled = false;

  _SwiftZoomTag get _tag =>
      _SwiftZoomTag(id: widget.id, namespace: widget.namespace);

  BorderRadius get borderRadius => widget.borderRadius;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncRegistryRole();
  }

  @override
  void didUpdateWidget(covariant SwiftZoomHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id ||
        oldWidget.namespace != widget.namespace ||
        oldWidget.active != widget.active) {
      _syncRegistryRole();
    }
  }

  @override
  void dispose() {
    final sourceTag = _registeredSourceTag;
    if (sourceTag != null) {
      _SwiftZoomHeroRegistry.instance.unregisterSource(sourceTag, this);
    }
    final destinationRoute = _destinationRoute;
    if (destinationRoute != null) {
      _SwiftZoomHeroRegistry.instance.clearDestination(destinationRoute);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sourceSuppressed = _registeredSourceTag != null && _sourceSuppressed;

    return RepaintBoundary(
      key: _renderKey,
      child: IgnorePointer(
        ignoring: sourceSuppressed,
        child: Opacity(
          opacity: sourceSuppressed ? 0.0 : 1.0,
          child: HeroMode(
            enabled: widget.active && !_protectActiveFlight,
            child: Hero(
              key: ValueKey(_heroGeneration),
              tag: _tag,
              createRectTween: (Rect? begin, Rect? end) =>
                  RectTween(begin: begin, end: end),
              flightShuttleBuilder: _buildSwiftZoomFlight,
              placeholderBuilder: _buildPlaceholder,
              transitionOnUserGestures: true,
              curve: _zoomForwardSpring,
              reverseCurve: _destinationRoute == null
                  ? _zoomHeroReverseCurve
                  : _SwiftZoomRouteReverseCurve(_destinationRoute!),
              child: KeyedSubtree(key: _flightChildKey, child: widget.child),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context, Size heroSize, Widget child) {
    return SizedBox.fromSize(size: heroSize);
  }

  void _syncRegistryRole() {
    final route = _SwiftZoomRouteScope.maybeOf(context)?.route;
    final nextDestinationRoute = widget.active ? route : null;
    final nextSourceTag = widget.active && route == null ? _tag : null;

    if (!identical(_destinationRoute, nextDestinationRoute)) {
      final oldDestinationRoute = _destinationRoute;
      _destinationRoute = nextDestinationRoute;
      if (oldDestinationRoute != null) {
        _SwiftZoomHeroRegistry.instance.clearDestination(oldDestinationRoute);
      }
    }

    if (_registeredSourceTag != nextSourceTag) {
      final oldSourceTag = _registeredSourceTag;
      _registeredSourceTag = nextSourceTag;
      if (oldSourceTag != null) {
        _SwiftZoomHeroRegistry.instance.unregisterSource(oldSourceTag, this);
      }
      if (nextSourceTag != null) {
        _SwiftZoomHeroRegistry.instance.registerSource(nextSourceTag, this);
      } else {
        _setSourceSuppressed(false);
      }
    }

    if (nextDestinationRoute != null) {
      _scheduleDestinationUpdate();
    }
  }

  void _scheduleDestinationUpdate() {
    if (_destinationUpdateScheduled) return;
    _destinationUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _destinationUpdateScheduled = false;
      if (!mounted) return;
      final destinationRoute = _destinationRoute;
      if (destinationRoute != null) {
        _SwiftZoomHeroRegistry.instance.setDestination(destinationRoute, _tag);
      }
    });
  }

  void _setSourceSuppressed(bool value) {
    if (_sourceSuppressed == value) return;
    _sourceSuppressed = value;
    _scheduleVisualUpdate();
  }

  void _beginFlight() {
    _activeFlights += 1;
  }

  void _endFlight() {
    if (_activeFlights == 0) return;
    _activeFlights -= 1;
    if (_activeFlights == 0 && _registeredSourceTag != null) {
      _heroGeneration += 1;
    }
    _scheduleVisualUpdate();
  }

  void _scheduleVisualUpdate() {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase !=
        SchedulerPhase.persistentCallbacks) {
      setState(() {});
      return;
    }
    if (_visualUpdateScheduled) return;
    _visualUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visualUpdateScheduled = false;
      if (mounted) setState(() {});
    });
  }

  void protectActiveFlight() {
    if (_protectActiveFlight || _flightProtectionScheduled) return;
    _flightProtectionScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_flightProtectionScheduled) return;
      _flightProtectionScheduled = false;
      setState(() => _protectActiveFlight = true);
    });
  }

  void releaseActiveFlight() {
    _flightProtectionScheduled = false;
    if (!mounted || !_protectActiveFlight) return;
    setState(() => _protectActiveFlight = false);
  }
}

Widget _buildSwiftZoomFlight(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection flightDirection,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final fromHero = fromHeroContext.widget as Hero;
  final toHero = toHeroContext.widget as Hero;
  final fromState = fromHeroContext
      .findAncestorStateOfType<_SwiftZoomHeroState>();
  final toState = toHeroContext.findAncestorStateOfType<_SwiftZoomHeroState>();
  final participants = <_SwiftZoomHeroState>{?fromState, ?toState}.toList();
  for (final participant in participants) {
    participant._beginFlight();
  }
  if (flightDirection == HeroFlightDirection.pop) {
    final destinationRoute = fromState?._destinationRoute;
    if (destinationRoute != null) {
      _SwiftZoomHeroRegistry.instance.clearDestination(destinationRoute);
    }
  }

  return _SwiftZoomFlight(
    animation: animation,
    direction: flightDirection,
    fromSize: _renderBoxSize(fromHeroContext),
    toSize: _renderBoxSize(toHeroContext),
    fromChild: _captureHeroChild(fromHeroContext, fromHero.child),
    toChild: _captureHeroChild(toHeroContext, toHero.child),
    fromRadius: fromState?.borderRadius ?? BorderRadius.zero,
    toRadius: toState?.borderRadius ?? BorderRadius.zero,
    protectedDestination: flightDirection == HeroFlightDirection.pop
        ? toState
        : null,
    participants: participants,
  );
}

Widget _captureHeroChild(BuildContext context, Widget child) {
  Widget result = InheritedTheme.captureAll(context, child);
  final mediaQuery = MediaQuery.maybeOf(context);
  if (mediaQuery != null) {
    result = MediaQuery(data: mediaQuery, child: result);
  }
  return result;
}

Size? _renderBoxSize(BuildContext context) {
  final renderObject = context.findRenderObject();
  if (renderObject is! RenderBox || !renderObject.hasSize) return null;
  final size = renderObject.size;
  return size.isFinite && !size.isEmpty ? size : null;
}

class _SwiftZoomFlight extends StatefulWidget {
  const _SwiftZoomFlight({
    required this.animation,
    required this.direction,
    required this.fromSize,
    required this.toSize,
    required this.fromChild,
    required this.toChild,
    required this.fromRadius,
    required this.toRadius,
    required this.protectedDestination,
    required this.participants,
  });

  final Animation<double> animation;
  final HeroFlightDirection direction;
  final Size? fromSize;
  final Size? toSize;
  final Widget fromChild;
  final Widget toChild;
  final BorderRadius fromRadius;
  final BorderRadius toRadius;
  final _SwiftZoomHeroState? protectedDestination;
  final List<_SwiftZoomHeroState> participants;

  @override
  State<_SwiftZoomFlight> createState() => _SwiftZoomFlightState();
}

class _SwiftZoomFlightState extends State<_SwiftZoomFlight> {
  @override
  void initState() {
    super.initState();
    widget.protectedDestination?.protectActiveFlight();
    widget.animation.addStatusListener(_handleAnimationStatus);
  }

  @override
  void didUpdateWidget(covariant _SwiftZoomFlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.participants, widget.participants)) {
      for (final participant in oldWidget.participants) {
        participant._endFlight();
      }
    }
    if (identical(oldWidget.animation, widget.animation) &&
        identical(
          oldWidget.protectedDestination,
          widget.protectedDestination,
        )) {
      return;
    }
    oldWidget.animation.removeStatusListener(_handleAnimationStatus);
    oldWidget.protectedDestination?.releaseActiveFlight();
    widget.protectedDestination?.protectActiveFlight();
    widget.animation.addStatusListener(_handleAnimationStatus);
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_handleAnimationStatus);
    widget.protectedDestination?.releaseActiveFlight();
    for (final participant in widget.participants) {
      participant._endFlight();
    }
    super.dispose();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (!status.isAnimating) {
      widget.protectedDestination?.releaseActiveFlight();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (BuildContext context, Widget? child) {
        final routeProgress = widget.animation.value.clamp(0.0, 1.0).toDouble();
        final flightProgress = widget.direction == HeroFlightDirection.push
            ? routeProgress
            : 1.0 - routeProgress;
        final borderRadius = BorderRadius.lerp(
          widget.fromRadius,
          widget.toRadius,
          flightProgress,
        )!;
        final shadowProgress = 4.0 * flightProgress * (1.0 - flightProgress);
        final sourceOpacity = switch (widget.direction) {
          HeroFlightDirection.push =>
            1.0 -
                const Interval(
                  0.0,
                  _zoomPushSourceFadeEnd,
                  curve: Curves.easeOutCubic,
                ).transform(flightProgress),
          HeroFlightDirection.pop => const Interval(
            _zoomPopSourceFadeStart,
            1.0,
            curve: Curves.easeInCubic,
          ).transform(flightProgress),
        };
        final pageSize = widget.direction == HeroFlightDirection.push
            ? widget.toSize
            : widget.fromSize;
        final pageChild = widget.direction == HeroFlightDirection.push
            ? widget.toChild
            : widget.fromChild;
        final sourceSize = widget.direction == HeroFlightDirection.push
            ? widget.fromSize
            : widget.toSize;
        final sourceChild = widget.direction == HeroFlightDirection.push
            ? widget.fromChild
            : widget.toChild;

        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24 * shadowProgress),
                blurRadius: 36.0 * shadowProgress,
                spreadRadius: shadowProgress,
                offset: Offset(0.0, 12.0 * shadowProgress),
              ),
            ],
          ),
          child: ClipRSuperellipse(
            borderRadius: borderRadius,
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Material(
                  type: MaterialType.transparency,
                  child: _FrozenZoomHeroChild(size: pageSize, child: pageChild),
                ),
                Opacity(
                  opacity: sourceOpacity,
                  child: Material(
                    type: MaterialType.transparency,
                    child: _FrozenZoomHeroChild(
                      size: sourceSize,
                      child: sourceChild,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FrozenZoomHeroChild extends StatelessWidget {
  const _FrozenZoomHeroChild({required this.size, required this.child});

  final Size? size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final frozenSize = size;
    if (frozenSize == null || frozenSize.isEmpty) return child;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final width = constraints.maxWidth;
        if (!width.isFinite || width <= 0.0) return child;

        return OverflowBox(
          alignment: Alignment.topCenter,
          minWidth: 0.0,
          minHeight: 0.0,
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: Transform.scale(
            scale: width / frozenSize.width,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.medium,
            child: SizedBox.fromSize(size: frozenSize, child: child),
          ),
        );
      },
    );
  }
}

/// A lightweight route for [SwiftZoomHero] transitions.
///
/// The route owns background treatment, whole-page drag, and fallback scale.
/// Element matching and dynamic destination selection remain entirely inside
/// [SwiftZoomHero].
class SwiftZoomRoute<T> extends PageRoute<T> {
  SwiftZoomRoute({
    required this.builder,
    this.enableDrag = true,
    this.dismissDirection = SwiftZoomDismissDirection.any,
    Duration transitionDuration = _zoomDefaultTransitionDuration,
    super.settings,
  }) : _transitionDuration = transitionDuration,
       _reverseHeroCurve = _createZoomReverseCurve(transitionDuration);

  final WidgetBuilder builder;
  final bool enableDrag;
  final SwiftZoomDismissDirection dismissDirection;
  final Duration _transitionDuration;
  final ValueNotifier<Offset> _dragOffset = ValueNotifier(Offset.zero);
  final ValueNotifier<double> _dragProgress = ValueNotifier(0.0);

  Curve _reverseHeroCurve;
  bool _isPopping = false;

  bool get isPopping => _isPopping;

  AnimationController? get routeController => controller;

  @override
  bool get opaque => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => _transitionDuration;

  @override
  Duration get reverseTransitionDuration => _transitionDuration;

  @override
  DelegatedTransitionBuilder? get delegatedTransition {
    return (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      bool allowSnapshotting,
      Widget? child,
    ) {
      final listenable = Listenable.merge([secondaryAnimation, _dragProgress]);
      final screenRadius = _screenBorderRadius;

      return AnimatedBuilder(
        animation: listenable,
        child: child,
        builder: (BuildContext context, Widget? child) {
          final transitionProgress = _zoomFlightCurve.transform(
            secondaryAnimation.value.clamp(0.0, 1.0).toDouble(),
          );
          final progress = transitionProgress * (1.0 - _dragProgress.value);
          final hasRadius = progress > 0.0;

          return Transform.scale(
            scale: 1.0 - _zoomBackgroundScaleReduction * progress,
            alignment: Alignment.center,
            child: ClipRSuperellipse(
              borderRadius: hasRadius ? screenRadius : BorderRadius.zero,
              clipBehavior: hasRadius ? Clip.antiAlias : Clip.none,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  child!,
                  IgnorePointer(
                    child: ColoredBox(
                      color: Colors.black.withValues(
                        alpha: _zoomBackgroundDimmingOpacity * progress,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    };
  }

  @override
  bool didPop(T? result) {
    _isPopping = true;
    changedInternalState();
    return super.didPop(result);
  }

  @override
  void dispose() {
    _dragOffset.dispose();
    _dragProgress.dispose();
    super.dispose();
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _SwiftZoomRouteScope(
      route: this,
      child: Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        child: ValueListenableBuilder<Offset>(
          valueListenable: _dragOffset,
          child: builder(context),
          builder: (BuildContext context, Offset offset, Widget? child) {
            final screenSize = MediaQuery.sizeOf(context);
            final progress = _dragProgressFor(
              offset,
              screenSize,
              dismissDirection,
            );
            final scale = 1.0 - _zoomMaxDragScaleReduction * progress;
            final isDragging = progress > 0.0;

            Widget result = ClipRSuperellipse(
              borderRadius: isDragging
                  ? _screenBorderRadius
                  : BorderRadius.zero,
              clipBehavior: isDragging ? Clip.antiAlias : Clip.none,
              child: child,
            );
            result = Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: result,
            );
            result = Transform.translate(offset: offset, child: result);

            return result;
          },
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fallbackAnimation = CurvedAnimation(
      parent: animation,
      curve: _zoomFlightCurve,
      reverseCurve: _reverseHeroCurve,
    );
    Widget content = FadeTransition(
      opacity: fallbackAnimation,
      child: ScaleTransition(
        scale: Tween<double>(
          begin: _zoomFallbackScale,
          end: 1.0,
        ).animate(fallbackAnimation),
        filterQuality: FilterQuality.medium,
        child: child,
      ),
    );

    if (enableDrag) {
      content = _SwiftZoomDraggable(route: this, child: content);
    }

    return IgnorePointer(ignoring: _isPopping, child: content);
  }

  void updateDragOffset(Offset offset, Size viewport) {
    _dragOffset.value = offset;
    _dragProgress.value = _dragProgressFor(offset, viewport, dismissDirection);
  }

  void popInteractively(Offset velocity, Size viewport) {
    final currentNavigator = navigator;
    if (currentNavigator == null || !currentNavigator.context.mounted) return;

    final normalizedVelocity =
        velocity.distance / viewport.shortestSide.clamp(1.0, double.infinity);
    _reverseHeroCurve = _createZoomReverseCurve(
      _transitionDuration,
      initialVelocity: normalizedVelocity.clamp(0.0, 8.0).toDouble(),
    );

    currentNavigator.pop();
  }
}

double _dragProgressFor(
  Offset offset,
  Size viewport,
  SwiftZoomDismissDirection direction,
) {
  final normalizedX =
      offset.dx.abs() / viewport.width.clamp(1.0, double.infinity);
  final normalizedY =
      offset.dy.abs() / viewport.height.clamp(1.0, double.infinity);
  final distance = switch (direction) {
    SwiftZoomDismissDirection.any || SwiftZoomDismissDirection.horizontal =>
      math.sqrt(normalizedX * normalizedX + normalizedY * normalizedY),
    SwiftZoomDismissDirection.downward => normalizedY,
  };
  return (distance / _zoomDismissThreshold).clamp(0.0, 1.0).toDouble();
}

BorderRadius get _screenBorderRadius {
  final radius = ScreenRadiusService.instance.radius;
  return radius == BorderRadius.zero
      ? const BorderRadius.all(Radius.circular(_zoomFallbackRadius))
      : radius;
}

class _SwiftZoomRouteReverseCurve extends Curve {
  const _SwiftZoomRouteReverseCurve(this.route);

  final SwiftZoomRoute<dynamic> route;

  @override
  double transformInternal(double t) => route._reverseHeroCurve.transform(t);
}

class _SwiftZoomRouteScope extends InheritedWidget {
  const _SwiftZoomRouteScope({required this.route, required super.child});

  final SwiftZoomRoute<dynamic> route;

  static _SwiftZoomRouteScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_SwiftZoomRouteScope>();
  }

  @override
  bool updateShouldNotify(_SwiftZoomRouteScope oldWidget) {
    return !identical(route, oldWidget.route);
  }
}

class _SwiftZoomDraggable extends StatefulWidget {
  const _SwiftZoomDraggable({required this.route, required this.child});

  final SwiftZoomRoute<dynamic> route;
  final Widget child;

  @override
  State<_SwiftZoomDraggable> createState() => _SwiftZoomDraggableState();
}

class _SwiftZoomDraggableState extends State<_SwiftZoomDraggable>
    with SingleTickerProviderStateMixin {
  late final PhysicsController2D _snapController;
  Offset _dragOffset = Offset.zero;
  Offset _snapOrigin = Offset.zero;
  bool _isSnapping = false;
  bool _pushComplete = false;

  @override
  void initState() {
    super.initState();
    _pushComplete = widget.route.routeController?.isCompleted ?? false;
    _snapController = PhysicsController2D.unbounded(
      vsync: this,
      defaultPhysics: Simulation2D(_zoomSnapSpring, _zoomSnapSpring),
    );
    _snapController.addListener(_handleSnapUpdate);
    _snapController.addStatusListener(_handleSnapStatus);
    widget.route.routeController?.addStatusListener(_handleRouteStatus);
  }

  @override
  void didUpdateWidget(covariant _SwiftZoomDraggable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(widget.route, oldWidget.route)) return;
    oldWidget.route.routeController?.removeStatusListener(_handleRouteStatus);
    widget.route.routeController?.addStatusListener(_handleRouteStatus);
    _pushComplete = widget.route.routeController?.isCompleted ?? false;
  }

  @override
  void dispose() {
    widget.route.routeController?.removeStatusListener(_handleRouteStatus);
    _snapController
      ..removeListener(_handleSnapUpdate)
      ..removeStatusListener(_handleSnapStatus)
      ..dispose();
    super.dispose();
  }

  void _handleRouteStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _pushComplete = true;
    }
  }

  void _handleSnapUpdate() {
    if (!_isSnapping || !mounted) return;
    _dragOffset = Offset(
      _clampSnapAxis(_snapController.value.dx, _snapOrigin.dx),
      _clampSnapAxis(_snapController.value.dy, _snapOrigin.dy),
    );
    widget.route.updateDragOffset(_dragOffset, MediaQuery.sizeOf(context));
  }

  void _handleSnapStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    _isSnapping = false;
    _dragOffset = Offset.zero;
    widget.route.updateDragOffset(Offset.zero, MediaQuery.sizeOf(context));
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_isSnapping) {
      _isSnapping = false;
      _snapController.stop();
      _dragOffset = _snapController.value;
    }
    if (!_pushComplete || widget.route.isPopping) return;

    final DragGestureRecognizer recognizer =
        switch (widget.route.dismissDirection) {
          SwiftZoomDismissDirection.any => PanGestureRecognizer(),
          SwiftZoomDismissDirection.horizontal =>
            _HorizontalStartPanGestureRecognizer(),
          SwiftZoomDismissDirection.downward => VerticalDragGestureRecognizer(),
        };
    recognizer
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel
      ..addPointer(event);
  }

  void _handleDragStart(DragStartDetails details) {}

  void _handleDragUpdate(DragUpdateDetails details) {
    if (widget.route.isPopping) return;

    final nextOffset = switch (widget.route.dismissDirection) {
      SwiftZoomDismissDirection.any => _dragOffset + details.delta,
      SwiftZoomDismissDirection.horizontal => Offset(
        _dragOffset.dx + details.delta.dx,
        _dragOffset.dy + details.delta.dy,
      ),
      SwiftZoomDismissDirection.downward => Offset(
        0.0,
        (_dragOffset.dy + details.delta.dy).clamp(0.0, double.infinity),
      ),
    };
    _dragOffset = nextOffset;
    widget.route.updateDragOffset(nextOffset, MediaQuery.sizeOf(context));
  }

  void _handleDragEnd(DragEndDetails details) {
    if (widget.route.isPopping) return;

    final viewport = MediaQuery.sizeOf(context);
    final velocity = details.velocity.pixelsPerSecond;
    if (_shouldDismiss(velocity, viewport)) {
      widget.route.popInteractively(velocity, viewport);
      return;
    }

    _isSnapping = true;
    _snapOrigin = _dragOffset;
    _snapController.value = _dragOffset;
    _snapController.animateTo(
      Offset.zero,
      velocityDelta: details.velocity.pixelsPerSecond,
    );
  }

  bool _shouldDismiss(Offset velocity, Size viewport) {
    return switch (widget.route.dismissDirection) {
      SwiftZoomDismissDirection.horizontal =>
        velocity.dx.abs() >= _zoomMinFlingVelocity ||
            _dragOffset.dx.abs() / viewport.width >= _zoomDismissThreshold,
      SwiftZoomDismissDirection.downward =>
        velocity.dy >= _zoomMinFlingVelocity ||
            _dragOffset.dy / viewport.height >= _zoomDismissThreshold,
      SwiftZoomDismissDirection.any =>
        velocity.dx.abs() >= _zoomMinFlingVelocity ||
            velocity.dy.abs() >= _zoomMinFlingVelocity ||
            _dragProgressFor(
                  _dragOffset,
                  viewport,
                  SwiftZoomDismissDirection.any,
                ) >=
                1.0,
    };
  }

  void _handleDragCancel() {
    if (widget.route.isPopping) return;
    _isSnapping = true;
    _snapOrigin = _dragOffset;
    _snapController.value = _dragOffset;
    _snapController.animateTo(Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}

double _clampSnapAxis(double value, double origin) {
  if (origin > 0.0) return math.max(0.0, value);
  if (origin < 0.0) return math.min(0.0, value);
  return 0.0;
}

class _HorizontalStartPanGestureRecognizer extends PanGestureRecognizer {
  Offset _pendingOffset = Offset.zero;
  bool _accepted = false;

  @override
  void acceptGesture(int pointer) {
    _accepted = true;
    super.acceptGesture(pointer);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerDownEvent) {
      _pendingOffset = Offset.zero;
      _accepted = false;
    } else if (!_accepted && event is PointerMoveEvent) {
      _pendingOffset += event.delta;
      final slop = computeHitSlop(event.kind, gestureSettings);
      if (_pendingOffset.distance > slop) {
        if (_pendingOffset.dx.abs() <= _pendingOffset.dy.abs()) {
          resolve(GestureDisposition.rejected);
          stopTrackingPointer(event.pointer);
          return;
        }
        resolve(GestureDisposition.accepted);
      }
    }
    super.handleEvent(event);
  }
}

class _SwiftZoomHeroRegistry {
  _SwiftZoomHeroRegistry._();

  static final instance = _SwiftZoomHeroRegistry._();

  final Map<_SwiftZoomTag, Set<_SwiftZoomHeroState>> _sources = {};
  final Map<SwiftZoomRoute<dynamic>, _SwiftZoomTag> _destinations = {};
  final Map<_SwiftZoomTag, Set<SwiftZoomRoute<dynamic>>> _destinationOwners =
      {};

  void registerSource(_SwiftZoomTag tag, _SwiftZoomHeroState state) {
    _sources.putIfAbsent(tag, () => {}).add(state);
    state._setSourceSuppressed(_destinationOwners[tag]?.isNotEmpty ?? false);
  }

  void unregisterSource(_SwiftZoomTag tag, _SwiftZoomHeroState state) {
    final states = _sources[tag];
    states?.remove(state);
    if (states?.isEmpty ?? false) {
      _sources.remove(tag);
    }
    state._setSourceSuppressed(false);
  }

  void setDestination(SwiftZoomRoute<dynamic> route, _SwiftZoomTag tag) {
    final oldTag = _destinations[route];
    if (oldTag == tag) return;

    if (oldTag != null) {
      final owners = _destinationOwners[oldTag];
      owners?.remove(route);
      if (owners?.isEmpty ?? false) {
        _destinationOwners.remove(oldTag);
      }
      _notifySources(oldTag);
    }

    _destinations[route] = tag;
    _destinationOwners.putIfAbsent(tag, () => {}).add(route);
    _notifySources(tag);
  }

  void clearDestination(SwiftZoomRoute<dynamic> route) {
    final tag = _destinations.remove(route);
    if (tag == null) return;

    final owners = _destinationOwners[tag];
    owners?.remove(route);
    if (owners?.isEmpty ?? false) {
      _destinationOwners.remove(tag);
    }
    _notifySources(tag);
  }

  void _notifySources(_SwiftZoomTag tag) {
    final suppressed = _destinationOwners[tag]?.isNotEmpty ?? false;
    for (final source in List.of(_sources[tag] ?? const {})) {
      source._setSourceSuppressed(suppressed);
    }
  }
}

class _SwiftZoomTag {
  const _SwiftZoomTag({required this.id, required this.namespace});

  final Object id;
  final Object? namespace;

  @override
  bool operator ==(Object other) {
    return other is _SwiftZoomTag &&
        other.id == id &&
        other.namespace == namespace;
  }

  @override
  int get hashCode => Object.hash(id, namespace);
}
