import 'package:flutter/material.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 64),
            const SizedBox(height: 16),
            Text('SwiftPage demo', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Swipe from the left edge to go back'),
          ],
        ),
      ),
    );
  }
}
