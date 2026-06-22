import 'package:example/src/core/router/router.dart';
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  App({super.key});

  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData(
        brightness: .dark,

        applyElevationOverlayColor: false,
        appBarTheme: AppBarTheme(surfaceTintColor: Colors.transparent),
        colorScheme: ColorScheme.dark(
          surface: Colors.black,
          onSurface: Colors.white,
        ),
      ),

      routerConfig: _appRouter.config(),
    );
  }
}
