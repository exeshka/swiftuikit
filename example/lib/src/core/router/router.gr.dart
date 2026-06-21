// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i5;
import 'package:example/src/features/home/features/header_branch/presentation/pages/header_bracnk_detail_screen.dart'
    as _i1;
import 'package:example/src/features/home/features/header_branch/presentation/pages/header_branch2_screen.dart'
    as _i2;
import 'package:example/src/features/home/features/header_branch/presentation/pages/header_branch_screen.dart'
    as _i3;
import 'package:example/src/features/home/presentantion/pages/home_screen.dart'
    as _i4;
import 'package:flutter/material.dart' as _i6;

/// generated route for
/// [_i1.HeaderBracnkDetailScreen]
class HeaderBracnkDetailRoute
    extends _i5.PageRouteInfo<HeaderBracnkDetailRouteArgs> {
  HeaderBracnkDetailRoute({
    _i6.Key? key,
    required String url,
    List<_i5.PageRouteInfo>? children,
  }) : super(
         HeaderBracnkDetailRoute.name,
         args: HeaderBracnkDetailRouteArgs(key: key, url: url),
         initialChildren: children,
       );

  static const String name = 'HeaderBracnkDetailRoute';

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<HeaderBracnkDetailRouteArgs>();
      return _i1.HeaderBracnkDetailScreen(key: args.key, url: args.url);
    },
  );
}

class HeaderBracnkDetailRouteArgs {
  const HeaderBracnkDetailRouteArgs({this.key, required this.url});

  final _i6.Key? key;

  final String url;

  @override
  String toString() {
    return 'HeaderBracnkDetailRouteArgs{key: $key, url: $url}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HeaderBracnkDetailRouteArgs) return false;
    return key == other.key && url == other.url;
  }

  @override
  int get hashCode => key.hashCode ^ url.hashCode;
}

/// generated route for
/// [_i2.HeaderBranch2Screen]
class HeaderBranch2Route extends _i5.PageRouteInfo<void> {
  const HeaderBranch2Route({List<_i5.PageRouteInfo>? children})
    : super(HeaderBranch2Route.name, initialChildren: children);

  static const String name = 'HeaderBranch2Route';

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      return const _i2.HeaderBranch2Screen();
    },
  );
}

/// generated route for
/// [_i3.HeaderBranchScreen]
class HeaderBranchRoute extends _i5.PageRouteInfo<void> {
  const HeaderBranchRoute({List<_i5.PageRouteInfo>? children})
    : super(HeaderBranchRoute.name, initialChildren: children);

  static const String name = 'HeaderBranchRoute';

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      return const _i3.HeaderBranchScreen();
    },
  );
}

/// generated route for
/// [_i4.HomeScreen]
class HomeRoute extends _i5.PageRouteInfo<HomeRouteArgs> {
  HomeRoute({_i6.Key? key, List<_i5.PageRouteInfo>? children})
    : super(
        HomeRoute.name,
        args: HomeRouteArgs(key: key),
        initialChildren: children,
      );

  static const String name = 'HomeRoute';

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<HomeRouteArgs>(
        orElse: () => const HomeRouteArgs(),
      );
      return _i4.HomeScreen(key: args.key);
    },
  );
}

class HomeRouteArgs {
  const HomeRouteArgs({this.key});

  final _i6.Key? key;

  @override
  String toString() {
    return 'HomeRouteArgs{key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HomeRouteArgs) return false;
    return key == other.key;
  }

  @override
  int get hashCode => key.hashCode;
}
