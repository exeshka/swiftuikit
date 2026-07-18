// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/physics.dart';

import 'package:swiftuikit/src/routing/page_transitions.dart';

// Tween for animating a Cupertino sheet onto the screen.
//
// Begins fully offscreen below the screen and ends onscreen with a small gap at
// the top of the screen. Values found from eyeballing a simulator running iOS 18.0.
final Animatable<Offset> _kBottomUpTween = Tween<Offset>(
  begin: const Offset(0.0, 1.0),
  end: Offset.zero,
);

// Offset change for when a new sheet covers another sheet. '0.0' represents the
// top of the space available for the new sheet, but because the previous sheet
// was lowered slightly, the new sheet needs to go slightly higher than that.
// Values found from eyeballing a simulator running iOS 18.0.
final Animatable<Offset> _kBottomUpTweenWhenCoveringOtherSheet = Tween<Offset>(
  begin: const Offset(0.0, 1.0),
  end: const Offset(0.0, -0.02),
);

// The signature for a method called on the start of a drag.
typedef _DragStartCallback = void Function();

// The signature for a method called to trigger a change based on a moving drag gesture.
typedef _DragUpdateCallback = void Function(double delta);

// The signature for a method called on the end of a drag, passing the velocity at
// the end of the drag along.
typedef _DragEndCallback = void Function(double velocity);

// The signature for a method that checks if the sheet is currently dragged downwards.
typedef _GetSheetDragged = bool Function();

/// Shows a Cupertino-style sheet widget that slides up from the bottom of the
/// screen and stacks the previous route behind the new sheet.
///
/// This is a convenience method for displaying [SwiftSheetRoute] for most
/// use cases. The Widget returned from `scrollableBuilder` will be used to display
/// the content on the [SwiftSheetRoute]. If the content of the sheet has a
/// scrollable view, the [ScrollController] provided by `scrollableBuilder` can be
/// used to enable the drag-to-dismiss gesture to work with the scrolling of the
/// content.
///
/// `useNestedNavigation` allows new routes to be pushed inside of a [SwiftSheetRoute]
/// by adding a new [Navigator] inside of the [SwiftSheetRoute].
///
/// When `useNestedNavigation` is set to `true`, any route pushed to the stack
/// from within the context of the [SwiftSheetRoute] will display within that
/// sheet. System back gestures and programmatic pops on the initial route in a
/// sheet will also be intercepted to pop the whole [SwiftSheetRoute].
///
/// The whole sheet can be popped at once by either dragging down on the sheet,
/// or calling [SwiftSheetRoute.popSheet].
///
/// When `enableDrag` is set to `true` (the default), users can dismiss the sheet
/// by dragging it down or by calling [SwiftSheetRoute.popSheet]. When
/// `enableDrag` is `false`, users cannot dismiss the sheet by dragging, and it
/// can only be closed by calling [SwiftSheetRoute.popSheet].
///
/// The `topGap` parameter can be used to customize the gap between the top of
/// the screen and the top of the sheet as a ratio of the screen height.
/// It should be a value between 0.0 and 0.9, where 0.0 means no gap and 0.9
/// means the sheet takes up only the bottom 10% of the screen. If not provided, defaults
/// to [SwiftPageTransitions.sheetTopGapRatio].
///
/// When `showDragHandle` is set to `true`, then a drag handle will be placed at
/// the top of the sheet. This flag will default to false.
Future<T?> showSwiftSheet<T>({
  required BuildContext context,
  @Deprecated(
    'Use scrollableBuilder instead. '
    'This feature was deprecated after v3.33.0-0.2.pre.',
  )
  WidgetBuilder? pageBuilder,
  @Deprecated(
    'Use scrollableBuilder instead. '
    'This feature was deprecated after v3.40.0-0.2.pre.',
  )
  WidgetBuilder? builder,
  ScrollableWidgetBuilder? scrollableBuilder,
  bool useNestedNavigation = false,
  bool enableDrag = true,
  RouteSettings? settings,
  double? topGap,
  bool showDragHandle = false,
  double? sheetRadius,
  BorderRadius? sheetBorderRadius,
  bool routeCanPop = true,
  Duration transitionDuration = const Duration(milliseconds: 500),
}) {
  assert(
    topGap == null || (topGap >= 0.0 && topGap <= 0.9),
    'topGap must be between 0.0 and 0.9',
  );
  assert(pageBuilder != null || builder != null || scrollableBuilder != null);
  assert(
    (pageBuilder == null && builder == null && scrollableBuilder != null) ||
        scrollableBuilder == null,
  );

  final WidgetBuilder? effectiveBuilder = builder ?? pageBuilder;
  final nestedNavigatorKey = GlobalKey<NavigatorState>();
  if (!useNestedNavigation) {
    final PageRoute<T> route = SwiftSheetRoute<T>(
      builder: effectiveBuilder,
      scrollableBuilder: scrollableBuilder,
      settings: settings,
      enableDrag: enableDrag,
      showDragHandle: showDragHandle,
      topGap: topGap,
      sheetRadius: sheetRadius,
      sheetBorderRadius: sheetBorderRadius,
      routeCanPop: routeCanPop,
      transitionDurationOverride: transitionDuration,
    );

    return Navigator.of(context, rootNavigator: true).push<T>(route);
  } else {
    Widget nestedNavigationContent(WidgetBuilder builder) {
      return NavigatorPopHandler(
        onPopWithResult: (T? result) {
          nestedNavigatorKey.currentState!.maybePop();
        },
        child: Navigator(
          key: nestedNavigatorKey,
          initialRoute: '/',
          onGenerateInitialRoutes:
              (NavigatorState navigator, String initialRouteName) {
                return <Route<void>>[
                  CupertinoPageRoute<void>(
                    builder: (BuildContext context) {
                      return PopScope(
                        canPop: false,
                        onPopInvokedWithResult: (bool didPop, Object? result) {
                          if (didPop) {
                            return;
                          }
                          Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pop(result);
                        },
                        child: builder(context),
                      );
                    },
                  ),
                ];
              },
        ),
      );
    }

    final route = SwiftSheetRoute<T>(
      scrollableBuilder: (BuildContext context, ScrollController controller) =>
          nestedNavigationContent(
            scrollableBuilder != null
                ? (BuildContext context) =>
                      scrollableBuilder(context, controller)
                : effectiveBuilder!,
          ),
      settings: settings,
      enableDrag: enableDrag,
      showDragHandle: showDragHandle,
      topGap: topGap,
      sheetRadius: sheetRadius,
      sheetBorderRadius: sheetBorderRadius,
      routeCanPop: routeCanPop,
      transitionDurationOverride: transitionDuration,
    );
    return Navigator.of(context, rootNavigator: true).push<T>(route);
  }
}

/// Provides an iOS-style sheet transition.
///
/// The page slides up and stops below the top of the screen. When covered by
/// another sheet view, it will slide slightly up and scale down to appear
/// stacked behind the new sheet.
class SwiftSheetTransition extends StatefulWidget {
  /// Creates an iOS style sheet transition.
  const SwiftSheetTransition({
    super.key,
    required this.primaryRouteAnimation,
    required this.secondaryRouteAnimation,
    required this.child,
    required this.linearTransition,
    required this.transitionDuration,
    this.topGap = 0.08,
  });

  /// `primaryRouteAnimation` is a linear route animation from 0.0 to 1.0 when
  /// this screen is being pushed.
  final Animation<double> primaryRouteAnimation;

  /// `secondaryRouteAnimation` is a linear route animation from 0.0 to 1.0 when
  /// another screen is being pushed on top of this one.
  final Animation<double> secondaryRouteAnimation;

  /// The widget below this widget in the tree.
  final Widget child;

  /// Whether to perform the transition linearly.
  ///
  /// Used to respond to a drag gesture.
  final bool linearTransition;

  /// Duration of the transition, used for custom spring physics curves.
  final Duration transitionDuration;

  /// The gap between the top of the screen and the top of the sheet as a ratio
  /// of the screen height.
  final double topGap;

  /// The primary delegated transition. Will slide a non [SwiftSheetRoute] page down.
  ///
  /// Provided to the previous route to coordinate transitions between routes.
  ///
  /// If a [SwiftSheetRoute] already exists in the stack, then it will
  /// slide the previous sheet upwards instead.
  static Widget delegateTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child, {
    double? sheetRadius,
    BorderRadius? sheetBorderRadius,
  }) {
    final route = ModalRoute.of(context);
    final isSheet = route is SwiftSheetRoute || route is CupertinoSheetRoute;
    if (isSheet ||
        SwiftSheetRoute.hasParentSheet(context) ||
        CupertinoSheetRoute.hasParentSheet(context)) {
      return _delegatedCoverSheetSecondaryTransition(context, secondaryAnimation, child);
    }
    final bool linear = Navigator.of(context).userGestureInProgress;

    final Curve curve = linear ? Curves.linear : Curves.linearToEaseOut;
    final Curve reverseCurve = linear ? Curves.linear : Curves.easeInToLinear;
    final curvedAnimation = CurvedAnimation(
      curve: curve,
      reverseCurve: reverseCurve,
      parent: secondaryAnimation,
    );

    final double deviceCornerRadius =
        (MediaQuery.maybeViewPaddingOf(context)?.top ?? 0) *
        SwiftPageTransitions.sheetDeviceCornerRadiusSmoothingFactor;
    final bool roundedDeviceCorners =
        deviceCornerRadius >
        SwiftPageTransitions.sheetRoundedDeviceCornersThreshold;

    final scope = _SwiftSheetScope.maybeOf(context);
    final double? customRadius = sheetRadius ?? scope?.radius;
    final BorderRadius? customBorderRadius = sheetBorderRadius ?? scope?.borderRadius;

    final BorderRadiusGeometry targetRadius;
    if (customBorderRadius != null) {
      targetRadius = customBorderRadius;
    } else if (customRadius != null) {
      targetRadius = BorderRadius.all(Radius.circular(customRadius));
    } else {
      targetRadius = BorderRadius.all(
        Radius.circular(SwiftPageTransitions.sheetCornerRadius),
      );
    }

    final BorderRadiusGeometry startRadius;
    if (customBorderRadius != null) {
      startRadius = customBorderRadius;
    } else if (customRadius != null) {
      startRadius = BorderRadius.all(Radius.circular(customRadius));
    } else if (roundedDeviceCorners) {
      startRadius = BorderRadius.vertical(
        top: Radius.circular(deviceCornerRadius),
      );
    } else {
      startRadius = BorderRadius.zero;
    }

    final Animatable<BorderRadiusGeometry> decorationTween =
        Tween<BorderRadiusGeometry>(begin: startRadius, end: targetRadius);

    final Animation<BorderRadiusGeometry> radiusAnimation = curvedAnimation
        .drive(decorationTween);
    final Animation<double> opacityAnimation = curvedAnimation.drive(
      Tween<double>(
        begin: 0.0,
        end: SwiftPageTransitions.sheetBackgroundDimmingOpacity,
      ),
    );

    final Animatable<Offset> topDownTween = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(0.0, SwiftPageTransitions.sheetTopDownOffsetFraction),
    );
    final Animation<Offset> slideAnimation = curvedAnimation.drive(
      topDownTween,
    );

    final Animatable<double> scaleTween = Tween<double>(
      begin: 1.0,
      end: 1.0 - SwiftPageTransitions.sheetScaleFactor,
    );
    final Animation<double> scaleAnimation = curvedAnimation.drive(scaleTween);

    final isDarkMode = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final overlayColor = isDarkMode
        ? const Color(0xFFc8c8c8)
        : const Color(0xFF000000);

    final Widget? contrastedChild =
        child != null && !secondaryAnimation.isDismissed
        ? Stack(
            children: <Widget>[
              child,
              FadeTransition(
                opacity: opacityAnimation,
                child: ColoredBox(
                  color: overlayColor,
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          )
        : child;

    final double topGapHeight =
        MediaQuery.sizeOf(context).height *
        SwiftPageTransitions.sheetTopGapRatio;

    return Stack(
      children: <Widget>[
        AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarBrightness: Brightness.dark,
            statusBarIconBrightness: Brightness.light,
          ),
          child: SizedBox(height: topGapHeight, width: double.infinity),
        ),
        SlideTransition(
          position: slideAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            filterQuality: FilterQuality.medium,
            alignment: Alignment.topCenter,
            child: AnimatedBuilder(
              animation: radiusAnimation,
              child: contrastedChild,
              builder: (BuildContext context, Widget? child) {
                return ClipRSuperellipse(
                  borderRadius: !secondaryAnimation.isDismissed
                      ? radiusAnimation.value
                      : BorderRadius.zero,
                  child: child,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  static Widget _delegatedCoverSheetSecondaryTransition(
    BuildContext context,
    Animation<double> secondaryAnimation,
    Widget? child,
  ) {
    final bool linear = Navigator.of(context).userGestureInProgress;
    final Curve curve = linear ? Curves.linear : Curves.linearToEaseOut;
    final Curve reverseCurve = linear ? Curves.linear : Curves.easeInToLinear;
    final curvedAnimation = CurvedAnimation(
      curve: curve,
      reverseCurve: reverseCurve,
      parent: secondaryAnimation,
    );

    final Animatable<Offset> midUpTween = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(0.0, -SwiftPageTransitions.sheetMidUpOffsetFraction),
    );
    final Animation<Offset> slideAnimation = curvedAnimation.drive(midUpTween);

    final Animatable<double> scaleTween = Tween<double>(
      begin: 1.0,
      end: 1.0 - SwiftPageTransitions.sheetScaleFactor,
    );
    final Animation<double> scaleAnimation = curvedAnimation.drive(scaleTween);

    return SlideTransition(
      position: slideAnimation,
      transformHitTests: false,
      child: ScaleTransition(
        scale: scaleAnimation,
        filterQuality: FilterQuality.medium,
        alignment: Alignment.topCenter,
        child: ClipRSuperellipse(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(SwiftPageTransitions.sheetCornerRadius),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  State<SwiftSheetTransition> createState() => _SwiftSheetTransitionState();
}

class _SwiftSheetTransitionState extends State<SwiftSheetTransition>
    with SingleTickerProviderStateMixin {
  // Controls the top padding animation when the sheet is being slightly stretched upward.
  late AnimationController _stretchDragController;

  // Animates the top padding of the sheet based on the _stretchDragController’s value.
  late Animation<double> _stretchDragAnimation;

  // The offset animation when this page is being covered by another sheet.
  late Animation<Offset> _secondaryPositionAnimation;

  // The scale animation when this page is being covered by another sheet.
  late Animation<double> _secondaryScaleAnimation;

  // Curve of primary page which is coming in to cover another route.
  CurvedAnimation? _primaryPositionCurve;

  // Curve of secondary page which is becoming covered by another sheet.
  CurvedAnimation? _secondaryPositionCurve;

  @override
  void initState() {
    super.initState();

    _stretchDragController = AnimationController(
      duration: const Duration(microseconds: 1),
      value: 0.0,
      lowerBound: -0.5,
      upperBound: 1.5,
      vsync: this,
    );
    _setupAnimation();
  }

  @override
  void didUpdateWidget(covariant SwiftSheetTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.primaryRouteAnimation != widget.primaryRouteAnimation ||
        oldWidget.secondaryRouteAnimation != widget.secondaryRouteAnimation) {
      _disposeCurve();
      _setupAnimation();
    }
  }

  @override
  void dispose() {
    _disposeCurve();
    _stretchDragController.dispose();
    super.dispose();
  }

  void _setupAnimation() {
    _primaryPositionCurve = CurvedAnimation(
      curve: Curves.fastEaseInToSlowEaseOut,
      reverseCurve: Curves.fastEaseInToSlowEaseOut.flipped,
      parent: widget.primaryRouteAnimation,
    );
    _secondaryPositionCurve = CurvedAnimation(
      curve: Curves.linearToEaseOut,
      reverseCurve: Curves.easeInToLinear,
      parent: widget.secondaryRouteAnimation,
    );
    // Maintain the same stretch distance regardless of custom topGap.
    final double stretchDistance =
        SwiftPageTransitions.sheetTopGapRatio -
        SwiftPageTransitions.sheetStretchedTopGapRatio;
    final double stretchedTopGap = widget.topGap - stretchDistance;
    _stretchDragAnimation = _stretchDragController.drive(
      Tween<double>(begin: widget.topGap, end: stretchedTopGap),
    );

    final Animatable<Offset> midUpTween = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(0.0, -SwiftPageTransitions.sheetMidUpOffsetFraction),
    );
    _secondaryPositionAnimation = _secondaryPositionCurve!.drive(midUpTween);

    final Animatable<double> scaleTween = Tween<double>(
      begin: 1.0,
      end: 1.0 - SwiftPageTransitions.sheetScaleFactor,
    );
    _secondaryScaleAnimation = _secondaryPositionCurve!.drive(scaleTween);
  }

  void _disposeCurve() {
    _primaryPositionCurve?.dispose();
    _secondaryPositionCurve?.dispose();
    _primaryPositionCurve = null;
    _secondaryPositionCurve = null;
  }

  Widget _coverSheetPrimaryTransition(
    BuildContext context,
    Animation<double> animation,
    bool linearTransition,
    Widget? child,
  ) {
    final Animatable<Offset> offsetTween =
        SwiftSheetRoute.hasParentSheet(context)
        ? _kBottomUpTweenWhenCoveringOtherSheet
        : _kBottomUpTween;

    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: linearTransition ? Curves.linear : Curves.fastEaseInToSlowEaseOut,
      reverseCurve: linearTransition
          ? Curves.linear
          : Curves.fastEaseInToSlowEaseOut.flipped,
    );

    final Animation<Offset> positionAnimation = curvedAnimation.drive(
      offsetTween,
    );

    curvedAnimation.dispose();

    return SlideTransition(position: positionAnimation, child: child);
  }

  Widget _coverSheetSecondaryTransition(
    Animation<double> secondaryAnimation,
    Widget? child,
  ) {
    return SlideTransition(
      position: _secondaryPositionAnimation,
      transformHitTests: false,
      child: ScaleTransition(
        scale: _secondaryScaleAnimation,
        filterQuality: FilterQuality.medium,
        alignment: Alignment.topCenter,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _StretchDragControllerProvider(
      controller: _stretchDragController,
      child: SizedBox.expand(
        child: AnimatedBuilder(
          animation: _stretchDragAnimation,
          builder: (BuildContext context, Widget? child) {
            return Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.heightOf(context) * _stretchDragAnimation.value,
              ),
              child: _coverSheetSecondaryTransition(
                widget.secondaryRouteAnimation,
                _coverSheetPrimaryTransition(
                  context,
                  widget.primaryRouteAnimation,
                  widget.linearTransition,
                  widget.child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Internally used to provide the controller for upward stretch animation.
class _StretchDragControllerProvider extends InheritedWidget {
  const _StretchDragControllerProvider({
    required this.controller,
    required super.child,
  });

  final AnimationController controller;

  static _StretchDragControllerProvider? maybeOf(BuildContext context) {
    return context
        .getInheritedWidgetOfExactType<_StretchDragControllerProvider>();
  }

  @override
  bool updateShouldNotify(_StretchDragControllerProvider oldWidget) {
    return false;
  }
}

/// Route for displaying an iOS sheet styled page.
///
/// The `SwiftSheetRoute` will slide up from the bottom of the screen and stop
/// below the top of the screen. If the previous route is a non-sheet route, then
/// it will animate downwards to stack behind the new sheet. If the previous route
/// is a sheet route, then it will animate slightly upwards to look like it is laying
/// on top of the previous stack of sheets.
///
/// Typically called by [showSwiftSheet], which provides some boilerplate for
/// pushing the `SwiftSheetRoute` to the root navigator and providing simple
/// nested navigation.
///
/// The sheet will be dismissed by dragging downwards on the screen, or a call to
/// [SwiftSheetRoute.popSheet].
///
/// Any time a SwiftSheetRoute contains a large scrollable that might conflict
/// with the dismiss drag gesture, pass the provided [ScrollController] from `scrollableBuilder`
/// to the scrollable.
class SwiftSheetRoute<T> extends CupertinoSheetRoute<T> {
  /// Creates a page route that displays an iOS styled sheet.
  SwiftSheetRoute({
    super.settings,
    @Deprecated(
      'Use scrollableBuilder instead. '
      'This feature was deprecated after v3.40.0-0.2.pre.',
    )
    WidgetBuilder? builder,
    ScrollableWidgetBuilder? scrollableBuilder,
    bool enableDrag = true,
    bool showDragHandle = false,
    double? topGap,
    this.sheetRadius,
    this.sheetBorderRadius,
    this.routeCanPop = true,
    this.animateBackground = true,
    this.transitionDurationOverride = const Duration(milliseconds: 500),
  }) : _topGap = topGap,
       super(
         builder: builder,
         scrollableBuilder: scrollableBuilder,
         enableDrag: enableDrag,
         showDragHandle: showDragHandle,
         topGap: topGap,
       );

  /// Corner radius value.
  final double? sheetRadius;

  /// Border radius geometry.
  final BorderRadius? sheetBorderRadius;

  /// Whether the route can be popped.
  final bool routeCanPop;

  /// Whether to animate the previous page when this sheet is pushed on top.
  final bool animateBackground;

  /// Customized duration of transitions.
  final Duration transitionDurationOverride;

  // The gap between the top of the screen and the top of the sheet.
  final double? _topGap;

  @override
  double get topGap => _topGap ?? SwiftPageTransitions.sheetTopGapRatio;

  Route? _nextRoute;
  Route? get nextRoute => _nextRoute;
  Route? previousRoute;

  @override
  Widget buildContent(BuildContext context) {
    final Widget superWidget = super.buildContent(context);
    return _SwiftSheetScope(
      radius: sheetRadius,
      borderRadius: sheetBorderRadius,
      child: _replaceClipRadius(superWidget, context),
    );
  }

  @override
  DelegatedTransitionBuilder? get delegatedTransition {
    if (_topGap != null) {
      return null;
    }
    if (!animateBackground) {
      return null;
    }
    return (context, animation, secondaryAnimation, allowSnapshotting, child) {
      return SwiftSheetTransition.delegateTransition(
        context,
        animation,
        secondaryAnimation,
        allowSnapshotting,
        child,
        sheetRadius: sheetRadius,
        sheetBorderRadius: sheetBorderRadius,
      );
    };
  }

  Widget _replaceClipRadius(Widget widget, BuildContext context) {
    final borderRadius = _resolveSheetBorderRadius(context);
    
    if (widget is MediaQuery) {
      return MediaQuery(
        data: widget.data,
        child: _replaceClipRadius(widget.child, context),
      );
    }
    if (widget is ClipRSuperellipse) {
      return ClipRSuperellipse(
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: widget.child,
      );
    }
    return widget;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _SwiftSheetRouteTransitionMixin.buildPageTransitions<T>(
      this,
      context,
      animation,
      secondaryAnimation,
      child,
      enableDrag,
      topGap,
    );
  }

  @override
  Duration get transitionDuration => transitionDurationOverride;

  @override
  Duration get reverseTransitionDuration => transitionDurationOverride;

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



  BorderRadius _resolveSheetBorderRadius(BuildContext context) {
    return SwiftPageTransitions.resolveSheetBorderRadius(
      context,
      radius: sheetRadius,
      borderRadius: sheetBorderRadius,
    );
  }

  /// Checks if a Cupertino/Swift sheet view exists in the widget tree above the current
  /// context.
  static bool hasParentSheet(BuildContext context) {
    return _SwiftSheetScope.maybeOf(context) != null;
  }

  /// Pops the entire [SwiftSheetRoute], if a sheet route exists in the stack.
  static void popSheet(BuildContext context) {
    if (hasParentSheet(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Color? get barrierColor => CupertinoColors.transparent;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  bool get opaque => false;

  @override
  RoutePopDisposition get popDisposition {
    if (!routeCanPop) return RoutePopDisposition.doNotPop;
    return super.popDisposition;
  }
}

// Internally used to see if another sheet is in the tree already.
class _SwiftSheetScope extends InheritedWidget {
  const _SwiftSheetScope({
    required this.radius,
    required this.borderRadius,
    required super.child,
  });

  final double? radius;
  final BorderRadius? borderRadius;

  static _SwiftSheetScope? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_SwiftSheetScope>();
  }

  @override
  bool updateShouldNotify(_SwiftSheetScope oldWidget) {
    return radius != oldWidget.radius || borderRadius != oldWidget.borderRadius;
  }
}

/// A mixin that replaces the entire screen with an iOS sheet transition for a
/// [PageRoute].
mixin _SwiftSheetRouteTransitionMixin<T> on PageRoute<T> {
  /// Builds the primary contents of the route.
  @protected
  Widget buildContent(BuildContext context);

  @override
  Duration get transitionDuration => const Duration(milliseconds: 500);

  @override
  DelegatedTransitionBuilder? get delegatedTransition {
    if (_hasCustomTopGap) {
      return null;
    }
    if (!animateBackground) {
      return null;
    }
    return (context, animation, secondaryAnimation, allowSnapshotting, child) {
      return SwiftSheetTransition.delegateTransition(
        context,
        animation,
        secondaryAnimation,
        allowSnapshotting,
        child,
        sheetRadius: sheetRadius,
        sheetBorderRadius: sheetBorderRadius,
      );
    };
  }

  /// Determines whether the content can be dragged.
  bool get enableDrag;

  /// The gap between the top of the screen and the top of the sheet as a ratio
  /// of the screen height.
  double get topGap;

  /// Whether to animate the previous page when this sheet is pushed on top.
  bool get animateBackground => true;

  /// Custom corner radius for the sheet.
  double? get sheetRadius;

  /// Custom border radius geometry for the sheet.
  BorderRadius? get sheetBorderRadius;

  /// Whether a custom top gap has been set.
  bool get _hasCustomTopGap;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return buildContent(context);
  }

  static _SwiftDragGestureController<T> _startPopGesture<T>(
    ModalRoute<T> route,
    double topGap,
  ) {
    return _SwiftDragGestureController<T>(
      topGap: topGap,
      navigator: route.navigator!,
      getIsCurrent: () => route.isCurrent,
      getIsActive: () => route.isActive,
      popDragController: route.controller!,
    );
  }

  /// Returns a [SwiftSheetTransition].
  static Widget buildPageTransitions<T>(
    ModalRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
    bool enableDrag,
    double topGap,
  ) {
    final bool linearTransition = route.popGestureInProgress;
    return SwiftSheetTransition(
      primaryRouteAnimation: animation,
      secondaryRouteAnimation: secondaryAnimation,
      linearTransition: linearTransition,
      topGap: topGap,
      transitionDuration: route.transitionDuration,
      child: _SwiftDragGestureDetector<T>(
        enabledCallback: () => enableDrag,
        onStartPopGesture: () => _startPopGesture<T>(route, topGap),
        child: child,
      ),
    );
  }

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) {
    return !_hasCustomTopGap;
  }

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    if (this is SwiftSheetRoute<dynamic> && _hasCustomTopGap) {
      return false;
    }
    return nextRoute is _SwiftSheetRouteTransitionMixin;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return buildPageTransitions<T>(
      this,
      context,
      animation,
      secondaryAnimation,
      child,
      enableDrag,
      topGap,
    );
  }
}

class _SwiftDragGestureDetector<T> extends StatefulWidget {
  const _SwiftDragGestureDetector({
    super.key,
    required this.enabledCallback,
    required this.onStartPopGesture,
    required this.child,
  });

  final Widget child;

  final ValueGetter<bool> enabledCallback;

  final ValueGetter<_SwiftDragGestureController<T>> onStartPopGesture;

  @override
  _SwiftDragGestureDetectorState<T> createState() =>
      _SwiftDragGestureDetectorState<T>();
}

class _SwiftDragGestureDetectorState<T>
    extends State<_SwiftDragGestureDetector<T>> {
  _SwiftDragGestureController<T>? _dragGestureController;

  late VerticalDragGestureRecognizer _recognizer;
  _StretchDragControllerProvider? _stretchDragController;

  static VelocityTracker _cupertinoVelocityBuilder(PointerEvent event) =>
      IOSScrollViewFlingVelocityTracker(event.kind);

  double get sheetHeight => context.size!.height;

  @override
  void initState() {
    super.initState();
    _stretchDragController = _StretchDragControllerProvider.maybeOf(context);
    _recognizer = VerticalDragGestureRecognizer(debugOwner: this)
      ..velocityTrackerBuilder = _cupertinoVelocityBuilder
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stretchDragController = _StretchDragControllerProvider.maybeOf(context);
  }

  @override
  void dispose() {
    _recognizer.dispose();

    // If this is disposed during a drag, call navigator.didStopUserGesture.
    if (_dragGestureController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_dragGestureController?.navigator.mounted ?? false) {
          _dragGestureController?.navigator.didStopUserGesture();
        }
        _dragGestureController = null;
      });
    }
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    debugPrint(
      '[SwiftSheetRoute] _handleDragStart: details=${details.globalPosition}',
    );
    assert(mounted);
    assert(_dragGestureController == null);
    if (_stretchDragController != null &&
        _stretchDragController!.controller.isAnimating) {
      debugPrint('[SwiftSheetRoute] Stopping active stretch animation!');
      _stretchDragController!.controller.stop();
    }
    _dragGestureController = widget.onStartPopGesture();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    debugPrint(
      '[SwiftSheetRoute] _handleDragUpdate: delta=${details.primaryDelta}, controllerValue=${_dragGestureController?.popDragController.value}',
    );
    assert(mounted);
    assert(_dragGestureController != null);
    if (_stretchDragController == null) {
      return;
    }
    final double delta = sheetHeight > 0
        ? details.primaryDelta! / sheetHeight
        : 0.0;
    _dragGestureController!.dragUpdate(
      // Divide by size of the sheet.
      delta,
      _stretchDragController!.controller,
    );
  }

  void _handleDragEnd(DragEndDetails details) {
    debugPrint(
      '[SwiftSheetRoute] _handleDragEnd: velocity=${details.velocity.pixelsPerSecond.dy}',
    );
    assert(mounted);
    assert(_dragGestureController != null);
    if (_stretchDragController == null) {
      _dragGestureController = null;
      return;
    }
    final double velocity = sheetHeight > 0
        ? details.velocity.pixelsPerSecond.dy / sheetHeight
        : 0.0;
    _dragGestureController!.dragEnd(
      velocity,
      _stretchDragController!.controller,
    );
    _dragGestureController = null;
  }

  void _handleDragCancel() {
    debugPrint('[SwiftSheetRoute] _handleDragCancel');
    assert(mounted);
    if (_stretchDragController == null) {
      _dragGestureController = null;
      return;
    }
    _dragGestureController?.dragEnd(0.0, _stretchDragController!.controller);
    _dragGestureController = null;
  }

  void _handlePointerDown(PointerDownEvent event) {
    debugPrint(
      '[SwiftSheetRoute] _handlePointerDown: position=${event.position}',
    );
    if (widget.enabledCallback()) {
      _recognizer.addPointer(event);
    }
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

class _SwiftDragGestureController<T> {
  /// Creates a controller for an iOS-style back gesture.
  _SwiftDragGestureController({
    required this.navigator,
    required this.popDragController,
    required this.getIsActive,
    required this.getIsCurrent,
    required this.topGap,
  }) {
    debugPrint(
      '[SwiftSheetRoute] _SwiftDragGestureController constructor: isAnimating=${popDragController.isAnimating}, value=${popDragController.value}',
    );
    if (popDragController.isAnimating) {
      final double currentValue = popDragController.value;
      double visualProgress = currentValue;
      if (popDragController.status == AnimationStatus.forward) {
        visualProgress = Curves.fastEaseInToSlowEaseOut.transform(currentValue);
      } else if (popDragController.status == AnimationStatus.reverse) {
        visualProgress = Curves.fastEaseInToSlowEaseOut.flipped.transform(
          currentValue,
        );
      }
      debugPrint(
        '[SwiftSheetRoute] Stopping active animation! Adjusting value from $currentValue to $visualProgress',
      );
      popDragController.stop();
      popDragController.value = visualProgress;
    }
    navigator.didStartUserGesture();
  }

  final AnimationController popDragController;
  final NavigatorState navigator;
  final ValueGetter<bool> getIsActive;
  final ValueGetter<bool> getIsCurrent;
  final double topGap;

  /// The drag gesture has changed by [delta]. The total range of the drag
  /// should be 0.0 to 1.0.
  void dragUpdate(double delta, AnimationController? upController) {
    if (upController != null &&
        popDragController.value == 1.0 &&
        (upController.value > 0 || delta < 0)) {
      // Divide by stretchable range (when dragging upward at max extent).
      final double stretchDistance =
          SwiftPageTransitions.sheetTopGapRatio -
          SwiftPageTransitions.sheetStretchedTopGapRatio;

      // Apply progressive resistance when stretching upward (delta < 0).
      // When pulling back down (delta > 0), no resistance is applied.
      final double resistance = delta < 0
          ? (0.26 * (1.0 - upController.value)).clamp(0.04, 0.26)
          : 1.0;

      final double newValue =
          upController.value - (delta * resistance) / stretchDistance;
      if (newValue <= 0.0) {
        upController.value = 0.0;
        final double remainder = -newValue * stretchDistance;
        popDragController.value -= remainder;
      } else {
        upController.value = newValue;
      }
    } else {
      popDragController.value -= delta;
    }
  }

  bool isDragged() {
    return popDragController.value != 1.0;
  }

  /// The drag gesture has ended with a vertical motion of [velocity] as a
  /// fraction of screen height per second.
  void dragEnd(double velocity, AnimationController? upController) {
    if (upController != null && upController.value > 0) {
      final double stretchDistance =
          SwiftPageTransitions.sheetTopGapRatio -
          SwiftPageTransitions.sheetStretchedTopGapRatio;

      // Convert drag velocity to the upController's coordinate system.
      // Since upController increases as we stretch upward (negative velocity),
      // we negate the velocity.
      final double upVelocity = (-velocity / stretchDistance).clamp(
        -20.0,
        20.0,
      );

      // Realistic spring physics simulation with a lively bounce
      const SpringDescription spring = SpringDescription(
        mass: 1.0,
        stiffness: 400.0,
        damping: 20.0,
      );

      final SpringSimulation simulation = SpringSimulation(
        spring,
        upController.value, // start value
        0.0, // target value (unstretched)
        upVelocity, // initial velocity from gesture
      );

      upController.animateWith(simulation);
      navigator.didStopUserGesture();
      return;
    }

    const Curve animationCurve = Curves.easeOut;
    final bool isCurrent = getIsCurrent();
    final bool animateForward;

    if (!isCurrent) {
      animateForward = getIsActive();
    } else if (velocity.abs() >= 2.0) {
      animateForward = velocity <= 0;
    } else {
      animateForward = popDragController.value > 0.52;
    }

    late TickerFuture ticker;
    if (animateForward) {
      ticker = popDragController.animateTo(
        1.0,
        duration: const Duration(milliseconds: 300),
        curve: animationCurve,
      );
    } else {
      if (isCurrent) {
        // This route is destined to pop at this point. Reuse navigator's pop.
        navigator.pop();
      }

      ticker = popDragController.animateBack(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: animationCurve,
      );
    }

    if (popDragController.isAnimating) {
      ticker.whenCompleteOrCancel(navigator.didStopUserGesture);
    } else {
      navigator.didStopUserGesture();
    }
  }
}

class _SwiftSheetScrollController extends ScrollController {
  _SwiftSheetScrollController({
    required this.enabledCallback,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.sheetIsDraggedDown,
  });

  final ValueGetter<bool> enabledCallback;
  final _DragStartCallback onDragStart;
  final _DragEndCallback onDragUpdate;
  final _DragUpdateCallback onDragEnd;
  final _GetSheetDragged sheetIsDraggedDown;

  @override
  _SwiftSheetScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _SwiftSheetScrollPosition(
      physics: physics.applyTo(const AlwaysScrollableScrollPhysics()),
      context: context,
      oldPosition: oldPosition,
      enabledCallback: enabledCallback,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
      onDragEnd: onDragEnd,
      sheetIsDraggedDown: sheetIsDraggedDown,
    );
  }
}

/// A scroll position that manages scroll activities for
/// [_SwiftSheetScrollController].
class _SwiftSheetScrollPosition extends ScrollPositionWithSingleContext {
  _SwiftSheetScrollPosition({
    required super.physics,
    required super.context,
    super.oldPosition,
    required this.enabledCallback,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.sheetIsDraggedDown,
  });

  VoidCallback? _dragCancelCallback;
  final Set<AnimationController> _ballisticControllers =
      <AnimationController>{};
  bool get listShouldScroll => pixels > 0.0;

  final ValueGetter<bool> enabledCallback;
  final _DragStartCallback onDragStart;
  final _DragEndCallback onDragUpdate;
  final _DragUpdateCallback onDragEnd;

  final _GetSheetDragged sheetIsDraggedDown;

  @override
  void absorb(ScrollPosition other) {
    super.absorb(other);
    assert(_dragCancelCallback == null);

    if (other is! _SwiftSheetScrollPosition) {
      return;
    }

    if (other._dragCancelCallback != null) {
      _dragCancelCallback = other._dragCancelCallback;
      other._dragCancelCallback = null;
    }
  }

  @override
  void beginActivity(ScrollActivity? newActivity) {
    // Cancel the running ballistic simulations
    for (final AnimationController ballisticController
        in _ballisticControllers) {
      ballisticController.stop();
    }
    super.beginActivity(newActivity);
  }

  @override
  void dispose() {
    for (final AnimationController ballisticController
        in _ballisticControllers) {
      ballisticController.dispose();
    }
    _ballisticControllers.clear();
    super.dispose();
  }

  @override
  void applyUserOffset(double delta) {
    if (!enabledCallback()) {
      super.applyUserOffset(delta);
      return;
    }
    onDragStart();
    if (!listShouldScroll && (delta > 0 || sheetIsDraggedDown())) {
      onDragUpdate(delta);
    } else {
      super.applyUserOffset(delta);
    }
  }

  @override
  void goBallistic(double velocity) {
    // End drag gesture.
    if ((velocity == 0.0) ||
        (velocity < 0.0 && listShouldScroll) ||
        (velocity > 0.0 && pixels != maxScrollExtent)) {
      onDragEnd(0.0);
      super.goBallistic(velocity);
      return;
    }
    _dragCancelCallback?.call();
    _dragCancelCallback = null;
    if (velocity < 0.0 && !listShouldScroll) {
      onDragEnd(velocity);
      super.goBallistic(0);
      return;
    }
    onDragEnd(0.0);
    super.goBallistic(velocity);
  }

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    // Save this so we can call it later if we have to [goBallistic] on our own.
    _dragCancelCallback = dragCancelCallback;
    return super.drag(details, dragCancelCallback);
  }
}

class _SwiftDraggableScrollableSheet<T> extends StatefulWidget {
  const _SwiftDraggableScrollableSheet({
    super.key,
    required this.enabledCallback,
    required this.onStartPopGesture,
    required this.builder,
  });

  final ScrollableWidgetBuilder builder;

  final ValueGetter<bool> enabledCallback;

  final ValueGetter<_SwiftDragGestureController<T>> onStartPopGesture;

  @override
  _SwiftDraggableScrollableSheetState<T> createState() =>
      _SwiftDraggableScrollableSheetState<T>();
}

class _SwiftDraggableScrollableSheetState<T>
    extends State<_SwiftDraggableScrollableSheet<T>> {
  late _SwiftSheetScrollController _scrollController;
  _SwiftDragGestureController<T>? _dragGestureController;

  @override
  void initState() {
    super.initState();
    _scrollController = _SwiftSheetScrollController(
      enabledCallback: widget.enabledCallback,
      onDragStart: _dragStart,
      onDragUpdate: _dragUpdate,
      onDragEnd: _handleDragEnd,
      sheetIsDraggedDown: () => _dragGestureController?.isDragged() ?? false,
    );
  }

  @override
  void dispose() {
    // If this is disposed during a drag, call navigator.didStopUserGesture.
    if (_dragGestureController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_dragGestureController?.navigator.mounted ?? false) {
          _dragGestureController?.navigator.didStopUserGesture();
        }
        _dragGestureController = null;
      });
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _dragStart() {
    assert(mounted);
    _dragGestureController ??= widget.onStartPopGesture();
  }

  void _dragUpdate(double delta) {
    assert(mounted);
    if (_dragGestureController != null) {
      _dragGestureController!.dragUpdate(
        delta /
            (context.size!.height -
                (context.size!.height * SwiftPageTransitions.sheetTopGapRatio)),
        null,
      );
    }
  }

  void _handleDragEnd(double velocity) {
    assert(mounted);
    if (_dragGestureController != null) {
      _dragGestureController!.dragEnd(-velocity / context.size!.height, null);
      _dragGestureController = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _scrollController);
  }
}
