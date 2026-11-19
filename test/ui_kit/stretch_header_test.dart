import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftuikit/swiftuikit.dart';

import 'test_app.dart';

void main() {
  Widget page(
    ValueChanged<bool> onExpanded, {
    StretchHeaderMode mode = StretchHeaderMode.snap,
    VoidCallback? onOverpull,
    bool overpullOnRelease = true,
  }) => testApp(
    ChromeScaffold(
      topBar: const ChromeBar(child: SizedBox(height: 52)),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          StretchHeader(
            mode: mode,
            collapsedHeight: 200,
            expandedHeight: 400,
            compactHeight: 80,
            haptics: false,
            onExpandedChanged: onExpanded,
            onOverpull: onOverpull,
            overpullOnRelease: overpullOnRelease,
            builder: (context, info) => ColoredBox(
              color: Colors.blue,
              child: Text(
                't=${info.t.toStringAsFixed(2)} c=${info.collapse.toStringAsFixed(2)}',
              ),
            ),
          ),
          SliverList.builder(
            itemCount: 30,
            itemBuilder: (c, i) => SizedBox(height: 50, child: Text('Row $i')),
          ),
        ],
      ),
    ),
  );

  testWidgets(
    'a long pull and a release snaps the header open and displaces the list',
    (tester) async {
      setPhoneSize(tester);
      final events = <bool>[];
      await tester.pumpWidget(page(events.add));
      await tester.pump();
      final before = tester.getTopLeft(find.text('Row 0')).dy;

      final g = await tester.startGesture(const Offset(200, 300));
      for (var i = 0; i < 12; i++) {
        await g.moveBy(const Offset(0, 25));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await tester.pumpAndSettle();

      expect(events, [true]);
      final after = tester.getTopLeft(find.text('Row 0')).dy;
      expect(
        after - before,
        closeTo(200, 1),
        reason: 'the open header is 200 pt taller and the list sits below it',
      );
    },
  );

  testWidgets('a short pull springs back', (tester) async {
    setPhoneSize(tester);
    final events = <bool>[];
    await tester.pumpWidget(page(events.add));
    await tester.pump();
    final before = tester.getTopLeft(find.text('Row 0')).dy;

    final g = await tester.startGesture(const Offset(200, 300));
    await g.moveBy(const Offset(0, 40));
    await tester.pump(const Duration(milliseconds: 16));
    await g.up();
    await tester.pumpAndSettle();

    expect(events, isEmpty);
    expect(tester.getTopLeft(find.text('Row 0')).dy, closeTo(before, 1));
  });

  testWidgets('follow mode never snaps open', (tester) async {
    setPhoneSize(tester);
    final events = <bool>[];
    await tester.pumpWidget(page(events.add, mode: StretchHeaderMode.follow));
    await tester.pump();
    final g = await tester.startGesture(const Offset(200, 300));
    for (var i = 0; i < 12; i++) {
      await g.moveBy(const Offset(0, 25));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await tester.pumpAndSettle();
    expect(events, isEmpty);
  });

  testWidgets(
    'scrolling the list up shrinks the pinned header to its compact height',
    (tester) async {
      setPhoneSize(tester);
      await tester.pumpWidget(page((_) {}));
      await tester.pump();
      expect(find.textContaining('c=0.00'), findsOneWidget);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();

      // fully collapsed: the header stays at the top with the compact height and the rows scrolled under it
      expect(find.textContaining('c=1.00'), findsOneWidget);
      final box = tester.getRect(
        find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color == Colors.blue,
        ),
      );
      expect(box.top, closeTo(0, 0.5));
      expect(box.height, closeTo(80, 0.5));
    },
  );

  testWidgets(
    "the scaffold's top fade is off from the first frame, before any scroll",
    (tester) async {
      setPhoneSize(tester);
      await tester.pumpWidget(page((_) {}));
      await tester
          .pump(); // the frame after the first one: the header has synced
      final ctx = tester.element(find.byType(StretchHeader));
      expect(ChromeScaffoldScope.controllerOf(ctx).topEdgeFade.value, 0.0);
    },
  );

  // collapsed 200, compact 80: the header collapses over 120 pt of scroll
  testWidgets(
    'a scroll that rests in the middle of the collapse settles to the nearer end',
    (tester) async {
      setPhoneSize(tester);
      await tester.pumpWidget(page((_) {}));
      await tester.pump();

      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -40),
      ); // < half of 120
      await tester.pumpAndSettle();
      expect(
        find.textContaining('c=0.00'),
        findsOneWidget,
        reason: 'less than half: back to the full header',
      );

      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -90),
      ); // > half of 120
      await tester.pumpAndSettle();
      expect(
        find.textContaining('c=1.00'),
        findsOneWidget,
        reason: 'more than half: on to the compact header',
      );
    },
  );

  Future<void> pullAndRelease(WidgetTester tester, double dy) async {
    final g = await tester.startGesture(const Offset(200, 300));
    for (var i = 0; i < (dy / 25).ceil(); i++) {
      await g.moveBy(const Offset(0, 25));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await tester.pumpAndSettle();
  }

  testWidgets(
    'second stage: a new pull on the open header, past overpullDistance, calls onOverpull once',
    (tester) async {
      setPhoneSize(tester);
      var calls = 0;
      await tester.pumpWidget(page((_) {}, onOverpull: () => calls++));
      await tester.pump();

      await pullAndRelease(tester, 300); // opens the header (the first stage)
      expect(
        calls,
        0,
        reason: 'the pull that opened the header does not count',
      );

      await pullAndRelease(tester, 40); // a short second pull: not enough
      expect(calls, 0);

      await pullAndRelease(tester, 700); // a long second pull
      expect(calls, 1);
    },
  );

  testWidgets(
    'overpull fires as soon as the offset is reached, finger still down',
    (tester) async {
      setPhoneSize(tester);
      var calls = 0;
      await tester.pumpWidget(
        page((_) {}, onOverpull: () => calls++, overpullOnRelease: false),
      );
      await tester.pump();
      await pullAndRelease(tester, 300);
      expect(calls, 0);

      final g = await tester.startGesture(const Offset(200, 300));
      for (var i = 0; i < 40; i++) {
        await g.moveBy(const Offset(0, 25));
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(calls, 1, reason: 'fired before the finger was lifted, once');
      await g.up();
      await tester.pumpAndSettle();
      expect(calls, 1);
    },
  );

  testWidgets(
    'one continuous pull: opens, then fires the second stage without lifting',
    (tester) async {
      setPhoneSize(tester);
      var calls = 0;
      await tester.pumpWidget(
        page((_) {}, onOverpull: () => calls++, overpullOnRelease: false),
      );
      await tester.pump();
      final g = await tester.startGesture(const Offset(200, 300));
      for (var i = 0; i < 60; i++) {
        await g.moveBy(const Offset(0, 25));
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(calls, 1);
      await g.up();
      await tester.pumpAndSettle();
      expect(calls, 1);
    },
  );

  testWidgets(
    'a gentle fling settles right after the finger leaves, not after the scroll has stopped',
    (tester) async {
      setPhoneSize(tester);
      final offsets = <double>[];
      await tester.pumpWidget(page((_) {}));
      await tester.pump();
      final scroll = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );

      // a slow fling up that would roll for a while and rest inside the 120 pt collapse range
      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, -30),
        180,
      );
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        offsets.add(scroll.position.pixels);
      }
      // within ~0.6 s the position is at one of the ends (the settle was started at the lift)
      final end = offsets.last;
      expect(end == 0 || (end - 120).abs() < 1, true, reason: 'ended at $end');
    },
  );
}
