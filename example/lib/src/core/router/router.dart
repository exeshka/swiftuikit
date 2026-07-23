// ignore_for_file: experimental_member_use

import 'package:auto_route/auto_route.dart';
import 'package:example/src/core/router/router.gr.dart';
import 'package:example/src/screens/product_detail_screen.dart';
import 'package:swiftuikit/swiftuikit.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    SwiftPageAutoRoute(page: ProductListRoute.page, initial: true),

    SwiftInteractiveZoomAutoRoute(
      page: ProductDetailZoomRoute.page,
      sourceIdResolver: (data) =>
          data.argsAs<ProductDetailZoomRouteArgs>().product.id,
    ),

    SwiftSheetAutoRoute(
      page: ProductDetailSheetRoute.page,

      preserveTopSafeArea: true,
    ),
  ];
}
