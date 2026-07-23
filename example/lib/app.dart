import 'package:example/src/core/router/router.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  App({super.key});

  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(surface: Colors.black),
      ),
      routerConfig: _appRouter.config(),
      builder: (context, child) => CupertinoTheme(
        data: CupertinoThemeData(
          brightness: .dark,
          scaffoldBackgroundColor: Colors.black,
        ),
        child: child!,
      ),
    );
  }
}
