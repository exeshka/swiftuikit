import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:swiftuikit/src/services/screen_radius_service.dart';
import 'package:swiftuikit/src/routing/page_transitions.dart';

/// A modal page route with dynamic height that sizes to its content,
/// constrained to at most `screenHeight - topInset`.
///
/// Renders the child as-is with no custom UI chrome.
/// Slides up from the bottom, supports drag-to-dismiss with scroll handoff,
/// and background dimming. Does NOT participate in the sheet stack system
/// (no [SwiftSheetStackRoute] — previous route does not animate).
///
/// **Not stable** — API may change.
@experimental
class SwiftModalRoute<T> extends PageRoute<T>
    with CupertinoRouteTransitionMixin<T> {
  SwiftModalRoute({
    required this.child,
    required RouteSettings settings,
    this.sheetRadius,
    this.sheetBorderRadius,
    this.routeCanPop = true,
    bool barrierDismissible = true,
    this.barrierOpacity = 0.3,
    this.transitionDurationOverride = const Duration(milliseconds: 400),
    this.dismissThreshold = 0.3,
  })  : _barrierDismissible = barrierDismissible,
        super(settings: settings);

  final Widget child;
  final double? sheetRadius;
  final BorderRadius? sheetBorderRadius;
  final bool routeCanPop;
  final bool _barrierDismissible;
  final double barrierOpacity;
  final Duration transitionDurationOverride;
  final double dismissThreshold;

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
  String? get barrierLabel => 'Dismiss Modal';

  @override
  bool get barrierDismissible => _barrierDismissible;

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
    return _SwiftModalRouteTransition(
      route: this,
      animation: animation,
      sheetRadius: sheetRadius,
      sheetBorderRadius: sheetBorderRadius,
      barrierDismissible: barrierDismissible,
      barrierOpacity: barrierOpacity,
      dismissThreshold: dismissThreshold,
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Transition widget
// ---------------------------------------------------------------------------

class _SwiftModalRouteTransition extends StatefulWidget {
  const _SwiftModalRouteTransition({
    required this.route,
    required this.animation,
    required this.sheetRadius,
    required this.sheetBorderRadius,
    required this.barrierDismissible,
    required this.barrierOpacity,
    required this.dismissThreshold,
    required this.child,
  });

  final SwiftModalRoute route;
  final Animation<double> animation;
  final double? sheetRadius;
  final BorderRadius? sheetBorderRadius;
  final bool barrierDismissible;
  final double barrierOpacity;
  final double dismissThreshold;
  final Widget child;

  @override
  State<_SwiftModalRouteTransition> createState() =>
      _SwiftModalRouteTransitionState();
}

class _SwiftModalRouteTransitionState
    extends State<_SwiftModalRouteTransition> {
  late CurvedAnimation _primaryCurve;
  final GlobalKey _measureKey = GlobalKey();
  double? _measuredContentHeight;

  @override
  void initState() {
    super.initState();
    _primaryCurve = CurvedAnimation(
      parent: widget.animation,
      curve: Curves.fastEaseInToSlowEaseOut,
      reverseCurve: Curves.fastEaseInToSlowEaseOut.flipped,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureChild());
  }

  @override
  void didUpdateWidget(covariant _SwiftModalRouteTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      _primaryCurve.dispose();
      _primaryCurve = CurvedAnimation(
        parent: widget.animation,
        curve: Curves.fastEaseInToSlowEaseOut,
        reverseCurve: Curves.fastEaseInToSlowEaseOut.flipped,
      );
    }
  }

  @override
  void dispose() {
    _primaryCurve.dispose();
    super.dispose();
  }

  void _measureChild() {
    if (!mounted) return;
    final renderBox =
        _measureKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final height = renderBox.size.height;
      if (height > 0 &&
          (_measuredContentHeight == null ||
              (_measuredContentHeight! - height).abs() > 0.5)) {
        setState(() => _measuredContentHeight = height);
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final bool linearTransition = route.popGestureInProgress;

    final Animation<double> currentPrimary =
        linearTransition ? widget.animation : _primaryCurve;

    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double topPadding = MediaQuery.paddingOf(context).top;
    final double topOffset = math.max(
      SwiftPageTransitions.sheetMinimumTopOffset,
      topPadding + SwiftPageTransitions.sheetTopOffsetPadding,
    );
    final double maxHeight = screenHeight - topOffset;

    final double? measuredHeight = _measuredContentHeight;
    final double sheetHeight = measuredHeight != null
        ? math.min(measuredHeight, maxHeight)
        : maxHeight;
    final bool isScrollable =
        measuredHeight != null && measuredHeight > maxHeight;

    // Build the sheet body.
    Widget sheetBody;
    if (isScrollable) {
      sheetBody = SizedBox(
        height: maxHeight,
        child: SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: widget.child,
          ),
        ),
      );
    } else {
      sheetBody = SizedBox(
        width: double.infinity,
        child: widget.child,
      );
    }

    final sheetContent = MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: sheetBody,
    );

    return _SwiftModalGestureDetector(
      route: route,
      sheetHeight: sheetHeight,
      dismissThreshold: widget.dismissThreshold,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          currentPrimary,
          ScreenRadiusService.instance,
        ]),
        builder: (context, child) {
          final double primaryOffsetY =
              (1.0 - currentPrimary.value) * sheetHeight;

          return Stack(
            children: [
              // Measurement widget — constrained to maxHeight so the child
              // gets bounded height (0..maxHeight). Smaller children size to
              // their natural height; larger ones fill maxHeight.
              if (measuredHeight == null)
                Opacity(
                  opacity: 0,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxHeight),
                    child: SizedBox(
                      key: _measureKey,
                      child: widget.child,
                    ),
                  ),
                ),
              // Barrier
              GestureDetector(
                onTap: widget.barrierDismissible
                    ? () => route.navigator?.maybePop()
                    : null,
                child: Container(
                  color: Colors.black.withAlpha(
                    (currentPrimary.value * widget.barrierOpacity * 255)
                        .round(),
                  ),
                ),
              ),
              // Sheet content (after measurement)
              if (measuredHeight != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    height: sheetHeight,
                    child: Transform.translate(
                      offset: Offset(0.0, primaryOffsetY),
                      child: sheetContent,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gesture detector — swipe-to-dismiss with scroll handoff
// ---------------------------------------------------------------------------

class _SwiftModalGestureDetector extends StatefulWidget {
  const _SwiftModalGestureDetector({
    required this.child,
    required this.route,
    required this.sheetHeight,
    required this.dismissThreshold,
  });

  final Widget child;
  final SwiftModalRoute route;
  final double sheetHeight;
  final double dismissThreshold;

  @override
  State<_SwiftModalGestureDetector> createState() =>
      _SwiftModalGestureDetectorState();
}

class _SwiftModalGestureDetectorState
    extends State<_SwiftModalGestureDetector> {
  _SwiftModalGestureController? _gestureController;
  VelocityTracker? _velocityTracker;
  PointerDeviceKind? _pointerKind;
  ScrollPosition? _activeScrollPosition;
  bool _isHandoffBackToScrollable = false;
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
    _isHandoffBackToScrollable = false;
    // ignore: invalid_use_of_protected_member
    final double currentValue = widget.route.controller?.value ?? 1.0;
    if (currentValue < 0.25) return;

    _gestureController = _SwiftModalGestureController(
      navigator: widget.route.navigator!,
      // ignore: invalid_use_of_protected_member
      controller: widget.route.controller!,
      getIsActive: () => widget.route.isActive,
      getIsCurrent: () => widget.route.isCurrent,
      transitionDuration: widget.route.transitionDuration,
      dismissThreshold: widget.dismissThreshold,
    );
    final kind = _pointerKind;
    _velocityTracker = kind == null ? null : VelocityTracker.withKind(kind);
    _pinActiveScrollableToTop();
  }

  double _handleDragUpdate(double deltaY) {
    // ignore: invalid_use_of_protected_member
    final valueBeforeUpdate = widget.route.controller?.value ?? 1.0;

    _pinActiveScrollableToTop();
    _gestureController?.dragUpdate(deltaY / widget.sheetHeight);

    // When swiped upward past fully expanded, pass leftover to scrollable.
    // ignore: invalid_use_of_protected_member
    final valueAfterUpdate = widget.route.controller?.value ?? 1.0;
    if (deltaY >= 0 || valueAfterUpdate < 1.0) return 0.0;

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
    _gestureController?.dragEnd(velocityY);
    _gestureController = null;
    _isHandoffBackToScrollable = false;
    _isOverscrollDragging = false;
    _activeScrollPosition = null;
  }

  void _handoffDragBackToScrollable() {
    _gestureController?.handoffToScrollable();
    _gestureController = null;
    _isHandoffBackToScrollable = true;
    _isOverscrollDragging = false;
  }

  void _handleDragCancel() {
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
    if (position.pixels != top) position.jumpTo(top);
  }

  void _scrollActiveScrollableBy(double delta) {
    final position = _activeScrollPosition;
    if (position == null || !position.hasPixels || delta == 0.0) return;
    final target = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (target != position.pixels) position.jumpTo(target);
  }

  void _handleHandoffPointerMove(PointerMoveEvent event) {
    final position = _activeScrollPosition;
    if (position == null || !position.hasPixels) return;

    final deltaY = event.delta.dy;
    if (deltaY == 0.0) return;

    if (deltaY < 0) {
      _scrollActiveScrollableBy(-deltaY);
      return;
    }

    final distanceToTop = position.pixels - position.minScrollExtent;
    if (distanceToTop > 0.0) {
      final scrollDelta = -math.min(deltaY, distanceToTop);
      _scrollActiveScrollableBy(scrollDelta);
    }

    final remainingDownDelta = deltaY - math.max(0.0, distanceToTop);
    if (remainingDownDelta > 0.0) {
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
      if (!_isOverscrollDragging) {
        if (_isAtTop(notification.metrics) &&
            !_isHandoffBackToScrollable &&
            notification.dragDetails != null &&
            notification.dragDetails!.delta.dy > 0) {
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
          }
          _pointerKind = null;
          _isHandoffBackToScrollable = false;
        },
        onPointerCancel: (event) {
          if (_isOverscrollDragging) _handleDragCancel();
          _pointerKind = null;
          _isHandoffBackToScrollable = false;
        },
        behavior: HitTestBehavior.translucent,
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gesture controller — dismiss logic with threshold
// ---------------------------------------------------------------------------

class _SwiftModalGestureController {
  _SwiftModalGestureController({
    required this.navigator,
    required this.controller,
    required this.getIsActive,
    required this.getIsCurrent,
    required this.transitionDuration,
    required this.dismissThreshold,
  }) {
    navigator.didStartUserGesture();
  }

  final AnimationController controller;
  final NavigatorState navigator;
  final ValueGetter<bool> getIsActive;
  final ValueGetter<bool> getIsCurrent;
  final Duration transitionDuration;
  final double dismissThreshold;

  void dragUpdate(double delta) {
    controller.value = (controller.value - delta).clamp(0.01, 1.0);
  }

  void handoffToScrollable() {
    if (controller.isAnimating) controller.stop();
    controller.value = 1.0;
    navigator.didStopUserGesture();
  }

  void dragEnd(double velocity) {
    const Curve animationCurve = Curves.fastEaseInToSlowEaseOut;
    final bool isCurrent = getIsCurrent();
    final bool animateForward;

    if (!isCurrent) {
      animateForward = getIsActive();
    } else if (velocity.abs() >= 1.0) {
      animateForward = velocity < 0;
    } else {
      animateForward = controller.value > (1.0 - dismissThreshold);
    }

    if (animateForward) {
      controller.animateTo(
        1.0,
        duration: transitionDuration,
        curve: animationCurve,
      );
    } else {
      if (isCurrent) navigator.pop();
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
}
