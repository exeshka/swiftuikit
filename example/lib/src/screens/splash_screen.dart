import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'package:example/src/core/router/router.gr.dart';

@RoutePage()
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => context.router.push(const HomeRoute()),
          child: const Text('Enter'),
        ),
      ),
    );
  }
}
