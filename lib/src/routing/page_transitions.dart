import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

import 'package:swiftuikit/src/services/screen_radius_service.dart';
import 'package:swiftuikit/src/routing/sheet_route.dart';
import 'package:swiftuikit/src/routing/modal_route.dart';
import 'package:swiftuikit/src/routing/scroll_sheet_route.dart';

abstract interface class SwiftSheetStackRoute {
  Route? get nextRoute;
  Route? get previousRoute;
  set previousRoute(Route? route);
  double? get sheetRadius;
  BorderRadius? get sheetBorderRadius;
  ValueListenable<double> get sheetExtentListenable;
  double get sheetExtent;
  bool get animateBackground;
}

class SwiftPageTransitions {
  const SwiftPageTransitions._();

  // -- Size / layout ----------------------------------------------------------

  /// Minimum offset from the top of the screen for the sheet.
  /// Used when there is no safe area top padding.
  static double sheetMinimumTopOffset = 12.0;

  /// Gap from top of the screen (below status bar) for the active sheet.
  /// Standard iOS sheets have a 10.0 pixel margin.
  static double sheetTopOffsetPadding = 10.0;

  /// Gap between the top of the screen and the top of the sheet, as a ratio
  /// of the screen height.  Default 0.08 = 8% of screen height.
  static double sheetTopGapRatio = 0.08;

  /// Top gap ratio when the sheet is stretched upward during a drag.
  static double sheetStretchedTopGapRatio = 0.06;

  // -- Background page animation ----------------------------------------------

  /// Vertical offset step (in pixels) per stacked level in the background.
  /// Higher values push background cards lower.
  static double backgroundOffsetStep = 20.0;

  /// Scale step per stacked level in the background.
  /// e.g. 0.08 means level 0 = 1.0, level 1 = 0.92, level 2 = 0.84.
  static double scaleStep = 0.08;

  /// Scale factor for sheets moving into the background.
  /// The scale will go from 1.0 to 1.0 - [sheetScaleFactor].
  /// Matches native iOS 18 value of 0.0835.
  static double sheetScaleFactor = 0.0835;

  /// Vertical offset (as fraction of screen height) when a non-sheet page
  /// is covered by a sheet.
  static double sheetTopDownOffsetFraction = 0.07;

  /// Vertical offset (as fraction of screen height) when a sheet is covered
  /// by another sheet.
  static double sheetMidUpOffsetFraction = 0.005;

  // -- Corner radius ----------------------------------------------------------

  /// Default corner radius for sheet top corners.
  static double sheetCornerRadius = 38.0;

  /// Smoothing factor applied to the device's top padding to achieve a smoother
  /// end to the corner radius animation.
  static double sheetDeviceCornerRadiusSmoothingFactor = 0.9;

  /// Threshold in logical pixels for rounded device corners.
  static double sheetRoundedDeviceCornersThreshold = 20.0;

  /// Optional top radius applied to routes when they move into the sheet background.
  /// If null, the device screen radius from [ScreenRadiusService] is used.
  static double? sheetBackgroundRadius;

  /// Optional border radius applied to routes when they move into the sheet background.
  /// If null, [sheetBackgroundRadius] is used, then the device screen radius.
  static BorderRadius? sheetBackgroundBorderRadius;

  // -- Overlay / dimming ------------------------------------------------------

  /// Dimming opacity applied to background routes while a sheet is above them.
  /// The original Cupertino sheet package uses 0.10.
  static double sheetBackgroundDimmingOpacity = 0.10;

  /// Sheet extent where background route lift/scale starts.
  /// 0.5 means the previous page stays still until the sheet is half-open.
  static double sheetBackgroundAnimationStart = 0.5;

  static double sheetBackgroundProgressFor(double sheetExtent) {
    final start = sheetBackgroundAnimationStart.clamp(0.0, 0.99).toDouble();
    return ((sheetExtent - start) / (1.0 - start)).clamp(0.0, 1.0).toDouble();
  }

  static BorderRadius resolveBorderRadius(
    BuildContext context, {
    BorderRadius? borderRadius,
    double? radius,
    bool useScreenRadius = true,
  }) {
    if (borderRadius != null) return borderRadius;
    if (radius != null) return BorderRadius.circular(radius);
    return useScreenRadius
        ? ScreenRadiusService.instance.radius
        : BorderRadius.zero;
  }

  static BorderRadius resolveSheetBorderRadius(
    BuildContext context, {
    BorderRadius? borderRadius,
    double? radius,
    bool useScreenRadius = true,
  }) {
    if (borderRadius != null) return borderRadius;
    final double effectiveRadius =
        radius ?? SwiftPageTransitions.sheetCornerRadius;
    return BorderRadius.vertical(top: Radius.circular(effectiveRadius));
  }

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
    double pageOverlapFraction = 0.40,
    bool clipWithScreenRadius = true,
    double? radius,
    BorderRadius? borderRadius,
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
        pageOverlapFraction: pageOverlapFraction,
        clipWithScreenRadius: clipWithScreenRadius,
        radius: radius,
        borderRadius: borderRadius,
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
    double pageOverlapFraction = 0.40,
    bool clipWithScreenRadius = true,
    double? radius,
    BorderRadius? borderRadius,
    double? backGestureWidth,
    bool canSwipe = true,
    bool canOnlySwipeFromEdge = false,
    bool routeCanPop = true,
    Duration transitionDuration = const Duration(milliseconds: 400),
  }) {
    return SwiftPageRoute<T>(
      child: child,
      settings: settings,
      minScale: minScale,
      pageOverlapFraction: pageOverlapFraction,
      clipWithScreenRadius: clipWithScreenRadius,
      radius: radius,
      borderRadius: borderRadius,
      backGestureWidth: backGestureWidth,
      canSwipe: canSwipe,
      canOnlySwipeFromEdge: canOnlySwipeFromEdge,
      routeCanPop: routeCanPop,
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
    this.pageOverlapFraction = 0.40,
    this.clipWithScreenRadius = true,
    this.radius,
    this.borderRadius,
    this.backGestureWidth,
    this.canSwipe = true,
    this.canOnlySwipeFromEdge = false,
    this.routeCanPop = true,
    this.customTransitionDuration,
  }) : super(settings: settings);

  final Widget child;
  final double minScale;
  final double pageOverlapFraction;
  final bool clipWithScreenRadius;
  final double? radius;
  final BorderRadius? borderRadius;
  final double? backGestureWidth;
  final bool canSwipe;
  final bool canOnlySwipeFromEdge;
  final bool routeCanPop;
  final Duration? customTransitionDuration;

  Route? _nextRoute;
  bool _transitionGestureInProgress = false;
  bool _navigatorGestureActive = false;

  /// Returns the next route in the navigator stack.
  Route? get nextRoute => _nextRoute;

  /// The previous route in the navigator stack.
  Route? previousRoute;

  void _startUserGesture() {
    if (_transitionGestureInProgress) return;
    _transitionGestureInProgress = true;
    if (_navigatorGestureActive) return;
    _navigatorGestureActive = true;
    navigator!.didStartUserGesture();
  }

  void _releaseInputLock() {
    if (!_navigatorGestureActive) return;
    _navigatorGestureActive = false;
    navigator?.didStopUserGesture();
  }

  void _settleUserGesture() {
    _transitionGestureInProgress = false;
    _releaseInputLock();
  }

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
    if (!isActive && !isCurrent) return;
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
  RoutePopDisposition get popDisposition {
    if (!routeCanPop) return RoutePopDisposition.doNotPop;
    return super.popDisposition;
  }

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
      pageOverlapFraction: pageOverlapFraction,
      clipWithScreenRadius: clipWithScreenRadius,
      radius: radius,
      borderRadius: borderRadius,
    )(context, animation, secondaryAnimation, child);

    // We MUST always return _SwiftBackGestureDetector in the tree, otherwise it will
    // be disposed mid-gesture when popGestureEnabled changes to false.
    return _SwiftBackGestureDetector<T>(
      route: this,
      backGestureWidth: backGestureWidth,
      canSwipe: canSwipe,
      canOnlySwipeFromEdge: canOnlySwipeFromEdge,
      child: transitionWidget,
    );
  }
}

class _SwiftPageRouteTransition extends StatefulWidget {
  const _SwiftPageRouteTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.pageOverlapFraction,
    required this.clipWithScreenRadius,
    required this.radius,
    required this.borderRadius,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final double pageOverlapFraction;
  final bool clipWithScreenRadius;
  final double? radius;
  final BorderRadius? borderRadius;
  final Widget child;

  @override
  State<_SwiftPageRouteTransition> createState() =>
      _SwiftPageRouteTransitionState();
}

class _SwiftPageRouteTransitionState extends State<_SwiftPageRouteTransition> {
  late CurvedAnimation _primaryCurve;
  late CurvedAnimation _secondaryCurve;
  bool _wasNextRouteSheet = false;
  bool _wasNextRouteModal = false;
  bool _wasNextRoutePopGesture = false;
  double _lastSheetBackgroundProgress = 1.0;
  BorderRadius? _lastSheetBackgroundBorderRadius;
  bool _lastAnimateBackground = true;
  bool _hasPageBackgroundClipConfiguration = false;
  bool _lastPageBackgroundShouldClip = false;
  BorderRadius _lastPageBackgroundBorderRadius = BorderRadius.zero;

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

  BorderRadius _borderRadiusForMovement({
    required double progress,
    required BorderRadius target,
  }) {
    return progress > precisionErrorTolerance ? target : BorderRadius.zero;
  }

  bool _shouldClipForPage(SwiftPageRoute<dynamic>? configuration) {
    if (configuration != null) {
      return configuration.clipWithScreenRadius ||
          configuration.radius != null ||
          configuration.borderRadius != null;
    }
    return widget.clipWithScreenRadius ||
        widget.radius != null ||
        widget.borderRadius != null;
  }

  BorderRadius _resolveClipBorderRadius(
    BuildContext context, {
    SwiftPageRoute<dynamic>? configuration,
  }) {
    final borderRadius = configuration != null
        ? configuration.borderRadius
        : widget.borderRadius;
    final radius = configuration != null ? configuration.radius : widget.radius;
    final clipWithScreenRadius = configuration != null
        ? configuration.clipWithScreenRadius
        : widget.clipWithScreenRadius;

    if (borderRadius != null) return borderRadius;
    if (radius != null) return BorderRadius.circular(radius);
    if (!clipWithScreenRadius) return BorderRadius.zero;

    final screenRadius = ScreenRadiusService.instance.radius;
    final sheetScope = SwiftSheetScope.maybeOf(context);

    if (sheetScope != null) {
      return BorderRadius.only(
        topLeft: sheetScope.resolvedBorderRadius.topLeft,
        topRight: Radius.zero,
        bottomLeft: screenRadius.bottomLeft,
        bottomRight: Radius.zero,
      );
    }

    return BorderRadius.only(
      topLeft: screenRadius.topLeft,
      topRight: Radius.zero,
      bottomLeft: screenRadius.bottomLeft,
      bottomRight: Radius.zero,
    );
  }

  BorderRadius _resolveSheetBackgroundBorderRadius(
    BuildContext context,
    Route? nextRoute,
  ) {
    BorderRadius? borderRadius;
    double? radius;

    if (nextRoute is SwiftSheetRoute) {
      borderRadius = nextRoute.sheetBorderRadius;
      radius = nextRoute.sheetRadius;
    } else if (nextRoute is SwiftSheetStackRoute) {
      final stackRoute = nextRoute as SwiftSheetStackRoute;
      borderRadius = stackRoute.sheetBorderRadius;
      radius = stackRoute.sheetRadius;
    }

    return SwiftPageTransitions.resolveSheetBorderRadius(
      context,
      radius: radius ?? SwiftPageTransitions.sheetBackgroundRadius,
      borderRadius:
          borderRadius ?? SwiftPageTransitions.sheetBackgroundBorderRadius,
      useScreenRadius: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final SwiftPageRoute<dynamic>? swiftRoute = route is SwiftPageRoute
        ? route
        : null;
    final SwiftPageRoute<dynamic>? nextSwiftRoute =
        swiftRoute?.nextRoute is SwiftPageRoute
        ? swiftRoute!.nextRoute as SwiftPageRoute<dynamic>
        : null;
    final bool currentRoutePopGesture =
        swiftRoute?._transitionGestureInProgress == true;
    final bool nextRoutePopGesture =
        nextSwiftRoute?._transitionGestureInProgress == true;
    final bool navigatorPopGesture =
        route is PageRoute && route.popGestureInProgress;
    if (nextRoutePopGesture) {
      _wasNextRoutePopGesture = true;
    } else if (nextSwiftRoute != null ||
        widget.secondaryAnimation.isDismissed) {
      _wasNextRoutePopGesture = false;
    }
    final bool linearTransition =
        currentRoutePopGesture ||
        nextRoutePopGesture ||
        _wasNextRoutePopGesture ||
        navigatorPopGesture;

    if (nextSwiftRoute != null) {
      _hasPageBackgroundClipConfiguration = true;
      _lastPageBackgroundShouldClip = _shouldClipForPage(nextSwiftRoute);
      _lastPageBackgroundBorderRadius = _lastPageBackgroundShouldClip
          ? _resolveClipBorderRadius(context, configuration: nextSwiftRoute)
          : BorderRadius.zero;
    } else if (widget.secondaryAnimation.isDismissed) {
      _hasPageBackgroundClipConfiguration = false;
      _lastPageBackgroundShouldClip = false;
      _lastPageBackgroundBorderRadius = BorderRadius.zero;
    }

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

    final SwiftSheetStackRoute? nextStackRoute =
        nextRoute is SwiftSheetStackRoute
        ? nextRoute as SwiftSheetStackRoute
        : null;
    final bool isNextRouteSheet =
        nextRoute is SwiftSheetRoute || nextStackRoute != null;
    if (isNextRouteSheet) {
      _wasNextRouteSheet = true;
    } else if (widget.secondaryAnimation.value == 0.0) {
      _wasNextRouteSheet = false;
      _lastSheetBackgroundProgress = 1.0;
    }
    final bool activeNextRouteSheet =
        isNextRouteSheet ||
        (_wasNextRouteSheet && widget.secondaryAnimation.value > 0.0);
    final bool animateBackground;
    if (nextRoute is SwiftSheetRoute) {
      animateBackground = nextRoute.animateBackground;
      _lastAnimateBackground = animateBackground;
    } else if (nextStackRoute != null) {
      animateBackground = nextStackRoute.animateBackground;
      _lastAnimateBackground = animateBackground;
    } else if (_wasNextRouteSheet && widget.secondaryAnimation.value > 0.0) {
      animateBackground = _lastAnimateBackground;
    } else {
      animateBackground = true;
      _lastAnimateBackground = true;
    }

    final bool isNextRouteModal =
        nextRoute is SwiftModalRoute || nextRoute is SwiftScrollSheetRoute;
    if (isNextRouteModal) {
      _wasNextRouteModal = true;
    } else if (widget.secondaryAnimation.value == 0.0) {
      _wasNextRouteModal = false;
    }

    return Offstage(
      offstage: isOffstage,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          currentPrimary,
          currentSecondary,
          if (nextStackRoute != null) nextStackRoute.sheetExtentListenable,
          if (widget.clipWithScreenRadius) ScreenRadiusService.instance,
        ]),
        builder: (context, child) {
          if (activeNextRouteSheet) {
            if (!animateBackground) {
              return child ?? const SizedBox.shrink();
            }
            final double sheetProgress;
            if (nextStackRoute != null) {
              sheetProgress = SwiftPageTransitions.sheetBackgroundProgressFor(
                nextStackRoute.sheetExtent,
              );
              _lastSheetBackgroundProgress = sheetProgress;
            } else if (isNextRouteSheet) {
              sheetProgress = 1.0;
              _lastSheetBackgroundProgress = sheetProgress;
            } else {
              sheetProgress = _lastSheetBackgroundProgress;
            }
            final double s = currentSecondary.value * sheetProgress;

            final double translationX = (1.0 - currentPrimary.value) * width;
            final double translationY =
                s * SwiftPageTransitions.backgroundOffsetStep;
            final double scale = 1.0 - (s * SwiftPageTransitions.scaleStep);

            if (isNextRouteSheet) {
              _lastSheetBackgroundBorderRadius =
                  _resolveSheetBackgroundBorderRadius(context, nextRoute);
            }

            final BorderRadius targetBorderRadius =
                _lastSheetBackgroundBorderRadius ??
                _resolveSheetBackgroundBorderRadius(context, nextRoute);

            final BorderRadius borderRadius = _borderRadiusForMovement(
              progress: s,
              target: targetBorderRadius,
            );

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

            if (s > precisionErrorTolerance) {
              transitionChild = Stack(
                children: [
                  transitionChild,
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: borderRadius,
                          color: CupertinoColors.black.withAlpha(
                            (s *
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

            if (s > precisionErrorTolerance) {
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
            // When a modal route is pushed on top, don't animate this page.
            final bool skipSecondary =
                isNextRouteModal ||
                (_wasNextRouteModal && currentSecondary.value > 0.0);
            final double secondaryValue = skipSecondary
                ? 0.0
                : currentSecondary.value;

            final double translationX =
                (1.0 - currentPrimary.value) * width -
                secondaryValue * width * widget.pageOverlapFraction;
            final double radiusProgress = math.max(
              (1.0 - currentPrimary.value).abs(),
              secondaryValue,
            );

            // A page moving out of the background is part of the same physical
            // transition as the page above it. Use the foreground route's
            // corner configuration so both surfaces keep one continuous shape.
            final useForegroundClipConfiguration =
                nextSwiftRoute != null ||
                (_hasPageBackgroundClipConfiguration &&
                    currentSecondary.value > precisionErrorTolerance);
            final shouldClip = useForegroundClipConfiguration
                ? _lastPageBackgroundShouldClip
                : _shouldClipForPage(null);
            final targetBorderRadius = shouldClip
                ? useForegroundClipConfiguration
                      ? _lastPageBackgroundBorderRadius
                      : _resolveClipBorderRadius(context)
                : BorderRadius.zero;
            final borderRadius = _borderRadiusForMovement(
              progress: radiusProgress,
              target: targetBorderRadius,
            );

            final clippedChild = shouldClip
                ? ClipRRect(
                    borderRadius: borderRadius,
                    clipBehavior: Clip.antiAlias,
                    child: child,
                  )
                : child;

            final shadowOpacity = currentPrimary.value * 0.3;
            final shadowChild = Container(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withValues(
                      alpha: shadowOpacity,
                    ),
                    offset: const Offset(0, 10),
                    blurRadius: 100,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: clippedChild,
            );

            final transitionChild = Transform.translate(
              offset: Offset(translationX, 0.0),
              child: shadowChild,
            );

            return transitionChild;
          }
        },
        child: widget.child,
      ),
    );
  }
}

class _DirectionDependentDragGestureRecognizer
    extends HorizontalDragGestureRecognizer {
  _DirectionDependentDragGestureRecognizer({
    required this.directionality,
    required this.enabledCallback,
    required this.checkStartedCallback,
    super.debugOwner,
  });

  final TextDirection directionality;
  final ValueGetter<bool> enabledCallback;
  final ValueGetter<bool> checkStartedCallback;
  final Map<int, Offset> _pendingOffsets = <int, Offset>{};
  final Set<int> _activePointers = <int>{};
  final Set<int> _scheduledAccepts = <int>{};

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _pendingOffsets[event.pointer] = Offset.zero;
    _activePointers.add(event.pointer);
    super.addAllowedPointer(event);
  }

  @override
  bool hasSufficientGlobalDistanceToAccept(
    PointerDeviceKind pointerDeviceKind,
    double? deviceTouchSlop,
  ) {
    return false;
  }

  @override
  void handleEvent(PointerEvent event) {
    if (checkStartedCallback()) {
      super.handleEvent(event);
      _removePointerIfFinished(event);
      return;
    }

    if (!enabledCallback()) {
      stopTrackingPointer(event.pointer);
      _removePointer(event.pointer);
      return;
    }

    var shouldScheduleAccept = false;
    if (event case PointerMoveEvent()) {
      final offset =
          (_pendingOffsets[event.pointer] ?? Offset.zero) + event.delta;
      _pendingOffsets[event.pointer] = offset;
      final touchSlop = gestureSettings?.touchSlop ?? kTouchSlop;
      if (offset.distanceSquared > touchSlop * touchSlop) {
        final isHorizontal = offset.dx.abs() > offset.dy.abs();
        final isBackDirection = switch (directionality) {
          TextDirection.ltr => offset.dx > 0,
          TextDirection.rtl => offset.dx < 0,
        };
        if (!isHorizontal || !isBackDirection) {
          stopTrackingPointer(event.pointer);
          _removePointer(event.pointer);
          return;
        }
        shouldScheduleAccept = true;
      }
    }

    super.handleEvent(event);

    if (shouldScheduleAccept &&
        _activePointers.contains(event.pointer) &&
        _scheduledAccepts.add(event.pointer)) {
      scheduleMicrotask(() {
        _scheduledAccepts.remove(event.pointer);
        if (_activePointers.contains(event.pointer) &&
            !checkStartedCallback()) {
          resolve(GestureDisposition.accepted);
        }
      });
    }

    _removePointerIfFinished(event);
  }

  void _removePointerIfFinished(PointerEvent event) {
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _removePointer(event.pointer);
    }
  }

  void _removePointer(int pointer) {
    _pendingOffsets.remove(pointer);
    _activePointers.remove(pointer);
    _scheduledAccepts.remove(pointer);
  }

  @override
  void rejectGesture(int pointer) {
    _removePointer(pointer);
    super.rejectGesture(pointer);
  }

  @override
  void dispose() {
    _pendingOffsets.clear();
    _activePointers.clear();
    _scheduledAccepts.clear();
    super.dispose();
  }
}

class _EdgeBackGestureRecognizer extends HorizontalDragGestureRecognizer {
  _EdgeBackGestureRecognizer({
    required this.directionality,
    required this.checkStartedCallback,
    super.debugOwner,
  });

  final ValueGetter<TextDirection> directionality;
  final ValueGetter<bool> checkStartedCallback;
  final Map<int, Offset> _pendingOffsets = <int, Offset>{};

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _pendingOffsets[event.pointer] = Offset.zero;
    super.addAllowedPointer(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event case PointerMoveEvent() when !checkStartedCallback()) {
      final offset =
          (_pendingOffsets[event.pointer] ?? Offset.zero) + event.delta;
      _pendingOffsets[event.pointer] = offset;
      if (offset.distanceSquared >= 9.0) {
        final isHorizontal = offset.dx.abs() > offset.dy.abs();
        final isBackDirection = switch (directionality()) {
          TextDirection.ltr => offset.dx > 0,
          TextDirection.rtl => offset.dx < 0,
        };
        if (!isHorizontal || !isBackDirection) {
          stopTrackingPointer(event.pointer);
          _pendingOffsets.remove(event.pointer);
          return;
        }
        resolve(GestureDisposition.accepted);
      }
    }

    super.handleEvent(event);
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _pendingOffsets.remove(event.pointer);
    }
  }

  @override
  void rejectGesture(int pointer) {
    _pendingOffsets.remove(pointer);
    super.rejectGesture(pointer);
  }

  @override
  void dispose() {
    _pendingOffsets.clear();
    super.dispose();
  }
}

class _SwiftBackGestureDetector<T> extends StatefulWidget {
  const _SwiftBackGestureDetector({
    super.key,
    required this.child,
    required this.route,
    required this.backGestureWidth,
    required this.canSwipe,
    required this.canOnlySwipeFromEdge,
  });

  final Widget child;
  final SwiftPageRoute<T> route;
  final double? backGestureWidth;
  final bool canSwipe;
  final bool canOnlySwipeFromEdge;

  @override
  State<_SwiftBackGestureDetector<T>> createState() =>
      _SwiftBackGestureDetectorState<T>();
}

class _SwiftBackGestureDetectorState<T>
    extends State<_SwiftBackGestureDetector<T>> {
  _SwiftBackGestureController<T>? _backGestureController;
  late final HorizontalDragGestureRecognizer _edgeRecognizer;

  @override
  void initState() {
    super.initState();
    _edgeRecognizer =
        _EdgeBackGestureRecognizer(
            debugOwner: this,
            directionality: () => Directionality.of(context),
            checkStartedCallback: () => _backGestureController != null,
          )
          ..onStart = _handleDragStart
          ..onUpdate = _handleDragUpdate
          ..onEnd = _handleDragEnd
          ..onCancel = _handleDragCancel;
  }

  @override
  void dispose() {
    _edgeRecognizer.dispose();
    if (_backGestureController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_backGestureController?.navigator.mounted ?? false) {
          _backGestureController?.settleUserGesture();
        }
        _backGestureController = null;
      });
    }
    super.dispose();
  }

  bool _isGestureEnabled() {
    if (!widget.canSwipe) return false;
    final route = widget.route;
    if (!route.isActive || !route.isCurrent) return false;
    return route.popGestureEnabled;
  }

  _DirectionDependentDragGestureRecognizer _createRecognizer() {
    final directionality = Directionality.of(context);
    return _DirectionDependentDragGestureRecognizer(
        debugOwner: this,
        directionality: directionality,
        checkStartedCallback: () => _backGestureController != null,
        enabledCallback: _isGestureEnabled,
      )
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel;
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
      startUserGesture: widget.route._startUserGesture,
      settleUserGesture: widget.route._settleUserGesture,
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

  void _handleEdgePointerDown(PointerDownEvent event) {
    if (_isGestureEnabled()) {
      _edgeRecognizer.addPointer(event);
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

    Widget gestureDetector({Widget? child}) {
      return RawGestureDetector(
        behavior: HitTestBehavior.translucent,
        gestures: {
          _DirectionDependentDragGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<
                _DirectionDependentDragGestureRecognizer
              >(_createRecognizer, (instance) {}),
        },
        child: child,
      );
    }

    final textDirection = Directionality.of(context);
    final padding = MediaQuery.paddingOf(context);
    final systemEdgeInset = switch (textDirection) {
      TextDirection.ltr => padding.left,
      TextDirection.rtl => padding.right,
    };
    final edgeWidth =
        widget.backGestureWidth ?? math.max(20.0, systemEdgeInset);
    final child = widget.canOnlySwipeFromEdge
        ? widget.child
        : gestureDetector(child: widget.child);

    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        PositionedDirectional(
          start: 0,
          width: edgeWidth,
          top: 0,
          bottom: 0,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _handleEdgePointerDown,
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
    required this.startUserGesture,
    required this.settleUserGesture,
  }) {
    startUserGesture();
  }

  final AnimationController controller;
  final NavigatorState navigator;
  final ValueGetter<bool> getIsActive;
  final ValueGetter<bool> getIsCurrent;
  final VoidCallback startUserGesture;
  final VoidCallback settleUserGesture;

  void dragUpdate(double delta) {
    controller.value -= delta;
  }

  void dragEnd(double velocity) {
    const Curve animationCurve = Curves.fastEaseInToSlowEaseOut;
    const int maxPageBackAnimationTime = 300;
    final settleDuration =
        controller.reverseDuration ??
        controller.duration ??
        const Duration(milliseconds: 400);
    final settleMilliseconds = settleDuration.inMilliseconds;
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

    TickerFuture? ticker;
    if (animateForward) {
      final droppedForwardTime = math.min(
        lerpDouble(settleMilliseconds.toDouble(), 0, controller.value)!.floor(),
        maxPageBackAnimationTime,
      );
      ticker = controller.animateTo(
        1.0,
        duration: Duration(milliseconds: droppedForwardTime),
        curve: animationCurve,
      );
    } else {
      if (isCurrent) {
        navigator.pop();
      }

      if (controller.isAnimating) {
        final droppedBackTime = lerpDouble(
          0,
          settleMilliseconds.toDouble(),
          controller.value,
        )!.floor();
        ticker = controller.animateBack(
          0.0,
          duration: Duration(milliseconds: droppedBackTime),
          curve: animationCurve,
        );
      }
    }

    if (controller.isAnimating) {
      ticker!.whenCompleteOrCancel(settleUserGesture);
    } else {
      settleUserGesture();
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
    } else if (current is SwiftSheetStackRoute) {
      next = (current as SwiftSheetStackRoute).nextRoute;
    }
    if (next == null) break;
    depth++;
    current = next;
  }
  return depth;
}
