import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../services/screen_radius_service.dart';
import 'swift_page_transitions.dart';

const bool _debugSheetGestureLogs = false;

void _logSheetGesture(String message) {
  if (!_debugSheetGestureLogs) return;
  debugPrint('[SwiftSheetGesture] $message');
}

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
            final double minScale = widget.sheetMinScale
                .clamp(0.0, 1.0)
                .toDouble();
            final double scale = 1.0 - (s * (1.0 - minScale));

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
  PointerDeviceKind? _pointerKind;
  ScrollPosition? _activeScrollPosition;
  bool _isHandoffBackToScrollable = false;
  bool _isOverscrollDragging = false;
  bool _isScrollableAtTop = true;

  String _scrollSnapshot() {
    final position = _activeScrollPosition;
    if (position == null || !position.hasPixels) return 'scroll=null';

    return 'scroll=${position.pixels.toStringAsFixed(1)} '
        'min=${position.minScrollExtent.toStringAsFixed(1)} '
        'max=${position.maxScrollExtent.toStringAsFixed(1)}';
  }

  String _controllerSnapshot() {
    // ignore: invalid_use_of_protected_member
    final value = widget.route.controller?.value ?? 1.0;
    return 'controller=${value.toStringAsFixed(3)}';
  }

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
    _isHandoffBackToScrollable = false;
    // ignore: invalid_use_of_protected_member
    final double currentValue = widget.route.controller?.value ?? 1.0;
    if (currentValue < 0.25) {
      _logSheetGesture(
        'sheet start ignored: controller=${currentValue.toStringAsFixed(3)}',
      );
      return;
    }
    _logSheetGesture(
      'sheet start: ${_controllerSnapshot()} ${_scrollSnapshot()}',
    );
    _gestureController = _SwiftVerticalBackGestureController(
      navigator: widget.route.navigator!,
      // ignore: invalid_use_of_protected_member
      controller: widget.route.controller!,
      getIsActive: () => widget.route.isActive,
      getIsCurrent: () => widget.route.isCurrent,
      transitionDuration: widget.route.transitionDuration,
    );
    final kind = _pointerKind;
    _velocityTracker = kind == null ? null : VelocityTracker.withKind(kind);
    _pinActiveScrollableToTop();
  }

  double _handleDragUpdate(double deltaY) {
    final before = _controllerSnapshot();
    // ignore: invalid_use_of_protected_member
    final valueBeforeUpdate = widget.route.controller?.value ?? 1.0;

    _pinActiveScrollableToTop();
    _gestureController?.dragUpdate(deltaY / widget.sheetHeight);
    _logSheetGesture(
      'sheet update: dy=${deltaY.toStringAsFixed(1)} '
      '$before -> ${_controllerSnapshot()} ${_scrollSnapshot()}',
    );

    // When the user swipes upward past the fully expanded sheet, the sheet
    // cannot consume the rest of that movement. Pass the leftover into content.
    // ignore: invalid_use_of_protected_member
    final valueAfterUpdate = widget.route.controller?.value ?? 1.0;
    if (deltaY >= 0 || valueAfterUpdate < 1.0) {
      return 0.0;
    }

    final draggedUpPixels = -deltaY;
    final sheetPixelsConsumed =
        (1.0 - valueBeforeUpdate).clamp(0.0, 1.0) * widget.sheetHeight;
    return math.max(0.0, draggedUpPixels - sheetPixelsConsumed);
  }

  bool _isSheetFullyExpanded() {
    // ignore: invalid_use_of_protected_member
    return (widget.route.controller?.value ?? 1.0) >= 1.0;
  }

  void _handleDragEnd(double velocityY) {
    _logSheetGesture(
      'sheet end: velocity=${velocityY.toStringAsFixed(3)} '
      '${_controllerSnapshot()} ${_scrollSnapshot()}',
    );
    _gestureController?.dragEnd(velocityY);
    _gestureController = null;
    _isHandoffBackToScrollable = false;
    _isOverscrollDragging = false;
    _activeScrollPosition = null;
  }

  void _handoffDragBackToScrollable() {
    _logSheetGesture(
      'handoff sheet -> scroll: ${_controllerSnapshot()} ${_scrollSnapshot()}',
    );
    _gestureController?.handoffToScrollable();
    _gestureController = null;
    _isHandoffBackToScrollable = true;
    _isOverscrollDragging = false;
  }

  void _handleDragCancel() {
    _logSheetGesture(
      'sheet cancel: ${_controllerSnapshot()} ${_scrollSnapshot()}',
    );
    _gestureController?.dragEnd(0.0);
    _gestureController = null;
    _isHandoffBackToScrollable = false;
    _isOverscrollDragging = false;
    _activeScrollPosition = null;
  }

  bool _isAtTop(ScrollMetrics metrics) {
    return metrics.pixels <= metrics.minScrollExtent;
  }

  void _trackScrollable(ScrollNotification notification) {
    final context = notification.context;
    if (context == null) return;

    final scrollable = Scrollable.maybeOf(context);
    final position = scrollable?.position;
    if (position == null || position.axis != Axis.vertical) return;

    _activeScrollPosition = position;
  }

  void _pinActiveScrollableToTop() {
    final position = _activeScrollPosition;
    if (position == null || !position.hasPixels) return;

    final top = position.minScrollExtent;
    if (position.pixels != top) {
      _logSheetGesture(
        'pin scroll to top: from=${position.pixels.toStringAsFixed(1)} '
        'to=${top.toStringAsFixed(1)}',
      );
      position.jumpTo(top);
    }
  }

  void _scrollActiveScrollableBy(double delta) {
    final position = _activeScrollPosition;
    if (position == null || !position.hasPixels || delta == 0.0) return;

    final target = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (target != position.pixels) {
      _logSheetGesture(
        'handoff scroll leftover: delta=${delta.toStringAsFixed(1)} '
        'from=${position.pixels.toStringAsFixed(1)} '
        'to=${target.toStringAsFixed(1)}',
      );
      position.jumpTo(target);
    }
  }

  void _handleHandoffPointerMove(PointerMoveEvent event) {
    final position = _activeScrollPosition;
    if (position == null || !position.hasPixels) return;

    final deltaY = event.delta.dy;
    if (deltaY == 0.0) return;

    if (deltaY < 0) {
      _logSheetGesture(
        'handoff manual scroll up: dy=${deltaY.toStringAsFixed(1)}',
      );
      _scrollActiveScrollableBy(-deltaY);
      return;
    }

    final distanceToTop = position.pixels - position.minScrollExtent;
    if (distanceToTop > 0.0) {
      final scrollDelta = -math.min(deltaY, distanceToTop);
      _logSheetGesture(
        'handoff manual scroll down: dy=${deltaY.toStringAsFixed(1)} '
        'scrollDelta=${scrollDelta.toStringAsFixed(1)}',
      );
      _scrollActiveScrollableBy(scrollDelta);
    }

    final remainingDownDelta = deltaY - math.max(0.0, distanceToTop);
    if (remainingDownDelta > 0.0) {
      _logSheetGesture(
        'handoff back to sheet: dy=${remainingDownDelta.toStringAsFixed(1)}',
      );
      _isHandoffBackToScrollable = false;
      _isOverscrollDragging = true;
      _handleDragStart();
      _handleDragUpdate(remainingDownDelta);
    }
  }

  bool _canStartSheetDragFromPointerMove(PointerMoveEvent event) {
    if (event.delta.dy <= 0 || event.delta.dy.abs() <= event.delta.dx.abs()) {
      return false;
    }

    final position = _activeScrollPosition;
    if (position == null || !position.hasPixels) return _isScrollableAtTop;
    if (_isHandoffBackToScrollable) return false;

    return position.pixels <= position.minScrollExtent;
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!widget.route.popGestureEnabled) return false;

    if (notification.metrics.axis == Axis.vertical) {
      _trackScrollable(notification);
      _isScrollableAtTop = _isAtTop(notification.metrics);
    }

    if (notification is ScrollUpdateNotification) {
      final dragDelta = notification.dragDetails?.delta.dy;
      if (_isAtTop(notification.metrics) || _isOverscrollDragging) {
        _logSheetGesture(
          'scroll update: pixels=${notification.metrics.pixels.toStringAsFixed(1)} '
          'min=${notification.metrics.minScrollExtent.toStringAsFixed(1)} '
          'dragDy=${dragDelta?.toStringAsFixed(1)} '
          'atTop=${_isAtTop(notification.metrics)} '
          'sheetDragging=$_isOverscrollDragging',
        );
      }
      if (!_isOverscrollDragging) {
        // Start overscroll dragging when content reaches the top and drag continues downward
        if (_isAtTop(notification.metrics) &&
            !_isHandoffBackToScrollable &&
            notification.dragDetails != null &&
            notification.dragDetails!.delta.dy > 0) {
          _logSheetGesture('start sheet from scroll notification');
          _isOverscrollDragging = true;
          _handleDragStart();
        }
      } else {
        _pinActiveScrollableToTop();
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
          _isHandoffBackToScrollable = false;
          _logSheetGesture(
            'pointer down: kind=${event.kind} ${_controllerSnapshot()} '
            '${_scrollSnapshot()}',
          );
          _pointerKind = event.kind;
          _velocityTracker = VelocityTracker.withKind(event.kind);
          _velocityTracker?.addPosition(event.timeStamp, event.position);
        },
        onPointerMove: (event) {
          _velocityTracker?.addPosition(event.timeStamp, event.position);
          if (_isHandoffBackToScrollable && !_isOverscrollDragging) {
            _handleHandoffPointerMove(event);
            return;
          }
          if (!_isOverscrollDragging &&
              _canStartSheetDragFromPointerMove(event)) {
            _logSheetGesture(
              'start sheet from pointer move: '
              'dy=${event.delta.dy.toStringAsFixed(1)} '
              '${_controllerSnapshot()} ${_scrollSnapshot()}',
            );
            _isOverscrollDragging = true;
            _handleDragStart();
          }
          if (_isOverscrollDragging) {
            final scrollDelta = _handleDragUpdate(event.delta.dy);
            if (event.delta.dy < 0 && _isSheetFullyExpanded()) {
              _handoffDragBackToScrollable();
              _scrollActiveScrollableBy(scrollDelta);
            }
          }
        },
        onPointerUp: (event) {
          _velocityTracker?.addPosition(event.timeStamp, event.position);
          if (_isOverscrollDragging) {
            final velocityY =
                _velocityTracker?.getVelocity().pixelsPerSecond.dy ?? 0.0;
            _handleDragEnd(velocityY / widget.sheetHeight);
          } else {
            _logSheetGesture(
              'pointer up without sheet drag: ${_controllerSnapshot()} '
              '${_scrollSnapshot()}',
            );
          }
          _pointerKind = null;
          _isHandoffBackToScrollable = false;
        },
        onPointerCancel: (event) {
          if (_isOverscrollDragging) {
            _handleDragCancel();
          }
          _pointerKind = null;
          _isHandoffBackToScrollable = false;
        },
        behavior: HitTestBehavior.translucent,
        child: widget.child,
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

  void handoffToScrollable() {
    if (controller.isAnimating) {
      controller.stop();
    }
    controller.value = 1.0;
    navigator.didStopUserGesture();
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
