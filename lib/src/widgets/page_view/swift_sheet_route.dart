import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../services/screen_radius_service.dart';
import 'swift_page_transitions.dart';

/// A modal page route that overlays a widget over the current route and animates
/// it from the bottom with an iOS 13+ style page sheet appearance.
///
/// It clips the content to top rounded corners, pushes it to start below the top
/// status bar, and enables dismissing the route by dragging downwards.
class SwiftSheetRoute<T> extends PageRoute<T>
    with CupertinoRouteTransitionMixin<T> {
  SwiftSheetRoute({
    required this.child,
    required RouteSettings settings,
    this.sheetRadius = 16.0,
    this.sheetMinScale = 0.92,
    this.transitionDurationOverride = const Duration(milliseconds: 400),
  }) : super(settings: settings);

  /// The widget content of the sheet.
  final Widget child;

  /// Top corners radius of the sheet container.
  final double sheetRadius;

  /// Min scale of this sheet when another sheet is pushed on top.
  final double sheetMinScale;

  /// Overridden transition duration.
  final Duration transitionDurationOverride;

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
  bool get opaque => false;

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  String? get barrierLabel => 'Dismiss Sheet';

  @override
  bool get barrierDismissible => true;

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
    return _SwiftSheetRouteTransition(
      route: this,
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      sheetRadius: sheetRadius,
      sheetMinScale: sheetMinScale,
      child: child,
    );
  }
}

class _SwiftSheetRouteTransition extends StatefulWidget {
  const _SwiftSheetRouteTransition({
    required this.route,
    required this.animation,
    required this.secondaryAnimation,
    required this.sheetRadius,
    required this.sheetMinScale,
    required this.child,
  });

  final SwiftSheetRoute route;
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final double sheetRadius;
  final double sheetMinScale;
  final Widget child;

  @override
  State<_SwiftSheetRouteTransition> createState() =>
      _SwiftSheetRouteTransitionState();
}

class _SwiftSheetRouteTransitionState
    extends State<_SwiftSheetRouteTransition> {
  late CurvedAnimation _primaryCurve;
  late CurvedAnimation _secondaryCurve;

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
      curve: Curves.fastEaseInToSlowEaseOut,
      reverseCurve: Curves.fastEaseInToSlowEaseOut.flipped,
    );
  }

  @override
  void didUpdateWidget(covariant _SwiftSheetRouteTransition oldWidget) {
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
        curve: Curves.fastEaseInToSlowEaseOut,
        reverseCurve: Curves.fastEaseInToSlowEaseOut.flipped,
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
    final route = widget.route;
    final bool linearTransition = route.popGestureInProgress;

    final Animation<double> currentPrimary = linearTransition
        ? widget.animation
        : _primaryCurve;
    final Animation<double> currentSecondary = linearTransition
        ? widget.secondaryAnimation
        : _secondaryCurve;

    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double topPadding = MediaQuery.paddingOf(context).top;
    final double topOffset = math.max(
      12.0,
      topPadding + SwiftPageTransitions.sheetTopOffsetPadding,
    );
    final double sheetHeight = screenHeight - topOffset;

    final int depth = _getRouteDepthAbove(route);
    final bool isOffstage = depth >= 3;

    return Offstage(
      offstage: isOffstage,
      child: _SwiftVerticalBackGestureDetector(
        route: route,
        sheetHeight: sheetHeight,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            currentPrimary,
            currentSecondary,
            ScreenRadiusService.instance,
          ]),
          builder: (context, child) {
            // Slide up transition: from screenHeight to topOffset
            final double primaryOffsetY =
                topOffset + (1.0 - currentPrimary.value) * sheetHeight;

            final double s = currentSecondary.value;

            // When another sheet is pushed on top, scale down and translate up slightly
            final double secondaryOffsetY =
                -s * SwiftPageTransitions.backgroundOffsetStep;
            final double scale = 1.0 - (s * SwiftPageTransitions.scaleStep);

            final double offsetY = primaryOffsetY + secondaryOffsetY;

            final double screenRadius =
                ScreenRadiusService.instance.radius.topLeft.x;
            final double resolvedRadius = screenRadius > 0.0
                ? screenRadius
                : widget.sheetRadius;

            final borderRadius = BorderRadius.vertical(
              top: Radius.circular(resolvedRadius),
            );

            Widget sheetWidget = Container(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: borderRadius,
                clipBehavior: Clip.antiAlias,
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: widget.child,
                ),
              ),
            );

            // If another sheet is stacked on top, apply dimming overlay
            if (currentSecondary.value > 0) {
              sheetWidget = Stack(
                children: [
                  sheetWidget,
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: borderRadius,
                          color: Colors.black.withAlpha(
                            (currentSecondary.value * 0.15 * 255).round(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            // If scaled down, wrap with a black background container to prevent see-through gaps
            if (currentSecondary.value > 0) {
              sheetWidget = Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: borderRadius,
                ),
                child: sheetWidget,
              );
            }

            return Transform.translate(
              offset: Offset(0.0, offsetY),
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.topCenter,
                child: sheetWidget,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _VerticalSheetGestureRecognizer extends VerticalDragGestureRecognizer {
  _VerticalSheetGestureRecognizer({
    required this.isScrollableAtTop,
    super.debugOwner,
  });

  final ValueGetter<bool> isScrollableAtTop;

  @override
  void handleEvent(PointerEvent event) {
    super.handleEvent(event);
    if (event is PointerMoveEvent) {
      if (event.delta.dy > 0 &&
          event.delta.dy.abs() > event.delta.dx.abs() &&
          isScrollableAtTop()) {
        resolve(GestureDisposition.accepted);
      }
    }
  }
}

class _SwiftVerticalBackGestureDetector extends StatefulWidget {
  const _SwiftVerticalBackGestureDetector({
    required this.child,
    required this.route,
    required this.sheetHeight,
  });

  final Widget child;
  final SwiftSheetRoute route;
  final double sheetHeight;

  @override
  State<_SwiftVerticalBackGestureDetector> createState() =>
      _SwiftVerticalBackGestureDetectorState();
}

class _SwiftVerticalBackGestureDetectorState
    extends State<_SwiftVerticalBackGestureDetector> {
  _SwiftVerticalBackGestureController? _gestureController;
  VelocityTracker? _velocityTracker;
  bool _isOverscrollDragging = false;
  bool _isScrollableAtTop = true;

  @override
  void dispose() {
    if (_gestureController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_gestureController?.navigator.mounted ?? false) {
          _gestureController?.navigator.didStopUserGesture();
        }
        _gestureController = null;
      });
    }
    super.dispose();
  }

  void _handleDragStart() {
    if (_gestureController != null) return;
    // ignore: invalid_use_of_protected_member
    final double currentValue = widget.route.controller?.value ?? 1.0;
    if (currentValue < 0.25) {
      return;
    }
    _gestureController = _SwiftVerticalBackGestureController(
      navigator: widget.route.navigator!,
      // ignore: invalid_use_of_protected_member
      controller: widget.route.controller!,
      getIsActive: () => widget.route.isActive,
      getIsCurrent: () => widget.route.isCurrent,
      transitionDuration: widget.route.transitionDuration,
    );
  }

  void _handleDragUpdate(double deltaY) {
    _gestureController?.dragUpdate(deltaY / widget.sheetHeight);
  }

  void _handleDragEnd(double velocityY) {
    _gestureController?.dragEnd(velocityY);
    _gestureController = null;
    _isOverscrollDragging = false;
  }

  void _handleDragCancel() {
    _gestureController?.dragEnd(0.0);
    _gestureController = null;
    _isOverscrollDragging = false;
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!widget.route.popGestureEnabled) return false;

    if (notification.metrics.axis == Axis.vertical) {
      _isScrollableAtTop = notification.metrics.pixels <= 0;
    }

    if (notification is ScrollUpdateNotification) {
      if (!_isOverscrollDragging) {
        // Start overscroll dragging when content reaches the top and drag continues downward
        if (notification.metrics.pixels <= 0 &&
            notification.dragDetails != null &&
            notification.dragDetails!.delta.dy > 0) {
          _isOverscrollDragging = true;
          _handleDragStart();
        }
      }
    } else if (notification is ScrollEndNotification) {
      if (_isOverscrollDragging) {
        _handleDragEnd(0.0);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: Listener(
        onPointerDown: (event) {
          _velocityTracker = VelocityTracker.withKind(event.kind);
          _velocityTracker?.addPosition(event.timeStamp, event.position);
        },
        onPointerMove: (event) {
          _velocityTracker?.addPosition(event.timeStamp, event.position);
          if (_isOverscrollDragging) {
            _handleDragUpdate(event.delta.dy);
          }
        },
        onPointerUp: (event) {
          _velocityTracker?.addPosition(event.timeStamp, event.position);
          if (_isOverscrollDragging) {
            final velocityY =
                _velocityTracker?.getVelocity().pixelsPerSecond.dy ?? 0.0;
            _handleDragEnd(velocityY);
          }
        },
        onPointerCancel: (event) {
          if (_isOverscrollDragging) {
            _handleDragCancel();
          }
        },
        behavior: HitTestBehavior.translucent,
        child: RawGestureDetector(
          gestures: {
            _VerticalSheetGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<
                  _VerticalSheetGestureRecognizer
                >(
                  () => _VerticalSheetGestureRecognizer(
                    isScrollableAtTop: () => _isScrollableAtTop,
                    debugOwner: this,
                  ),
                  (_VerticalSheetGestureRecognizer instance) {
                    instance.onStart = (DragStartDetails details) {
                      _handleDragStart();
                    };
                    instance.onUpdate = (DragUpdateDetails details) {
                      _handleDragUpdate(details.delta.dy);
                    };
                    instance.onEnd = (DragEndDetails details) {
                      _handleDragEnd(details.velocity.pixelsPerSecond.dy);
                    };
                    instance.onCancel = () {
                      _handleDragCancel();
                    };
                  },
                ),
          },
          behavior: HitTestBehavior.translucent,
          child: widget.child,
        ),
      ),
    );
  }
}

class _SwiftVerticalBackGestureController {
  _SwiftVerticalBackGestureController({
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
    // Pulling down decreases route animation controller value, clamped to 0.01
    // to ensure there is always a tiny transition step remaining for pop finalization
    controller.value = (controller.value - delta).clamp(0.01, 1.0);
  }

  void dragEnd(double velocity) {
    const Curve animationCurve = Curves.fastEaseInToSlowEaseOut;
    final bool isCurrent = getIsCurrent();
    final bool
    animateForward; // true means restore to 1.0, false means dismiss to 0.0

    if (!isCurrent) {
      animateForward = getIsActive();
    } else if (velocity.abs() >= 1.0) {
      animateForward = velocity < 0; // negative velocity = flick up (restore)
    } else {
      animateForward =
          controller.value > 0.5; // restore if less than 50% dragged
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

      // Always call animateBack to 0.0 to ensure the controller value animates from
      // 0.01 to 0.0, triggering the status listener that finalizes the pop.
      controller.animateBack(
        0.0,
        duration: transitionDuration,
        curve: animationCurve,
      );
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

  void dispose() {}
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
