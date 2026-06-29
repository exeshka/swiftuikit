import 'package:auto_route/auto_route.dart';
import 'package:example/src/core/router/router.gr.dart';
import 'package:flutter/material.dart';

@RoutePage()
class RouteLabScreen extends StatelessWidget {
  const RouteLabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _RouteLabScaffold(
      title: 'Route lab',
      subtitle: 'Push, replace, sheets and locked pop behavior',
      children: [
        _RouteLabTile(
          title: 'Push page',
          subtitle: 'Regular SwiftPageAutoRoute. Back swipe should close it.',
          onTap: () => context.router.push(const RouteLabPushRoute()),
        ),
        _RouteLabTile(
          title: 'Push sheet',
          subtitle: 'SwiftSheetAutoRoute with the same radius path.',
          onTap: () => context.router.push(const RouteLabSheetRoute()),
        ),
        _RouteLabTile(
          title: 'Replace page',
          subtitle: 'Calls router.replace and removes this lab screen.',
          onTap: () => context.router.replace(const RouteLabReplaceRoute()),
        ),
        _RouteLabTile(
          title: 'Locked canPop: false',
          subtitle: 'System back, swipe back and maybePop should be blocked.',
          onTap: () => context.router.push(const RouteLabLockedRoute()),
        ),
      ],
    );
  }
}

@RoutePage()
class RouteLabPushScreen extends StatelessWidget {
  const RouteLabPushScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _RouteLabScaffold(
      title: 'Pushed page',
      subtitle: 'Try the horizontal back swipe or the back button.',
      children: [
        _RouteLabTile(
          title: 'Push another page',
          subtitle: 'Checks stacked SwiftPageRoute transitions.',
          onTap: () => context.router.push(const RouteLabPushRoute()),
        ),
        _RouteLabTile(
          title: 'Replace from pushed page',
          subtitle: 'Current page should be swapped for replace target.',
          onTap: () => context.router.replace(const RouteLabReplaceRoute()),
        ),
        _RouteLabTile(
          title: 'Open sheet above page',
          subtitle: 'Checks page background rounding under a sheet.',
          onTap: () => context.router.push(const RouteLabSheetRoute()),
        ),
      ],
    );
  }
}

@RoutePage()
class RouteLabReplaceScreen extends StatelessWidget {
  const RouteLabReplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _RouteLabScaffold(
      title: 'Replace target',
      subtitle: 'This screen arrived through router.replace.',
      children: [
        _RouteLabTile(
          title: 'Push normal page',
          subtitle: 'Checks stack after replace.',
          onTap: () => context.router.push(const RouteLabPushRoute()),
        ),
        _RouteLabTile(
          title: 'Back to lab root',
          subtitle: 'Uses replace so the stack stays easy to reason about.',
          onTap: () => context.router.replace(const RouteLabRoute()),
        ),
      ],
    );
  }
}

@RoutePage()
class RouteLabLockedScreen extends StatefulWidget {
  const RouteLabLockedScreen({super.key});

  @override
  State<RouteLabLockedScreen> createState() => _RouteLabLockedScreenState();
}

class _RouteLabLockedScreenState extends State<RouteLabLockedScreen> {
  String _lastResult = 'No pop attempts yet';

  @override
  Widget build(BuildContext context) {
    return _RouteLabScaffold(
      title: 'Locked route',
      subtitle: 'Configured as SwiftPageAutoRoute(canPop: false).',
      footer: _lastResult,
      children: [
        _RouteLabTile(
          title: 'Try maybePop()',
          subtitle: 'Expected result: false, route remains visible.',
          onTap: () async {
            final didPop = await context.router.maybePop();
            if (!mounted) return;
            setState(() {
              _lastResult = 'maybePop returned $didPop';
            });
          },
        ),
        _RouteLabTile(
          title: 'Replace to exit',
          subtitle: 'Programmatic replace should still let us leave the test.',
          onTap: () => context.router.replace(const RouteLabReplaceRoute()),
        ),
      ],
    );
  }
}

@RoutePage()
class RouteLabSheetScreen extends StatelessWidget {
  const RouteLabSheetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _RouteLabScaffold(
      title: 'Sheet route',
      subtitle: 'Pull down to dismiss. AppBar should have no status padding.',
      children: [
        _RouteLabTile(
          title: 'Push page from sheet',
          subtitle: 'Checks stacked sheet to page behavior.',
          onTap: () => context.router.push(const RouteLabPushRoute()),
        ),
        _RouteLabTile(
          title: 'Replace sheet',
          subtitle: 'Checks replace while a sheet route is current.',
          onTap: () => context.router.replace(const RouteLabReplaceRoute()),
        ),
      ],
    );
  }
}

class _RouteLabScaffold extends StatelessWidget {
  const _RouteLabScaffold({
    required this.title,
    required this.subtitle,
    required this.children,
    this.footer,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text(title), backgroundColor: Colors.black),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ...children,
          if (footer != null) ...[
            const SizedBox(height: 16),
            Text(
              footer!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.lightGreenAccent),
            ),
          ],
        ],
      ),
    );
  }
}

class _RouteLabTile extends StatelessWidget {
  const _RouteLabTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}
