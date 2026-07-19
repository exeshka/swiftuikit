import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'package:example/src/core/router/router.gr.dart';
import 'package:swiftuikit/swiftuikit.dart';

@RoutePage()
class ProductGridScreen extends StatelessWidget {
  const ProductGridScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SwiftInteractiveZoomBackground(
      child: Scaffold(
        appBar: AppBar(title: const Text('Products')),
        body: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.76,
          ),
          itemCount: _products.length,
          itemBuilder: (BuildContext context, int index) {
            final product = _products[index];
            return SwiftInteractiveZoomSource(
              id: product.id,
              borderRadius: BorderRadius.circular(24),
              child: _ProductCard(
                product: product,
                onTap: () =>
                    context.router.push(DetailRoute(heroId: product.id)),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Product {
  const _Product({
    required this.id,
    required this.name,
    required this.price,
    required this.color,
  });

  final String id;
  final String name;
  final String price;
  final Color color;
}

const _products = [
  _Product(
    id: 'product-air',
    name: 'Air Headphones',
    price: r'$249',
    color: Color(0xFF5E5CE6),
  ),
  _Product(
    id: 'product-watch',
    name: 'Studio Watch',
    price: r'$399',
    color: Color(0xFF0A84FF),
  ),
  _Product(
    id: 'product-speaker',
    name: 'Mini Speaker',
    price: r'$129',
    color: Color(0xFFFF9F0A),
  ),
  _Product(
    id: 'product-camera',
    name: 'Pocket Camera',
    price: r'$549',
    color: Color(0xFF30D158),
  ),
  _Product(
    id: 'product-light',
    name: 'Ambient Light',
    price: r'$89',
    color: Color(0xFFFF375F),
  ),
  _Product(
    id: 'product-keyboard',
    name: 'Magic Keyboard',
    price: r'$199',
    color: Color(0xFF64D2FF),
  ),
];

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final _Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: product.color,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Icon(
                Icons.inventory_2_outlined,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(height: 20),
              Text(
                product.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                product.price,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.76),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
