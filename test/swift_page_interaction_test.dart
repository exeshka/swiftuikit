import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftuikit/swiftuikit.dart';

void main() {
  testWidgets(
    'dismiss animation keeps both routes input locked until it settles',
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

      final route = SwiftPageRoute<void>(
        settings: const RouteSettings(name: 'test-page'),
        customTransitionDuration: const Duration(milliseconds: 500),
        child: const ColoredBox(key: ValueKey('page'), color: Colors.white),
      );
      navigatorKey.currentState!.push(route);
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(const Offset(1, 400));
      await gesture.moveBy(const Offset(400, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(route.animation!.status, AnimationStatus.reverse);
      expect(navigatorKey.currentState!.userGestureInProgress, isTrue);
      expect(route.isCurrent, isFalse);
      final animationValueAfterRelease = route.animation!.value;
      expect(animationValueAfterRelease, greaterThan(0.0));
      expect(find.byKey(const ValueKey('page')).hitTestable(), findsNothing);

      await tester.tapAt(const Offset(20, 400));
      await tester.pump();

      expect(homeTaps, 0);
      expect(navigatorKey.currentState!.userGestureInProgress, isTrue);
      expect(route.animation!.value, greaterThan(0.0));

      await tester.pump(const Duration(milliseconds: 80));
      expect(route.animation!.value, lessThan(animationValueAfterRelease));
      await tester.pumpAndSettle();

      expect(navigatorKey.currentState!.userGestureInProgress, isFalse);
      await tester.tapAt(const Offset(20, 400));
      await tester.pump();
      expect(homeTaps, 1);
    },
  );

  testWidgets(
    'pages API does not reset the page position after swipe release',
    (tester) async {
      final homeTaps = ValueNotifier(0);
      await tester.pumpWidget(_PagesHarness(homeTaps: homeTaps));
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(const Offset(1, 400));
      await gesture.moveBy(const Offset(400, 0));
      await tester.pump(const Duration(milliseconds: 200));
      final pageXBeforeRelease = tester
          .getTopLeft(find.byKey(const ValueKey('pages-api-page')))
          .dx;
      final homeXBeforeRelease = tester
          .getTopLeft(find.byKey(const ValueKey('pages-api-home')))
          .dx;

      await gesture.up();
      await tester.pump();

      final pageXAfterRelease = tester
          .getTopLeft(find.byKey(const ValueKey('pages-api-page')))
          .dx;
      final homeXAfterRelease = tester
          .getTopLeft(find.byKey(const ValueKey('pages-api-home')))
          .dx;
      expect(pageXAfterRelease, closeTo(pageXBeforeRelease, 0.001));
      expect(homeXAfterRelease, closeTo(homeXBeforeRelease, 0.001));

      await tester.pump(const Duration(milliseconds: 50));
      final pageXDuringDismiss = tester
          .getTopLeft(find.byKey(const ValueKey('pages-api-page')))
          .dx;
      final homeXDuringDismiss = tester
          .getTopLeft(find.byKey(const ValueKey('pages-api-home')))
          .dx;
      expect(pageXDuringDismiss, greaterThan(pageXAfterRelease));
      expect(homeXDuringDismiss, greaterThan(homeXAfterRelease));

      expect(homeTaps.value, 0);
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(20, 400));
      await tester.pump();
      expect(homeTaps.value, 1);
    },
  );

  testWidgets('short cancelled swipe releases its lock after a short settle', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const ColoredBox(color: Colors.black),
      ),
    );

    final route = SwiftPageRoute<void>(
      settings: const RouteSettings(name: 'quick-cancel-page'),
      customTransitionDuration: const Duration(milliseconds: 400),
      child: const ColoredBox(color: Colors.white),
    );
    navigatorKey.currentState!.push(route);
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(const Offset(1, 300));
    await gesture.moveBy(const Offset(80, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(route.animation!.status, AnimationStatus.forward);
    expect(navigatorKey.currentState!.userGestureInProgress, isTrue);

    await tester.pump(const Duration(milliseconds: 60));

    expect(route.animation!.value, 1);
    expect(navigatorKey.currentState!.userGestureInProgress, isFalse);
    expect(route.popGestureEnabled, isTrue);
  });

  testWidgets('near-complete pop has no fixed post-gesture delay', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    var homeTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => homeTaps += 1,
          child: const SizedBox.expand(),
        ),
      ),
    );

    final route = SwiftPageRoute<void>(
      settings: const RouteSettings(name: 'quick-pop-page'),
      customTransitionDuration: const Duration(milliseconds: 400),
      child: const ColoredBox(color: Colors.white),
    );
    navigatorKey.currentState!.push(route);
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(const Offset(1, 300));
    await gesture.moveBy(const Offset(720, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(navigatorKey.currentState!.userGestureInProgress, isTrue);

    await tester.pump(const Duration(milliseconds: 60));

    expect(route.isActive, isFalse);
    expect(navigatorKey.currentState!.userGestureInProgress, isFalse);
    await tester.tapAt(const Offset(400, 300));
    await tester.pump();
    expect(homeTaps, 1);
  });

  testWidgets('previous and current pages keep the same animated corners', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    const previousKey = ValueKey('rounded-previous-page');
    const currentKey = ValueKey('rounded-current-page');
    const transitionRadius = BorderRadius.all(Radius.circular(36));

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const ColoredBox(color: Colors.black),
      ),
    );

    navigatorKey.currentState!.push(
      SwiftPageRoute<void>(
        settings: const RouteSettings(name: 'rounded-previous'),
        radius: 12,
        child: const ColoredBox(key: previousKey, color: Colors.blue),
      ),
    );
    await tester.pumpAndSettle();

    final currentRoute = SwiftPageRoute<void>(
      settings: const RouteSettings(name: 'rounded-current'),
      radius: 36,
      child: const ColoredBox(key: currentKey, color: Colors.white),
    );
    navigatorKey.currentState!.push(currentRoute);
    await tester.pumpAndSettle();

    BorderRadiusGeometry pageRadius(ValueKey<String> key) {
      final clips = tester.widgetList<ClipRRect>(
        find.ancestor(of: find.byKey(key), matching: find.byType(ClipRRect)),
      );
      return clips.single.borderRadius;
    }

    final gesture = await tester.startGesture(const Offset(1, 300));
    await gesture.moveBy(const Offset(500, 0));
    await tester.pump();

    expect(pageRadius(previousKey), transitionRadius);
    expect(pageRadius(currentKey), transitionRadius);

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 20));

    expect(currentRoute.animation!.status, AnimationStatus.reverse);
    expect(pageRadius(previousKey), transitionRadius);
    expect(pageRadius(currentKey), transitionRadius);

    await tester.pumpAndSettle();
  });

  testWidgets(
    'interactive pop drives opted-in hero without a second transition',
    (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      var homeTaps = 0;
      var heroFlights = 0;

      Widget trackedHero(Color color) {
        return Hero(
          tag: 'page-hero',
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
                return const SizedBox.square(dimension: 80);
              },
          child: ColoredBox(
            color: color,
            child: const SizedBox.square(dimension: 80),
          ),
        );
      }

      await tester.pumpWidget(
        MaterialApp(navigatorKey: navigatorKey, home: const SizedBox.expand()),
      );

      final homeRoute = SwiftPageRoute<void>(
        settings: const RouteSettings(name: 'hero-home'),
        child: GestureDetector(
          key: const ValueKey('hero-home-page'),
          behavior: HitTestBehavior.opaque,
          onTap: () => homeTaps += 1,
          child: CupertinoPageScaffold(
            navigationBar: const CupertinoNavigationBar(
              middle: Text('Hero home'),
            ),
            child: Center(child: trackedHero(Colors.red)),
          ),
        ),
      );
      navigatorKey.currentState!.push(homeRoute);
      await tester.pumpAndSettle();

      final detailRoute = SwiftPageRoute<void>(
        settings: const RouteSettings(name: 'hero-detail'),
        child: CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Text('Hero detail'),
          ),
          child: Center(child: trackedHero(Colors.purple)),
        ),
      );
      navigatorKey.currentState!.push(detailRoute);
      await tester.pumpAndSettle();
      expect(heroFlights, greaterThan(0));
      heroFlights = 0;

      final gesture = await tester.startGesture(const Offset(1, 400));
      await gesture.moveBy(const Offset(120, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(homeTaps, 0);
      expect(heroFlights, 1);
      expect(navigatorKey.currentState!.userGestureInProgress, isTrue);

      await tester.pumpAndSettle();
      expect(heroFlights, 1);
      expect(navigatorKey.currentState!.userGestureInProgress, isFalse);
      expect(detailRoute.isCurrent, isTrue);
    },
  );

  testWidgets('a second fast swipe cannot interrupt a settling page', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const ColoredBox(color: Colors.black),
      ),
    );

    final route = SwiftPageRoute<void>(
      settings: const RouteSettings(name: 'fast-swipe-page'),
      child: const ColoredBox(color: Colors.white),
    );
    navigatorKey.currentState!.push(route);
    await tester.pumpAndSettle();

    final firstGesture = await tester.startGesture(const Offset(1, 400));
    await firstGesture.moveBy(const Offset(80, 0));
    await tester.pump();
    await firstGesture.up();
    await tester.pump();

    expect(route.animation!.status, AnimationStatus.forward);
    expect(navigatorKey.currentState!.userGestureInProgress, isTrue);
    final valueBeforeSecondGesture = route.animation!.value;

    final secondGesture = await tester.startGesture(const Offset(1, 400));
    await secondGesture.moveBy(const Offset(120, 0));
    await tester.pump(const Duration(milliseconds: 16));
    await secondGesture.up();

    expect(route.animation!.value, greaterThan(valueBeforeSecondGesture));
    expect(route.animation!.status, AnimationStatus.forward);
    await tester.pumpAndSettle();
    expect(route.animation!.value, 1.0);
    expect(route.isCurrent, isTrue);
  });

  testWidgets('content swipe can pop from the center of an unclaimed area', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const ColoredBox(color: Colors.black),
      ),
    );

    final route = SwiftPageRoute<void>(
      settings: const RouteSettings(name: 'center-swipe-page'),
      child: const ColoredBox(color: Colors.white),
    );
    navigatorKey.currentState!.push(route);
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(const Offset(400, 400));
    await gesture.moveBy(const Offset(500, 0));
    await tester.pump();

    expect(route.animation!.value, lessThan(0.5));
    expect(navigatorKey.currentState!.userGestureInProgress, isTrue);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(route.isActive, isFalse);
  });

  testWidgets('horizontal page view keeps its drag and edge swipe pops route', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final pageController = PageController(initialPage: 1);
    addTearDown(pageController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const ColoredBox(color: Colors.black),
      ),
    );

    final route = SwiftPageRoute<void>(
      settings: const RouteSettings(name: 'horizontal-page'),
      child: PageView(
        key: const ValueKey('horizontal-page-view'),
        controller: pageController,
        children: const [
          ColoredBox(color: Colors.red),
          ColoredBox(color: Colors.green),
          ColoredBox(color: Colors.blue),
        ],
      ),
    );
    navigatorKey.currentState!.push(route);
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('horizontal-page-view')),
      const Offset(500, 0),
    );
    await tester.pumpAndSettle();

    expect(pageController.page, closeTo(0.0, 0.001));
    expect(route.animation!.value, 1.0);
    expect(route.isCurrent, isTrue);
    expect(route.popGestureEnabled, isTrue);

    final edgeGesture = await tester.startGesture(const Offset(1, 400));
    await edgeGesture.moveBy(const Offset(500, 0));
    await tester.pump();
    expect(route.animation!.value, lessThan(0.5));
    await edgeGesture.up();
    await tester.pumpAndSettle();

    expect(route.isActive, isFalse);
  });

  testWidgets('slider drag is not captured by the page swipe recognizer', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final sliderValue = ValueNotifier<double>(0.25);
    addTearDown(sliderValue.dispose);

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const ColoredBox(color: Colors.black),
      ),
    );

    final route = SwiftPageRoute<void>(
      settings: const RouteSettings(name: 'slider-page'),
      child: Material(
        child: Center(
          child: ValueListenableBuilder<double>(
            valueListenable: sliderValue,
            builder: (context, value, child) => Slider(
              key: const ValueKey('page-slider'),
              value: value,
              onChanged: (nextValue) => sliderValue.value = nextValue,
            ),
          ),
        ),
      ),
    );
    navigatorKey.currentState!.push(route);
    await tester.pumpAndSettle();

    final valueBeforeDrag = sliderValue.value;
    await tester.drag(
      find.byKey(const ValueKey('page-slider')),
      const Offset(180, 0),
    );
    await tester.pumpAndSettle();

    expect(sliderValue.value, greaterThan(valueBeforeDrag));
    expect(route.animation!.value, 1.0);
    expect(route.isCurrent, isTrue);
  });

  testWidgets('custom horizontal drag control keeps its gesture', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final dragDistance = ValueNotifier<double>(0);
    addTearDown(dragDistance.dispose);

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const ColoredBox(color: Colors.black),
      ),
    );

    final route = SwiftPageRoute<void>(
      settings: const RouteSettings(name: 'drag-control-page'),
      child: Material(
        child: Center(
          child: GestureDetector(
            key: const ValueKey('horizontal-drag-control'),
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (details) {
              dragDistance.value += details.primaryDelta ?? 0;
            },
            child: const SizedBox(width: 400, height: 80),
          ),
        ),
      ),
    );
    navigatorKey.currentState!.push(route);
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('horizontal-drag-control')),
      const Offset(180, 0),
    );
    await tester.pumpAndSettle();

    expect(dragDistance.value, greaterThan(0));
    expect(route.animation!.value, 1.0);
    expect(route.isCurrent, isTrue);
  });
}

class _PagesHarness extends StatefulWidget {
  const _PagesHarness({required this.homeTaps});

  final ValueNotifier<int> homeTaps;

  @override
  State<_PagesHarness> createState() => _PagesHarnessState();
}

class _PagesHarnessState extends State<_PagesHarness> {
  var _showPage = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Navigator(
        pages: [
          SwiftPage<void>(
            key: const ValueKey('pages-api-home-route'),
            child: GestureDetector(
              key: const ValueKey('pages-api-home'),
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.homeTaps.value += 1,
              child: const SizedBox.expand(),
            ),
          ),
          if (_showPage)
            const SwiftPage<void>(
              key: ValueKey('pages-api-route'),
              child: ColoredBox(
                key: ValueKey('pages-api-page'),
                color: Colors.white,
              ),
            ),
        ],
        onDidRemovePage: (page) {
          if (_showPage) {
            setState(() => _showPage = false);
          }
        },
      ),
    );
  }
}
