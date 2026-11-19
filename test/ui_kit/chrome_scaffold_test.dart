import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftuikit/swiftuikit.dart';

import 'test_app.dart';

Widget _scaffold({
  ChromeController? controller,
  Widget? top,
  Widget? bottom,
  Widget? body,
}) => testApp(
  ChromeScaffold(
    controller: controller,
    topBar: top,
    bottomBar: bottom,
    body: body ?? ListView(children: rows(30)),
  ),
);

void main() {
  testWidgets('a screen without a safe area (a sheet) keeps a little air above the first row', (tester) async {
    setPhoneSize(tester);
    await tester.pumpWidget(
      SwiftUiApp(
        warmUp: false,
        debugShowCheckedModeBanner: false,
        home: MediaQuery(
          data: const MediaQueryData(size: Size(402, 874), devicePixelRatio: 2),
          child: ChromeScaffold(body: ListView(children: rows(5))),
        ),
      ),
    );
    await tester.pump();
    expect(tester.getTopLeft(find.byKey(const ValueKey('row0'))).dy, 12, reason: 'no system inset: the default minimum');
  });

  testWidgets('a screen under the status bar is not pushed down any further', (tester) async {
    setPhoneSize(tester);
    await tester.pumpWidget(_scaffold());
    await tester.pump();
    expect(tester.getTopLeft(find.byKey(const ValueKey('row0'))).dy, 59, reason: 'the system inset wins over the minimum');
  });

  testWidgets('without bars the body only gets the safe area', (tester) async {
    setPhoneSize(tester);
    await tester.pumpWidget(_scaffold());
    await tester.pump();
    expect(tester.getTopLeft(find.byKey(const ValueKey('row0'))).dy, 59);
  });

  testWidgets('a registered top bar pushes the first row below it', (
    tester,
  ) async {
    setPhoneSize(tester);
    await tester.pumpWidget(
      _scaffold(
        top: const ChromeBar(child: SizedBox(height: 52, child: Text('title'))),
      ),
    );
    await tester.pump(); // size reported post-frame
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.getTopLeft(find.byKey(const ValueKey('row0'))).dy, 59 + 52);
    expect(tester.getTopLeft(find.text('title')).dy, 59);
  });

  testWidgets('bottom bar adds bottom padding to the end of the list', (
    tester,
  ) async {
    setPhoneSize(tester);
    await tester.pumpWidget(
      _scaffold(
        bottom: const ChromeBar(
          edge: ChromeEdge.bottom,
          child: SizedBox(height: 48, child: Text('bottom')),
        ),
        body: ListView(children: rows(3)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final insets = ChromeScaffoldScope.insetsOf(
      tester.element(find.text('bottom')),
    );
    // with a bottom bar only 30% of the home-indicator inset stays below it (bottomBarSafeAreaShare)
    expect(insets.bottom, closeTo(34 * 0.3 + 48, 0.01));
    expect(insets.top, 59);
  });

  testWidgets('bar registration animates and removal gives the space back', (
    tester,
  ) async {
    setPhoneSize(tester);
    final c = ChromeController();
    addTearDown(c.dispose);
    final show = ValueNotifier(true);
    addTearDown(show.dispose);
    await tester.pumpWidget(
      testApp(
        ValueListenableBuilder<bool>(
          valueListenable: show,
          builder: (context, v, _) => ChromeScaffold(
            controller: c,
            topBar: v
                ? const ChromeBar(
                    child: SizedBox(height: 60, child: Text('bar')),
                  )
                : null,
            body: ListView(children: rows(30)),
          ),
        ),
      ),
    );
    await tester.pump();
    // registration is animated from 0 (first size) or immediate; either way ends at 60
    await tester.pump(const Duration(milliseconds: 500));
    expect(c.inset(ChromeEdge.top), 60);
    expect(tester.getTopLeft(find.byKey(const ValueKey('row0'))).dy, 59 + 60);

    show.value = false;
    await tester.pump();
    await tester.pump();
    expect(c.inset(ChromeEdge.top), 0);
    expect(tester.getTopLeft(find.byKey(const ValueKey('row0'))).dy, 59);
    expect(c.entries(ChromeEdge.top), isEmpty);
  });

  testWidgets('height change of a bar eases the content padding', (
    tester,
  ) async {
    setPhoneSize(tester);
    final c = ChromeController();
    addTearDown(c.dispose);
    final h = ValueNotifier<double>(50);
    addTearDown(h.dispose);
    await tester.pumpWidget(
      testApp(
        ValueListenableBuilder<double>(
          valueListenable: h,
          builder: (context, v, _) => ChromeScaffold(
            controller: c,
            topBar: ChromeBar(child: SizedBox(height: v)),
            body: ListView(children: rows(30)),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.getTopLeft(find.byKey(const ValueKey('row0'))).dy, 59 + 50);

    h.value = 110;
    await tester.pump(); // layout; size reported post-frame
    await tester.pump(); // animation starts
    await tester.pump(const Duration(milliseconds: 100));
    final mid = tester.getTopLeft(find.byKey(const ValueKey('row0'))).dy;
    expect(mid, inExclusiveRange(59 + 50, 59 + 110));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.getTopLeft(find.byKey(const ValueKey('row0'))).dy, 59 + 110);
  });

  testWidgets('blur zone = safe area + bars + fade extension', (tester) async {
    setPhoneSize(tester);
    await tester.pumpWidget(
      _scaffold(top: const ChromeBar(child: SizedBox(height: 52))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final tokens = SwiftUiTheme.of(tester.element(find.byType(ChromeScaffold)));
    final insets = ChromeScaffoldScope.insetsOf(
      tester.element(find.byType(ListView)),
    );
    expect(insets.topZone, 59 + 52 + tokens.chrome.blurExtra);
    // no bottom bar: only the home-indicator area is blurred, without the fade extension
    expect(insets.bottomZone, 34);
    // the fade (default) is drawn only where there is a bar: none at the bottom
    expect(find.byType(ProgressiveBlur), findsOneWidget);
  });

  testWidgets('scroll offset is published to the controller', (tester) async {
    setPhoneSize(tester);
    final c = ChromeController();
    addTearDown(c.dispose);
    await tester.pumpWidget(_scaffold(controller: c));
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pump();
    expect(c.scrollOffset.value, closeTo(200, 1));
  });

  group('sticky headers', () {
    Widget sticky(ChromeController c) => testApp(
      ChromeScaffold(
        controller: c,
        topBar: const ChromeBar(child: SizedBox(height: 52)),
        body: CustomScrollView(
          slivers: [
            const SliverChromeInset.top(),
            for (var s = 0; s < 4; s++) ...[
              PinnedHeader(
                height: 36,
                child: Text('H$s', key: ValueKey('h$s')),
              ),
              SliverList(delegate: SliverChildListDelegate(rows(5))),
            ],
          ],
        ),
      ),
    );

    testWidgets('pin below the bar, register while stuck, grow the zone', (
      tester,
    ) async {
      setPhoneSize(tester);
      final c = ChromeController();
      addTearDown(c.dispose);
      await tester.pumpWidget(sticky(c));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(c.stuckOverlays(), isEmpty);
      expect(c.inset(ChromeEdge.top), 52);

      // scroll so that H0 and H1 are stuck (each section is 36 + 5*49 = 281)
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -330));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(c.stuckOverlays().length, 2);
      expect(c.inset(ChromeEdge.top), 52 + 36 + 36);
      // padding did not change: stuck headers do not move the content origin
      expect(c.padding(ChromeEdge.top), 52);
      // overlays are painted above the zone at the pin positions
      final tops = [
        for (final h in ['h0', 'h1'])
          tester.getTopLeft(find.byKey(ValueKey(h)).last).dy,
      ];
      expect(tops, [59 + 52, 59 + 52 + 36]);

      // scroll back: they unstick, zone shrinks
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 600));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(c.stuckOverlays(), isEmpty);
      expect(c.inset(ChromeEdge.top), 52);
    });

    testWidgets('sharp copy switches in the same frame the header sticks', (
      tester,
    ) async {
      setPhoneSize(tester);
      final c = ChromeController();
      addTearDown(c.dispose);
      await tester.pumpWidget(sticky(c));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -60));
      await tester.pump(); // exactly one frame after the scroll
      expect(c.stuckOverlays(), isNotEmpty);
      // in-content copy is not painted any more, overlay copy is (by gate)
      final gates = find
          .byType(PaintWhenStuck)
          .evaluate()
          .map((e) => e.renderObject as RenderBox);
      expect(gates, isNotEmpty);
    });

    testWidgets('disposing a stuck header gives its height back', (
      tester,
    ) async {
      setPhoneSize(tester);
      final c = ChromeController();
      addTearDown(c.dispose);
      await tester.pumpWidget(sticky(c));
      await tester.pump();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -330));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(c.inset(ChromeEdge.top), greaterThan(52));
      await tester.pumpWidget(const SizedBox());
      expect(c.inset(ChromeEdge.top), 0);
    });
  });

  testWidgets('PinnedSection: headers replace each other, zone grows by one', (
    tester,
  ) async {
    setPhoneSize(tester);
    final c = ChromeController();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      testApp(
        ChromeScaffold(
          controller: c,
          topBar: const ChromeBar(child: SizedBox(height: 52)),
          body: CustomScrollView(
            slivers: [
              const SliverChromeInset.top(),
              for (var s = 0; s < 4; s++)
                PinnedSection(
                  headerHeight: 36,
                  header: Text('H$s', key: ValueKey('h$s')),
                  slivers: [
                    SliverList(delegate: SliverChildListDelegate(rows(5))),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // scrolled to the end: inside section 1 (section 0 is gone)
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    // only one header's height is added, however many sections were passed
    expect(c.inset(ChromeEdge.top), 52 + 36);
    final pinned = tester.getTopLeft(find.byKey(const ValueKey('h1')).last).dy;
    expect(pinned, 59 + 52);
  });

  testWidgets('PinnedSection: the blur zone leaves with a pushed-out header', (
    tester,
  ) async {
    setPhoneSize(tester);
    final c = ChromeController();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      testApp(
        ChromeScaffold(
          controller: c,
          topBar: const ChromeBar(child: SizedBox(height: 52)),
          body: CustomScrollView(
            slivers: [
              const SliverChromeInset.top(),
              for (var s = 0; s < 6; s++)
                PinnedSection(
                  headerHeight: 36,
                  header: Text('H$s'),
                  slivers: [
                    SliverList(delegate: SliverChildListDelegate(rows(5))),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    // section 0 = 36 + 5 * 49 = 281; at 263 the next header has pushed H0 up by half
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -263));
    // the zone eases in over 380 ms
    for (var i = 0; i < 7; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(c.inset(ChromeEdge.top), closeTo(52 + 18, 1.5));
  });

  testWidgets('LargeTitleHeader: padding fixed, zone collapses with scroll', (
    tester,
  ) async {
    setPhoneSize(tester);
    final c = ChromeController();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      testApp(
        ChromeScaffold(
          controller: c,
          topBar: const LargeTitleHeader(title: 'Title'),
          body: ListView(children: rows(40)),
        ),
      ),
    );
    await tester.pump();
    const bar = 44.0; // native bar row
    const large = 61.0; // native large title block
    expect(c.inset(ChromeEdge.top), bar + large);
    expect(c.padding(ChromeEdge.top), bar + large);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('row0'))).dy,
      59 + bar + large,
    );

    await tester.drag(find.byType(ListView), const Offset(0, -30));
    await tester.pump();
    expect(c.inset(ChromeEdge.top), bar + large - 30);
    expect(
      c.padding(ChromeEdge.top),
      bar + large,
      reason: 'content origin must not jump',
    );

    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pump();
    expect(c.inset(ChromeEdge.top), bar);
    expect(c.minPadding(ChromeEdge.top), bar);
  });
}
