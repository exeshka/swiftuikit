// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i6;
import 'package:example/src/screens/detail_screen.dart' as _i1;
import 'package:example/src/screens/home_screen.dart' as _i2;
import 'package:example/src/screens/modal_screen.dart' as _i3;
import 'package:example/src/screens/sheet_screen.dart' as _i4;
import 'package:example/src/screens/splash_screen.dart' as _i5;
import 'package:flutter/material.dart' as _i7;

/// generated route for
/// [_i1.DetailScreen]
class DetailRoute extends _i6.PageRouteInfo<DetailRouteArgs> {
  DetailRoute({
    _i7.Key? key,
    required String heroId,
    List<_i6.PageRouteInfo>? children,
  }) : super(
         DetailRoute.name,
         args: DetailRouteArgs(key: key, heroId: heroId),
         rawPathParams: {'heroId': heroId},
         initialChildren: children,
       );

  static const String name = 'DetailRoute';

  static _i6.PageInfo page = _i6.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<DetailRouteArgs>(
        orElse: () => DetailRouteArgs(heroId: pathParams.getString('heroId')),
      );
      return _i1.DetailScreen(key: args.key, heroId: args.heroId);
    },
  );
}

class DetailRouteArgs {
  const DetailRouteArgs({this.key, required this.heroId});

  final _i7.Key? key;

  final String heroId;

  @override
  String toString() {
    return 'DetailRouteArgs{key: $key, heroId: $heroId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DetailRouteArgs) return false;
    return key == other.key && heroId == other.heroId;
  }

  @override
  int get hashCode => key.hashCode ^ heroId.hashCode;
}

/// generated route for
/// [_i2.HomeScreen]
class HomeRoute extends _i6.PageRouteInfo<void> {
  const HomeRoute({List<_i6.PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static _i6.PageInfo page = _i6.PageInfo(
    name,
    builder: (data) {
      return const _i2.HomeScreen();
    },
  );
}

/// generated route for
/// [_i3.ModalScreen]
class ModalRoute extends _i6.PageRouteInfo<void> {
  const ModalRoute({List<_i6.PageRouteInfo>? children})
    : super(ModalRoute.name, initialChildren: children);

  static const String name = 'ModalRoute';

  static _i6.PageInfo page = _i6.PageInfo(
    name,
    builder: (data) {
      return const _i3.ModalScreen();
    },
  );
}

/// generated route for
/// [_i4.SheetScreen]
class SheetRoute extends _i6.PageRouteInfo<void> {
  const SheetRoute({List<_i6.PageRouteInfo>? children})
    : super(SheetRoute.name, initialChildren: children);

  static const String name = 'SheetRoute';

  static _i6.PageInfo page = _i6.PageInfo(
    name,
    builder: (data) {
      return const _i4.SheetScreen();
    },
  );
}

/// generated route for
/// [_i5.SplashScreen]
class SplashRoute extends _i6.PageRouteInfo<void> {
  const SplashRoute({List<_i6.PageRouteInfo>? children})
    : super(SplashRoute.name, initialChildren: children);

  static const String name = 'SplashRoute';

  static _i6.PageInfo page = _i6.PageInfo(
    name,
    builder: (data) {
      return const _i5.SplashScreen();
    },
  );
}
