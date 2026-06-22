import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

import '../../services/screen_radius_service.dart';
import 'swift_sheet_route.dart';

class SwiftPageTransitions {
  const SwiftPageTransitions._();

  /// Gap from top of the screen (below status bar) for the active sheet.
  /// Standard iOS sheets have a 10.0 pixel margin.
  static double sheetTopOffsetPadding = 10.0;

  /// Vertical offset step (in pixels) per stacked level in the background.
  /// Higher values push background cards lower.
  static double backgroundOffsetStep = 20.0;

  /// Scale step per stacked level in the background.
  /// e.g. 0.08 means level 0 = 1.0, level 1 = 0.92, level 2 = 0.84.
  static double scaleStep = 0.08;

  /// Top radius applied to routes when they move into the sheet background.
  /// The original Cupertino sheet package uses 32.0.
  static double sheetBackgroundRadius = 32.0;

  /// Dimming opacity applied to background routes while a sheet is above them.
  /// The original Cupertino sheet package uses 0.10.
  static double sheetBackgroundDimmingOpacity = 0.10;

  /// Default transitions builder that can be used directly with auto_route or standard routing.
  static Widget builder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return customBuilder()(context, animation, secondaryAnimation, child);
  }

  /// Custom transitions builder creator that allows configuring parameters.
  static RouteTransitionsBuilder customBuilder({
    double minScale = 0.95,
    double pageOverlapFraction = 0.20,
    bool clipWithScreenRadius = true,
  }) {
    return (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      return _SwiftPageRouteTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        minScale: minScale,
        pageOverlapFraction: pageOverlapFraction,
        clipWithScreenRadius: clipWithScreenRadius,
        child: child,
      );
    };
  }

  /// Helper to create a custom page route that supports the native iOS swipe-back gesture
  /// and applies the parallax and scale transitions to the page transitions.
  static PageRoute<T> routeBuilder<T>({
    required BuildContext context,
    required Widget child,
    required RouteSettings settings,
    double minScale = 0.95,
    double pageOverlapFraction = 0.20,
    bool clipWithScreenRadius = true,
    double? backGestureWidth,
    Duration transitionDuration = const Duration(milliseconds: 400),
  }) {
    return SwiftPageRoute<T>(
      child: child,
      settings: settings,
      minScale: minScale,
      pageOverlapFraction: pageOverlapFraction,
      clipWithScreenRadius: clipWithScreenRadius,
      backGestureWidth: backGestureWidth,
      customTransitionDuration: transitionDuration,
    );
  }
}

class SwiftPageRoute<T> extends PageRoute<T>
    with CupertinoRouteTransitionMixin<T> {
  SwiftPageRoute({
    required this.child,
    required RouteSettings settings,
    this.minScale = 0.95,
    this.pageOverlapFraction = 0.20,
    this.clipWithScreenRadius = true,
    this.backGestureWidth,
    this.customTransitionDuration,
  }) : super(settings: settings);

  final Widget child;
  final double minScale;
  final double pageOverlapFraction;
  final bool clipWithScreenRadius;
  final double? backGestureWidth;
  final Duration? customTransitionDuration;

  Route? _nextRoute;

  /// Returns the next route in the navigator stack.
  Route? get nextRoute => _nextRoute;

  /// The previous route in the navigator stack.
  Route? previousRoute;

  @override
  void didChangeNext(Route? nextRoute) {
    _nextRoute = nextRoute;
    super.didChangeNext(nextRoute);
    if (nextRoute is SwiftPageRoute) {
      nextRoute.previousRoute = this;
    } else if (nextRoute is SwiftSheetRoute) {
      nextRoute.previousRoute = this;
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
  Widget buildContent(BuildContext context) => child;

  @override
  String? get title => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration =>
      customTransitionDuration ?? const Duration(milliseconds: 400);

  @override
  Duration get reverseTransitionDuration =>
      customTransitionDuration ?? const Duration(milliseconds: 400);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final transitionWidget = SwiftPageTransitions.customBuilder(
      minScale: minScale,
      pageOverlapFraction: pageOverlapFraction,
      clipWithScreenRadius: clipWithScreenRadius,
    )(context, animation, secondaryAnimation, child);

    // We MUST always return _SwiftBackGestureDetector in the tree, otherwise it will
    // be disposed mid-gesture when popGestureEnabled changes to false.
    return _SwiftBackGestureDetector<T>(
      route: this,
      backGestureWidth: backGestureWidth,
      child: transitionWidget,
    );
  }
}

class _SwiftPageRouteTransition extends StatefulWidget {
  const _SwiftPageRouteTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.minScale,
    required this.pageOverlapFraction,
    required this.clipWithScreenRadius,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final double minScale;
  final double pageOverlapFraction;
  final bool clipWithScreenRadius;
  final Widget child;

  @override
  State<_SwiftPageRouteTransition> createState() =>
      _SwiftPageRouteTransitionState();
}

class _SwiftPageRouteTransitionState extends State<_SwiftPageRouteTransition> {
  late CurvedAnimation _primaryCurve;
  late CurvedAnimation _secondaryCurve;
  bool _wasNextRouteSheet = false;

  @override
  void initState() {
    super.initState();
    _primaryCurve = CurvedAnimation(
      parent: widget.animation,
      curve: Curves.fastEaseInToSlowEaseOut,
      reverseCurve: Curves.fastEaseInToSlowEaseOut.flipped,
    );
    _secondaryCurve = CurvedAnimation(
      parent: widget.secondaryAnimation,
      curve: Curves.linearToEaseOut,
      reverseCurve: Curves.easeInToLinear,
    );
  }

  @override
  void didUpdateWidget(covariant _SwiftPageRouteTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation ||
        oldWidget.secondaryAnimation != widget.secondaryAnimation) {
      _primaryCurve.dispose();
      _secondaryCurve.dispose();
      _primaryCurve = CurvedAnimation(
        parent: widget.animation,
        curve: Curves.fastEaseInToSlowEaseOut,
        reverseCurve: Curves.fastEaseInToSlowEaseOut.flipped,
      );
      _secondaryCurve = CurvedAnimation(
        parent: widget.secondaryAnimation,
        curve: Curves.linearToEaseOut,
        reverseCurve: Curves.easeInToLinear,
      );
    }
  }

  @override
  void dispose() {
    _primaryCurve.dispose();
    _secondaryCurve.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final bool linearTransition =
        route is PageRoute && route.popGestureInProgress;

    final Animation<double> currentPrimary = linearTransition
        ? widget.animation
        : _primaryCurve;
    final Animation<double> currentSecondary = linearTransition
        ? widget.secondaryAnimation
        : _secondaryCurve;

    final width = MediaQuery.sizeOf(context).width;

    Route? nextRoute;
    if (route is SwiftPageRoute) {
      nextRoute = route.nextRoute;
    } else if (route is SwiftSheetRoute) {
      nextRoute = route.nextRoute;
    }

    final int depth = _getRouteDepthAbove(route);
    final bool isOffstage = depth >= 3;

    final bool isNextRouteSheet = nextRoute is SwiftSheetRoute;
    if (isNextRouteSheet) {
      _wasNextRouteSheet = true;
    } else if (widget.secondaryAnimation.value == 0.0) {
      _wasNextRouteSheet = false;
    }
    final bool activeNextRouteSheet =
        isNextRouteSheet ||
        (_wasNextRouteSheet && widget.secondaryAnimation.value > 0.0);

    return Offstage(
      offstage: isOffstage,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          currentPrimary,
          currentSecondary,
          if (widget.clipWithScreenRadius) ScreenRadiusService.instance,
        ]),
        builder: (context, child) {
          if (activeNextRouteSheet) {
            final double topPadding = MediaQuery.paddingOf(context).top;
            final double topOffset = math.max(
              12.0,
              topPadding + SwiftPageTransitions.sheetTopOffsetPadding,
            );

            final double s = currentSecondary.value;

            final double translationX = (1.0 - currentPrimary.value) * width;
            final double translationY =
                s * (topOffset - SwiftPageTransitions.backgroundOffsetStep);
            final double scale = 1.0 - (s * SwiftPageTransitions.scaleStep);

            final BorderRadius screenBorderRadius = widget.clipWithScreenRadius
                ? ScreenRadiusService.instance.radius
                : BorderRadius.zero;

            final BorderRadius targetBorderRadius = BorderRadius.vertical(
              top: Radius.circular(SwiftPageTransitions.sheetBackgroundRadius),
            );

            final BorderRadius borderRadius = BorderRadius.lerp(
              screenBorderRadius,
              targetBorderRadius,
              currentSecondary.value,
            )!;

            Widget transitionChild = Transform.translate(
              offset: Offset(translationX, translationY),
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.topCenter,
                child: ClipRRect(
                  borderRadius: borderRadius,
                  clipBehavior: Clip.antiAlias,
                  child: child,
                ),
              ),
            );

            if (currentSecondary.value > 0) {
              transitionChild = Stack(
                children: [
                  transitionChild,
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: borderRadius,
                          color: CupertinoColors.black.withAlpha(
                            (currentSecondary.value *
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

            if (currentSecondary.value > 0) {
              transitionChild = Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.black,
                  borderRadius: borderRadius,
                ),
                child: transitionChild,
              );
            }

            return transitionChild;
          } else {
            final double translationX =
                (1.0 - currentPrimary.value) * width -
                currentSecondary.value * width * widget.pageOverlapFraction;
            final double scale =
                1.0 - (1.0 - widget.minScale) * currentSecondary.value;

            Widget transitionChild = Transform.translate(
              offset: Offset(translationX, 0.0),
              child: Transform.scale(scale: scale, child: child),
            );

            if (widget.clipWithScreenRadius) {
              transitionChild = ClipRRect(
                borderRadius: ScreenRadiusService.instance.radius,
                clipBehavior: Clip.antiAlias,
                child: transitionChild,
              );
            }

            return transitionChild;
          }
        },
        child: widget.child,
      ),
    );
  }
}

class _FullscreenBackGestureRecognizer extends HorizontalDragGestureRecognizer {
  _FullscreenBackGestureRecognizer({super.debugOwner});

  @override
  void handleEvent(PointerEvent event) {
    super.handleEvent(event);
    if (event is PointerMoveEvent) {
      // If the user drags to the right and the drag is primarily horizontal,
      // immediately claim the gesture to win the arena over parent scrollables.
      if (event.delta.dx > 0 && event.delta.dx.abs() > event.delta.dy.abs()) {
        resolve(GestureDisposition.accepted);
      }
    }
  }
}

class _SwiftBackGestureDetector<T> extends StatefulWidget {
  const _SwiftBackGestureDetector({
    super.key,
    required this.child,
    required this.route,
    required this.backGestureWidth,
  });

  final Widget child;
  final SwiftPageRoute<T> route;
  final double? backGestureWidth;

  @override
  State<_SwiftBackGestureDetector<T>> createState() =>
      _SwiftBackGestureDetectorState<T>();
}

class _SwiftBackGestureDetectorState<T>
    extends State<_SwiftBackGestureDetector<T>> {
  _SwiftBackGestureController<T>? _backGestureController;

  late _FullscreenBackGestureRecognizer _recognizer;

  @override
  void initState() {
    super.initState();
    _recognizer = _FullscreenBackGestureRecognizer(debugOwner: this)
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel;
  }

  @override
  void dispose() {
    _recognizer.dispose();
    if (_backGestureController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_backGestureController?.navigator.mounted ?? false) {
          _backGestureController?.navigator.didStopUserGesture();
        }
        _backGestureController = null;
      });
    }
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    assert(mounted);
    assert(_backGestureController == null);
    _backGestureController = _SwiftBackGestureController<T>(
      navigator: widget.route.navigator!,
      // ignore: invalid_use_of_protected_member
      controller: widget.route.controller!,
      getIsActive: () => widget.route.isActive,
      getIsCurrent: () => widget.route.isCurrent,
      transitionDuration: widget.route.transitionDuration,
    );
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    assert(mounted);
    assert(_backGestureController != null);
    final width = MediaQuery.sizeOf(context).width;
    _backGestureController!.dragUpdate(
      _convertToLogical(details.primaryDelta! / width),
    );
  }

  void _handleDragEnd(DragEndDetails details) {
    assert(mounted);
    assert(_backGestureController != null);
    final width = MediaQuery.sizeOf(context).width;
    _backGestureController!.dragEnd(
      _convertToLogical(details.velocity.pixelsPerSecond.dx / width),
    );
    _backGestureController = null;
  }

  void _handleDragCancel() {
    assert(mounted);
    _backGestureController?.dragEnd(0.0);
    _backGestureController = null;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.route.popGestureEnabled) {
      _recognizer.addPointer(event);
    }
  }

  double _convertToLogical(double value) {
    return switch (Directionality.of(context)) {
      TextDirection.rtl => -value,
      TextDirection.ltr => value,
    };
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    final width = MediaQuery.sizeOf(context).width;
    final gestureWidth = widget.backGestureWidth ?? width;

    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        PositionedDirectional(
          start: 0.0,
          width: gestureWidth,
          top: 0.0,
          bottom: 0.0,
          child: Listener(
            onPointerDown: _handlePointerDown,
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }
}

class _SwiftBackGestureController<T> {
  _SwiftBackGestureController({
    required this.navigator,
    required this.controller,
    required this.getIsActive,
    required this.getIsCurrent,
    required this.transitionDuration,
  }) {
    navigator.didStartUserGesture();
  }

  final AnimationController controller;
  final NavigatorState navigator;
  final ValueGetter<bool> getIsActive;
  final ValueGetter<bool> getIsCurrent;
  final Duration transitionDuration;

  void dragUpdate(double delta) {
    controller.value -= delta;
  }

  void dragEnd(double velocity) {
    const Curve animationCurve = Curves.fastEaseInToSlowEaseOut;
    final bool isCurrent = getIsCurrent();
    final bool animateForward;

    if (!isCurrent) {
      animateForward = getIsActive();
    } else if (velocity.abs() >= 1.0) {
      // _kMinFlingVelocity = 1.0
      animateForward = velocity <= 0;
    } else {
      animateForward = controller.value > 0.5;
    }

    if (animateForward) {
      controller.animateTo(
        1.0,
        duration: transitionDuration,
        curve: animationCurve,
      );
    } else {
      if (isCurrent) {
        navigator.pop();
      }

      if (controller.isAnimating) {
        controller.animateBack(
          0.0,
          duration: transitionDuration,
          curve: animationCurve,
        );
      }
    }

    if (controller.isAnimating) {
      late AnimationStatusListener animationStatusCallback;
      animationStatusCallback = (AnimationStatus status) {
        navigator.didStopUserGesture();
        controller.removeStatusListener(animationStatusCallback);
      };
      controller.addStatusListener(animationStatusCallback);
    } else {
      navigator.didStopUserGesture();
    }
  }
}

int _getRouteDepthAbove(Route? route) {
  int depth = 0;
  Route? current = route;
  while (current != null) {
    Route? next;
    if (current is SwiftPageRoute) {
      next = current.nextRoute;
    } else if (current is SwiftSheetRoute) {
      next = current.nextRoute;
    }
    if (next == null) break;
    depth++;
    current = next;
  }
  return depth;
}
