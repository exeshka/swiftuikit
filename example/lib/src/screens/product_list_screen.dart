import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:example/gen/assets.gen.dart';
import 'package:example/src/core/router/router.gr.dart';
import 'package:example/src/core/widgets/page_scroll_sync_coordinator.dart';
import 'package:example/src/core/widgets/scroll_overlap_listener.dart';
import 'package:example/src/core/widgets/scroll_value_listener.dart';
import 'package:example/src/core/widgets/snapping_scroll_physics.dart';
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

  final Map<int, ScrollController> _controllers = {};

  PageScrollSyncCoordinator? _syncCoordinator;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // snapPoint зависит от screenHeight, MediaQuery доступен только тут,
    // поэтому инициализация не в initState, а тут, с защитой от повторного создания
    final screenHeight = MediaQuery.sizeOf(context).height;
    final snapPoint = screenHeight / 1.5;
    _syncCoordinator ??= PageScrollSyncCoordinator(snapPoint: snapPoint);
  }

  ScrollController _controllerFor(int index) {
    final isNew = !_controllers.containsKey(index);

    final controller = _controllers.putIfAbsent(index, () {
      return ScrollController(
        initialScrollOffset: _syncCoordinator!.initialOffsetForNewController,
      );
    });

    if (isNew) {
      _syncCoordinator!.attach(controller);
    }

    // на каждую сборку страницы — досинкаем на случай если состояние
    // изменилось между созданием контроллера и его реальным attach к Scrollable
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncCoordinator?.syncIfNeeded(controller);
    });

    return controller;
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      _syncCoordinator?.detach(c);
      c.dispose();
    }
    _syncCoordinator?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              itemCount: 5, // сколько категорий
              itemBuilder: (context, index) {
                return PrimaryScrollController(
                  controller: _controllerFor(index),
                  child: _CategoryPage(controller: _controllerFor(index)),
                );
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
                final rawPage =
                    _pageController.hasClients &&
                        _pageController.positions.isNotEmpty
                    ? (_pageController.page ??
                          _pageController.initialPage.toDouble())
                    : 0.0;
                final index = rawPage.round();

                return ScrollValueListener(
                  controller: _controllerFor(index),
                  builder: (context, offset) {
                    final screenHeight = MediaQuery.sizeOf(context).height;
                    final mainContentTopPadding = screenHeight / 1.5;
                    final rawProgress = (offset / mainContentTopPadding).clamp(
                      0.0,
                      1.0,
                    );
                    const curve = Interval(0.4, 1.0, curve: Curves.easeIn);
                    final progress = curve.transform(rawProgress);

                    return Opacity(
                      opacity: progress,
                      child: CupertinoNavigationBar.large(
                        transitionBetweenRoutes: false,
                        largeTitle: Text("Content appbar"),
                      ),
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

class _CategoryPage extends StatelessWidget {
  final ScrollController controller;

  const _CategoryPage({required this.controller});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final mainContentTopPadding = screenHeight / 1.5;
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        physics: SnappingScrollPhysics(
          snapPoints: [0, mainContentTopPadding],
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
                              middle: Text("Profile appbar"),
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
                  controller: PrimaryScrollController.of(context),
                  builder: (context, offset) {
                    final t = (offset / mainContentTopPadding).clamp(0.0, 1.0);

                    return Container(
                      height: screenHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [
                            0.3,
                            1.0 - t / 2,
                          ], // стоп едет вверх — чёрное "поле" расширяется
                          colors: [
                            Colors.black.withValues(
                              alpha: t,
                            ), // верх плавно чернеет

                            Colors.black.withValues(
                              alpha: 0.9 + t,
                            ), // низ всегда чёрный
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
                              id: "434",
                              title: "Banner",
                              image: Assets.banner.path,
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

                  SliverToBoxAdapter(child: SizedBox(height: 80)),
                  SliverSafeArea(
                    sliver: SliverPadding(
                      padding: .symmetric(horizontal: 16),
                      sliver: SliverGrid.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 16,

                              childAspectRatio: 160 / 220,
                            ),
                        itemBuilder: (context, index) {
                          final product = ProductEntity(
                            id: "id$index",
                            title: "Best coffe $index",
                            image: Assets.mockPhoto.path,
                          );
                          return SwiftInteractiveZoomSource(
                            id: "id$index",
                            child: GestureDetector(
                              onTap: () {
                                context.router.push(
                                  ProductDetailZoomRoute(product: product),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 26, 26, 26),
                                  border: Border.all(
                                    color: const Color.fromARGB(
                                      31,
                                      130,
                                      130,
                                      130,
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                ),

                                child: ClipRRect(
                                  borderRadius: .circular(30),
                                  child: Image.asset(
                                    product.image,
                                    fit: .cover,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        itemCount: 40,
                      ),
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

class CategoriesWidget extends StatelessWidget {
  final ScrollController controller;

  final PageController pageController;

  const CategoriesWidget({
    super.key,
    required this.controller,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: .horizontal,
        itemCount: 5,
        itemBuilder: (context, index) => Text("Mock category"),
      ),
    );
  }
}
