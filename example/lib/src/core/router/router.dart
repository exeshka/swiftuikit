import 'package:auto_route/auto_route.dart';
import 'package:example/src/core/router/router.gr.dart';
import 'package:swiftuikit/swiftuikit.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType =>
      RouteType.custom(customRouteBuilder: swiftPageRouteBuilder);

  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: ClientFlowRoute.page,
      initial: true,
      children: [
        SwiftPageAutoRoute(page: ClientCreateStoriesRoute.page),
        SwiftPageAutoRoute(
          page: ClientHomeRoute.page,
          initial: true,

          children: [],
        ),
      ],
    ),
    SwiftPageAutoRoute(page: PostDetailRoute.page),
  ];
}
