import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftuikit/swiftuikit.dart';

import 'test_app.dart';

void main() {
  test('groups interpolate: colours, doubles, text styles', () {
    final a = SwiftUiThemeData.dark();
    final b = SwiftUiThemeData.light();
    final m = a.lerp(b, 0.5);
    expect(
      m.colors.background,
      Color.lerp(a.colors.background, b.colors.background, 0.5),
    );
    expect(m.chrome.blurSigma, 10);
    final c = a.copyWith(chrome: a.chrome.copyWith(blurSigma: 20));
    expect(a.lerp(c, 0.5).chrome.blurSigma, 15);
    expect(m.typography.body.color, isNotNull);
  });

  test('the chrome style cannot be interpolated: it switches half way', () {
    final a = SwiftUiThemeData.dark();
    final b = a.copyWith(
      chrome: a.chrome.copyWith(top: const ChromeStyle.none()),
    );
    expect(a.lerp(b, 0.4).chrome.top, isA<ProgressiveChromeStyle>());
    expect(a.lerp(b, 0.6).chrome.top, isA<NoChromeStyle>());
  });

  testWidgets('the theme decides the chrome style of a scaffold', (
    tester,
  ) async {
    setPhoneSize(tester);
    final base = SwiftUiThemeData.dark();
    await tester.pumpWidget(
      SwiftUiApp(
        themeMode: ThemeMode.dark,
        darkTheme: base.copyWith(
          chrome: base.chrome.copyWith(top: const ChromeStyle.solid()),
        ),
        home: ChromeScaffold(
          topBar: const ChromeBar(child: SizedBox(height: 52)),
          body: ListView(children: rows(30)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ProgressiveBlur), findsNothing);
  });
}
