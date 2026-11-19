import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftuikit/swiftuikit.dart';

class _Probe extends StatelessWidget {
  const _Probe();
  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    return Text('${t.brightness.name} ${t.colors.accent.toARGB32()}');
  }
}

void main() {
  testWidgets('themeMode picks the light or the dark theme data', (
    tester,
  ) async {
    final light = SwiftUiThemeData.light();
    final dark = SwiftUiThemeData.dark();
    final accent = dark.colors.copyWith(accent: const Color(0xFF0A84FF));
    Widget app(ThemeMode m) => SwiftUiApp(
      warmUp: false,
      themeMode: m,
      theme: light,
      darkTheme: dark.copyWith(colors: accent),
      home: const _Probe(),
    );
    await tester.pumpWidget(app(ThemeMode.light));
    expect(
      find.text('light ${light.colors.accent.toARGB32()}'),
      findsOneWidget,
    );
    await tester.pumpWidget(app(ThemeMode.dark));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('dark ${0xFF0A84FF}'), findsOneWidget);
  });

  testWidgets('defaults to the kit themes and follows the platform', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await tester.pumpWidget(const SwiftUiApp(warmUp: false, home: _Probe()));
    expect(find.textContaining('dark'), findsOneWidget);
  });

  testWidgets('the app builder wraps the navigator', (tester) async {
    await tester.pumpWidget(
      SwiftUiApp(
        warmUp: false,
        builder: (context, child) => Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(children: [child!, const Text('over')]),
        ),
        home: const _Probe(),
      ),
    );
    expect(find.text('over'), findsOneWidget);
  });

  testWidgets('SwiftUiApp.router builds from a router config', (tester) async {
    final config = RouterConfig<Object>(
      routeInformationProvider: PlatformRouteInformationProvider(
        initialRouteInformation: RouteInformation(uri: Uri.parse('/')),
      ),
      routeInformationParser: _Parser(),
      routerDelegate: _Delegate(),
    );
    await tester.pumpWidget(
      SwiftUiApp.router(warmUp: false, routerConfig: config),
    );
    expect(find.byType(_Probe), findsOneWidget);
  });
}

class _Parser extends RouteInformationParser<Object> {
  @override
  Future<Object> parseRouteInformation(RouteInformation info) async => '/';
}

class _Delegate extends RouterDelegate<Object> with ChangeNotifier {
  @override
  Widget build(BuildContext context) => const _Probe();
  @override
  Future<void> setNewRoutePath(Object configuration) async {}
  @override
  Future<bool> popRoute() async => false;
}
