import 'package:example/src/screens/swift_sheet_hero_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftuikit/swiftuikit.dart';

void main() {
  testWidgets(
    'SwiftSheet Hero supports slow drag and immediate background scrolling',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final backgroundController = ScrollController();
      final routeObserver = _LastPushedRouteObserver();
      addTearDown(backgroundController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [routeObserver],
          home: Scaffold(
            backgroundColor: Colors.black,
            body: ListView(
              controller: backgroundController,
              padding: const EdgeInsets.fromLTRB(16, 72, 16, 80),
              children: [
                const SwiftSheetHeroDemoCard(heroTag: 'test-sheet-hero'),
                ...List.generate(
                  12,
                  (index) => Container(
                    height: 76,
                    margin: const EdgeInsets.only(top: 12),
                    color: Colors.white10,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('swift-sheet-hero-demo-card')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('swift-sheet-hero-demo-content')),
        findsOneWidget,
      );

      final slowGesture = await tester.startGesture(const Offset(195, 250));
      await slowGesture.moveBy(const Offset(0, 30));
      await tester.pump();
      await slowGesture.moveBy(const Offset(0, 100));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('swift-sheet-hero-flight')),
        findsOneWidget,
      );

      await slowGesture.up();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('swift-sheet-hero-demo-content')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('swift-sheet-hero-flight')),
        findsNothing,
      );

      await tester.fling(
        find.byKey(const ValueKey('swift-sheet-hero-demo-content')),
        const Offset(0, 500),
        5000,
      );
      await tester.pump();

      final sheetRoute = routeObserver.lastPushed! as SwiftSheetRoute<void>;
      expect(sheetRoute.isCurrent, isFalse);
      expect(sheetRoute.animation!.status, AnimationStatus.reverse);
      expect(
        find
            .byKey(const ValueKey('swift-sheet-hero-demo-content'))
            .hitTestable(),
        findsNothing,
      );

      final backgroundGesture = await tester.startGesture(
        const Offset(30, 700),
      );
      await backgroundGesture.moveBy(const Offset(0, -70));
      await tester.pump(const Duration(milliseconds: 50));

      expect(backgroundController.offset, greaterThan(0));
      expect(
        find.byKey(const ValueKey('swift-sheet-hero-flight')),
        findsOneWidget,
      );

      await backgroundGesture.up();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('swift-sheet-hero-demo-content')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('swift-sheet-hero-flight')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

class _LastPushedRouteObserver extends NavigatorObserver {
  Route<dynamic>? lastPushed;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    lastPushed = route;
  }
}
