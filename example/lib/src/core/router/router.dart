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
    SwiftSheetAutoRoute(
      page: SheetRoute.page,
      sheetRadius: 38,
      showDragHandle: true,
      enableDrag: true,
    ),
    SwiftScrollSheetAutoRoute(
      page: ModalRoute.page,
      detents: [
        SwiftSheetDetent.fraction(0.0),
        SwiftSheetDetent.height(260),
        SwiftSheetDetent.fraction(0.8),
        SwiftSheetDetent.large,
      ],
      initialDetent: SwiftSheetDetent.height(260),
    ),
  ];
}
