import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class SheetNestedPage2 extends StatelessWidget {
  const SheetNestedPage2({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Page 2',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'This is the second page inside the sheet.\n'
          'Swipe back or tap the back button to return to page 1.',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 24),
        Card(
          color: Colors.grey.shade800,
          child: ListTile(
            leading: const Icon(Icons.arrow_back, color: Colors.white),
            title: const Text(
              'Back to Page 1',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Pops back inside the sheet',
              style: TextStyle(color: Colors.white54),
            ),
            trailing: const Icon(Icons.chevron_left, color: Colors.white54),
            onTap: () => context.router.maybePop(),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: Colors.grey.shade800,
          child: ListTile(
            leading: const Icon(Icons.close, color: Colors.red),
            title: const Text(
              'Close entire sheet',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Pops the sheet route itself',
              style: TextStyle(color: Colors.white54),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white54),
            onTap: () => context.router.maybePop(),
          ),
        ),
      ],
    );
  }
}
