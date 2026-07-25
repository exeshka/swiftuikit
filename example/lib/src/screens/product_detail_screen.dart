import 'package:auto_route/annotations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProductEntity {
  final String id;
  final String title;
  final String image;

  ProductEntity({required this.id, required this.title, required this.image});
}

@RoutePage()
class ProductDetailScreen extends StatelessWidget {
  final ProductEntity product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CupertinoNavigationBar(
        enableBackgroundFilterBlur: false,
        transitionBetweenRoutes: false,
        backgroundColor: Colors.transparent,
      ),
      body: SizedBox(
        height: .infinity,

        child: Image.asset(
          product.image,
          fit: .cover,
          // color: Colors.red.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
