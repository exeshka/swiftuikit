import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftuikit/swiftuikit.dart';

import 'test_app.dart';

Widget _app() => testApp(
  SwiftUiDrawer(
    menu: const Text('menu'),
    body: Builder(
      builder: (context) => Center(
        child: TextButton(
          key: const Key('toggle'),
          onPressed: () => SwiftUiDrawer.of(context).toggle(),
          child: const Text('page'),
        ),
      ),
    ),
  ),
);

double _pageLeft(WidgetTester tester) =>
    tester.getTopLeft(find.byKey(const Key('toggle'))).dx;

void main() {
  testWidgets('the area behind the page has the menu colour, not black', (tester) async {
    setPhoneSize(tester);
    const white = Color(0xFFFFFFFF);
    await tester.pumpWidget(
      testApp(
        const SwiftUiDrawer(menu: Text('menu'), body: SizedBox.expand(), menuBackground: white),
      ),
    );
    final colored = tester.widgetList<ColoredBox>(
      find.descendant(of: find.byType(SwiftUiDrawer), matching: find.byType(ColoredBox)),
    );
    expect(colored.any((c) => c.color == white), isTrue);
    await tester.pumpWidget(testApp(const SwiftUiDrawer(menu: Text('menu'), body: SizedBox.expand())));
    final fallback = tester.widgetList<ColoredBox>(
      find.descendant(of: find.byType(SwiftUiDrawer), matching: find.byType(ColoredBox)),
    );
    expect(fallback.any((c) => c.color == const Color(0xFF000000)), isTrue, reason: 'black by default, as before');
  });

  drawerGestureTests();
  drawerAfterCloseTests();
  testWidgets('closed: the menu is not painted, the page is in place', (
    tester,
  ) async {
    setPhoneSize(tester);
    await tester.pumpWidget(_app());
    expect(find.text('menu'), findsNothing); // offstage
    expect(find.text('page'), findsOneWidget);
  });

  testWidgets('a button of the page opens and closes it', (tester) async {
    setPhoneSize(tester);
    await tester.pumpWidget(_app());
    final closedLeft = _pageLeft(tester);
    await tester.tap(find.byKey(const Key('toggle')));
    await tester.pumpAndSettle();
    expect(find.text('menu'), findsOneWidget);
    expect(_pageLeft(tester), closeTo(closedLeft + 402 * 0.8, 0.5));
    // a tap on the page closes it
    await tester.tapAt(const Offset(380, 400));
    await tester.pumpAndSettle();
    expect(_pageLeft(tester), closeTo(closedLeft, 0.5));
  });

  testWidgets('a drag from the left edge follows the finger and opens', (
    tester,
  ) async {
    setPhoneSize(tester);
    await tester.pumpWidget(_app());
    await tester.dragFrom(const Offset(5, 400), const Offset(260, 0));
    await tester.pumpAndSettle();
    expect(find.text('menu'), findsOneWidget);
  });

  testWidgets('a slow drag from the middle of a closed page does nothing', (
    tester,
  ) async {
    setPhoneSize(tester);
    await tester.pumpWidget(_app());
    final left = _pageLeft(tester);
    await tester.dragFrom(const Offset(200, 400), const Offset(120, 0));
    await tester.pumpAndSettle();
    expect(_pageLeft(tester), closeTo(left, 0.5));
  });
}

Widget _listApp() => testApp(
  SwiftUiDrawer(
    menu: const Text('menu'),
    body: ListView(key: const Key('list'), children: rows(60)),
  ),
);

double _scrolled(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;

void drawerGestureTests() {
  testWidgets(
    'a vertical scroll with a sideways drift still scrolls the list',
    (tester) async {
      setPhoneSize(tester);
      await tester.pumpWidget(_listApp());
      final before = tester.getTopLeft(find.byKey(const Key('list'))).dx;
      // a real finger moves in small steps: it drifts sideways past the touch slop first, then goes up. The drawer must not
      // take this from the list.
      final gesture = await tester.startGesture(const Offset(200, 600));
      await gesture.moveBy(const Offset(22, -4));
      await tester.pump();
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(0, -30));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(_scrolled(tester), greaterThan(100));
      expect(
        tester.getTopLeft(find.byKey(const Key('list'))).dx,
        closeTo(before, 0.5),
      );
      expect(find.text('menu'), findsNothing); // never opened
    },
  );

  testWidgets('a quick horizontal flick from the middle opens it', (
    tester,
  ) async {
    setPhoneSize(tester);
    await tester.pumpWidget(_listApp());
    await tester.fling(
      find.byKey(const Key('list')),
      const Offset(220, 0),
      1800,
    );
    await tester.pumpAndSettle();
    expect(find.text('menu'), findsOneWidget);
    expect(_scrolled(tester), 0);
  });

  testWidgets('a quick but diagonal flick does not open it', (tester) async {
    setPhoneSize(tester);
    await tester.pumpWidget(_listApp());
    await tester.fling(
      find.byKey(const Key('list')),
      const Offset(200, -200),
      1800,
    );
    await tester.pumpAndSettle();
    expect(find.text('menu'), findsNothing);
  });

  testWidgets('open: a drag to the left closes it', (tester) async {
    setPhoneSize(tester);
    await tester.pumpWidget(_listApp());
    tester.state<SwiftUiDrawerState>(find.byType(SwiftUiDrawer)).open();
    await tester.pumpAndSettle();
    await tester.dragFrom(const Offset(380, 400), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(
      tester.state<SwiftUiDrawerState>(find.byType(SwiftUiDrawer)).isOpen,
      isFalse,
    );
  });
}

void drawerAfterCloseTests() {
  testWidgets(
    'right after it closes the page scrolls again and nothing re-opens it',
    (tester) async {
      setPhoneSize(tester);
      await tester.pumpWidget(_listApp());
      final drawer = tester.state<SwiftUiDrawerState>(
        find.byType(SwiftUiDrawer),
      );
      drawer.open();
      await tester.pumpAndSettle();
      drawer.close();
      await tester.pumpAndSettle();
      // the spring stops within its tolerance of the end: the page must be exactly at rest, not 0.0008 from it
      expect(drawer.progress, 0);

      // a vertical scroll with a sideways drift: the list scrolls, the drawer stays shut
      final gesture = await tester.startGesture(const Offset(200, 600));
      await gesture.moveBy(const Offset(22, -4));
      await tester.pump();
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(0, -30));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(_scrolled(tester), greaterThan(100));
      expect(drawer.progress, 0);
    },
  );

  testWidgets('a tap closes it and the page takes touches at once after', (
    tester,
  ) async {
    setPhoneSize(tester);
    await tester.pumpWidget(_listApp());
    final drawer = tester.state<SwiftUiDrawerState>(find.byType(SwiftUiDrawer));
    drawer.open();
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(390, 400)); // the page: closes the menu
    await tester.pumpAndSettle();
    expect(drawer.progress, 0);
    await tester.drag(find.byKey(const Key('list')), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(_scrolled(tester), greaterThan(100));
  });
}
