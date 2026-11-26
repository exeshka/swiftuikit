import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftuikit/swiftuikit.dart';

import 'test_app.dart';

void main() {
  testWidgets('LiquidGlass.opacity fades the child and survives 0', (
    tester,
  ) async {
    Widget build(double o) => testApp(
      Center(
        child: LiquidGlass(
          cornerRadius: 20,
          width: 100,
          height: 60,
          opacity: o,
          child: const Text('x'),
        ),
      ),
    );
    await tester.pumpWidget(build(1));
    expect(find.byType(Opacity), findsNothing);
    await tester.pumpWidget(build(0.5));
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0.5);
    await tester.pumpWidget(build(0));
    expect(tester.takeException(), isNull);
  });
}
