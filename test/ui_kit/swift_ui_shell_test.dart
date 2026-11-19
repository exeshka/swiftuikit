import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftuikit/swiftuikit.dart';

import 'test_app.dart';

class _Bar extends StatefulWidget {
  const _Bar();
  static int created = 0;
  @override
  State<_Bar> createState() => _BarState();
}

class _BarState extends State<_Bar> {
  @override
  void initState() {
    super.initState();
    _Bar.created++;
  }

  @override
  Widget build(BuildContext context) =>
      const SizedBox(key: Key('bar'), height: 58, child: Text('bar'));
}

Widget _app(int page, {double keyboard = 0}) => testApp(
  MediaQuery(
    data: MediaQueryData(
      size: const Size(402, 874),
      devicePixelRatio: 2,
      padding: const EdgeInsets.only(top: 59, bottom: 34),
      viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
      viewInsets: EdgeInsets.only(bottom: keyboard),
    ),
    child: SwiftUiShell(
      bottomBar: const _Bar(),
      body: SwiftUiPageSwitcher(
        index: page,
        transition: SwiftUiSwitchTransition.none,
        children: [
          for (final n in ['one', 'two'])
            SwiftUiScaffold(
              title: n,
              body: ListView(children: rows(40)),
            ),
        ],
      ),
    ),
  ),
);

ChromeInsetsData _insets(WidgetTester tester) =>
    ChromeScaffoldScope.insetsOf(tester.element(find.byType(ListView)));

void main() {
  setUp(() => _Bar.created = 0);

  testWidgets('the pages get the room for the bar, and the bar floats over', (
    tester,
  ) async {
    setPhoneSize(tester);
    await tester.pumpWidget(_app(0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final lift = 34 * 0.3; // the share of the home indicator kept under the bar
    // page padding = the lift + the bar (58); the pages have no home-indicator inset of their own
    expect(_insets(tester).bottom, closeTo(lift + 58, 0.01));
    // the bar sits at the bottom, above the lift
    expect(
      tester.getBottomLeft(find.byKey(const Key('bar'))).dy,
      closeTo(874 - lift, 0.01),
    );
  });

  testWidgets('the bottom blur zone of a page covers the shell bar', (
    tester,
  ) async {
    setPhoneSize(tester);
    await tester.pumpWidget(_app(0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(_insets(tester).bottomZone, greaterThan(58));
    expect(find.byType(ProgressiveBlur), findsWidgets);
  });

  testWidgets('switching the page never rebuilds the bar', (tester) async {
    setPhoneSize(tester);
    await tester.pumpWidget(_app(0));
    await tester.pump();
    await tester.pumpWidget(_app(1));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_app(0));
    await tester.pumpAndSettle();
    expect(_Bar.created, 1);
  });

  testWidgets('the keyboard slides the bar away and gives the room back', (
    tester,
  ) async {
    setPhoneSize(tester);
    await tester.pumpWidget(_app(0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpWidget(_app(0, keyboard: 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    // the pages only keep the keyboard's room
    expect(_insets(tester).bottom, closeTo(300, 0.01));
    expect(
      tester.getTopLeft(find.byKey(const Key('bar'))).dy,
      greaterThanOrEqualTo(874),
    );
  });

  testWidgets('outside a shell nothing changes', (tester) async {
    setPhoneSize(tester);
    await tester.pumpWidget(
      testApp(
        SwiftUiScaffold(
          title: 'x',
          body: ListView(children: rows(40)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(_insets(tester).bottom, 34);
  });
}
