import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:swiftuikit/src/services/screen_radius_service.dart';

const _interactiveZoomBackgroundScaleReduction = 0.085;
const _interactiveZoomFallbackTargetScale = 0.44;
const _interactiveZoomSourceCrossfadeEnd = 0.58;
const _interactiveZoomBottomRevealStart = 0.3;
const _interactiveZoomFlightCurve = Curves.easeInOutCubic;
const _interactiveZoomDragCurve = Curves.easeInOut;

/// Registers the visual origin for [SwiftInteractiveZoomRoute].
///
/// The route resolves the source by [id] for both opening and closing, so a
/// source in a scrollable list can move or rebuild between transitions.
class SwiftInteractiveZoomSource extends StatefulWidget {
  const SwiftInteractiveZoomSource({
    super.key,
    required this.id,
    required this.child,
    this.namespace,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });

  final Object id;
  final Object? namespace;
  final Widget child;
  final BorderRadius borderRadius;

  @override
  State<SwiftInteractiveZoomSource> createState() =>
      _SwiftInteractiveZoomSourceState();
}

class _SwiftInteractiveZoomSourceState
    extends State<SwiftInteractiveZoomSource> {
  final GlobalKey _renderKey = GlobalKey();
  SwiftInteractiveZoomRoute<dynamic>? _route;

  _SwiftInteractiveZoomTag get _tag =>
      _SwiftInteractiveZoomTag(id: widget.id, namespace: widget.namespace);

  @override
  void initState() {
    super.initState();
    _SwiftInteractiveZoomRegistry.instance.registerSource(_tag, this);
  }

  @override
  void didUpdateWidget(covariant SwiftInteractiveZoomSource oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldTag = _SwiftInteractiveZoomTag(
      id: oldWidget.id,
      namespace: oldWidget.namespace,
    );
    if (oldTag != _tag) {
      _SwiftInteractiveZoomRegistry.instance.unregisterSource(oldTag, this);
      _SwiftInteractiveZoomRegistry.instance.registerSource(_tag, this);
    }
  }

  @override
  void dispose() {
    _SwiftInteractiveZoomRegistry.instance.unregisterSource(_tag, this);
    super.dispose();
  }

  void attach(SwiftInteractiveZoomRoute<dynamic> route) {
    if (identical(_route, route)) return;
    setState(() => _route = route);
  }

  void detach(SwiftInteractiveZoomRoute<dynamic> route) {
    if (!identical(_route, route)) return;
    setState(() => _route = null);
  }

  Size? get size {
    final renderObject = _renderKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    return renderObject.size;
  }

  Rect? rectIn(NavigatorState navigator) {
    final renderObject = _renderKey.currentContext?.findRenderObject();
    final navigatorObject = navigator.context.findRenderObject();
    if (renderObject is! RenderBox || navigatorObject is! RenderBox) {
      return null;
    }
    if (!renderObject.hasSize || !renderObject.size.isFinite) return null;
    return MatrixUtils.transformRect(
      renderObject.getTransformTo(navigatorObject),
      Offset.zero & renderObject.size,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _renderKey,
      child: Hero(
        tag: _tag,
        createRectTween: (Rect? begin, Rect? end) =>
            _createInteractiveZoomRectTween(
              begin,
              end,
              route:
                  _route ??
                  _SwiftInteractiveZoomRegistry.instance.lookupRoute(_tag),
            ),
        flightShuttleBuilder: _buildInteractiveZoomHeroFlight,
        placeholderBuilder: _buildInteractiveZoomPlaceholder,
        transitionOnUserGestures: true,
        curve: _interactiveZoomFlightCurve,
        reverseCurve: _interactiveZoomFlightCurve.flipped,
        child: widget.child,
      ),
    );
  }

  Widget _buildInteractiveZoomPlaceholder(
    BuildContext context,
    Size heroSize,
    Widget child,
  ) {
    final route = _route;
    if (route == null) {
      return SizedBox(width: heroSize.width, height: heroSize.height);
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        route.interactionState,
        route.progressAnimation,
      ]),
      builder: (BuildContext context, Widget? unused) {
        if (!route.isInteractive) {
          return SizedBox(width: heroSize.width, height: heroSize.height);
        }
        return SizedBox(width: heroSize.width, height: heroSize.height);
      },
    );
  }
}

Tween<Rect?> _createInteractiveZoomRectTween(
  Rect? begin,
  Rect? end, {
  SwiftInteractiveZoomRoute<dynamic>? route,
}) {
  if (route?.isPopping == true) {
    return _LiveSourceRectTween(begin: begin, end: end, route: route!);
  }
  final correctedEnd = route?.correctSourceRect(end) ?? end;
  return _InteractiveZoomRectTween(begin: begin, end: correctedEnd);
}

class _InteractiveZoomRectTween extends RectTween {
  _InteractiveZoomRectTween({required super.begin, required super.end});

  @override
  Rect? lerp(double t) {
    final beginRect = begin;
    final endRect = end;
    if (beginRect == null || endRect == null) {
      return Rect.lerp(beginRect, endRect, t);
    }
    final bottomProgress = Curves.easeInOut.transform(
      ((t - _interactiveZoomBottomRevealStart) /
              (1.0 - _interactiveZoomBottomRevealStart))
          .clamp(0.0, 1.0)
          .toDouble(),
    );
    return Rect.fromLTRB(
      _lerpDouble(beginRect.left, endRect.left, t),
      _lerpDouble(beginRect.top, endRect.top, t),
      _lerpDouble(beginRect.right, endRect.right, t),
      _lerpDouble(beginRect.bottom, endRect.bottom, bottomProgress),
    );
  }
}

double _lerpDouble(double begin, double end, double t) =>
    begin + (end - begin) * t;

class _LiveSourceRectTween extends RectTween {
  _LiveSourceRectTween({
    required super.begin,
    required super.end,
    required this.route,
  });

  final SwiftInteractiveZoomRoute<dynamic> route;

  @override
  Rect? lerp(double t) => Rect.lerp(
    route.interactiveHandoffRect(begin) ?? begin,
    route.sourceFinalRect ?? end,
    t,
  );
}

Widget _buildInteractiveZoomHeroFlight(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection flightDirection,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final fromHero = fromHeroContext.widget as Hero;
  final toHero = toHeroContext.widget as Hero;
  final tag = fromHero.tag as _SwiftInteractiveZoomTag;
  final source = _SwiftInteractiveZoomRegistry.instance.lookupSource(tag);
  final route = _SwiftInteractiveZoomRegistry.instance.lookupRoute(tag);
  final frozenFromHero = _FrozenHeroChild(
    size: _renderBoxSize(fromHeroContext),
    child: fromHero.child,
  );
  final frozenToHero = _FrozenHeroChild(
    size: _renderBoxSize(toHeroContext) ?? source?.size,
    child: toHero.child,
  );
  final popStart = flightDirection == HeroFlightDirection.pop
      ? animation.value
      : 1.0;
  return AnimatedBuilder(
    animation: animation,
    builder: (BuildContext context, Widget? child) {
      final targetOpacity = SwiftInteractiveZoomRoute.contentOpacity(
        animation.value,
      );
      final toHeroOpacity = flightDirection == HeroFlightDirection.push
          ? targetOpacity
          : 1.0 - targetOpacity;
      final sourceBorderRadius =
          route?.resolvedSourceBorderRadius ??
          source?.widget.borderRadius ??
          BorderRadius.zero;
      final destinationBorderRadius =
          route?.resolvedDestinationBorderRadius ??
          ScreenRadiusService.instance.radius;
      final handoffProgress = flightDirection == HeroFlightDirection.pop
          ? (animation.value / popStart).clamp(0.0, 1.0).toDouble()
          : 0.0;
      final handoffBorderRadius = BorderRadius.lerp(
        destinationBorderRadius,
        sourceBorderRadius,
        route?.heroHandoffProgress ?? 0.0,
      )!;
      final borderRadius = flightDirection == HeroFlightDirection.push
          ? BorderRadius.lerp(
              sourceBorderRadius,
              destinationBorderRadius,
              animation.value,
            )!
          : BorderRadius.lerp(
              sourceBorderRadius,
              handoffBorderRadius,
              handoffProgress,
            )!;
      final fromChild = flightDirection == HeroFlightDirection.push
          ? frozenFromHero
          : frozenFromHero;
      return ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: 1.0 - toHeroOpacity,
              child: Material(
                type: MaterialType.transparency,
                child: fromChild,
              ),
            ),
            Opacity(
              opacity: toHeroOpacity,
              child: Material(
                type: MaterialType.transparency,
                child: frozenToHero,
              ),
            ),
          ],
        ),
      );
    },
  );
}

Size? _renderBoxSize(BuildContext context) {
  final renderObject = context.findRenderObject();
  if (renderObject is! RenderBox || !renderObject.hasSize) return null;
  final size = renderObject.size;
  return size.isFinite && !size.isEmpty ? size : null;
}

class _FrozenHeroChild extends StatelessWidget {
  const _FrozenHeroChild({required this.size, required this.child});

  final Size? size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final frozenSize = size;
    if (frozenSize == null || frozenSize.isEmpty) return child;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final scale = math.max(
          constraints.maxWidth / frozenSize.width,
          constraints.maxHeight / frozenSize.height,
        );
        return OverflowBox(
          alignment: Alignment.topCenter,
          minWidth: 0.0,
          minHeight: 0.0,
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: Transform.scale(
            alignment: Alignment.topCenter,
            scale: scale,
            child: SizedBox(
              width: frozenSize.width,
              height: frozenSize.height,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Makes a source page react to [SwiftInteractiveZoomRoute].
///
/// Wrap the page that owns [SwiftInteractiveZoomSource]. While the zoom route
/// is on top, this widget scales and adopts the physical screen corner radius.
/// It is opt-in and has no effect on other routes.
class SwiftInteractiveZoomBackground extends StatefulWidget {
  const SwiftInteractiveZoomBackground({
    super.key,
    required this.child,
    this.namespace,
  });

  final Widget child;
  final Object? namespace;

  @override
  State<SwiftInteractiveZoomBackground> createState() =>
      _SwiftInteractiveZoomBackgroundState();
}

class _SwiftInteractiveZoomBackgroundState
    extends State<SwiftInteractiveZoomBackground> {
  SwiftInteractiveZoomRoute<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    _SwiftInteractiveZoomRegistry.instance.registerBackground(
      widget.namespace,
      this,
    );
  }

  @override
  void didUpdateWidget(covariant SwiftInteractiveZoomBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.namespace != widget.namespace) {
      _SwiftInteractiveZoomRegistry.instance.unregisterBackground(
        oldWidget.namespace,
        this,
      );
      _SwiftInteractiveZoomRegistry.instance.registerBackground(
        widget.namespace,
        this,
      );
    }
  }

  @override
  void dispose() {
    _SwiftInteractiveZoomRegistry.instance.unregisterBackground(
      widget.namespace,
      this,
    );
    super.dispose();
  }

  void attach(SwiftInteractiveZoomRoute<dynamic> route) {
    if (identical(_route, route)) return;
    setState(() => _route = route);
  }

  void detach(SwiftInteractiveZoomRoute<dynamic> route) {
    if (!identical(_route, route)) return;
    setState(() => _route = null);
  }

  @override
  Widget build(BuildContext context) {
    final route = _route;
    if (route == null) return widget.child;
    final progressAnimation = route.progressAnimation;

    return ColoredBox(
      color: Colors.black,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          progressAnimation,
          route.panProgress,
          route.interactionState,
          ScreenRadiusService.instance,
        ]),
        child: widget.child,
        builder: (BuildContext context, Widget? child) {
          final progress = route.backgroundProgress;
          final radius = BorderRadius.lerp(
            BorderRadius.zero,
            ScreenRadiusService.instance.radius,
            (progress / 0.12).clamp(0.0, 1.0),
          )!;

          return Transform.scale(
            alignment: Alignment.center,
            scale: 1.0 - (_interactiveZoomBackgroundScaleReduction * progress),
            child: ClipRRect(
              borderRadius: radius,
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
          );
        },
      ),
    );
  }
}

/// A standalone, gesture-driven card-to-page zoom transition.
///
/// Unlike [SwiftPageRoute], this route owns its animation and supports an
/// omnidirectional interactive dismissal. Wrap the opening element in
/// [SwiftInteractiveZoomSource] and pass the same [sourceId] here.
class SwiftInteractiveZoomRoute<T> extends PageRoute<T> {
  SwiftInteractiveZoomRoute({
    required this.sourceId,
    required this.builder,
    this.namespace,
    this.sourceBorderRadius,
    this.destinationBorderRadius,
    this.canSwipe = true,
    this.canOnlySwipeFromEdge = false,
    this.backGestureWidth,
    this.verticalDragSensitivity = 1.6,
    this.minInteractiveHeroProgress = 0.15,
    this.customTransitionDuration = const Duration(milliseconds: 420),
    super.settings,
  }) : assert(verticalDragSensitivity > 0.0),
       assert(minInteractiveHeroProgress >= 0.0),
       assert(minInteractiveHeroProgress < 1.0);

  final Object sourceId;
  final Object? namespace;
  final WidgetBuilder builder;
  final BorderRadius? sourceBorderRadius;
  final BorderRadius? destinationBorderRadius;
  final bool canSwipe;
  final bool canOnlySwipeFromEdge;
  final double? backGestureWidth;
  final double verticalDragSensitivity;
  final double minInteractiveHeroProgress;
  final Duration customTransitionDuration;

  final ValueNotifier<Offset> dragOffset = ValueNotifier(Offset.zero);
  final ValueNotifier<bool> interactionState = ValueNotifier(false);
  final ValueNotifier<double> panProgress = ValueNotifier(0.0);
  bool _isCompletingPop = false;
  bool _isPopping = false;
  Duration? _interactivePopDuration;
  Offset? _heroHandoffOffset;
  double? _heroHandoffProgress;
  Size? _lastViewport;

  _SwiftInteractiveZoomSourceState? get _source =>
      _SwiftInteractiveZoomRegistry.instance.lookupSource(
        _SwiftInteractiveZoomTag(id: sourceId, namespace: namespace),
      );

  _SwiftInteractiveZoomBackgroundState? get _background =>
      _SwiftInteractiveZoomRegistry.instance.lookupBackground(namespace);

  BorderRadius get resolvedSourceBorderRadius =>
      sourceBorderRadius ?? _source?.widget.borderRadius ?? BorderRadius.zero;

  BorderRadius get resolvedDestinationBorderRadius =>
      destinationBorderRadius ?? ScreenRadiusService.instance.radius;

  bool get isCompletingPop => _isCompletingPop;

  bool get isInteractive => interactionState.value;

  bool get isPopping => _isPopping;

  double get backgroundProgress {
    if (_isCompletingPop || _isPopping) {
      final curvedProgress = _interactiveZoomFlightCurve.flipped.transform(
        progress,
      );
      final backgroundPhase =
          ((curvedProgress - _interactiveZoomSourceCrossfadeEnd) /
                  (1.0 - _interactiveZoomSourceCrossfadeEnd))
              .clamp(0.0, 1.0)
              .toDouble();
      return (1.0 - (_heroHandoffProgress ?? 0.0)) * backgroundPhase;
    }
    if (isInteractive) return 1.0 - panProgress.value;
    return _interactiveZoomFlightCurve.transform(progress);
  }

  double? get heroHandoffProgress => _heroHandoffProgress;

  Rect? interactiveHandoffRect(Rect? fullRect) {
    final handoffProgress = _heroHandoffProgress;
    final handoffOffset = _heroHandoffOffset;
    final viewport = _lastViewport;
    if (fullRect == null ||
        handoffProgress == null ||
        handoffOffset == null ||
        viewport == null ||
        viewport.isEmpty) {
      return fullRect;
    }
    final scale = _interactiveScale(handoffProgress, viewport);
    final heightFactor = _interactiveClipHeightFactor(
      handoffProgress,
      viewport,
    );
    final center = fullRect.center;
    final left = center.dx + (fullRect.left - center.dx) * scale;
    final top = center.dy + (fullRect.top - center.dy) * scale;
    return Rect.fromLTWH(
      left + handoffOffset.dx,
      top + handoffOffset.dy,
      fullRect.width * scale,
      fullRect.height * scale * heightFactor,
    );
  }

  double get progress => controller?.value ?? 1.0;

  Animation<double> get progressAnimation => controller!;

  Rect? get sourceRect {
    final currentNavigator = navigator;
    if (currentNavigator == null) return null;
    return _source?.rectIn(currentNavigator);
  }

  Rect? get sourceFinalRect {
    final visualRect = sourceRect;
    final sourceSize = _source?.size;
    final navigatorBox = navigator?.context.findRenderObject();
    if (visualRect == null ||
        sourceSize == null ||
        navigatorBox is! RenderBox) {
      return visualRect;
    }
    final scale =
        1.0 - (_interactiveZoomBackgroundScaleReduction * backgroundProgress);
    final center = navigatorBox.size.center(Offset.zero);
    final topLeft = center + (visualRect.topLeft - center) / scale;
    return topLeft & sourceSize;
  }

  Rect? correctSourceRect(Rect? rect) {
    if (rect == null || !_isPopping) return rect;
    final navigatorBox = navigator?.context.findRenderObject();
    if (navigatorBox is! RenderBox || !navigatorBox.hasSize) return rect;
    final scale =
        1.0 - (_interactiveZoomBackgroundScaleReduction * backgroundProgress);
    if (scale == 1.0) return rect;
    final center = navigatorBox.size.center(Offset.zero);
    final topLeft = center + (rect.topLeft - center) / scale;
    final sourceSize = _source?.size;
    return Rect.fromLTWH(
      topLeft.dx,
      topLeft.dy,
      sourceSize?.width ?? rect.width / scale,
      sourceSize?.height ?? rect.height / scale,
    );
  }

  static double contentOpacity(double progress) => Curves.easeInOut.transform(
    ((progress - 0.04) / (_interactiveZoomSourceCrossfadeEnd - 0.04)).clamp(
      0.0,
      1.0,
    ),
  );

  @override
  bool get opaque => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => customTransitionDuration;

  @override
  Duration get reverseTransitionDuration =>
      _interactivePopDuration ?? customTransitionDuration;

  @override
  void install() {
    super.install();
    _SwiftInteractiveZoomRegistry.instance.registerRoute(
      _SwiftInteractiveZoomTag(id: sourceId, namespace: namespace),
      this,
    );
    _source?.attach(this);
  }

  @override
  TickerFuture didPush() {
    final result = super.didPush();
    _background?.attach(this);
    return result;
  }

  @override
  bool didPop(T? result) {
    _isPopping = true;
    return super.didPop(result);
  }

  @override
  void dispose() {
    _SwiftInteractiveZoomRegistry.instance.unregisterRoute(
      _SwiftInteractiveZoomTag(id: sourceId, namespace: namespace),
      this,
    );
    _source?.detach(this);
    _background?.detach(this);
    dragOffset.dispose();
    interactionState.dispose();
    panProgress.dispose();
    super.dispose();
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: Hero(
        tag: _SwiftInteractiveZoomTag(id: sourceId, namespace: namespace),
        createRectTween: (Rect? begin, Rect? end) =>
            _createInteractiveZoomRectTween(begin, end, route: this),
        flightShuttleBuilder: _buildInteractiveZoomHeroFlight,
        transitionOnUserGestures: true,
        curve: _interactiveZoomFlightCurve,
        reverseCurve: _interactiveZoomFlightCurve.flipped,
        child: builder(context),
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
    return _SwiftInteractiveZoomTransition<T>(route: this, child: child);
  }

  void startInteractivePop() {
    if (isInteractive || _isCompletingPop) return;
    final routeController = controller!;
    routeController.stop();
    routeController.value = 1.0;
    dragOffset.value = Offset.zero;
    panProgress.value = 0.0;
    interactionState.value = true;
  }

  void updateInteractivePop(
    Offset offset,
    Size viewport,
    double initialProgressLoss,
  ) {
    final resistedOffset = _resistedOffset(offset, viewport);
    dragOffset.value = resistedOffset;
    _lastViewport = viewport;
    final progressLoss = math
        .max(
          initialProgressLoss + resistedOffset.dx.abs() / viewport.width,
          initialProgressLoss +
              (resistedOffset.dy.abs() / viewport.height) *
                  verticalDragSensitivity,
        )
        .clamp(0.0, 1.0);
    panProgress.value = progressLoss;
  }

  void endInteractivePop(Offset velocity, Offset drag) {
    final velocityInDragDirection =
        velocity.dx * drag.dx + velocity.dy * drag.dy;
    final shouldPop =
        panProgress.value > 0.45 ||
        (velocity.distance > 900.0 && velocityInDragDirection > 0.0);

    if (shouldPop) {
      _isCompletingPop = true;
      _heroHandoffOffset = _boundedTranslation(
        dragOffset.value,
        panProgress.value,
        _lastViewport,
      );
      _heroHandoffProgress = panProgress.value;
      final remainingDistance = 1.0 - panProgress.value;
      final velocityFactor =
          1.0 - (velocity.distance / 3000.0).clamp(0.0, 0.45);
      _interactivePopDuration = Duration(
        milliseconds: math.max(
          160,
          (customTransitionDuration.inMilliseconds *
                  remainingDistance *
                  velocityFactor)
              .round(),
        ),
      );
      controller!.reverseDuration = _interactivePopDuration;
      navigator?.pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isActive) interactionState.value = false;
      });
      return;
    }

    final duration = Duration(
      milliseconds: math.max(
        180,
        (customTransitionDuration.inMilliseconds * panProgress.value).round(),
      ),
    );
    controller!.value = 1.0 - panProgress.value;
    _animateInteractiveProgressTo(1.0, duration).whenComplete(() {
      interactionState.value = false;
    });
  }

  Future<void> _animateInteractiveProgressTo(double target, Duration duration) {
    final routeController = controller!;
    final initialProgress = routeController.value;
    final initialDragOffset = dragOffset.value;
    final progressDistance = (target - initialProgress).abs();

    void syncDragOffset() {
      final completed = progressDistance == 0.0
          ? 1.0
          : ((routeController.value - initialProgress).abs() / progressDistance)
                .clamp(0.0, 1.0)
                .toDouble();
      dragOffset.value = Offset.lerp(
        initialDragOffset,
        Offset.zero,
        completed,
      )!;
      panProgress.value = (1.0 - routeController.value)
          .clamp(0.0, 1.0)
          .toDouble();
    }

    routeController.addListener(syncDragOffset);
    return routeController
        .animateTo(
          target,
          duration: duration,
          curve: _interactiveZoomFlightCurve,
        )
        .whenComplete(() {
          routeController.removeListener(syncDragOffset);
          dragOffset.value = Offset.zero;
          panProgress.value = 0.0;
        });
  }

  Offset _resistedOffset(Offset offset, Size viewport) {
    return Offset(
      _resistedDistance(offset.dx, viewport.width * 0.65),
      _resistedDistance(offset.dy, viewport.height * 0.48),
    );
  }

  double _resistedDistance(double value, double limit) {
    final distance = value.abs();
    final resisted = limit * (1.0 - math.exp(-distance / limit));
    return value.isNegative ? -resisted : resisted;
  }

  double _interactiveTargetScale(Size? viewport) {
    final sourceSize = _source?.size;
    if (viewport == null ||
        viewport.isEmpty ||
        sourceSize == null ||
        sourceSize.isEmpty) {
      return _interactiveZoomFallbackTargetScale;
    }
    return (sourceSize.width / viewport.width).clamp(0.25, 0.92).toDouble();
  }

  double _interactiveScale(double progress, Size? viewport) {
    final curvedProgress = _interactiveZoomDragCurve.transform(
      progress.clamp(0.0, 1.0),
    );
    return _lerpDouble(1.0, _interactiveTargetScale(viewport), curvedProgress);
  }

  double _interactiveClipHeightFactor(double progress, Size viewport) {
    final sourceSize = _source?.size;
    if (sourceSize == null || sourceSize.isEmpty || viewport.isEmpty) {
      return _lerpDouble(1.0, 0.62, progress.clamp(0.0, 1.0));
    }
    final targetScale = _interactiveTargetScale(viewport);
    final targetHeightFactor =
        sourceSize.height / (viewport.height * targetScale);
    return _lerpDouble(
      1.0,
      targetHeightFactor.clamp(0.3, 1.0).toDouble(),
      _interactiveZoomDragCurve.transform(progress.clamp(0.0, 1.0)),
    );
  }

  Offset _boundedTranslation(Offset drag, double progress, Size? viewport) {
    if (viewport == null || viewport.isEmpty) return Offset.zero;
    final scale = _interactiveScale(progress, viewport);
    final horizontalLimit = viewport.width * (1.0 - scale) / 2.0;
    final verticalLimit = viewport.height * (1.0 - scale) / 2.0;
    return Offset(
      (drag.dx * 0.65).clamp(-horizontalLimit, horizontalLimit).toDouble(),
      (drag.dy * 0.65).clamp(-verticalLimit, verticalLimit).toDouble(),
    );
  }
}

class _InteractiveDragClip extends StatelessWidget {
  const _InteractiveDragClip({
    required this.route,
    required this.progress,
    required this.viewport,
    required this.child,
  });

  final SwiftInteractiveZoomRoute<dynamic> route;
  final double progress;
  final Size viewport;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.lerp(
      route.resolvedDestinationBorderRadius,
      route.resolvedSourceBorderRadius,
      progress,
    )!;
    return ClipPath(
      clipper: _InteractiveDragClipper(
        heightFactor: route._interactiveClipHeightFactor(progress, viewport),
        borderRadius: borderRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _InteractiveDragClipper extends CustomClipper<Path> {
  const _InteractiveDragClipper({
    required this.heightFactor,
    required this.borderRadius,
  });

  final double heightFactor;
  final BorderRadius borderRadius;

  @override
  Path getClip(Size size) {
    final rect = Rect.fromLTWH(
      0.0,
      0.0,
      size.width,
      size.height * heightFactor,
    );
    return Path()..addRRect(borderRadius.toRRect(rect));
  }

  @override
  bool shouldReclip(covariant _InteractiveDragClipper oldClipper) =>
      oldClipper.heightFactor != heightFactor ||
      oldClipper.borderRadius != borderRadius;
}

class _SwiftInteractiveZoomTransition<T> extends StatefulWidget {
  const _SwiftInteractiveZoomTransition({
    required this.route,
    required this.child,
  });

  final SwiftInteractiveZoomRoute<T> route;
  final Widget child;

  @override
  State<_SwiftInteractiveZoomTransition<T>> createState() =>
      _SwiftInteractiveZoomTransitionState<T>();
}

class _SwiftInteractiveZoomTransitionState<T>
    extends State<_SwiftInteractiveZoomTransition<T>> {
  _ZoomPanGestureController<T>? _gestureController;

  bool get _canStartGesture {
    final route = widget.route;
    return route.canSwipe &&
        route.isActive &&
        route.isCurrent &&
        !route.isCompletingPop &&
        !route.isFirst &&
        !route.willHandlePopInternally;
  }

  _ZoomPanGestureRecognizer _createRecognizer() {
    return _ZoomPanGestureRecognizer(
        enabledCallback: () => _canStartGesture,
        startedCallback: () => _gestureController != null,
        detectionArea: () {
          if (!widget.route.canOnlySwipeFromEdge) return null;
          return (
            startOffset: 0.0,
            width:
                widget.route.backGestureWidth ??
                MediaQuery.sizeOf(context).width * 0.2,
          );
        },
        debugOwner: this,
      )
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel;
  }

  void _handleDragStart(DragStartDetails details) {
    if (_gestureController != null || !_canStartGesture) return;
    widget.route.startInteractivePop();
    _gestureController = _ZoomPanGestureController<T>(
      route: widget.route,
      initialProgressLoss: 1.0 - widget.route.progress,
    );
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final gestureController = _gestureController;
    if (gestureController == null) return;
    gestureController.update(details.delta, MediaQuery.sizeOf(context));
  }

  void _handleDragEnd(DragEndDetails details) {
    final gestureController = _gestureController;
    if (gestureController == null) return;
    gestureController.end(details.velocity.pixelsPerSecond);
    _gestureController = null;
  }

  void _handleDragCancel() {
    _gestureController?.end(Offset.zero);
    _gestureController = null;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([
            widget.route.progressAnimation,
            widget.route.panProgress,
            widget.route.interactionState,
            widget.route.dragOffset,
            ScreenRadiusService.instance,
          ]),
          child: widget.child,
          builder: (BuildContext context, Widget? child) {
            final route = widget.route;
            if (!route.isInteractive) return child!;

            final viewport = MediaQuery.sizeOf(context);
            if (viewport.isEmpty) return child!;

            final drag = route.dragOffset.value;
            final progress = route.panProgress.value;
            final scale = route._interactiveScale(progress, viewport);
            return Transform.translate(
              offset: route._boundedTranslation(drag, progress, viewport),
              child: Transform.scale(
                alignment: Alignment.center,
                scale: scale,
                child: _InteractiveDragClip(
                  route: route,
                  progress: progress,
                  viewport: viewport,
                  child: IgnorePointer(ignoring: progress < 0.02, child: child),
                ),
              ),
            );
          },
        ),
        Positioned.fill(
          child: RawGestureDetector(
            behavior: HitTestBehavior.translucent,
            gestures: {
              _ZoomPanGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                    _ZoomPanGestureRecognizer
                  >(_createRecognizer, (instance) {}),
            },
          ),
        ),
      ],
    );
  }
}

class _ZoomPanGestureController<T> {
  _ZoomPanGestureController({
    required this.route,
    required this.initialProgressLoss,
  });

  final SwiftInteractiveZoomRoute<T> route;
  final double initialProgressLoss;
  Offset _offset = Offset.zero;

  void update(Offset delta, Size viewport) {
    _offset += delta;
    route.updateInteractivePop(_offset, viewport, initialProgressLoss);
  }

  void end(Offset velocity) => route.endInteractivePop(velocity, _offset);
}

class _ZoomPanGestureRecognizer extends PanGestureRecognizer {
  _ZoomPanGestureRecognizer({
    required this.enabledCallback,
    required this.startedCallback,
    required this.detectionArea,
    super.debugOwner,
  });

  final ValueGetter<bool> enabledCallback;
  final ValueGetter<bool> startedCallback;
  final ValueGetter<({double startOffset, double width})?> detectionArea;

  @override
  void handleEvent(PointerEvent event) {
    if (_shouldHandle(event)) {
      super.handleEvent(event);
    } else {
      stopTrackingPointer(event.pointer);
    }
  }

  bool _shouldHandle(PointerEvent event) {
    if (startedCallback()) return true;
    if (!enabledCallback()) return false;
    final area = detectionArea();
    if (area != null &&
        event is PointerDownEvent &&
        (event.localPosition.dx < area.startOffset ||
            event.localPosition.dx > area.startOffset + area.width)) {
      return false;
    }
    return true;
  }
}

class _SwiftInteractiveZoomRegistry {
  _SwiftInteractiveZoomRegistry._();

  static final instance = _SwiftInteractiveZoomRegistry._();

  final Map<_SwiftInteractiveZoomTag, _SwiftInteractiveZoomSourceState>
  _sources = {};
  final Map<Object?, _SwiftInteractiveZoomBackgroundState> _backgrounds = {};
  final Map<_SwiftInteractiveZoomTag, SwiftInteractiveZoomRoute<dynamic>>
  _routes = {};

  void registerSource(
    _SwiftInteractiveZoomTag tag,
    _SwiftInteractiveZoomSourceState source,
  ) {
    _sources[tag] = source;
  }

  void unregisterSource(
    _SwiftInteractiveZoomTag tag,
    _SwiftInteractiveZoomSourceState source,
  ) {
    if (identical(_sources[tag], source)) _sources.remove(tag);
  }

  _SwiftInteractiveZoomSourceState? lookupSource(
    _SwiftInteractiveZoomTag tag,
  ) => _sources[tag];

  void registerRoute(
    _SwiftInteractiveZoomTag tag,
    SwiftInteractiveZoomRoute<dynamic> route,
  ) {
    _routes[tag] = route;
  }

  void unregisterRoute(
    _SwiftInteractiveZoomTag tag,
    SwiftInteractiveZoomRoute<dynamic> route,
  ) {
    if (identical(_routes[tag], route)) _routes.remove(tag);
  }

  SwiftInteractiveZoomRoute<dynamic>? lookupRoute(
    _SwiftInteractiveZoomTag tag,
  ) => _routes[tag];

  void registerBackground(
    Object? namespace,
    _SwiftInteractiveZoomBackgroundState background,
  ) {
    _backgrounds[namespace] = background;
  }

  void unregisterBackground(
    Object? namespace,
    _SwiftInteractiveZoomBackgroundState background,
  ) {
    if (identical(_backgrounds[namespace], background)) {
      _backgrounds.remove(namespace);
    }
  }

  _SwiftInteractiveZoomBackgroundState? lookupBackground(Object? namespace) =>
      _backgrounds[namespace];
}

class _SwiftInteractiveZoomTag {
  const _SwiftInteractiveZoomTag({required this.id, required this.namespace});

  final Object id;
  final Object? namespace;

  @override
  bool operator ==(Object other) =>
      other is _SwiftInteractiveZoomTag &&
      other.id == id &&
      other.namespace == namespace;

  @override
  int get hashCode => Object.hash(id, namespace);
}
