import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:swiftuikit/src/services/screen_radius_service.dart';

const _interactiveZoomBackgroundScaleReduction = 0.085;
const _interactiveZoomSourceCrossfadeEnd = 0.65;
const _interactiveZoomFlightCurve = Curves.easeInOutCubic;
const _interactiveZoomDismissThreshold = 0.3;
const _interactiveZoomMinFlingVelocity = 500.0;
const _interactiveZoomMaxScaleReduction = 0.15;
const _interactiveZoomFallbackRadius = 38.0;

/// Registers the visual origin for [SwiftInteractiveZoomRoute].
///
/// The route resolves the source by [id] for both opening and closing, so a
/// source in a scrollable list can move or rebuild between transitions.
/// During the hero flight the source card is replaced by an empty placeholder
/// of the same size so that it visually disappears from the source page.
class SwiftInteractiveZoomSource extends StatefulWidget {
  const SwiftInteractiveZoomSource({
    super.key,
    required this.id,
    required this.child,
    this.namespace,
  });

  final Object id;
  final Object? namespace;
  final Widget child;

  @override
  State<SwiftInteractiveZoomSource> createState() =>
      _SwiftInteractiveZoomSourceState();
}

class _SwiftInteractiveZoomSourceState
    extends State<SwiftInteractiveZoomSource> {
  final GlobalKey _renderKey = GlobalKey();
  Size? _capturedSize;

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

  Size? get size => _capturedSize;

  Rect? rectIn(NavigatorState navigator) {
    if (!navigator.context.mounted) return null;
    final currentSize = _capturedSize;
    final ctx = _renderKey.currentContext;
    if (ctx == null || !ctx.mounted || currentSize == null) return null;
    final renderObject = ctx.findRenderObject();
    final navigatorObject = navigator.context.findRenderObject();
    if (renderObject is! RenderBox || navigatorObject is! RenderBox) {
      return null;
    }
    if (!renderObject.hasSize || !renderObject.size.isFinite) return null;
    return MatrixUtils.transformRect(
      renderObject.getTransformTo(navigatorObject),
      Offset.zero & currentSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _renderKey,
      child: Hero(
        tag: _tag,
        createRectTween: (Rect? begin, Rect? end) =>
            RectTween(begin: begin, end: end),
        flightShuttleBuilder: _buildInteractiveZoomHeroFlight,
        placeholderBuilder: _buildPlaceholder,
        transitionOnUserGestures: true,
        curve: _interactiveZoomFlightCurve,
        reverseCurve: _interactiveZoomFlightCurve.flipped,
        child: widget.child,
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context, Size heroSize, Widget child) {
    _capturedSize ??= heroSize;
    return SizedBox(width: heroSize.width, height: heroSize.height);
  }
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
  final isPush = flightDirection == HeroFlightDirection.push;

  return AnimatedBuilder(
    animation: animation,
    builder: (BuildContext context, Widget? child) {
      final progress = animation.value;
      final targetOpacity = SwiftInteractiveZoomRoute.contentOpacity(progress);
      final toHeroOpacity = isPush ? targetOpacity : 1.0 - targetOpacity;

      final cornerRadius = ScreenRadiusService.instance.radius;
      final screenSize = MediaQuery.sizeOf(context);

      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final heroWidth = constraints.maxWidth;
          final heroHeight = constraints.maxHeight;
          final scale = heroWidth / screenSize.width;

          final visibleHeight = screenSize.height * scale;
          final visibleFraction = visibleHeight > 0.0
              ? (heroHeight / visibleHeight).clamp(0.0, 1.0).toDouble()
              : 1.0;

          return Stack(
            fit: StackFit.expand,
            children: [
              ClipRSuperellipse(
                clipBehavior: !isPush ? Clip.hardEdge : Clip.none,
                borderRadius: cornerRadius,
                child: fromHero.child,
              ),
              Opacity(
                opacity: toHeroOpacity,
                child: ClipRSuperellipse(
                  clipBehavior: isPush ? Clip.hardEdge : Clip.none,
                  borderRadius: cornerRadius,
                  child: isPush
                      ? ClipPath(
                          clipper: _RevealClipper(
                            visibleFraction,
                            borderRadius: cornerRadius,
                          ),
                          child: OverflowBox(
                            alignment: Alignment.topCenter,
                            maxWidth: double.infinity,
                            maxHeight: double.infinity,
                            child: Transform.scale(
                              scale: scale,
                              alignment: Alignment.topCenter,
                              child: SizedBox(
                                width: screenSize.width,
                                height: screenSize.height,
                                child: toHero.child,
                              ),
                            ),
                          ),
                        )
                      : toHero.child,
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

class _RevealClipper extends CustomClipper<Path> {
  const _RevealClipper(this.visibleFraction, {required this.borderRadius});
  final double visibleFraction;
  final BorderRadius borderRadius;

  @override
  Path getClip(Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height * visibleFraction);
    return Path()..addRRect(borderRadius.toRRect(rect));
  }

  @override
  bool shouldReclip(_RevealClipper old) =>
      old.visibleFraction != visibleFraction ||
      old.borderRadius != borderRadius;
}

/// A card-to-page zoom transition with hero animation.
///
/// The background page scales down via [delegatedTransition] (like
/// [SwiftSheetRoute]). Wrap the opening element in
/// [SwiftInteractiveZoomSource] and pass the same [sourceId] here.
///
/// When [enableDrag] is true, the user can pan the page in any direction.
/// Releasing past [enableDrag] threshold triggers dismiss with hero flight
/// from the current position.
class SwiftInteractiveZoomRoute<T> extends PageRoute<T> {
  SwiftInteractiveZoomRoute({
    required this.sourceId,
    required this.builder,
    this.namespace,
    this.enableDrag = true,
    Duration transitionDuration = const Duration(milliseconds: 420),
    super.settings,
  }) : _transitionDuration = transitionDuration;

  final Object sourceId;
  final Object? namespace;
  final WidgetBuilder builder;
  final Duration _transitionDuration;
  final bool enableDrag;
  final ValueNotifier<Offset> panOffset = ValueNotifier(Offset.zero);

  bool _isPopping = false;

  _SwiftInteractiveZoomSourceState? get _source =>
      _SwiftInteractiveZoomRegistry.instance.lookupSource(
        _SwiftInteractiveZoomTag(id: sourceId, namespace: namespace),
      );

  double get progress => controller?.value ?? 1.0;

  bool get isPopping => _isPopping;

  AnimationController? get routeController => controller;

  Rect? get sourceRect {
    final currentNavigator = navigator;
    if (currentNavigator == null) return null;
    return _source?.rectIn(currentNavigator);
  }

  static double contentOpacity(double progress) =>
      const Cubic(0.4, 0.0, 0.2, 1.0).transform(
        ((progress - 0.12) / (_interactiveZoomSourceCrossfadeEnd - 0.12))
            .clamp(0.0, 1.0)
            .toDouble(),
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
      final Curve curve = Curves.linearToEaseOut;
      final Curve reverseCurve = Curves.easeInToLinear;
      final curvedAnimation = CurvedAnimation(
        curve: curve,
        reverseCurve: reverseCurve,
        parent: secondaryAnimation,
      );

      final Animatable<double> scaleTween = Tween<double>(
        begin: 1.0,
        end: 1.0 - _interactiveZoomBackgroundScaleReduction,
      );
      final Animation<double> scaleAnimation = curvedAnimation.drive(
        scaleTween,
      );

      final borderRadius =
          ScreenRadiusService.instance.radius == BorderRadius.zero
          ? BorderRadius.all(Radius.circular(_interactiveZoomFallbackRadius))
          : ScreenRadiusService.instance.radius;

      return ScaleTransition(
        scale: scaleAnimation,
        filterQuality: FilterQuality.medium,
        alignment: Alignment.center,
        child: ClipRSuperellipse(
          borderRadius: borderRadius,
          clipBehavior: Clip.hardEdge,
          child: child,
        ),
      );
    };
  }

  @override
  void install() {
    super.install();
    _SwiftInteractiveZoomRegistry.instance.registerRoute(
      _SwiftInteractiveZoomTag(id: sourceId, namespace: namespace),
      this,
    );
  }

  @override
  bool didPop(T? result) {
    _isPopping = true;
    return super.didPop(result);
  }

  @override
  void dispose() {
    panOffset.dispose();
    _SwiftInteractiveZoomRegistry.instance.unregisterRoute(
      _SwiftInteractiveZoomTag(id: sourceId, namespace: namespace),
      this,
    );
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
      child: ValueListenableBuilder<Offset>(
        valueListenable: panOffset,
        builder: (context, offset, child) {
          final screenSize = MediaQuery.sizeOf(context);
          final maxDistance = screenSize.height;
          final displacement = (offset.distance / maxDistance).clamp(0.0, 1.0);
          final scale = 1.0 - displacement * _interactiveZoomMaxScaleReduction;

          Widget result = child!;

          if (offset != Offset.zero) {
            result = ClipRSuperellipse(
              borderRadius:
                  ScreenRadiusService.instance.radius == BorderRadius.zero
                  ? BorderRadius.all(
                      Radius.circular(_interactiveZoomFallbackRadius),
                    )
                  : ScreenRadiusService.instance.radius,
              clipBehavior: Clip.hardEdge,
              child: result,
            );
          }

          result = Transform.scale(
            scale: scale,
            filterQuality: FilterQuality.medium,
            alignment: Alignment.center,
            child: result,
          );

          if (offset != Offset.zero) {
            result = Transform.translate(offset: offset, child: result);
          }

          return result;
        },
        child: Hero(
          tag: _SwiftInteractiveZoomTag(id: sourceId, namespace: namespace),
          createRectTween: (Rect? begin, Rect? end) =>
              RectTween(begin: begin, end: end),
          flightShuttleBuilder: _buildInteractiveZoomHeroFlight,
          transitionOnUserGestures: true,
          curve: _interactiveZoomFlightCurve,
          reverseCurve: _interactiveZoomFlightCurve.flipped,
          child: builder(context),
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
    Widget content = child;

    if (enableDrag) {
      content = _SwiftInteractiveZoomDraggable(route: this, child: content);
    }

    if (_isPopping) {
      content = FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: _interactiveZoomFlightCurve,
          reverseCurve: _interactiveZoomFlightCurve.flipped,
        ),
        child: content,
      );
    }

    return content;
  }
}

class _SwiftInteractiveZoomDraggable extends StatefulWidget {
  const _SwiftInteractiveZoomDraggable({
    required this.child,
    required this.route,
  });

  final Widget child;
  final SwiftInteractiveZoomRoute route;

  @override
  State<_SwiftInteractiveZoomDraggable> createState() =>
      _SwiftInteractiveZoomDraggableState();
}

class _SwiftInteractiveZoomDraggableState
    extends State<_SwiftInteractiveZoomDraggable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _snapController;
  final GlobalKey _renderKey = GlobalKey();
  Offset _dragOffset = Offset.zero;
  Offset _snapStartOffset = Offset.zero;
  bool _isSnapping = false;
  bool _pushComplete = false;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _snapController.addListener(() {
      if (_isSnapping) {
        final t = _snapController.value;
        final offset = Offset.lerp(_snapStartOffset, Offset.zero, t)!;
        _dragOffset = offset;
        widget.route.panOffset.value = offset;
        setState(() {});
      }
    });
    _snapController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _isSnapping = false;
        _dragOffset = Offset.zero;
        widget.route.panOffset.value = Offset.zero;
        setState(() {});
      }
    });
    widget.route.routeController?.addStatusListener(_onRouteStatus);
  }

  void _onRouteStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _pushComplete = true;
      widget.route.routeController?.removeStatusListener(_onRouteStatus);
    }
  }

  @override
  void didUpdateWidget(covariant _SwiftInteractiveZoomDraggable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(widget.route, oldWidget.route)) return;
    oldWidget.route.routeController?.removeStatusListener(_onRouteStatus);
    widget.route.routeController?.addStatusListener(_onRouteStatus);
  }

  @override
  void dispose() {
    widget.route.routeController?.removeStatusListener(_onRouteStatus);
    _snapController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!_pushComplete || widget.route.isPopping || _isSnapping) return;
    final recognizer = PanGestureRecognizer()
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel;
    recognizer.addPointer(event);
  }

  void _handleDragStart(DragStartDetails details) {}

  void _handleDragUpdate(DragUpdateDetails details) {
    if (widget.route.isPopping) return;

    setState(() => _dragOffset += details.delta);
    widget.route.panOffset.value = _dragOffset;
  }

  void _handleDragEnd(DragEndDetails details) {
    if (widget.route.isPopping) return;

    final velocity = details.velocity.pixelsPerSecond;
    final navigator = widget.route.navigator;
    if (navigator == null || !navigator.context.mounted) return;
    final screenSize = MediaQuery.sizeOf(navigator.context);

    bool shouldDismiss;
    if (velocity.dy.abs() >= _interactiveZoomMinFlingVelocity) {
      shouldDismiss = velocity.dy > 0;
    } else if (velocity.dx.abs() >= _interactiveZoomMinFlingVelocity) {
      shouldDismiss = true;
    } else {
      final dy = _dragOffset.dy.abs() / screenSize.height;
      final dx = _dragOffset.dx.abs() / screenSize.width;
      shouldDismiss =
          dy >= _interactiveZoomDismissThreshold ||
          dx >= _interactiveZoomDismissThreshold;
    }

    if (shouldDismiss) {
      widget.route.navigator?.pop();
    } else {
      _snapStartOffset = _dragOffset;
      _isSnapping = true;
      _snapController.forward(from: 0.0);
    }
  }

  void _handleDragCancel() {}

  @override
  Widget build(BuildContext context) {
    return Listener(
      key: _renderKey,
      onPointerDown: _onPointerDown,
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}

class _SwiftInteractiveZoomRegistry {
  _SwiftInteractiveZoomRegistry._();

  static final instance = _SwiftInteractiveZoomRegistry._();

  final Map<_SwiftInteractiveZoomTag, _SwiftInteractiveZoomSourceState>
  _sources = {};
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
