import 'package:example/src/screens/swift_page_hero_demo_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Hero follows an interactive SwiftPage pop from the center', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SwiftPageHeroDemoCard(heroTag: 'test-hero'),
              ),
            ),
          ),
        ),
      ),
    );
    final initialException = tester.takeException();
    expect(initialException, isNull);
    await tester.tap(find.byKey(const ValueKey('swift-page-hero-demo-card')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(
      find.byKey(const ValueKey('swift-page-hero-demo-screen')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('swift-page-hero-flight')), findsNothing);

    final gesture = await tester.startGesture(const Offset(195, 700));
    await gesture.moveBy(const Offset(210, 0));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('swift-page-hero-flight')),
      findsOneWidget,
    );
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('swift-page-hero-demo-screen')))
          .dx,
      greaterThan(0),
    );

    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('swift-page-hero-demo-screen')),
      findsNothing,
    );
  });
}
