import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import 'package:swiftuikit/src/routing/interactive_zoom_route.dart';
import 'package:swiftuikit/src/routing/page_transitions.dart';
import 'package:swiftuikit/src/routing/scroll_sheet_route.dart';
import 'package:swiftuikit/src/routing/sheet_route.dart' as sheet_route;
import 'package:swiftuikit/src/routing/modal_route.dart' as modal_route;

/// A [Page] adapter for go_router and Navigator 2.0 that transitions between
/// a [SwiftInteractiveZoomSource] and a full-screen page.
///
/// Pass the same runtime value to [sourceId] and the source widget. For
/// example, a product ID can identify both the tapped product card and its
/// details page.
class SwiftInteractiveZoomPage<T> extends Page<T> {
  const SwiftInteractiveZoomPage({
    required this.sourceId,
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    super.canPop,
    super.onPopInvoked,
    this.namespace,
    this.sourceBorderRadius,
    this.destinationBorderRadius,
    this.canSwipe = true,
    this.canOnlySwipeFromEdge = false,
    this.backGestureWidth,
    this.verticalDragSensitivity = 1.6,
    this.minInteractiveHeroProgress = 0.15,
    this.transitionDuration = const Duration(milliseconds: 420),
  });

  final Object sourceId;
  final Widget child;
  final Object? namespace;
  final BorderRadius? sourceBorderRadius;
  final BorderRadius? destinationBorderRadius;
  final bool canSwipe;
  final bool canOnlySwipeFromEdge;
  final double? backGestureWidth;
  final double verticalDragSensitivity;
  final double minInteractiveHeroProgress;
  final Duration transitionDuration;

  @override
  Route<T> createRoute(BuildContext context) {
    return SwiftInteractiveZoomRoute<T>(
      sourceId: sourceId,
      namespace: namespace,
      settings: this,
      sourceBorderRadius: sourceBorderRadius,
      destinationBorderRadius: destinationBorderRadius,
      canSwipe: canSwipe,
      canOnlySwipeFromEdge: canOnlySwipeFromEdge,
      backGestureWidth: backGestureWidth,
      verticalDragSensitivity: verticalDragSensitivity,
      minInteractiveHeroProgress: minInteractiveHeroProgress,
      customTransitionDuration: transitionDuration,
      builder: (_) => child,
    );
  }
}

/// A [Page] adapter for go_router and Navigator 2.0 that uses
/// [SwiftPageRoute].
class SwiftPage<T> extends Page<T> {
  const SwiftPage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    super.canPop,
    super.onPopInvoked,
    this.minScale = 0.95,
    this.pageOverlapFraction = 0.40,
    this.clipWithScreenRadius = true,
    this.radius,
    this.borderRadius,
    this.backGestureWidth,
    this.canSwipe = true,
    this.canOnlySwipeFromEdge = false,
    this.transitionDuration = const Duration(milliseconds: 500),
  });

  final Widget child;
  final double minScale;
  final double pageOverlapFraction;
  final bool clipWithScreenRadius;
  final double? radius;
  final BorderRadius? borderRadius;
  final double? backGestureWidth;
  final bool canSwipe;
  final bool canOnlySwipeFromEdge;
  final Duration transitionDuration;

  @override
  Route<T> createRoute(BuildContext context) {
    return SwiftPageTransitions.routeBuilder<T>(
      context: context,
      child: child,
      settings: this,
      minScale: minScale,
      pageOverlapFraction: pageOverlapFraction,
      clipWithScreenRadius: clipWithScreenRadius,
      radius: radius,
      borderRadius: borderRadius,
      backGestureWidth: backGestureWidth,
      canSwipe: canSwipe,
      canOnlySwipeFromEdge: canOnlySwipeFromEdge,
      routeCanPop: canPop,
      transitionDuration: transitionDuration,
    );
  }
}

/// A [Page] adapter for go_router and Navigator 2.0 that uses
/// [sheet_route.SwiftSheetRoute].
class SwiftSheetPage<T> extends Page<T> {
  const SwiftSheetPage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    super.canPop,
    super.onPopInvoked,
    this.sheetRadius,
    this.sheetBorderRadius,
    this.transitionDuration = const Duration(milliseconds: 500),
    this.showDragHandle = false,
    this.enableDrag = true,
    this.animateBackground = true,
  });

  final Widget child;
  final double? sheetRadius;
  final BorderRadius? sheetBorderRadius;
  final Duration transitionDuration;
  final bool showDragHandle;
  final bool enableDrag;
  final bool animateBackground;

  @override
  Route<T> createRoute(BuildContext context) {
    return sheet_route.SwiftSheetRoute<T>(
      settings: this,
      sheetRadius: sheetRadius,
      sheetBorderRadius: sheetBorderRadius,
      routeCanPop: canPop,
      transitionDurationOverride: transitionDuration,
      showDragHandle: showDragHandle,
      enableDrag: enableDrag,
      animateBackground: animateBackground,
      scrollableBuilder:
          (BuildContext context, ScrollController scrollController) =>
              PrimaryScrollController(
                controller: scrollController,
                child: child,
              ),
    );
  }
}

/// A [Page] adapter for go_router and Navigator 2.0 that uses
/// [SwiftScrollSheetRoute].
///
/// **Not stable** — API may change.
@experimental
class SwiftScrollSheetPage<T> extends Page<T> {
  const SwiftScrollSheetPage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    super.canPop,
    super.onPopInvoked,
    this.sheetRadius,
    this.sheetBorderRadius,
    this.sheetMinScale = 0.9,
    this.initialStop = 1.0,
    this.stops,
    this.detents,
    this.initialDetent,
    this.transitionDuration = const Duration(milliseconds: 500),
    this.snapAnimationDuration = const Duration(milliseconds: 220),
    this.stickySnap = true,
    this.dismissOnMinStop = true,
    this.sheetControllerBuilder,
  });

  final Widget child;
  final double? sheetRadius;
  final BorderRadius? sheetBorderRadius;
  final double sheetMinScale;
  final double initialStop;
  final List<double>? stops;
  final List<SwiftSheetDetent>? detents;
  final SwiftSheetDetent? initialDetent;
  final Duration transitionDuration;
  final Duration snapAnimationDuration;
  final bool stickySnap;
  final bool dismissOnMinStop;
  final SwiftScrollSheetController Function()? sheetControllerBuilder;

  @override
  Route<T> createRoute(BuildContext context) {
    return SwiftScrollSheetRoute<T>(
      child: child,
      settings: this,
      sheetRadius: sheetRadius,
      sheetBorderRadius: sheetBorderRadius,
      sheetMinScale: sheetMinScale,
      initialStop: initialStop,
      stops: stops,
      detents: detents,
      initialDetent: initialDetent,
      transitionDurationOverride: transitionDuration,
      snapAnimationDuration: snapAnimationDuration,
      stickySnap: stickySnap,
      dismissOnMinStop: dismissOnMinStop,
      routeCanPop: canPop,
      sheetController: sheetControllerBuilder?.call(),
    );
  }
}

/// A [Page] adapter for go_router and Navigator 2.0 that uses
/// [modal_route.SwiftModalRoute].
///
/// **Not stable** — API may change.
@experimental
class SwiftModalPage<T> extends Page<T> {
  const SwiftModalPage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    super.canPop,
    super.onPopInvoked,
    this.sheetRadius,
    this.sheetBorderRadius,
    this.barrierDismissible = true,
    this.barrierOpacity = 0.3,
    this.transitionDuration = const Duration(milliseconds: 500),
    this.dismissThreshold = 0.3,
  });

  final Widget child;
  final double? sheetRadius;
  final BorderRadius? sheetBorderRadius;
  final bool barrierDismissible;
  final double barrierOpacity;
  final Duration transitionDuration;
  final double dismissThreshold;

  @override
  Route<T> createRoute(BuildContext context) {
    return modal_route.SwiftModalRoute<T>(
      child: child,
      settings: this,
      sheetRadius: sheetRadius,
      sheetBorderRadius: sheetBorderRadius,
      routeCanPop: canPop,
      barrierDismissible: barrierDismissible,
      barrierOpacity: barrierOpacity,
      transitionDurationOverride: transitionDuration,
      dismissThreshold: dismissThreshold,
    );
  }
}
