// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i5;
import 'package:example/src/features/client/_flow/client_flow_screen.dart'
    as _i2;
import 'package:example/src/features/client/home/presentation/pages/client_home_screen.dart'
    as _i3;
import 'package:example/src/features/client/home/presentation/pages/post_detail_screen.dart'
    as _i4;
import 'package:example/src/features/client/stories/presentation/pages/create_stories_screen.dart'
    as _i1;

/// generated route for
/// [_i1.ClientCreateStoriesScreen]
class ClientCreateStoriesRoute extends _i5.PageRouteInfo<void> {
  const ClientCreateStoriesRoute({List<_i5.PageRouteInfo>? children})
    : super(ClientCreateStoriesRoute.name, initialChildren: children);

  static const String name = 'ClientCreateStoriesRoute';

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      return const _i1.ClientCreateStoriesScreen();
    },
  );
}

/// generated route for
/// [_i2.ClientFlowScreen]
class ClientFlowRoute extends _i5.PageRouteInfo<void> {
  const ClientFlowRoute({List<_i5.PageRouteInfo>? children})
    : super(ClientFlowRoute.name, initialChildren: children);

  static const String name = 'ClientFlowRoute';

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      return const _i2.ClientFlowScreen();
    },
  );
}

/// generated route for
/// [_i3.ClientHomeScreen]
class ClientHomeRoute extends _i5.PageRouteInfo<void> {
  const ClientHomeRoute({List<_i5.PageRouteInfo>? children})
    : super(ClientHomeRoute.name, initialChildren: children);

  static const String name = 'ClientHomeRoute';

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      return const _i3.ClientHomeScreen();
    },
  );
}

/// generated route for
/// [_i4.PostDetailScreen]
class PostDetailRoute extends _i5.PageRouteInfo<void> {
  const PostDetailRoute({List<_i5.PageRouteInfo>? children})
    : super(PostDetailRoute.name, initialChildren: children);

  static const String name = 'PostDetailRoute';

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      return const _i4.PostDetailScreen();
    },
  );
}
