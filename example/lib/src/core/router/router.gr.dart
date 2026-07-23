// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i4;
import 'package:example/src/screens/product_detail_screen.dart' as _i1;
import 'package:example/src/screens/product_list_screen.dart' as _i3;
import 'package:example/src/screens/product_wrappers.dart' as _i2;
import 'package:flutter/material.dart' as _i5;

/// generated route for
/// [_i1.ProductDetailScreen]
class ProductDetailRoute extends _i4.PageRouteInfo<ProductDetailRouteArgs> {
  ProductDetailRoute({
    _i5.Key? key,
    required _i1.ProductEntity product,
    List<_i4.PageRouteInfo>? children,
  }) : super(
         ProductDetailRoute.name,
         args: ProductDetailRouteArgs(key: key, product: product),
         initialChildren: children,
       );

  static const String name = 'ProductDetailRoute';

  static _i4.PageInfo page = _i4.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ProductDetailRouteArgs>();
      return _i1.ProductDetailScreen(key: args.key, product: args.product);
    },
  );
}

class ProductDetailRouteArgs {
  const ProductDetailRouteArgs({this.key, required this.product});

  final _i5.Key? key;

  final _i1.ProductEntity product;

  @override
  String toString() {
    return 'ProductDetailRouteArgs{key: $key, product: $product}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ProductDetailRouteArgs) return false;
    return key == other.key && product == other.product;
  }

  @override
  int get hashCode => key.hashCode ^ product.hashCode;
}

/// generated route for
/// [_i2.ProductDetailSheetPage]
class ProductDetailSheetRoute
    extends _i4.PageRouteInfo<ProductDetailSheetRouteArgs> {
  ProductDetailSheetRoute({
    _i5.Key? key,
    required _i1.ProductEntity product,
    List<_i4.PageRouteInfo>? children,
  }) : super(
         ProductDetailSheetRoute.name,
         args: ProductDetailSheetRouteArgs(key: key, product: product),
         initialChildren: children,
       );

  static const String name = 'ProductDetailSheetRoute';

  static _i4.PageInfo page = _i4.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ProductDetailSheetRouteArgs>();
      return _i2.ProductDetailSheetPage(key: args.key, product: args.product);
    },
  );
}

class ProductDetailSheetRouteArgs {
  const ProductDetailSheetRouteArgs({this.key, required this.product});

  final _i5.Key? key;

  final _i1.ProductEntity product;

  @override
  String toString() {
    return 'ProductDetailSheetRouteArgs{key: $key, product: $product}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ProductDetailSheetRouteArgs) return false;
    return key == other.key && product == other.product;
  }

  @override
  int get hashCode => key.hashCode ^ product.hashCode;
}

/// generated route for
/// [_i2.ProductDetailZoomPage]
class ProductDetailZoomRoute
    extends _i4.PageRouteInfo<ProductDetailZoomRouteArgs> {
  ProductDetailZoomRoute({
    _i5.Key? key,
    required _i1.ProductEntity product,
    List<_i4.PageRouteInfo>? children,
  }) : super(
         ProductDetailZoomRoute.name,
         args: ProductDetailZoomRouteArgs(key: key, product: product),
         initialChildren: children,
       );

  static const String name = 'ProductDetailZoomRoute';

  static _i4.PageInfo page = _i4.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ProductDetailZoomRouteArgs>();
      return _i2.ProductDetailZoomPage(key: args.key, product: args.product);
    },
  );
}

class ProductDetailZoomRouteArgs {
  const ProductDetailZoomRouteArgs({this.key, required this.product});

  final _i5.Key? key;

  final _i1.ProductEntity product;

  @override
  String toString() {
    return 'ProductDetailZoomRouteArgs{key: $key, product: $product}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ProductDetailZoomRouteArgs) return false;
    return key == other.key && product == other.product;
  }

  @override
  int get hashCode => key.hashCode ^ product.hashCode;
}

/// generated route for
/// [_i3.ProductListScreen]
class ProductListRoute extends _i4.PageRouteInfo<void> {
  const ProductListRoute({List<_i4.PageRouteInfo>? children})
    : super(ProductListRoute.name, initialChildren: children);

  static const String name = 'ProductListRoute';

  static _i4.PageInfo page = _i4.PageInfo(
    name,
    builder: (data) {
      return const _i3.ProductListScreen();
    },
  );
}
