import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class SheetScreen extends StatelessWidget {
  const SheetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _SheetContent(title: 'SwiftSheet', subtitle: 'Drag down to dismiss');
  }
}

@RoutePage()
class SheetNoBgScreen extends StatelessWidget {
  const SheetNoBgScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _SheetContent(
      title: 'No Background Animation',
      subtitle: 'Previous page stays still',
    );
  }
}

@RoutePage()
class SheetNoSwipeScreen extends StatelessWidget {
  const SheetNoSwipeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _SheetContent(
      title: 'No Drag to Dismiss',
      subtitle: 'Swipe disabled, use back button',
    );
  }
}

@RoutePage()
class SheetCustomRadiusScreen extends StatelessWidget {
  const SheetCustomRadiusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _SheetContent(
      title: 'Custom Radius (16)',
      subtitle: 'sheetRadius: 16',
    );
  }
}

@RoutePage()
class SheetFullHeightScreen extends StatelessWidget {
  const SheetFullHeightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return Material(
      color: Colors.indigo,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.fullscreen_rounded, size: 72, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              'Full-height SwiftSheet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'MediaQuery.padding.top = ${topPadding.toStringAsFixed(1)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sheet занимает 100% высоты, а контент остаётся ниже '
              'системной области благодаря SafeArea.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 28),
            FilledButton.tonal(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Закрыть'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetContent extends StatelessWidget {
  const _SheetContent({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Container(
              width: 36,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          ...List.generate(
            20,
            (i) => ListTile(
              leading: CircleAvatar(child: Text('${i + 1}')),
              title: Text('Item ${i + 1}'),
            ),
          ),
        ],
      ),
    );
  }
}
