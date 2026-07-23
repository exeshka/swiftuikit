import 'package:auto_route/auto_route.dart';
import 'package:example/src/screens/product_detail_screen.dart';
import 'package:flutter/material.dart';

@RoutePage()
class ProductDetailZoomPage extends StatelessWidget {
  const ProductDetailZoomPage({super.key, required this.product});

  final ProductEntity product;

  @override
  Widget build(BuildContext context) {
    return ProductDetailScreen(product: product);
  }
}

@RoutePage()
class ProductDetailSheetPage extends StatelessWidget {
  const ProductDetailSheetPage({super.key, required this.product});

  final ProductEntity product;

  @override
  Widget build(BuildContext context) {
    return ProductDetailScreen(product: product);
  }
}
