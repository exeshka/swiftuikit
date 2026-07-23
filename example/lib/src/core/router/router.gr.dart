// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i16;
import 'package:example/src/screens/detail_no_swipe_screen.dart' as _i1;
import 'package:example/src/screens/detail_screen.dart' as _i2;
import 'package:example/src/screens/hero_flow/hero_page_one_screen.dart' as _i3;
import 'package:example/src/screens/hero_flow/hero_page_two_screen.dart' as _i4;
import 'package:example/src/screens/hero_flow/hero_sheet_five_screen.dart'
    as _i5;
import 'package:example/src/screens/hero_flow/hero_sheet_four_screen.dart'
    as _i6;
import 'package:example/src/screens/hero_flow/hero_sheet_one_screen.dart'
    as _i7;
import 'package:example/src/screens/hero_flow/hero_sheet_three_screen.dart'
    as _i8;
import 'package:example/src/screens/hero_flow/hero_sheet_two_screen.dart'
    as _i9;
import 'package:example/src/screens/home_screen.dart' as _i10;
import 'package:example/src/screens/navigation_lab_screen.dart' as _i11;
import 'package:example/src/screens/product_grid_screen.dart' as _i12;
import 'package:example/src/screens/sheet_navigation_lab_screen.dart' as _i14;
import 'package:example/src/screens/sheet_screen.dart' as _i13;
import 'package:example/src/screens/splash_screen.dart' as _i15;
import 'package:flutter/material.dart' as _i17;

/// generated route for
/// [_i1.DetailNoSwipeScreen]
class DetailNoSwipeRoute extends _i16.PageRouteInfo<void> {
  const DetailNoSwipeRoute({List<_i16.PageRouteInfo>? children})
    : super(DetailNoSwipeRoute.name, initialChildren: children);

  static const String name = 'DetailNoSwipeRoute';

  static _i16.PageInfo page = _i16.PageInfo(
    name,
    builder: (data) {
      return const _i1.DetailNoSwipeScreen();
    },
  );
}

/// generated route for
/// [_i2.DetailScreen]
class DetailRoute extends _i16.PageRouteInfo<DetailRouteArgs> {
  DetailRoute({
    _i17.Key? key,
    required String heroId,
    List<_i16.PageRouteInfo>? children,
  }) : super(
         DetailRoute.name,
         args: DetailRouteArgs(key: key, heroId: heroId),
         initialChildren: children,
       );

  static const String name = 'DetailRoute';

  static _i16.PageInfo page = _i16.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DetailRouteArgs>();
      return _i2.DetailScreen(key: args.key, heroId: args.heroId);
    },
  );
}

class DetailRouteArgs {
  const DetailRouteArgs({this.key, required this.heroId});

  final _i17.Key? key;

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
/// [_i3.HeroPageOneScreen]
class HeroRouteOneRoute extends _i16.PageRouteInfo<void> {
  const HeroRouteOneRoute({List<_i16.PageRouteInfo>? children})
    : super(HeroRouteOneRoute.name, initialChildren: children);

  static const String name = 'HeroRouteOneRoute';

  static _i16.PageInfo page = _i16.PageInfo(
    name,
    builder: (data) {
      return const _i3.HeroPageOneScreen();
    },
  );
}

/// generated route for
/// [_i4.HeroPageTwoScreen]
class HeroRouteTwoRoute extends _i16.PageRouteInfo<void> {
  const HeroRouteTwoRoute({List<_i16.PageRouteInfo>? children})
    : super(HeroRouteTwoRoute.name, initialChildren: children);

  static const String name = 'HeroRouteTwoRoute';

  static _i16.PageInfo page = _i16.PageInfo(
    name,
    builder: (data) {
      return const _i4.HeroPageTwoScreen();
    },
  );
}

/// generated route for
/// [_i5.HeroSheetFiveScreen]
class HeroSheetFiveRoute extends _i16.PageRouteInfo<void> {
  const HeroSheetFiveRoute({List<_i16.PageRouteInfo>? children})
    : super(HeroSheetFiveRoute.name, initialChildren: children);

  static const String name = 'HeroSheetFiveRoute';

  static _i16.PageInfo page = _i16.PageInfo(
    name,
    builder: (data) {
      return const _i5.HeroSheetFiveScreen();
    },
  );
}

/// generated route for
/// [_i6.HeroSheetFourScreen]
class HeroSheetFourRoute extends _i16.PageRouteInfo<void> {
  const HeroSheetFourRoute({List<_i16.PageRouteInfo>? children})
    : super(HeroSheetFourRoute.name, initialChildren: children);

  static const String name = 'HeroSheetFourRoute';

  static _i16.PageInfo page = _i16.PageInfo(
    name,
    builder: (data) {
      return const _i6.HeroSheetFourScreen();
    },
  );
}

/// generated route for
/// [_i7.HeroSheetOneScreen]
class HeroSheetOneRoute extends _i16.PageRouteInfo<void> {
  const HeroSheetOneRoute({List<_i16.PageRouteInfo>? children})
    : super(HeroSheetOneRoute.name, initialChildren: children);

  static const String name = 'HeroSheetOneRoute';

  static _i16.PageInfo page = _i16.PageInfo(
    name,
    builder: (data) {
      return const _i7.HeroSheetOneScreen();
    },
  );
}

/// generated route for
/// [_i8.HeroSheetThreeScreen]
class HeroSheetThreeRoute extends _i16.PageRouteInfo<void> {
  const HeroSheetThreeRoute({List<_i16.PageRouteInfo>? children})
    : super(HeroSheetThreeRoute.name, initialChildren: children);

  static const String name = 'HeroSheetThreeRoute';

  static _i16.PageInfo page = _i16.PageInfo(
    name,
    builder: (data) {
      return const _i8.HeroSheetThreeScreen();
    },
  );
}

/// generated route for
/// [_i9.HeroSheetTwoScreen]
class HeroSheetTwoRoute extends _i16.PageRouteInfo<void> {
  const HeroSheetTwoRoute({List<_i16.PageRouteInfo>? children})
    : super(HeroSheetTwoRoute.name, initialChildren: children);

  static const String name = 'HeroSheetTwoRoute';

  static _i16.PageInfo page = _i16.PageInfo(
    name,
    builder: (data) {
      return const _i9.HeroSheetTwoScreen();
    },
  );
}

/// generated route for
/// [_i10.HomeScreen]
class HomeRoute extends _i16.PageRouteInfo<void> {
  const HomeRoute({List<_i16.PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static _i16.PageInfo page = _i16.PageInfo(
    name,
    builder: (data) {
      return const _i10.HomeScreen();
    },
  );
}

/// generated route for
/// [_i11.NavigationLabScreen]
class NavigationLabRoute extends _i16.PageRouteInfo<void> {
  const NavigationLabRoute({List<_i16.PageRouteInfo>? children})
    : super(NavigationLabRoute.name, initialChildren: children);

  static const String name = 'NavigationLabRoute';

  static _i16.PageInfo page = _i16.PageInfo(
    name,
    builder: (data) {
      return const _i11.NavigationLabScreen();
    },
  );
}

/// generated route for
/// [_i11.NavigationResultScreen]
class NavigationResultRoute
    extends _i16.PageRouteInfo<NavigationResultRouteArgs> {
  NavigationResultRoute({
    required String operation,
    required String expectedBackDestination,
    bool canReturnResult = false,
    _i17.Key? key,
    List<_i16.PageRouteInfo>? children,
  }) : super(
         NavigationResultRoute.name,
         args: NavigationResultRouteArgs(
           operation: operation,
           expectedBackDestination: expectedBackDestination,
           canReturnResult: canReturnResult,
           key: key,
         ),
         initialChildren: children,
       );

  static const String name = 'NavigationResultRoute';

  static _i16.PageInfo page = _i16.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NavigationResultRouteArgs>();
      return _i11.NavigationResultScreen(
        operation: args.operation,
        expectedBackDestination: args.expectedBackDestination,
        canReturnResult: args.canReturnResult,
        key: args.key,
      );
    },
  );
}

class NavigationResultRouteArgs {
  const NavigationResultRouteArgs({
    required this.operation,
    required this.expectedBackDestination,
    this.canReturnResult = false,
    this.key,
  });

  final String operation;

  final String expectedBackDestination;

  final bool canReturnResult;

  final _i17.Key? key;

  @override
  String toString() {
    return 'NavigationResultRouteArgs{operation: $operation, expectedBackDestination: $expectedBackDestination, canReturnResult: $canReturnResult, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NavigationResultRouteArgs) return false;
    return operation == other.operation &&
        expectedBackDestination == other.expectedBackDestination &&
        canReturnResult == other.canReturnResult &&
        key == other.key;
  }

  @override
  int get hashCode =>
      operation.hashCode ^
      expectedBackDestination.hashCode ^
      canReturnResult.hashCode ^
      key.hashCode;
}

/// generated route for
/// [_i12.ProductGridScreen]
class ProductGridRoute extends _i16.PageRouteInfo<void> {
  const ProductGridRoute({List<_i16.PageRouteInfo>? children})
    : super(ProductGridRoute.name, initialChildren: children);

  static const String name = 'ProductGridRoute';

  static _i16.PageInfo page = _i16.PageInfo(
    name,
    builder: (data) {
      return const _i12.ProductGridScreen();
    },
  );
}

/// generated route for
/// [_i13.SheetCustomRadiusScreen]
class SheetCustomRadiusRoute extends _i16.PageRouteInfo<void> {
  const SheetCustomRadiusRoute({List<_i16.PageRouteInfo>? children})
    : super(SheetCustomRadiusRoute.name, initialChildren: children);

  static const String name = 'SheetCustomRadiusRoute';

  static _i16.PageInfo page = _i16.PageInfo(
    name,
    builder: (data) {
      return const _i13.SheetCustomRadiusScreen();
    },
  );
}

/// generated route for
/// [_i13.SheetFullHeightScreen]
class SheetFullHeightRoute extends _i16.PageRouteInfo<void> {
  const SheetFullHeightRoute({List<_i16.PageRouteInfo>? children})
    : super(SheetFullHeightRoute.name, initialChildren: children);

  static const String name = 'SheetFullHeightRoute';

  static _i16.PageInfo page = _i16.PageInfo(
    name,
    builder: (data) {
      return const _i13.SheetFullHeightScreen();
    },
  );
}

/// generated route for
/// [_i14.SheetNavigationLabScreen]
class SheetNavigationLabRoute extends _i16.PageRouteInfo<void> {
  const SheetNavigationLabRoute({List<_i16.PageRouteInfo>? children})
    : super(SheetNavigationLabRoute.name, initialChildren: children);

  static const String name = 'SheetNavigationLabRoute';

  static _i16.PageInfo page = _i16.PageInfo(
    name,
    builder: (data) {
      return const _i14.SheetNavigationLabScreen();
    },
  );
}

/// generated route for
/// [_i14.SheetNavigationResultScreen]
class SheetNavigationResultRoute
    extends _i16.PageRouteInfo<SheetNavigationResultRouteArgs> {
  SheetNavigationResultRoute({
    required String operation,
    required String expectedBackDestination,
    bool canReturnResult = false,
    _i17.Key? key,
    List<_i16.PageRouteInfo>? children,
  }) : super(
         SheetNavigationResultRoute.name,
         args: SheetNavigationResultRouteArgs(
           operation: operation,
           expectedBackDestination: expectedBackDestination,
           canReturnResult: canReturnResult,
           key: key,
         ),
         initialChildren: children,
       );

  static const String name = 'SheetNavigationResultRoute';

  static _i16.PageInfo page = _i16.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SheetNavigationResultRouteArgs>();
      return _i14.SheetNavigationResultScreen(
        operation: args.operation,
        expectedBackDestination: args.expectedBackDestination,
        canReturnResult: args.canReturnResult,
        key: args.key,
      );
    },
  );
}

class SheetNavigationResultRouteArgs {
  const SheetNavigationResultRouteArgs({
    required this.operation,
    required this.expectedBackDestination,
    this.canReturnResult = false,
    this.key,
  });

  final String operation;

  final String expectedBackDestination;

  final bool canReturnResult;

  final _i17.Key? key;

  @override
  String toString() {
    return 'SheetNavigationResultRouteArgs{operation: $operation, expectedBackDestination: $expectedBackDestination, canReturnResult: $canReturnResult, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SheetNavigationResultRouteArgs) return false;
    return operation == other.operation &&
        expectedBackDestination == other.expectedBackDestination &&
        canReturnResult == other.canReturnResult &&
        key == other.key;
  }

  @override
  int get hashCode =>
      operation.hashCode ^
      expectedBackDestination.hashCode ^
      canReturnResult.hashCode ^
      key.hashCode;
}

/// generated route for
/// [_i13.SheetNoBgScreen]
class SheetNoBgRoute extends _i16.PageRouteInfo<void> {
  const SheetNoBgRoute({List<_i16.PageRouteInfo>? children})
    : super(SheetNoBgRoute.name, initialChildren: children);

  static const String name = 'SheetNoBgRoute';

  static _i16.PageInfo page = _i16.PageInfo(
    name,
    builder: (data) {
      return const _i13.SheetNoBgScreen();
    },
  );
}

/// generated route for
/// [_i13.SheetNoSwipeScreen]
class SheetNoSwipeRoute extends _i16.PageRouteInfo<void> {
  const SheetNoSwipeRoute({List<_i16.PageRouteInfo>? children})
    : super(SheetNoSwipeRoute.name, initialChildren: children);

  static const String name = 'SheetNoSwipeRoute';

  static _i16.PageInfo page = _i16.PageInfo(
    name,
    builder: (data) {
      return const _i13.SheetNoSwipeScreen();
    },
  );
}

/// generated route for
/// [_i13.SheetScreen]
class SheetRoute extends _i16.PageRouteInfo<void> {
  const SheetRoute({List<_i16.PageRouteInfo>? children})
    : super(SheetRoute.name, initialChildren: children);

  static const String name = 'SheetRoute';

  static _i16.PageInfo page = _i16.PageInfo(
    name,
    builder: (data) {
      return const _i13.SheetScreen();
    },
  );
}

/// generated route for
/// [_i15.SplashScreen]
class SplashRoute extends _i16.PageRouteInfo<void> {
  const SplashRoute({List<_i16.PageRouteInfo>? children})
    : super(SplashRoute.name, initialChildren: children);

  static const String name = 'SplashRoute';

  static _i16.PageInfo page = _i16.PageInfo(
    name,
    builder: (data) {
      return const _i15.SplashScreen();
    },
  );
}
