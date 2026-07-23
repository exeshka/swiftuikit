import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:example/src/core/router/router.gr.dart';
import 'package:swiftuikit/swiftuikit.dart';

@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SwiftInteractiveZoomBackground(
      child: Scaffold(
        appBar: AppBar(title: const Text('swiftuikit demos')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionHeader('Navigation'),
            _DemoTile(
              label: 'Navigation Lab',
              subtitle: 'push, replace, Back, result и проверка стека',
              color: Colors.indigo,
              onTap: () => context.router.push(const NavigationLabRoute()),
            ),
            const SizedBox(height: 24),
            _SectionHeader('SwiftZoom'),
            SwiftInteractiveZoomSource(
              id: 'detail-page',
              borderRadius: BorderRadius.circular(32),

              child: _DemoTile(
                label: 'Interactive Zoom',
                subtitle: 'Dedicated card-to-page transition with swipe back',
                bottomPadding: 0,
                onTap: () =>
                    context.router.push(DetailRoute(heroId: 'detail-page')),
              ),
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 24),
            _SectionHeader('Interactive Zoom + auto_route'),
            _DemoTile(
              label: 'Product Grid',
              subtitle: 'Each product ID becomes the interactive Hero tag',
              color: Colors.deepPurple,
              onTap: () => context.router.push(const ProductGridRoute()),
            ),
            const SizedBox(height: 16),
            _SectionHeader('SwiftPage'),
            _DemoTile(
              label: 'SwiftPage (no swipe)',
              subtitle: 'canSwipe: false, canOnlySwipeFromEdge: true',
              onTap: () => context.router.push(const DetailNoSwipeRoute()),
            ),
            const SizedBox(height: 24),
            _SectionHeader('SwiftSheet'),
            _DemoTile(
              label: 'SwiftSheet Navigation Lab',
              subtitle: 'Sheet → Sheet/Page, replace, Back, result и drag',
              color: Colors.teal.shade700,
              onTap: () => context.router.push(const SheetNavigationLabRoute()),
            ),
            _DemoTile(
              label: 'SwiftSheet',
              subtitle: 'Default sheet with drag-to-dismiss',
              color: Colors.green.shade600,
              onTap: () => context.router.push(const SheetRoute()),
            ),
            _DemoTile(
              label: 'SwiftSheet (full height + safe area)',
              subtitle: 'preserveTopSafeArea: true, topGap: 0',
              color: Colors.indigo,
              onTap: () => context.router.push(const SheetFullHeightRoute()),
            ),
            _DemoTile(
              label: 'SwiftSheet (no bg animation)',
              subtitle: 'animateBackground: false',
              color: Colors.green.shade600,
              onTap: () => context.router.push(const SheetNoBgRoute()),
            ),
            _DemoTile(
              label: 'SwiftSheet (no swipe)',
              subtitle: 'enableDrag: false',
              color: Colors.green.shade600,
              onTap: () => context.router.push(const SheetNoSwipeRoute()),
            ),
            _DemoTile(
              label: 'SwiftSheet (radius 16)',
              subtitle: 'sheetRadius: 16',
              color: Colors.green.shade600,
              onTap: () => context.router.push(const SheetCustomRadiusRoute()),
            ),
            const SizedBox(height: 24),
            _SectionHeader('Hero Flow'),
            _DemoTile(
              label: 'Hero Test Flow',
              subtitle: 'Page → Page → Sheet → Sheet with CupertinoNavBar',
              color: Colors.deepPurple,
              onTap: () => context.router.push(const HeroRouteOneRoute()),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(color: CupertinoColors.secondaryLabel),
      ),
    );
  }
}

class _DemoTile extends StatelessWidget {
  const _DemoTile({
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.color,
    this.bottomPadding = 8,
  });

  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Container(
          height: 100,

          width: double.infinity,
          decoration: BoxDecoration(
            color: color ?? CupertinoColors.systemBlue,

            borderRadius: BorderRadius.circular(32),
          ),

          child: Column(
            crossAxisAlignment: .start,

            children: [Text(label), Text(subtitle)],
          ),
        ),
      ),
    );
  }
}
