// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i8;
import 'package:collection/collection.dart' as _i11;
import 'package:example/src/screens/product_detail_screen.dart' as _i1;
import 'package:example/src/screens/product_list_screen.dart' as _i3;
import 'package:example/src/screens/product_wrappers.dart' as _i2;
import 'package:example/src/screens/profile/profile_edit_screen.dart' as _i4;
import 'package:example/src/screens/profile/profile_screen.dart' as _i5;
import 'package:example/src/screens/profile/profile_wrapper_screen.dart' as _i6;
import 'package:example/src/screens/swift_zoom_gallery_screen.dart' as _i7;
import 'package:flutter/cupertino.dart' as _i9;
import 'package:flutter/material.dart' as _i10;

/// generated route for
/// [_i1.ProductDetailScreen]
class ProductDetailRoute extends _i8.PageRouteInfo<ProductDetailRouteArgs> {
  ProductDetailRoute({
    _i9.Key? key,
    required _i1.ProductEntity product,
    List<_i8.PageRouteInfo>? children,
  }) : super(
         ProductDetailRoute.name,
         args: ProductDetailRouteArgs(key: key, product: product),
         initialChildren: children,
       );

  static const String name = 'ProductDetailRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ProductDetailRouteArgs>();
      return _i1.ProductDetailScreen(key: args.key, product: args.product);
    },
  );
}

class ProductDetailRouteArgs {
  const ProductDetailRouteArgs({this.key, required this.product});

  final _i9.Key? key;

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
    extends _i8.PageRouteInfo<ProductDetailSheetRouteArgs> {
  ProductDetailSheetRoute({
    _i10.Key? key,
    required _i1.ProductEntity product,
    List<_i8.PageRouteInfo>? children,
  }) : super(
         ProductDetailSheetRoute.name,
         args: ProductDetailSheetRouteArgs(key: key, product: product),
         initialChildren: children,
       );

  static const String name = 'ProductDetailSheetRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ProductDetailSheetRouteArgs>();
      return _i2.ProductDetailSheetPage(key: args.key, product: args.product);
    },
  );
}

class ProductDetailSheetRouteArgs {
  const ProductDetailSheetRouteArgs({this.key, required this.product});

  final _i10.Key? key;

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
/// [_i3.ProductListScreen]
class ProductListRoute extends _i8.PageRouteInfo<void> {
  const ProductListRoute({List<_i8.PageRouteInfo>? children})
    : super(ProductListRoute.name, initialChildren: children);

  static const String name = 'ProductListRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      return const _i3.ProductListScreen();
    },
  );
}

/// generated route for
/// [_i4.ProfileEditScreen]
class ProfileEditRoute extends _i8.PageRouteInfo<void> {
  const ProfileEditRoute({List<_i8.PageRouteInfo>? children})
    : super(ProfileEditRoute.name, initialChildren: children);

  static const String name = 'ProfileEditRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      return const _i4.ProfileEditScreen();
    },
  );
}

/// generated route for
/// [_i5.ProfileScreen]
class ProfileRoute extends _i8.PageRouteInfo<void> {
  const ProfileRoute({List<_i8.PageRouteInfo>? children})
    : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      return const _i5.ProfileScreen();
    },
  );
}

/// generated route for
/// [_i6.ProfileWrapperScreen]
class ProfileWrapperRoute extends _i8.PageRouteInfo<void> {
  const ProfileWrapperRoute({List<_i8.PageRouteInfo>? children})
    : super(ProfileWrapperRoute.name, initialChildren: children);

  static const String name = 'ProfileWrapperRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      return const _i6.ProfileWrapperScreen();
    },
  );
}

/// generated route for
/// [_i7.SwiftZoomGalleryScreen]
class SwiftZoomGalleryRoute
    extends _i8.PageRouteInfo<SwiftZoomGalleryRouteArgs> {
  SwiftZoomGalleryRoute({
    _i9.Key? key,
    required List<_i1.ProductEntity> products,
    required int initialIndex,
    List<_i8.PageRouteInfo>? children,
  }) : super(
         SwiftZoomGalleryRoute.name,
         args: SwiftZoomGalleryRouteArgs(
           key: key,
           products: products,
           initialIndex: initialIndex,
         ),
         initialChildren: children,
       );

  static const String name = 'SwiftZoomGalleryRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SwiftZoomGalleryRouteArgs>();
      return _i7.SwiftZoomGalleryScreen(
        key: args.key,
        products: args.products,
        initialIndex: args.initialIndex,
      );
    },
  );
}

class SwiftZoomGalleryRouteArgs {
  const SwiftZoomGalleryRouteArgs({
    this.key,
    required this.products,
    required this.initialIndex,
  });

  final _i9.Key? key;

  final List<_i1.ProductEntity> products;

  final int initialIndex;

  @override
  String toString() {
    return 'SwiftZoomGalleryRouteArgs{key: $key, products: $products, initialIndex: $initialIndex}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SwiftZoomGalleryRouteArgs) return false;
    return key == other.key &&
        const _i11.ListEquality<_i1.ProductEntity>().equals(
          products,
          other.products,
        ) &&
        initialIndex == other.initialIndex;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      const _i11.ListEquality<_i1.ProductEntity>().hash(products) ^
      initialIndex.hashCode;
}
