import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import 'package:swiftuikit/src/routing/interactive_zoom_route.dart';
import 'package:swiftuikit/src/routing/page_transitions.dart';
import 'package:swiftuikit/src/routing/scroll_sheet_route.dart';
import 'package:swiftuikit/src/routing/sheet_route.dart' as sheet_route;
import 'package:swiftuikit/src/routing/modal_route.dart' as modal_route;

/// Resolves a zoom source ID from the runtime data of an auto_route page.
typedef SwiftInteractiveZoomSourceIdResolver = Object Function(RouteData data);

Route<T> swiftInteractiveZoomRouteBuilder<T>(
  BuildContext context,
  Widget child,
  AutoRoutePage<T> page, {
  required Object sourceId,
  Object? namespace,
  BorderRadius? sourceBorderRadius,
  BorderRadius? destinationBorderRadius,
  bool canSwipe = true,
  bool canOnlySwipeFromEdge = false,
  double? backGestureWidth,
  double verticalDragSensitivity = 1.6,
  double minInteractiveHeroProgress = 0.15,
  Duration transitionDuration = const Duration(milliseconds: 420),
}) {
  return SwiftInteractiveZoomRoute<T>(
    sourceId: sourceId,
    namespace: namespace,
    settings: page,
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

Route<T> swiftPageRouteBuilder<T>(
  BuildContext context,
  Widget child,
  AutoRoutePage<T> page, {
  double minScale = 0.95,
  double pageOverlapFraction = 0.40,
  bool clipWithScreenRadius = true,
  double? radius,
  BorderRadius? borderRadius,
  double? backGestureWidth,
  bool canSwipe = true,
  bool canOnlySwipeFromEdge = false,
  bool canPop = true,
  Duration transitionDuration = const Duration(milliseconds: 500),
}) {
  return SwiftPageTransitions.routeBuilder<T>(
    context: context,
    child: child,
    settings: page,
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

Route<T> swiftSheetRouteBuilder<T>(
  BuildContext context,
  Widget child,
  AutoRoutePage<T> page, {
  double? sheetRadius,
  BorderRadius? sheetBorderRadius,
  bool canPop = true,
  Duration transitionDuration = const Duration(milliseconds: 500),
  bool showDragHandle = false,
  bool enableDrag = true,
  bool animateBackground = true,
}) {
  return sheet_route.SwiftSheetRoute<T>(
    settings: page,
    sheetRadius: sheetRadius,
    sheetBorderRadius: sheetBorderRadius,
    routeCanPop: canPop,
    transitionDurationOverride: transitionDuration,
    showDragHandle: showDragHandle,
    enableDrag: enableDrag,
    animateBackground: animateBackground,
    scrollableBuilder:
        (BuildContext context, ScrollController scrollController) =>
            PrimaryScrollController(controller: scrollController, child: child),
  );
}

Route<T> swiftScrollSheetRouteBuilder<T>(
  BuildContext context,
  Widget child,
  AutoRoutePage<T> page, {
  double? sheetRadius,
  BorderRadius? sheetBorderRadius,
  double sheetMinScale = 0.9,
  double initialStop = 1.0,
  List<double>? stops,
  List<SwiftSheetDetent>? detents,
  SwiftSheetDetent? initialDetent,
  Duration transitionDuration = const Duration(milliseconds: 500),
  Duration snapAnimationDuration = const Duration(milliseconds: 220),
  bool stickySnap = true,
  bool dismissOnMinStop = true,
  bool canPop = true,
  SwiftScrollSheetController Function()? sheetControllerBuilder,
}) {
  return SwiftScrollSheetRoute<T>(
    child: child,
    settings: page,
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

Route<T> swiftModalRouteBuilder<T>(
  BuildContext context,
  Widget child,
  AutoRoutePage<T> page, {
  double? sheetRadius,
  BorderRadius? sheetBorderRadius,
  bool canPop = true,
  bool barrierDismissible = true,
  double barrierOpacity = 0.3,
  Duration transitionDuration = const Duration(milliseconds: 500),
  double dismissThreshold = 0.3,
}) {
  return modal_route.SwiftModalRoute<T>(
    child: child,
    settings: page,
    sheetRadius: sheetRadius,
    sheetBorderRadius: sheetBorderRadius,
    routeCanPop: canPop,
    barrierDismissible: barrierDismissible,
    barrierOpacity: barrierOpacity,
    transitionDurationOverride: transitionDuration,
    dismissThreshold: dismissThreshold,
  );
}

/// An auto_route adapter for [SwiftInteractiveZoomRoute].
///
/// Use [sourceIdResolver] when the ID comes from generated route arguments:
///
/// ```dart
/// SwiftInteractiveZoomAutoRoute(
///   page: ProductRoute.page,
///   sourceIdResolver: (data) =>
///       data.argsAs<ProductRouteArgs>().productId,
/// )
/// ```
class SwiftInteractiveZoomAutoRoute<R> extends CustomRoute<R> {
  SwiftInteractiveZoomAutoRoute({
    required super.page,
    super.fullscreenDialog,
    super.maintainState,
    super.fullMatch,
    super.guards,
    super.usesPathAsKey,
    super.children,
    super.meta,
    super.title,
    super.path,
    super.keepHistory,
    super.initial,
    super.allowSnapshotting,
    super.restorationId,
    this.sourceId,
    this.sourceIdResolver,
    this.namespace,
    this.sourceBorderRadius,
    this.destinationBorderRadius,
    this.canSwipe = true,
    this.canOnlySwipeFromEdge = false,
    this.backGestureWidth,
    this.verticalDragSensitivity = 1.6,
    this.minInteractiveHeroProgress = 0.15,
    this.transitionDuration = const Duration(milliseconds: 420),
  }) : assert(
         (sourceId == null) != (sourceIdResolver == null),
         'Provide exactly one of sourceId or sourceIdResolver.',
       ),
       super(
         opaque: false,
         customRouteBuilder:
             <T>(BuildContext context, Widget child, AutoRoutePage<T> page) {
               final resolvedSourceId =
                   sourceIdResolver?.call(page.routeData) ?? sourceId!;
               return swiftInteractiveZoomRouteBuilder<T>(
                 context,
                 child,
                 page,
                 sourceId: resolvedSourceId,
                 namespace: namespace,
                 sourceBorderRadius: sourceBorderRadius,
                 destinationBorderRadius: destinationBorderRadius,
                 canSwipe: canSwipe,
                 canOnlySwipeFromEdge: canOnlySwipeFromEdge,
                 backGestureWidth: backGestureWidth,
                 verticalDragSensitivity: verticalDragSensitivity,
                 minInteractiveHeroProgress: minInteractiveHeroProgress,
                 transitionDuration: transitionDuration,
               );
             },
       );

  final Object? sourceId;
  final SwiftInteractiveZoomSourceIdResolver? sourceIdResolver;
  final Object? namespace;
  final BorderRadius? sourceBorderRadius;
  final BorderRadius? destinationBorderRadius;
  final bool canSwipe;
  final bool canOnlySwipeFromEdge;
  final double? backGestureWidth;
  final double verticalDragSensitivity;
  final double minInteractiveHeroProgress;
  final Duration transitionDuration;
}

class SwiftPageAutoRoute<R> extends CustomRoute<R> {
  SwiftPageAutoRoute({
    required super.page,
    super.fullscreenDialog,
    super.maintainState,
    super.fullMatch,
    super.guards,
    super.usesPathAsKey,
    super.children,
    super.meta,
    super.title,
    super.path,
    super.keepHistory,
    super.initial,
    super.allowSnapshotting,
    super.restorationId,
    this.minScale = 0.95,
    this.pageOverlapFraction = 0.40,
    this.clipWithScreenRadius = true,
    this.radius,
    this.borderRadius,
    this.backGestureWidth,
    this.canSwipe = true,
    this.canOnlySwipeFromEdge = false,
    this.canPop = true,
    this.transitionDuration = const Duration(milliseconds: 500),
  }) : super(
         customRouteBuilder:
             <T>(BuildContext context, Widget child, AutoRoutePage<T> page) {
               return swiftPageRouteBuilder<T>(
                 context,
                 child,
                 page,
                 minScale: minScale,
                 pageOverlapFraction: pageOverlapFraction,
                 clipWithScreenRadius: clipWithScreenRadius,
                 radius: radius,
                 borderRadius: borderRadius,
                 backGestureWidth: backGestureWidth,
                 canSwipe: canSwipe,
                 canOnlySwipeFromEdge: canOnlySwipeFromEdge,
                 canPop: canPop,
                 transitionDuration: transitionDuration,
               );
             },
       );

  final double minScale;
  final double pageOverlapFraction;
  final bool clipWithScreenRadius;
  final double? radius;
  final BorderRadius? borderRadius;
  final double? backGestureWidth;
  final bool canSwipe;
  final bool canOnlySwipeFromEdge;
  final bool canPop;
  final Duration transitionDuration;
}

class SwiftSheetAutoRoute<R> extends CustomRoute<R> {
  SwiftSheetAutoRoute({
    required super.page,
    super.fullscreenDialog,
    super.maintainState,
    super.fullMatch,
    super.guards,
    super.usesPathAsKey,
    super.children,
    super.meta,
    super.title,
    super.path,
    super.keepHistory,
    super.initial,
    super.allowSnapshotting,
    super.restorationId,
    this.sheetRadius,
    this.sheetBorderRadius,
    this.canPop = true,
    this.transitionDuration = const Duration(milliseconds: 500),
    this.showDragHandle = false,
    this.enableDrag = true,
    this.animateBackground = true,
  }) : super(
         opaque: false,
         barrierDismissible: true,
         barrierColor: Colors.transparent,
         customRouteBuilder:
             <T>(BuildContext context, Widget child, AutoRoutePage<T> page) {
               return swiftSheetRouteBuilder<T>(
                 context,
                 child,
                 page,
                 sheetRadius: sheetRadius,
                 sheetBorderRadius: sheetBorderRadius,
                 canPop: canPop,
                 transitionDuration: transitionDuration,
                 showDragHandle: showDragHandle,
                 enableDrag: enableDrag,
                 animateBackground: animateBackground,
               );
             },
       );

  final double? sheetRadius;
  final BorderRadius? sheetBorderRadius;
  final bool canPop;
  final Duration transitionDuration;
  final bool showDragHandle;
  final bool enableDrag;
  final bool animateBackground;
}

/// **Not stable** — API may change.
@experimental
class SwiftScrollSheetAutoRoute<R> extends CustomRoute<R> {
  SwiftScrollSheetAutoRoute({
    required super.page,
    super.fullscreenDialog,
    super.maintainState,
    super.fullMatch,
    super.guards,
    super.usesPathAsKey,
    super.children,
    super.meta,
    super.title,
    super.path,
    super.keepHistory,
    super.initial,
    super.allowSnapshotting,
    super.restorationId,
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
    this.canPop = true,
    this.sheetControllerBuilder,
  }) : super(
         opaque: false,
         barrierDismissible: true,
         barrierColor: Colors.transparent,
         customRouteBuilder:
             <T>(BuildContext context, Widget child, AutoRoutePage<T> page) {
               return swiftScrollSheetRouteBuilder<T>(
                 context,
                 child,
                 page,
                 sheetRadius: sheetRadius,
                 sheetBorderRadius: sheetBorderRadius,
                 sheetMinScale: sheetMinScale,
                 initialStop: initialStop,
                 stops: stops,
                 detents: detents,
                 initialDetent: initialDetent,
                 transitionDuration: transitionDuration,
                 snapAnimationDuration: snapAnimationDuration,
                 stickySnap: stickySnap,
                 dismissOnMinStop: dismissOnMinStop,
                 canPop: canPop,
                 sheetControllerBuilder: sheetControllerBuilder,
               );
             },
       );

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
  final bool canPop;
  final SwiftScrollSheetController Function()? sheetControllerBuilder;
}

/// **Not stable** — API may change.
@experimental
class SwiftModalAutoRoute<R> extends CustomRoute<R> {
  SwiftModalAutoRoute({
    required super.page,
    super.fullscreenDialog,
    super.maintainState,
    super.fullMatch,
    super.guards,
    super.usesPathAsKey,
    super.children,
    super.meta,
    super.title,
    super.path,
    super.keepHistory,
    super.initial,
    super.allowSnapshotting,
    super.restorationId,
    this.sheetRadius,
    this.sheetBorderRadius,
    this.canPop = true,
    this.barrierDismissible = true,
    this.barrierOpacity = 0.3,
    this.transitionDuration = const Duration(milliseconds: 500),
    this.dismissThreshold = 0.3,
  }) : super(
         opaque: false,
         barrierDismissible: true,
         barrierColor: Colors.transparent,
         customRouteBuilder:
             <T>(BuildContext context, Widget child, AutoRoutePage<T> page) {
               return swiftModalRouteBuilder<T>(
                 context,
                 child,
                 page,
                 sheetRadius: sheetRadius,
                 sheetBorderRadius: sheetBorderRadius,
                 canPop: canPop,
                 barrierDismissible: barrierDismissible,
                 barrierOpacity: barrierOpacity,
                 transitionDuration: transitionDuration,
                 dismissThreshold: dismissThreshold,
               );
             },
       );

  final double? sheetRadius;
  final BorderRadius? sheetBorderRadius;
  final bool canPop;
  final bool barrierDismissible;
  final double barrierOpacity;
  final Duration transitionDuration;
  final double dismissThreshold;
}
