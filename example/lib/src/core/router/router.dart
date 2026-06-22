import 'package:auto_route/auto_route.dart';
import 'package:example/src/core/router/router.gr.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

Route<T> swiftRouteBuilder<T>(
  BuildContext context,
  Widget child,
  AutoRoutePage<T> page,
) {
  return SwiftPageTransitions.routeBuilder(
    context: context,
    child: child,
    settings: page,
  );
}

Route<T> swiftSheetRouteBuilder<T>(
  BuildContext context,
  Widget child,
  AutoRoutePage<T> page,
) {
  return SwiftSheetRoute<T>(
    child: child,
    settings: page,
    // sheetRadius: 32,
    // sheetMinScale: 0.9,
  );
}

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType =>
      RouteType.custom(customRouteBuilder: swiftRouteBuilder);

  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: HomeRoute.page,
      initial: true,
      children: [
        AutoRoute(
          page: HeaderBranchRoute.page,
          children: [
            CustomRoute(
              page: HeaderBracnkDetailRoute.page,
              customRouteBuilder: swiftSheetRouteBuilder,
            ),
          ],
        ),
        CustomRoute(
          page: HeaderBranch2Route.page,
          transitionsBuilder: TransitionsBuilders.fadeIn,
          children: [
            CustomRoute(
              page: HeaderBracnkDetailRoute.page,
              customRouteBuilder: swiftSheetRouteBuilder,
            ),
          ],
        ),
      ],
    ),
    // Add top-level detail route so it can be opened full-screen
    CustomRoute(
      page: HeaderBracnkDetailRoute.page,
      customRouteBuilder: swiftSheetRouteBuilder,
    ),
  ];
}
