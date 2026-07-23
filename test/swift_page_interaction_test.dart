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
