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

  testWidgets('sheet supports push, slow interactive, and pop Hero flights', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    var heroFlights = 0;

    Widget trackedHero(Color color) {
      return Hero(
        tag: 'sheet-hero',
        transitionOnUserGestures: true,
        flightShuttleBuilder:
            (
              flightContext,
              animation,
              direction,
              fromHeroContext,
              toHeroContext,
            ) {
              heroFlights += 1;
              return const ColoredBox(
                key: ValueKey('sheet-hero-flight'),
                color: Colors.orange,
                child: SizedBox.square(dimension: 80),
              );
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
          navigationBar: const CupertinoNavigationBar(
            transitionBetweenRoutes: false,
            middle: Text('Home'),
          ),
          child: Center(child: trackedHero(Colors.red)),
        ),
      ),
    );

    final route = SwiftSheetRoute<void>(
      scrollableBuilder: (context, controller) => CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          transitionBetweenRoutes: false,
          middle: Text('Sheet title'),
        ),
        child: Center(child: trackedHero(Colors.purple)),
      ),
    );
    navigatorKey.currentState!.push(route);
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('sheet-hero-flight')), findsOneWidget);
    expect(heroFlights, 1);
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(const Offset(200, 300));
    await gesture.moveBy(const Offset(0, 100));
    await tester.pump();

    expect(route.animation!.value, lessThan(1));
    expect(find.byKey(const ValueKey('sheet-hero-flight')), findsOneWidget);
    expect(heroFlights, 2);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(route.isCurrent, isTrue);
    expect(find.byKey(const ValueKey('sheet-hero-flight')), findsNothing);
    expect(heroFlights, 2);

    navigatorKey.currentState!.pop();
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('sheet-hero-flight')), findsOneWidget);
    expect(heroFlights, 3);
    await tester.pumpAndSettle();

    expect(route.isActive, isFalse);
    expect(find.byKey(const ValueKey('sheet-hero-flight')), findsNothing);
    expect(heroFlights, 3);
  });

  testWidgets('modal sheet does not animate Cupertino navigation bars', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    var nativeSheetScopeFound = false;

    await tester.pumpWidget(
      CupertinoApp(
        navigatorKey: navigatorKey,
        home: const CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            key: ValueKey('regular-page-navigation-bar'),
            middle: Text('Regular page'),
          ),
          child: SizedBox.expand(),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('regular-page-navigation-bar')),
        matching: find.byType(Hero),
      ),
      findsOneWidget,
    );

    final route = SwiftSheetRoute<void>(
      scrollableBuilder: (context, controller) => Builder(
        builder: (context) {
          nativeSheetScopeFound = CupertinoSheetRoute.hasParentSheet(context);
          return const CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              key: ValueKey('sheet-navigation-bar'),
              middle: Text('Modal sheet'),
            ),
            child: SizedBox.expand(),
          );
        },
      ),
    );

    navigatorKey.currentState!.push(route);
    await tester.pump();
    await tester.pump();

    expect(nativeSheetScopeFound, isTrue);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('sheet-navigation-bar')),
        matching: find.byType(Hero),
      ),
      findsNothing,
    );
    expect(find.byType(Hero), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Regular page'), findsOneWidget);
    expect(find.text('Modal sheet'), findsOneWidget);

    navigatorKey.currentState!.pop();
    await tester.pump();
    await tester.pump();

    expect(find.byType(Hero), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();
    expect(route.isActive, isFalse);
  });

  testWidgets(
    'Hero geometry stays attached to the sheet on push pop and drag',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final navigatorKey = GlobalKey<NavigatorState>();

      Widget geometryHero(Key key, Color color) {
        return Hero(
          key: key,
          tag: 'sheet-hero-geometry',
          transitionOnUserGestures: true,
          flightShuttleBuilder:
              (
                flightContext,
                animation,
                direction,
                fromHeroContext,
                toHeroContext,
              ) {
                return const ColoredBox(
                  key: ValueKey('sheet-hero-geometry-flight'),
                  color: Colors.orange,
                  child: SizedBox.square(dimension: 80),
                );
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
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 155,
                  top: 620,
                  child: geometryHero(
                    const ValueKey('sheet-hero-geometry-home'),
                    Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final homeRect = tester.getRect(
        find.byKey(const ValueKey('sheet-hero-geometry-home')),
      );
      final route = SwiftSheetRoute<void>(
        transitionDurationOverride: const Duration(milliseconds: 500),
        scrollableBuilder: (context, controller) => ColoredBox(
          color: Colors.white,
          child: Stack(
            children: [
              Positioned(
                left: 155,
                top: 60,
                child: geometryHero(
                  const ValueKey('sheet-hero-geometry-sheet'),
                  Colors.purple,
                ),
              ),
            ],
          ),
        ),
      );
      navigatorKey.currentState!.push(route);
      await tester.pump();
      await tester.pump();

      var flightRect = tester.getRect(
        find.byKey(const ValueKey('sheet-hero-geometry-flight')),
      );
      expect((flightRect.top - homeRect.top).abs(), lessThan(1));

      await tester.pump(const Duration(milliseconds: 450));
      flightRect = tester.getRect(
        find.byKey(const ValueKey('sheet-hero-geometry-flight')),
      );
      await tester.pumpAndSettle();

      final settledSheetRect = tester.getRect(
        find.byKey(const ValueKey('sheet-hero-geometry-sheet')),
      );
      expect((flightRect.top - settledSheetRect.top).abs(), lessThan(20));

      final gesture = await tester.startGesture(const Offset(200, 400));
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump();

      flightRect = tester.getRect(
        find.byKey(const ValueKey('sheet-hero-geometry-flight')),
      );
      expect((flightRect.top - settledSheetRect.top).abs(), lessThan(20));

      await gesture.up();
      await tester.pumpAndSettle();

      navigatorKey.currentState!.pop();
      await tester.pump();
      await tester.pump();

      flightRect = tester.getRect(
        find.byKey(const ValueKey('sheet-hero-geometry-flight')),
      );
      expect((flightRect.top - settledSheetRect.top).abs(), lessThan(1));

      await tester.pumpAndSettle();
      expect(route.isActive, isFalse);
    },
  );

  testWidgets('rapid Hero drag can interrupt and reverse an active push', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    Widget rapidHero(Color color) {
      return Hero(
        tag: 'rapid-sheet-hero',
        transitionOnUserGestures: true,
        child: ColoredBox(
          color: color,
          child: const SizedBox.square(dimension: 80),
        ),
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: Scaffold(body: Center(child: rapidHero(Colors.red))),
      ),
    );

    SwiftSheetRoute<void> buildRoute() => SwiftSheetRoute<void>(
      transitionDurationOverride: const Duration(milliseconds: 500),
      scrollableBuilder: (context, controller) => ColoredBox(
        color: Colors.white,
        child: Center(child: rapidHero(Colors.purple)),
      ),
    );

    final route = buildRoute();
    navigatorKey.currentState!.push(route);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(route.animation!.status, AnimationStatus.forward);

    final gesture = await tester.startGesture(const Offset(200, 500));
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    await gesture.moveBy(const Offset(0, -20));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 260));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(route.isActive, isFalse);

    final regrabbedRoute = buildRoute();
    navigatorKey.currentState!.push(regrabbedRoute);
    await tester.pumpAndSettle();

    final canceledGesture = await tester.startGesture(const Offset(200, 300));
    await canceledGesture.moveBy(const Offset(0, 100));
    await tester.pump();
    await canceledGesture.up();
    await tester.pump(const Duration(milliseconds: 20));

    expect(regrabbedRoute.animation!.status, AnimationStatus.forward);
    expect(navigatorKey.currentState!.userGestureInProgress, isTrue);

    final regrabbedGesture = await tester.startGesture(const Offset(200, 300));
    await regrabbedGesture.moveBy(const Offset(0, 40));
    await tester.pump();

    expect(navigatorKey.currentState!.userGestureInProgress, isTrue);
    expect(tester.takeException(), isNull);

    await regrabbedGesture.moveBy(const Offset(0, -20));
    await tester.pump();
    await regrabbedGesture.moveBy(const Offset(0, 300));
    await tester.pump();
    await regrabbedGesture.up();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(regrabbedRoute.isActive, isFalse);
  });

  testWidgets('rapid scroll handoffs do not restart the same Hero pop flight', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    Widget stressHero(Color color) => Hero(
      tag: 'stress-sheet-hero',
      transitionOnUserGestures: true,
      child: ColoredBox(
        color: color,
        child: const SizedBox.square(dimension: 80),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: Scaffold(body: Center(child: stressHero(Colors.red))),
      ),
    );

    final route = SwiftSheetRoute<void>(
      transitionDurationOverride: const Duration(milliseconds: 500),
      scrollableBuilder: (context, controller) => Material(
        color: Colors.white,
        child: ListView(
          controller: controller,
          children: [
            const SizedBox(height: 80),
            Center(child: stressHero(Colors.purple)),
            ...List.generate(
              20,
              (index) => SizedBox(height: 80, child: Text('Stress row $index')),
            ),
          ],
        ),
      ),
    );
    navigatorKey.currentState!.push(route);
    await tester.pumpAndSettle();

    for (var index = 0; index < 6; index += 1) {
      final gesture = await tester.startGesture(const Offset(200, 500));
      await gesture.moveBy(const Offset(0, -30));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 40));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 40));
      await tester.pump();
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump();
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 12));

      expect(tester.takeException(), isNull);
      expect(route.isCurrent, isTrue);
    }

    await tester.pumpAndSettle();
    expect(navigatorKey.currentState!.userGestureInProgress, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scrolling sheet content does not leave a Hero overlay behind', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    ScrollController? sheetScrollController;

    Widget scrollingHero(Color color, {Key? key}) {
      return Hero(
        key: key,
        tag: 'scrolling-sheet-hero',
        transitionOnUserGestures: true,
        flightShuttleBuilder:
            (
              flightContext,
              animation,
              direction,
              fromHeroContext,
              toHeroContext,
            ) {
              return const ColoredBox(
                key: ValueKey('scrolling-sheet-hero-flight'),
                color: Colors.orange,
                child: SizedBox.square(dimension: 100),
              );
            },
        child: ColoredBox(
          color: color,
          child: const SizedBox.square(dimension: 100),
        ),
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: Scaffold(body: Center(child: scrollingHero(Colors.red))),
      ),
    );

    final route = SwiftSheetRoute<void>(
      scrollableBuilder: (context, controller) {
        sheetScrollController = controller;
        return Material(
          color: Colors.white,
          child: ListView(
            controller: controller,
            children: [
              const SizedBox(height: 80),
              Center(
                child: scrollingHero(
                  Colors.purple,
                  key: const ValueKey('scrolling-sheet-hero-destination'),
                ),
              ),
              ...List.generate(
                20,
                (index) =>
                    SizedBox(height: 80, child: Text('Sheet row $index')),
              ),
            ],
          ),
        );
      },
    );
    navigatorKey.currentState!.push(route);
    await tester.pumpAndSettle();

    final heroTopBeforeScroll = tester
        .getTopLeft(
          find.byKey(const ValueKey('scrolling-sheet-hero-destination')),
        )
        .dy;
    final gesture = await tester.startGesture(const Offset(200, 500));
    await gesture.moveBy(const Offset(0, -30));
    await tester.pump();
    await gesture.moveBy(const Offset(0, -120));
    await tester.pump();

    expect(sheetScrollController!.offset, greaterThan(0));
    expect(route.animation!.value, 1);
    expect(navigatorKey.currentState!.userGestureInProgress, isFalse);
    expect(
      find.byKey(const ValueKey('scrolling-sheet-hero-flight')),
      findsNothing,
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey('scrolling-sheet-hero-destination')),
          )
          .dy,
      lessThan(heroTopBeforeScroll),
    );

    await gesture.moveBy(const Offset(0, 60));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('scrolling-sheet-hero-flight')),
      findsNothing,
    );

    await gesture.moveBy(const Offset(0, 100));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();

    expect(route.animation!.value, lessThan(1));
    expect(navigatorKey.currentState!.userGestureInProgress, isTrue);
    expect(
      find.byKey(const ValueKey('scrolling-sheet-hero-flight')),
      findsOneWidget,
    );

    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(route.isCurrent, isTrue);
  });

  testWidgets(
    'fast Hero dismiss still allows immediate previous-page scrolling',
    (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      final homeScrollController = ScrollController();
      addTearDown(homeScrollController.dispose);
      var interactiveHeroFlights = 0;

      Widget trackedHero(Color color, {Key? key}) {
        return Hero(
          key: key,
          tag: 'fast-sheet-hero',
          transitionOnUserGestures: true,
          flightShuttleBuilder:
              (
                flightContext,
                animation,
                direction,
                fromHeroContext,
                toHeroContext,
              ) {
                interactiveHeroFlights += 1;
                return const ColoredBox(
                  key: ValueKey('fast-sheet-hero-flight'),
                  color: Colors.orange,
                  child: SizedBox.square(dimension: 72),
                );
              },
          child: ColoredBox(
            color: color,
            child: const SizedBox.square(dimension: 72),
          ),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: Scaffold(
            body: ListView(
              key: const ValueKey('sheet-hero-background-list'),
              controller: homeScrollController,
              children: [
                const SizedBox(height: 80),
                Center(
                  child: trackedHero(
                    Colors.red,
                    key: const ValueKey('sheet-hero-background-target'),
                  ),
                ),
                ...List.generate(
                  20,
                  (index) => SizedBox(
                    height: 80,
                    child: Text('Background row $index'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final route = SwiftSheetRoute<void>(
        transitionDurationOverride: const Duration(milliseconds: 500),
        scrollableBuilder: (context, controller) => ColoredBox(
          color: Colors.white,
          child: Align(
            alignment: const Alignment(0, -0.45),
            child: trackedHero(Colors.purple),
          ),
        ),
      );
      navigatorKey.currentState!.push(route);
      await tester.pumpAndSettle();
      interactiveHeroFlights = 0;

      final gesture = await tester.startGesture(const Offset(200, 220));
      await gesture.moveBy(const Offset(0, 340));
      await tester.pump();

      expect(find.byKey(const ValueKey('fast-sheet-hero-flight')), findsOne);
      expect(interactiveHeroFlights, 1);

      await gesture.up();
      await tester.pump();

      expect(route.animation!.status, AnimationStatus.reverse);
      expect(navigatorKey.currentState!.userGestureInProgress, isFalse);
      expect(route.isCurrent, isFalse);
      expect(route.animation!.value, greaterThan(0));

      final heroYBeforeScroll = tester
          .getTopLeft(
            find.byKey(const ValueKey('sheet-hero-background-target')),
          )
          .dy;
      final scrollGesture = await tester.startGesture(const Offset(200, 120));
      await scrollGesture.moveBy(const Offset(0, -70));
      await tester.pump();

      expect(homeScrollController.offset, greaterThan(0));
      expect(route.animation!.value, greaterThan(0));
      expect(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('sheet-hero-background-target')),
            )
            .dy,
        lessThan(heroYBeforeScroll),
      );
      expect(find.byKey(const ValueKey('fast-sheet-hero-flight')), findsOne);
      expect(interactiveHeroFlights, 1);

      await scrollGesture.up();
      await tester.pumpAndSettle();

      expect(route.isActive, isFalse);
      expect(
        find.byKey(const ValueKey('fast-sheet-hero-flight')),
        findsNothing,
      );
      expect(interactiveHeroFlights, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
