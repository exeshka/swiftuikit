import 'package:auto_route/annotations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProductEntity {
  final String id;
  final String title;
  final String image;
  final double price;
  final double rating;
  final String description;
  final List<Color> gradientColors;
  final IconData icon;

  ProductEntity({
    required this.id,
    required this.title,
    required this.image,
    this.price = 0.0,
    this.rating = 0.0,
    this.description = '',
    this.gradientColors = const [Color(0xFF1A1A1A), Color(0xFF4A4A4A)],
    this.icon = CupertinoIcons.flame_fill,
  });
}

@RoutePage()
class ProductDetailScreen extends StatefulWidget {
  final ProductEntity product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedSize = 1;
  int _quantity = 1;

  final _sizes = ['Small', 'Medium', 'Large'];

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CupertinoNavigationBar(
        enableBackgroundFilterBlur: false,
        transitionBetweenRoutes: false,
        backgroundColor: Colors.transparent,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.heart, color: Colors.white, size: 20),
          ),
          onPressed: () {},
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 320,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: product.gradientColors,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          product.icon,
                          size: 120,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: CupertinoTheme.of(context).primaryColor,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.star_fill,
                                  size: 14,
                                  color: CupertinoTheme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${product.rating}',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Text(
                      product.description,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Text(
                      'Select Size',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: List.generate(
                        _sizes.length,
                        (i) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: i < _sizes.length - 1 ? 8 : 0,
                            ),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedSize = i),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _selectedSize == i
                                      ? CupertinoTheme.of(context).primaryColor.withValues(alpha: 0.15)
                                      : const Color(0xFF1A1A1A),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _selectedSize == i
                                        ? CupertinoTheme.of(context).primaryColor
                                        : Colors.white.withValues(alpha: 0.08),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    _sizes[i],
                                    style: TextStyle(
                                      color: _selectedSize == i
                                          ? CupertinoTheme.of(context).primaryColor
                                          : Colors.grey[400],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Text(
                      'Nutrition Info',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        _NutritionChip(label: '120 kcal', icon: CupertinoIcons.flame_fill),
                        const SizedBox(width: 8),
                        _NutritionChip(label: '12g protein', icon: CupertinoIcons.cube_box_fill),
                        const SizedBox(width: 8),
                        _NutritionChip(label: '16g fat', icon: CupertinoIcons.circle_filled),
                      ],
                    ),
                  ),

                  SizedBox(height: 24 + bottom),
                ],
              ),
            ),
          ),

          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D0D),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottom),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.all(12),
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                        child: Icon(
                          CupertinoIcons.minus,
                          size: 20,
                          color: _quantity > 1 ? Colors.white : Colors.grey[600],
                        ),
                      ),
                      Text(
                        '$_quantity',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.all(12),
                        onPressed: () => setState(() => _quantity++),
                        child: const Icon(
                          CupertinoIcons.plus,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: CupertinoTheme.of(context).primaryColor,
                    ),
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {},
                      child: Text(
                        'Add to Cart — \$${(product.price * _quantity).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _NutritionChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
