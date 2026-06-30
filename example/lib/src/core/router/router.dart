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
        SwiftPageAutoRoute(page: ClientFlowRoute.page),
        SwiftPageAutoRoute(page: ClientCreateStoriesRoute.page),
        SwiftPageAutoRoute(
          page: ClientHomeRoute.page,
          initial: true,

          children: [],
        ),
      ],
    ),
    SwiftSheetAutoRoute(page: PostDetailRoute.page),
    SwiftPageAutoRoute(page: RouteLabRoute.page),
    SwiftPageAutoRoute(page: RouteLabPushRoute.page),
    SwiftPageAutoRoute(page: RouteLabReplaceRoute.page),
    SwiftPageAutoRoute(page: RouteLabLockedRoute.page, canPop: false),
    SwiftSheetAutoRoute(page: RouteLabSheetRoute.page, sheetRadius: 16),
    SwiftSheetAutoRoute(
      page: SheetNestedRoute.page,
      sheetRadius: 16,
      children: [
        SwiftPageAutoRoute(page: SheetNestedPage1Route.page, initial: true),
        SwiftPageAutoRoute(page: SheetNestedPage2Route.page),
      ],
    ),
    SwiftModalAutoRoute(page: StoriesModalRoute.page),
  ];
}
