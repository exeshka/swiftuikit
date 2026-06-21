import 'package:example/src/core/router/router.dart';
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  App({super.key});

  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: .dark(),

      routerConfig: _appRouter.config(),
    );
  }
}
