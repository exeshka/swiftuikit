import 'package:auto_route/auto_route.dart';
import 'package:example/src/core/router/router.gr.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

@RoutePage()
class ClientFlowScreen extends StatefulWidget {
  const ClientFlowScreen({super.key});

  @override
  State<ClientFlowScreen> createState() => _ClientFlowScreenState();
}

class _ClientFlowScreenState extends State<ClientFlowScreen> {
  PageController? _pageController;
  TabsRouter? _tabsRouter;

  void _onRouterChanged() {
    final router = _tabsRouter;
    final controller = _pageController;
    if (router == null || controller == null || !controller.hasClients) return;

    final current = controller.page?.round() ?? controller.initialPage;
    if (current != router.activeIndex) {
      controller.animateToPage(
        router.activeIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.linearToEaseOut,
      );
    }
  }

  @override
  void dispose() {
    _tabsRouter?.removeListener(_onRouterChanged);
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AutoTabsRouter.builder(
              routes: const [ClientCreateStoriesRoute(), ClientHomeRoute()],
              builder: (context, children, tabsRouter) {
                if (_tabsRouter != tabsRouter) {
                  _tabsRouter?.removeListener(_onRouterChanged);
                  _tabsRouter = tabsRouter;
                  _tabsRouter?.addListener(_onRouterChanged);
                }

                _pageController ??= PageController(
                  initialPage: tabsRouter.activeIndex,
                );

                return SwiftPageViewAnimation.autoTabsPageView(
                  controller: _pageController!,
                  children: children,
                  onPageChanged: tabsRouter.setActiveIndex,
                );
              },
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: AnimatedBuilder(
                animation: _pageController ?? PageController(),
                builder: (context, _) => _ClientBottomNav(
                  controller: _pageController ?? PageController(),
                  onTap: (index) {
                    _tabsRouter?.setActiveIndex(index);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientBottomNav extends StatelessWidget {
  const _ClientBottomNav({required this.controller, required this.onTap});

  final PageController controller;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final page = controller.hasClients
            ? controller.page ?? controller.initialPage.toDouble()
            : controller.initialPage.toDouble();

        return Container(
          height: 64,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(32),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / 2;

              return Stack(
                children: [
                  Transform.translate(
                    offset: Offset(page * itemWidth, 0),
                    child: Container(
                      width: itemWidth,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => onTap(0),
                          child: const Text('Stories'),
                        ),
                      ),
                      Expanded(
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => onTap(1),
                          child: const Text('Home'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
