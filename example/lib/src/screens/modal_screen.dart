import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

@RoutePage()
class ModalScreen extends StatelessWidget {
  const ModalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Read the current scroll sheet extent from context.
    // Rebuilds automatically on every drag tick.
    final double extent = SwiftScrollSheetRoute.extentOf(context);
    final controller = SwiftScrollSheetRoute.controllerOf(context);

    return SwiftModalScaffold(
      // backgroundColor: Colors.red,
      header: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Drag handle indicator
          Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(50),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Scroll Sheet Detents [.height(260), .fraction(0.8), .large]',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Current Extent: ${(extent * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
      body: ListView(
        // Automatically inherits PrimaryScrollController from scroll sheet
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        children: [
          Text(
            'This sheet is built with SwiftScrollSheetRoute and SwiftModalScaffold. As the extent grows past 45%, the margins shrink to 0, shadows fade, and the corner radius dynamically morphs into the screen radius.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer,
                ),
                onPressed: () => controller?.animateTo(0.4),
                child: const Text('Snap 40%'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer,
                ),
                onPressed: () => controller?.animateTo(0.8),
                child: const Text('Snap 80%'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer,
                ),
                onPressed: () => controller?.animateTo(1.0),
                child: const Text('Snap 100%'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
            onPressed: () => context.router.pop(),
            child: const Text('Close Route'),
          ),
          const SizedBox(height: 24),
          ...List.generate(15, (index) {
            return ListTile(
              leading: Icon(
                Icons.star_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Item #$index',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                'Scrollable item inside draggable sheet',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
