import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftuikit/swiftuikit.dart';

void main() {
  testWidgets(
    'previous route accepts input while dismissed sheet is still animating',
    (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      var homeTaps = 0;

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: GestureDetector(
            key: const ValueKey('home'),
            behavior: HitTestBehavior.opaque,
            onTap: () => homeTaps += 1,
            child: const SizedBox.expand(),
          ),
        ),
      );

      final route = SwiftSheetRoute<void>(
        transitionDurationOverride: const Duration(milliseconds: 500),
        scrollableBuilder: (context, controller) =>
            const ColoredBox(key: ValueKey('sheet'), color: Colors.white),
      );
      navigatorKey.currentState!.push(route);
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(const Offset(200, 300));
      await gesture.moveBy(const Offset(0, 300));
      await tester.pump(const Duration(milliseconds: 200));
      final sheetYBeforeRelease = tester
          .getTopLeft(find.byKey(const ValueKey('sheet')))
          .dy;
      final dimmingBeforeRelease = tester.widget<FadeTransition>(
        find.byKey(const ValueKey('swift-sheet-background-dimming')),
      );
      final dimmingOpacityBeforeRelease = dimmingBeforeRelease.opacity.value;
      await gesture.up();
      await tester.pump();
      final sheetYAfterRelease = tester
          .getTopLeft(find.byKey(const ValueKey('sheet')))
          .dy;

      expect(sheetYAfterRelease, closeTo(sheetYBeforeRelease, 0.001));
      expect(route.animation!.status, AnimationStatus.reverse);
      expect(navigatorKey.currentState!.userGestureInProgress, isFalse);
      expect(route.isCurrent, isFalse);
      final animationValueAfterRelease = route.animation!.value;
      expect(animationValueAfterRelease, greaterThan(0.0));
      expect(find.byKey(const ValueKey('sheet')).hitTestable(), findsNothing);
      final dimmingAfterRelease = tester.widget<FadeTransition>(
        find.byKey(const ValueKey('swift-sheet-background-dimming')),
      );
      expect(
        dimmingAfterRelease.opacity.value,
        closeTo(dimmingOpacityBeforeRelease, 0.001),
      );

      await tester.tapAt(const Offset(40, 40));
      await tester.pump();

      expect(homeTaps, 1);
      expect(route.animation!.value, greaterThan(0.0));

      await tester.pump(const Duration(milliseconds: 80));
      expect(route.animation!.value, lessThan(animationValueAfterRelease));
      final dimmingDuringDismiss = tester.widget<FadeTransition>(
        find.byKey(const ValueKey('swift-sheet-background-dimming')),
      );
      expect(
        dimmingDuringDismiss.opacity.value,
        lessThan(dimmingOpacityBeforeRelease),
      );
      expect(dimmingDuringDismiss.opacity.value, greaterThan(0.0));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('sheet navigation bar hero is always disabled', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    var heroFlightStarted = false;

    Widget trackedHero(Color color) {
      return Hero(
        tag: 'sheet-hero',
        flightShuttleBuilder:
            (
              flightContext,
              animation,
              direction,
              fromHeroContext,
              toHeroContext,
            ) {
              heroFlightStarted = true;
              return const SizedBox.square(dimension: 80);
            },
        child: ColoredBox(
          color: color,
          child: const SizedBox.square(dimension: 80),
        ),
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(middle: Text('Home')),
          child: Center(child: trackedHero(Colors.red)),
        ),
      ),
    );

    final route = SwiftSheetRoute<void>(
      scrollableBuilder: (context, controller) => CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Sheet title'),
        ),
        child: Center(child: trackedHero(Colors.purple)),
      ),
    );
    navigatorKey.currentState!.push(route);
    await tester.pumpAndSettle();

    final navigationBar = find.widgetWithText(
      CupertinoNavigationBar,
      'Sheet title',
    );
    var heroModes = tester.widgetList<HeroMode>(
      find.ancestor(of: navigationBar, matching: find.byType(HeroMode)),
    );
    expect(heroModes.any((mode) => !mode.enabled), isTrue);
    expect(heroFlightStarted, isFalse);

    final gesture = await tester.startGesture(const Offset(200, 300));
    await gesture.moveBy(const Offset(0, 100));
    await tester.pump();
    heroModes = tester.widgetList<HeroMode>(
      find.ancestor(of: navigationBar, matching: find.byType(HeroMode)),
    );
    expect(heroModes.any((mode) => !mode.enabled), isTrue);
    expect(heroFlightStarted, isFalse);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(heroFlightStarted, isFalse);

    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(heroFlightStarted, isFalse);
  });
}
