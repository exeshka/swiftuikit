import 'package:auto_route/annotations.dart';
import 'package:example/src/screens/product_detail_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

@RoutePage()
class SwiftZoomGalleryScreen extends StatefulWidget {
  const SwiftZoomGalleryScreen({
    super.key,
    required this.products,
    required this.initialIndex,
  });

  final List<ProductEntity> products;
  final int initialIndex;

  @override
  State<SwiftZoomGalleryScreen> createState() => _SwiftZoomGalleryScreenState();
}

class _SwiftZoomGalleryScreenState extends State<SwiftZoomGalleryScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.products[_currentIndex];
    final screenRadius = ScreenRadiusService.instance.radius;

    return SwiftZoomHero(
      id: product.id,
      borderRadius: screenRadius,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              key: const ValueKey('swift-zoom-vertical-page-view'),
              controller: _pageController,
              scrollDirection: Axis.vertical,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.products.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                return _ZoomGalleryItem(
                  product: widget.products[index],
                  index: index,
                  count: widget.products.length,
                );
              },
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.maybePop(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.38),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.chevron_back,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomGalleryItem extends StatelessWidget {
  const _ZoomGalleryItem({
    required this.product,
    required this.index,
    required this.count,
  });

  final ProductEntity product;
  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: product.gradientColors,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(28, 84, 28, 28 + bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${index + 1} / $count',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.58),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Center(
                child: Icon(
                  product.icon,
                  size: 180,
                  color: Colors.white.withValues(alpha: 0.22),
                ),
              ),
              const Spacer(),
              Text(
                product.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.68),
                  fontSize: 17,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    CupertinoIcons.arrow_up_arrow_down,
                    color: Colors.white70,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Swipe vertically',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
