import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'swift_page_transitions.dart';
import 'swift_scroll_sheet_route.dart';
import 'swift_sheet_route.dart' as sheet_route;

Route<T> swiftPageRouteBuilder<T>(
  BuildContext context,
  Widget child,
  AutoRoutePage<T> page, {
  double minScale = 0.95,
  double pageOverlapFraction = 0.20,
  bool clipWithScreenRadius = true,
  double? radius,
  BorderRadius? borderRadius,
  double? backGestureWidth,
  Duration transitionDuration = const Duration(milliseconds: 400),
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
    transitionDuration: transitionDuration,
  );
}

Route<T> swiftSheetRouteBuilder<T>(
  BuildContext context,
  Widget child,
  AutoRoutePage<T> page, {
  double? sheetRadius,
  BorderRadius? sheetBorderRadius,
  double sheetMinScale = 0.92,
  Duration transitionDuration = const Duration(milliseconds: 400),
}) {
  return sheet_route.SwiftSheetRoute<T>(
    child: child,
    settings: page,
    sheetRadius: sheetRadius,
    sheetBorderRadius: sheetBorderRadius,
    sheetMinScale: sheetMinScale,
    transitionDurationOverride: transitionDuration,
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
  Duration transitionDuration = const Duration(milliseconds: 400),
  Duration snapAnimationDuration = const Duration(milliseconds: 220),
  bool stickySnap = true,
  bool dismissOnMinStop = true,
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
    transitionDurationOverride: transitionDuration,
    snapAnimationDuration: snapAnimationDuration,
    stickySnap: stickySnap,
    dismissOnMinStop: dismissOnMinStop,
    sheetController: sheetControllerBuilder?.call(),
  );
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
    this.pageOverlapFraction = 0.20,
    this.clipWithScreenRadius = true,
    this.radius,
    this.borderRadius,
    this.backGestureWidth,
    this.transitionDuration = const Duration(milliseconds: 400),
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
    this.sheetMinScale = 0.92,
    this.transitionDuration = const Duration(milliseconds: 400),
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
                 sheetMinScale: sheetMinScale,
                 transitionDuration: transitionDuration,
               );
             },
       );

  final double? sheetRadius;
  final BorderRadius? sheetBorderRadius;
  final double sheetMinScale;
  final Duration transitionDuration;
}

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
    this.transitionDuration = const Duration(milliseconds: 400),
    this.snapAnimationDuration = const Duration(milliseconds: 220),
    this.stickySnap = true,
    this.dismissOnMinStop = true,
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
                 transitionDuration: transitionDuration,
                 snapAnimationDuration: snapAnimationDuration,
                 stickySnap: stickySnap,
                 dismissOnMinStop: dismissOnMinStop,
                 sheetControllerBuilder: sheetControllerBuilder,
               );
             },
       );

  final double? sheetRadius;
  final BorderRadius? sheetBorderRadius;
  final double sheetMinScale;
  final double initialStop;
  final List<double>? stops;
  final Duration transitionDuration;
  final Duration snapAnimationDuration;
  final bool stickySnap;
  final bool dismissOnMinStop;
  final SwiftScrollSheetController Function()? sheetControllerBuilder;
}
