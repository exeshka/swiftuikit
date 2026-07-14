// ignore_for_file: experimental_member_use

import 'package:auto_route/auto_route.dart';
import 'package:example/src/core/router/router.gr.dart';
import 'package:swiftuikit/swiftuikit.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    SwiftPageAutoRoute(page: SplashRoute.page, initial: true),
    SwiftPageAutoRoute(page: HomeRoute.page),
    SwiftPageAutoRoute(page: DetailRoute.page),
    SwiftPageAutoRoute(
      page: DetailNoSwipeRoute.page,
      canSwipe: false,
      canOnlySwipeFromEdge: true,
    ),
    SwiftSheetAutoRoute(page: SheetRoute.page),
    SwiftSheetAutoRoute(
      page: SheetNoBgRoute.page,
      animateBackground: false,
    ),
    SwiftSheetAutoRoute(
      page: SheetNoSwipeRoute.page,
      enableDrag: false,
    ),
    SwiftSheetAutoRoute(
      page: SheetCustomRadiusRoute.page,
      sheetRadius: 16,
    ),
    SwiftPageAutoRoute(page: HeroRouteOneRoute.page),
    SwiftPageAutoRoute(page: HeroRouteTwoRoute.page),
    SwiftSheetAutoRoute(page: HeroSheetOneRoute.page),
    SwiftSheetAutoRoute(page: HeroSheetTwoRoute.page),
    SwiftSheetAutoRoute(page: HeroSheetThreeRoute.page),
    SwiftSheetAutoRoute(page: HeroSheetFourRoute.page),
    SwiftSheetAutoRoute(page: HeroSheetFiveRoute.page),
  ];
}
