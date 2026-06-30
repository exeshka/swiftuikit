import 'package:auto_route/auto_route.dart';
import 'package:example/src/core/router/router.gr.dart';
import 'package:flutter/material.dart';

@RoutePage()
class SheetNestedPage1 extends StatelessWidget {
  const SheetNestedPage1({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Page 1',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'This is the first page inside the sheet navigator.\n'
          'Navigate to page 2 — the sheet stays open.',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 24),
        Card(
          color: Colors.grey.shade800,
          child: ListTile(
            leading: const Icon(Icons.arrow_forward, color: Colors.white),
            title: const Text(
              'Go to Page 2',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Pushes page 2 inside the sheet',
              style: TextStyle(color: Colors.white54),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white54),
            onTap: () => context.router.push(const SheetNestedPage2Route()),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: Colors.grey.shade800,
          child: const ListTile(
            leading: Icon(Icons.info_outline, color: Colors.amber),
            title: Text(
              'Static item 1',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Just filler content',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: Colors.grey.shade800,
          child: const ListTile(
            leading: Icon(Icons.info_outline, color: Colors.amber),
            title: Text(
              'Static item 2',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'More filler content',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ),
      ],
    );
  }
}
