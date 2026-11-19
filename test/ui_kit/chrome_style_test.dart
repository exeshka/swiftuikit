import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftuikit/swiftuikit.dart';

import 'test_app.dart';

Widget _page({ChromeStyle? top, ChromeStyle? bottom}) => testApp(
  ChromeScaffold(
    topChrome: top,
    bottomChrome: bottom,
    topBar: const ChromeBar(child: SizedBox(height: 52)),
    body: ListView(children: rows(30)),
  ),
);

Future<ChromeInsetsData> _insets(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  return ChromeScaffoldScope.insetsOf(tester.element(find.byType(ListView)));
}

void main() {
  testWidgets('default is the soft blur, the zone reaches past the bar', (
    tester,
  ) async {
    setPhoneSize(tester);
    await tester.pumpWidget(_page());
    final insets = await _insets(tester);
    final t = SwiftUiTheme.of(tester.element(find.byType(ChromeScaffold)));
    expect(find.byType(ProgressiveBlur), findsOneWidget);
    expect(insets.topZone, 59 + 52 + t.chrome.blurExtra);
  });

  testWidgets('solid: a plain container that ends with the bar', (
    tester,
  ) async {
    setPhoneSize(tester);
    await tester.pumpWidget(_page(top: const ChromeStyle.solid()));
    final insets = await _insets(tester);
    expect(find.byType(ProgressiveBlur), findsNothing);
    expect(insets.topZone, 59 + 52);
  });

  testWidgets('none: nothing is drawn and the zone is empty', (tester) async {
    setPhoneSize(tester);
    await tester.pumpWidget(_page(top: const ChromeStyle.none()));
    final insets = await _insets(tester);
    expect(find.byType(ProgressiveBlur), findsNothing);
    expect(insets.topZone, 0);
  });

  testWidgets('custom: the builder gets the zone spec', (tester) async {
    setPhoneSize(tester);
    ChromeSpec? seen;
    await tester.pumpWidget(
      _page(
        top: ChromeStyle.custom(
          extent: 10,
          builder: (context, spec) {
            seen = spec;
            return SizedBox(key: const ValueKey('custom'), height: spec.height);
          },
        ),
      ),
    );
    final insets = await _insets(tester);
    expect(find.byKey(const ValueKey('custom')), findsOneWidget);
    expect(seen!.edge, BlurEdge.top);
    expect(seen!.covered, 59 + 52);
    expect(insets.topZone, 59 + 52 + 10);
  });

  testWidgets('a ChromeStyleScope sets the default below it', (tester) async {
    setPhoneSize(tester);
    await tester.pumpWidget(
      testApp(
        ChromeStyleScope.both(
          style: const ChromeStyle.fade(),
          child: ChromeScaffold(
            topBar: const ChromeBar(child: SizedBox(height: 52)),
            body: ListView(children: rows(30)),
          ),
        ),
      ),
    );
    await _insets(tester);
    final blur = tester.widget<ProgressiveBlur>(find.byType(ProgressiveBlur));
    expect(blur.effect, ChromeEdgeEffect.fade);
  });
}
