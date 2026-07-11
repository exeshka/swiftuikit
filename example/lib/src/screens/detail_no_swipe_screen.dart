import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class DetailNoSwipeScreen extends StatelessWidget {
  const DetailNoSwipeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('No Swipe Back')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 64),
            const SizedBox(height: 16),
            Text('Swipe-back disabled', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Use the back button or edge swipe only'),
          ],
        ),
      ),
    );
  }
}
