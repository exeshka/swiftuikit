import 'package:auto_route/auto_route.dart';
import 'package:example/gen/assets.gen.dart';
import 'package:example/src/core/router/router.gr.dart';
import 'package:example/src/screens/product_detail_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:swiftuikit/swiftuikit.dart';

@RoutePage()
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  final Map<int, ScrollController> _controllers = {};

  static const _categories = ['Popular', 'New', 'Coffee', 'Dessert', 'Special'];

  ScrollController _controllerFor(int index) {
    return _controllers.putIfAbsent(index, () => ScrollController());
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SwiftPageViewAnimation.pageView(
              controller: _pageController,
              itemCount: 5,

              // parallaxIndexes: [],
              onPageChanged: (page) => setState(() => _currentPage = page),
              itemBuilder: (context, index) {
                return _CategoryPage(controller: _controllerFor(index));
              },
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _pageController,
              builder: (context, _) {
                return ScrollValueListener(
                  controller: _controllerFor(_currentPage),
                  builder: (context, offset) {
                    final screenHeight = MediaQuery.sizeOf(context).height;
                    final mainContentTopPadding = screenHeight / 1.5;
                    final rawProgress = (offset / mainContentTopPadding).clamp(
                      0.0,
                      1.0,
                    );
                    const curve = Interval(0.4, 1.0, curve: Curves.easeIn);
                    final progress = curve.transform(rawProgress);

                    return Column(
                      children: [
                        Opacity(
                          opacity: progress,
                          child: CupertinoNavigationBar.large(
                            transitionBetweenRoutes: false,
                            leading: CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.grey[800],
                                    child: Icon(
                                      CupertinoIcons.person_fill,
                                      size: 18,
                                      color: Colors.grey[300],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Profile',
                                    style: TextStyle(
                                      color: Colors.grey[300],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              onPressed: () {
                                context.router.push(ProfileRoute());
                              },
                            ),
                            largeTitle: Text(
                              _categories[_currentPage],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        _PageIndicator(currentPage: _currentPage, pageCount: 5),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int currentPage;
  final int pageCount;

  const _PageIndicator({required this.currentPage, required this.pageCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          pageCount,
          (i) => Container(
            width: i == currentPage ? 24 : 8,
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: i == currentPage
                  ? CupertinoTheme.of(context).primaryColor
                  : Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryPage extends StatelessWidget {
  final ScrollController controller;

  const _CategoryPage({required this.controller});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final mainContentTopPadding = screenHeight / 1.3;
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        physics: SnappingScrollPhysics(
          snapPoints: [0, mainContentTopPadding - 150],
          springConfig: SnapSpringConfig.snappy,
          parent: const BouncingScrollPhysics(),
        ),
        controller: controller,
        slivers: [
          SliverStack(
            children: [
              SliverToBoxAdapter(
                child: ScrollOverlapListener(
                  controller: controller,
                  maxOverlap: 1000,
                  builder: (context, overlap) {
                    return Transform.translate(
                      offset: Offset(0, -overlap),
                      child: Stack(
                        children: [
                          SizedBox(
                            height: screenHeight + overlap,
                            width: double.infinity,
                            child: AspectRatio(
                              aspectRatio: 21 / 9,
                              child: Image.asset(
                                Assets.banner.path,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: CupertinoNavigationBar(
                              middle: const Text('Discover'),
                              leading: CupertinoButton(
                                padding: EdgeInsets.zero,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.grey[800],
                                      child: Icon(
                                        CupertinoIcons.person_fill,
                                        size: 18,
                                        color: Colors.grey[300],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Profile',
                                      style: TextStyle(
                                        color: Colors.grey[300],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                onPressed: () {
                                  context.router.push(ProfileRoute());
                                },
                              ),
                              trailing: CupertinoButton(
                                padding: EdgeInsets.zero,
                                child: Icon(
                                  CupertinoIcons.search,
                                  color: Colors.grey[300],
                                ),
                                onPressed: () {},
                              ),
                              backgroundColor: Colors.transparent,
                              enableBackgroundFilterBlur: false,
                              transitionBetweenRoutes: false,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              SliverToBoxAdapter(
                child: ScrollValueListener(
                  controller: controller,
                  builder: (context, offset) {
                    final t = (offset / mainContentTopPadding).clamp(0.0, 1.0);
                    return Container(
                      height: screenHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.3, 1.0 - t / 2],
                          colors: [
                            Colors.black.withValues(alpha: t),
                            Colors.black.withValues(alpha: 0.9 + t),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              MultiSliver(
                children: [
                  SliverToBoxAdapter(
                    child: GestureDetector(
                      onTap: () {
                        context.router.push(
                          ProductDetailSheetRoute(
                            product: ProductEntity(
                              id: 'banner',
                              title: 'Featured Item',
                              image: Assets.banner.path,
                              price: 24.99,
                              rating: 4.8,
                              description:
                                  'A premium selection crafted for the perfect experience.',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: mainContentTopPadding,
                        color: Colors.transparent,
                      ),
                    ),
                  ),

                  SliverSafeArea(
                    sliver: MultiSliver(
                      children: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
                          sliver: SliverToBoxAdapter(
                            child: _SwiftZoomGallery(
                              products: _mockProducts.take(4).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SwiftZoomGallery extends StatelessWidget {
  const _SwiftZoomGallery({required this.products});

  final List<ProductEntity> products;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SwiftZoomHero · dynamic target',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Open a card, swipe vertically, then dismiss horizontally.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.75,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return SwiftZoomHero(
              id: product.id,
              borderRadius: BorderRadius.circular(22),

              child: GestureDetector(
                onTap: () {
                  context.router.push(
                    SwiftZoomGalleryRoute(
                      products: products,
                      initialIndex: index,
                    ),
                  );
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: product.gradientColors,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(
                          product.icon,
                          color: Colors.white.withValues(alpha: 0.35),
                          size: 36,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

final List<ProductEntity> _mockProducts = [
  ProductEntity(
    id: 'p1',
    title: 'Espresso Shot',
    price: 4.50,
    rating: 4.7,
    description: 'Rich and bold single-origin espresso.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF2D1B0E), const Color(0xFF6B3A2A)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p2',
    title: 'Cold Brew',
    price: 5.25,
    rating: 4.5,
    description: 'Smooth cold brew steeped for 20 hours.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF0D2137), const Color(0xFF1A4A6E)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p3',
    title: 'Matcha Latte',
    price: 5.75,
    rating: 4.8,
    description: 'Ceremonial grade matcha with oat milk.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF1B3B1A), const Color(0xFF4A7C3F)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p4',
    title: 'Croissant',
    price: 3.50,
    rating: 4.3,
    description: 'Flaky butter croissant baked fresh daily.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF4A3520), const Color(0xFFC49A6C)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p5',
    title: 'Blueberry Muffin',
    price: 3.25,
    rating: 4.2,
    description: 'Fresh blueberry muffin with streusel topping.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF2D1B3D), const Color(0xFF6B3A8C)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p6',
    title: 'Flat White',
    price: 4.75,
    rating: 4.6,
    description: 'Double ristretto with silky microfoam.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF1A1A2E), const Color(0xFF3A3A6E)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p7',
    title: 'Iced Latte',
    price: 4.50,
    rating: 4.4,
    description: 'Espresso over ice with your choice of milk.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF1E3A3A), const Color(0xFF3A6B6B)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p8',
    title: 'Chocolate Cake',
    price: 6.00,
    rating: 4.9,
    description: 'Decadent dark chocolate layer cake.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF2D0E0E), const Color(0xFF6B1A1A)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p9',
    title: 'Chai Latte',
    price: 5.00,
    rating: 4.3,
    description: 'Spiced chai blended with steamed milk.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF3D2D1A), const Color(0xFF8C6B3A)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p10',
    title: 'Bagel & Cream Cheese',
    price: 4.00,
    rating: 4.1,
    description: 'Toasted everything bagel with chive cream cheese.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF1A1A1A), const Color(0xFF4A4A4A)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p11',
    title: 'Mocha',
    price: 5.25,
    rating: 4.6,
    description: 'Espresso with dark chocolate and steamed milk.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF1A0E0E), const Color(0xFF4A1A1A)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p12',
    title: 'Avocado Toast',
    price: 7.50,
    rating: 4.4,
    description: 'Sourdough with avocado, chili flakes & lime.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF1B2D1A), const Color(0xFF4A6B3A)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p13',
    title: 'Cortado',
    price: 4.25,
    rating: 4.5,
    description: 'Equal parts espresso and warm milk.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF2D1A1A), const Color(0xFF6B3A3A)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p14',
    title: 'Banana Bread',
    price: 3.75,
    rating: 4.3,
    description: 'Moist banana bread with walnuts.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF3D2D1A), const Color(0xFF8C6B3A)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p15',
    title: 'Latte',
    price: 4.75,
    rating: 4.5,
    description: 'Classic espresso with steamed milk and light foam.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF1A1A2E), const Color(0xFF3A3A6E)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p16',
    title: ' Cappuccino',
    price: 4.50,
    rating: 4.4,
    description: 'Espresso with thick foam and cocoa dusting.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF2D1B0E), const Color(0xFF6B3A2A)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p17',
    title: 'Iced Matcha',
    price: 5.50,
    rating: 4.7,
    description: 'Shaken matcha over ice with vanilla syrup.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF1B3B1A), const Color(0xFF4A7C3F)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p18',
    title: 'Scone',
    price: 3.25,
    rating: 4.0,
    description: 'Buttermilk scone with clotted cream & jam.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF4A3520), const Color(0xFFC49A6C)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p19',
    title: 'Affogato',
    price: 5.00,
    rating: 4.8,
    description: 'Espresso poured over vanilla gelato.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF1A1A1A), const Color(0xFF4A3A2A)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p20',
    title: 'Turkish Coffee',
    price: 4.00,
    rating: 4.2,
    description: 'Traditionally brewed in cezve with cardamom.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF2D1B0E), const Color(0xFF4A2A1A)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p21',
    title: 'Sparkling Lemonade',
    price: 3.50,
    rating: 4.1,
    description: 'House-made sparkling lemonade with mint.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF1A2D1A), const Color(0xFF3A6B3A)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p22',
    title: 'Caramel Macchiato',
    price: 5.50,
    rating: 4.6,
    description: 'Layered vanilla latte with caramel drizzle.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF2D1A0E), const Color(0xFF6B4A2A)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p23',
    title: 'Cheesecake',
    price: 6.50,
    rating: 4.7,
    description: 'New York style cheesecake with berry compote.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF1A1A2E), const Color(0xFF4A4A6B)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p24',
    title: 'Americano',
    price: 3.75,
    rating: 4.3,
    description: 'Espresso topped with hot water.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF1A1A1A), const Color(0xFF3A3A3A)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p25',
    title: 'Hot Chocolate',
    price: 4.50,
    rating: 4.5,
    description: 'Rich Belgian chocolate with whipped cream.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF2D0E0E), const Color(0xFF6B1A1A)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p26',
    title: 'Panini',
    price: 7.00,
    rating: 4.3,
    description: 'Grilled panini with mozzarella, tomato & pesto.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF1B2D1A), const Color(0xFF4A6B3A)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p27',
    title: 'Nitro Cold Brew',
    price: 5.50,
    rating: 4.6,
    description: 'Cold brew infused with nitrogen for creamy texture.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF0D2137), const Color(0xFF1A4A6E)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p28',
    title: 'Cookie',
    price: 2.50,
    rating: 4.4,
    description: 'Warm chocolate chunk cookie with sea salt.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF3D2D1A), const Color(0xFF8C6B3A)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p29',
    title: 'Ristretto',
    price: 3.50,
    rating: 4.2,
    description: 'Short, concentrated espresso shot.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF2D1B0E), const Color(0xFF6B3A2A)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p30',
    title: 'Fruit Tart',
    price: 5.75,
    rating: 4.5,
    description: 'Shortcrust tart with fresh seasonal fruits.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF2D1B3D), const Color(0xFF6B3A8C)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p31',
    title: 'Macchiato',
    price: 4.00,
    rating: 4.1,
    description: 'Espresso marked with a dollop of foam.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF1A1A2E), const Color(0xFF3A3A6E)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p32',
    title: 'Brownie',
    price: 3.50,
    rating: 4.6,
    description: 'Fudgy dark chocolate brownie with walnuts.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF2D0E0E), const Color(0xFF6B1A1A)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p33',
    title: 'Pour Over',
    price: 5.00,
    rating: 4.7,
    description: 'Single-origin pour-over, hand-crafted to order.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF1A1A1A), const Color(0xFF4A3A2A)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p34',
    title: 'Smoothie Bowl',
    price: 8.00,
    rating: 4.4,
    description: 'Açaí smoothie bowl with granola & fresh fruit.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF2D1B3D), const Color(0xFF6B3A8C)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p35',
    title: 'Irish Coffee',
    price: 8.00,
    rating: 4.3,
    description: 'Coffee with Irish whiskey, sugar & cream.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF1A0E0E), const Color(0xFF4A1A1A)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p36',
    title: 'Tea (Earl Grey)',
    price: 3.00,
    rating: 4.0,
    description: 'Classic Earl Grey with bergamot.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF1E3A3A), const Color(0xFF3A6B6B)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p37',
    title: 'Red Velvet Cake',
    price: 6.50,
    rating: 4.7,
    description: 'Red velvet with cream cheese frosting.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF3D0E1A), const Color(0xFF8C1A3A)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p38',
    title: 'Doppio',
    price: 3.75,
    rating: 4.1,
    description: 'Double espresso, straight up.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF1A1A1A), const Color(0xFF3A3A3A)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p39',
    title: 'Cinnamon Roll',
    price: 4.25,
    rating: 4.8,
    description: 'Warm cinnamon roll with cream cheese glaze.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF4A3520), const Color(0xFFC49A6C)],
    icon: CupertinoIcons.flame_fill,
  ),
  ProductEntity(
    id: 'p40',
    title: 'Iced Chai',
    price: 5.25,
    rating: 4.3,
    description: 'Spiced chai concentrate over ice with milk.',
    image: Assets.mockPhoto.path,
    gradientColors: [const Color(0xFF3D2D1A), const Color(0xFF8C6B3A)],
    icon: CupertinoIcons.flame_fill,
  ),
];
