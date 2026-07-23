import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swiftuikit/swiftuikit.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const productId = 'product-42';
    return SwiftInteractiveZoomBackground(
      child: Scaffold(
        appBar: AppBar(title: const Text('swiftuikit demos (go_router)')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionHeader('Navigation'),
            _DemoTile(
              label: 'Navigation Lab',
              subtitle: 'push, pushReplacement, replace, Back и проверка стека',
              color: Colors.indigo,
              onTap: () => context.push('/navigation-lab'),
            ),
            const SizedBox(height: 24),
            _SectionHeader('SwiftZoom'),
            SwiftInteractiveZoomSource(
              id: productId,
              borderRadius: BorderRadius.circular(12),
              child: _DemoTile(
                label: 'Product #42',
                subtitle: 'The product ID is also the Hero tag',
                bottomPadding: 0,
                onTap: () => context.push('/product/$productId'),
              ),
            ),
            const SizedBox(height: 32),
            _SectionHeader('SwiftPage'),
            _DemoTile(
              label: 'SwiftPage',
              subtitle: 'Default iOS transition + swipe back',
              onTap: () => context.push('/detail'),
            ),
            _DemoTile(
              label: 'SwiftPage (no swipe)',
              subtitle: 'canSwipe: false, canOnlySwipeFromEdge: true',
              onTap: () => context.push('/detail-no-swipe'),
            ),
            const SizedBox(height: 24),
            _SectionHeader('SwiftSheet'),
            _DemoTile(
              label: 'SwiftSheet Navigation Lab',
              subtitle: 'Sheet → Sheet/Page, replacement, Back, result и drag',
              color: Colors.teal.shade700,
              onTap: () => context.push('/sheet-navigation-lab'),
            ),
            _DemoTile(
              label: 'SwiftSheet',
              subtitle: 'Default sheet with drag-to-dismiss',
              color: Colors.green.shade600,
              onTap: () => context.push('/sheet'),
            ),
            _DemoTile(
              label: 'SwiftSheet (full height + safe area)',
              subtitle: 'preserveTopSafeArea: true, topGap: 0',
              color: Colors.indigo,
              onTap: () => context.push('/sheet-full-height'),
            ),
            _DemoTile(
              label: 'SwiftSheet (no bg animation)',
              subtitle: 'animateBackground: false',
              color: Colors.green.shade600,
              onTap: () => context.push('/sheet-no-bg'),
            ),
            _DemoTile(
              label: 'SwiftSheet (no swipe)',
              subtitle: 'enableDrag: false',
              color: Colors.green.shade600,
              onTap: () => context.push('/sheet-no-swipe'),
            ),
            _DemoTile(
              label: 'SwiftSheet (radius 16)',
              subtitle: 'sheetRadius: 16',
              color: Colors.green.shade600,
              onTap: () => context.push('/sheet-custom-radius'),
            ),
            const SizedBox(height: 24),
            _SectionHeader('Hero Flow'),
            _DemoTile(
              label: 'Hero Test Flow',
              subtitle: 'Page → Page → Sheet → Sheet with CupertinoNavBar',
              color: Colors.deepPurple,
              onTap: () => context.push('/hero/page-one'),
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
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: ListTile(
        tileColor: color ?? CupertinoColors.systemBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        onTap: onTap,
      ),
    );
  }
}
