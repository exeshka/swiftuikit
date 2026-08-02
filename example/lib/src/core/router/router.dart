// ignore_for_file: experimental_member_use

import 'package:auto_route/auto_route.dart';
import 'package:example/src/core/router/router.gr.dart';

import 'package:swiftuikit/swiftuikit.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    SwiftPageAutoRoute(page: NativeMergedHeaderRoute.page, initial: true),
    SwiftPageAutoRoute(page: ProductListRoute.page),

    SwiftZoomAutoRoute(
      page: SwiftZoomGalleryRoute.page,
      dismissDirection: SwiftZoomDismissDirection.horizontal,
    ),

    SwiftSheetAutoRoute(
      page: ProductDetailSheetRoute.page,

      preserveTopSafeArea: true,
    ),

    SwiftSheetAutoRoute(
      page: ProfileWrapperRoute.page,
      children: [
        SwiftPageAutoRoute(page: ProfileRoute.page),
        SwiftPageAutoRoute(page: ProfileEditRoute.page),
      ],
    ),
  ];
}
