import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftuikit/swiftuikit.dart';

import 'test_app.dart';

Future<void> open(WidgetTester tester, {GlassSheetController? controller, bool dismissible = true, List<GlassSheetDetent>? detents}) async {
  setPhoneSize(tester);
  await tester.pumpWidget(
    testApp(
      Builder(
        builder: (context) => Center(
          child: GestureDetector(
            key: const ValueKey('open'),
            onTap: () => showGlassSheet<void>(
              context,
              controller: controller,
              dismissible: dismissible,
              liquid: false,
              detents: detents ?? const [GlassSheetDetent.medium, GlassSheetDetent.large],
              child: Column(children: [for (var i = 0; i < 12; i++) SizedBox(height: 50, child: Text('Row $i'))]),
            ),
            child: const SizedBox(width: 100, height: 100, child: Text('open')),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const ValueKey('open')));
  await tester.pumpAndSettle();
}

double sheetTop(WidgetTester tester) => tester.getTopLeft(find.byType(DraggableScrollableSheet)).dy;
Rect sheetRect(WidgetTester tester) => tester.getRect(find.text('Row 0').first);

void main() {
  testWidgets('opens at the medium detent with the content in it', (tester) async {
    await open(tester);
    expect(find.text('Row 0'), findsOneWidget);
    // the content starts in the lower half: the sheet is about half of the screen high
    final y = sheetRect(tester).top;
    expect(y, greaterThan(874 * 0.4));
    expect(y, lessThan(874 * 0.6));
  });

  testWidgets('dragging up grows the sheet to the large detent', (tester) async {
    await open(tester);
    await tester.fling(find.text('Row 0'), const Offset(0, -500), 1500);
    await tester.pumpAndSettle();
    // large: the gap under the status bar (59 + 3), the content right under it
    expect(sheetRect(tester).top, lessThan(120));
  });

  testWidgets('from the large detent a drag down brings the sheet back down', (tester) async {
    final c = GlassSheetController();
    addTearDown(c.dispose);
    await open(tester, controller: c);
    c.expand();
    await tester.pumpAndSettle();
    final large = c.extent;
    await tester.drag(find.text('Row 0'), const Offset(0, 300));
    await tester.pump(const Duration(milliseconds: 50));
    expect(c.extent, lessThan(large), reason: 'the drag moves the sheet while the content is at its top');
    await tester.pumpAndSettle();
  });

  testWidgets('a fling down closes the route', (tester) async {
    await open(tester);
    await tester.fling(find.text('Row 0'), const Offset(0, 600), 2000);
    await tester.pumpAndSettle();
    expect(find.text('Row 0'), findsNothing);
  });

  testWidgets('a tap outside the sheet closes it; a sheet that is not dismissible stays', (tester) async {
    await open(tester);
    await tester.tapAt(const Offset(200, 100));
    await tester.pumpAndSettle();
    expect(find.text('Row 0'), findsNothing);

    await open(tester, dismissible: false);
    await tester.tapAt(const Offset(200, 100));
    await tester.pumpAndSettle();
    expect(find.text('Row 0'), findsOneWidget);
    await tester.fling(find.text('Row 0'), const Offset(0, 600), 2000);
    await tester.pumpAndSettle();
    expect(find.text('Row 0'), findsOneWidget, reason: 'it rests at its smallest detent, it cannot be dragged away');
  });

  testWidgets('the controller moves the sheet between detents and closes it', (tester) async {
    final c = GlassSheetController();
    addTearDown(c.dispose);
    await open(tester, controller: c);
    final medium = c.extent;
    c.expand(); // the animation runs with the frames, do not await it before pumping
    await tester.pumpAndSettle();
    expect(c.extent, greaterThan(medium));
    c.collapse();
    await tester.pumpAndSettle();
    expect(c.extent, closeTo(medium, 0.01));
    c.dismiss();
    await tester.pumpAndSettle();
    expect(find.text('Row 0'), findsNothing);
  });

  testWidgets('custom detents: a fixed height', (tester) async {
    await open(tester, detents: [GlassSheetDetent.height(300), GlassSheetDetent.large]);
    final y = sheetRect(tester).top;
    // 300 pt tall sheet: its content starts about 874 - 300 below the top
    expect(y, closeTo(874 - 300 - 8, 40));
  });

  testWidgets('GlassSheetPresenter: a sheet inside the page, driven by a bool; modal: false leaves the page usable', (tester) async {
    setPhoneSize(tester);
    var open = false;
    var pageTaps = 0;
    late StateSetter set;
    await tester.pumpWidget(
      testApp(
        StatefulBuilder(
          builder: (context, setState) {
            set = setState;
            return GlassSheetPresenter(
              isPresented: open,
              modal: false,
              liquid: false,
              detents: const [GlassSheetDetent.fraction(0.3)],
              onDismissed: () => setState(() => open = false),
              sheetChild: const Text('inside'),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => pageTaps++,
                child: const SizedBox.expand(child: Text('page')),
              ),
            );
          },
        ),
      ),
    );
    expect(find.text('inside'), findsNothing);
    set(() => open = true);
    await tester.pumpAndSettle();
    expect(find.text('inside'), findsOneWidget);
    // a tap on the page above the sheet reaches the page
    await tester.tapAt(const Offset(200, 100));
    expect(pageTaps, 1);
    set(() => open = false);
    await tester.pumpAndSettle();
    expect(find.text('inside'), findsNothing);
  });

  testWidgets('grown out of a control: the control hides while the sheet is open, the sheet starts at it, and it comes back', (tester) async {
    setPhoneSize(tester);
    final origin = GlassSheetOriginController();
    addTearDown(origin.dispose);
    await tester.pumpWidget(
      testApp(
        Builder(
          builder: (context) => Align(
            alignment: Alignment.bottomLeft,
            child: GlassSheetOrigin(
              controller: origin,
              child: GestureDetector(
                key: const ValueKey('open'),
                onTap: () => showGlassSheet<void>(context, origin: origin, liquid: false, child: const SizedBox(height: 900, child: Text('Row 0'))),
                child: const SizedBox(width: 44, height: 44, child: Text('o')),
              ),
            ),
          ),
        ),
      ),
    );
    final from = tester.getRect(find.byKey(const ValueKey('open')));
    await tester.tap(find.byKey(const ValueKey('open')));
    await tester.pump(); // the route is built, the animation at its start
    await tester.pump(const Duration(milliseconds: 16));
    // the card starts on the control: its content is scaled into the control's rectangle
    final start = tester.getRect(find.text('Row 0'));
    expect(start.center.dx, lessThan(150));
    expect(start.center.dy, greaterThan(700));
    await tester.pumpAndSettle();
    expect(origin.hidden, isTrue);
    expect(find.byType(Visibility), findsWidgets);
    // at rest: the sheet is in its place, at the medium detent
    expect(tester.getRect(find.text('Row 0')).top, lessThan(from.top));
    GlassSheet.controllerOf(tester.element(find.text('Row 0'))).dismiss();
    await tester.pumpAndSettle();
    expect(origin.hidden, isFalse);
  });
}
