import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftuikit/swiftuikit.dart';

void main() {
  testWidgets(
    'previous route accepts input while dismissed page is still animating',
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

      final gesture = await tester.startGesture(const Offset(20, 400));
      await gesture.moveBy(const Offset(400, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(route.animation!.status, AnimationStatus.reverse);
      expect(navigatorKey.currentState!.userGestureInProgress, isFalse);
      expect(route.isCurrent, isFalse);
      final animationValueAfterRelease = route.animation!.value;
      expect(animationValueAfterRelease, greaterThan(0.0));
      expect(find.byKey(const ValueKey('page')).hitTestable(), findsNothing);

      await tester.tapAt(const Offset(20, 400));
      await tester.pump();

      expect(homeTaps, 1);
      expect(navigatorKey.currentState!.userGestureInProgress, isFalse);
      expect(route.animation!.value, greaterThan(0.0));

      await tester.pump(const Duration(milliseconds: 80));
      expect(route.animation!.value, lessThan(animationValueAfterRelease));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'pages API does not reset the page position after swipe release',
    (tester) async {
      final homeTaps = ValueNotifier(0);
      await tester.pumpWidget(_PagesHarness(homeTaps: homeTaps));
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(const Offset(20, 400));
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

      await tester.tapAt(const Offset(20, 400));
      await tester.pump();
      expect(homeTaps.value, 1);
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'interactive pop does not start hero flight before previous page tap',
    (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      var homeTaps = 0;
      var heroFlights = 0;

      Widget trackedHero(Color color) {
        return Hero(
          tag: 'page-hero',
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

      final gesture = await tester.startGesture(const Offset(20, 400));
      await gesture.moveBy(const Offset(400, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      final detailNavigationBar = find.widgetWithText(
        CupertinoNavigationBar,
        'Hero detail',
      );
      final heroModes = tester.widgetList<HeroMode>(
        find.ancestor(of: detailNavigationBar, matching: find.byType(HeroMode)),
      );
      expect(heroModes.any((mode) => !mode.enabled), isTrue);

      await tester.tap(find.byKey(const ValueKey('hero-home-page')));
      await tester.pump();

      expect(homeTaps, 1);
      expect(heroFlights, 0);
      expect(find.text('Hero home'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(heroFlights, 0);
    },
  );
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
