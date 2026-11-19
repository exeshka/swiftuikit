import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftuikit/swiftuikit.dart';
import 'package:swiftuikit/src/components/glass_selection_toolbar.dart'
    show paginateToolbar;

List<ContextMenuButtonItem> items(List<String> labels, List<String> pressed) =>
    [
      for (final l in labels)
        ContextMenuButtonItem(
          label: l,
          type: ContextMenuButtonType.custom,
          onPressed: () => pressed.add(l),
        ),
    ];

Widget host(
  List<ContextMenuButtonItem> menu, {
  Offset anchor = const Offset(160, 300),
}) => SwiftUiApp(
  warmUp: false,
  theme: SwiftUiThemeData.dark(),
  home: Stack(
    children: [
      GlassSelectionToolbar(
        anchors: TextSelectionToolbarAnchors(primaryAnchor: anchor),
        items: menu,
      ),
    ],
  ),
);

void main() {
  group('pagination', () {
    test('everything fits on one page when there is room', () {
      expect(paginateToolbar([80, 80, 80], 400), [
        [0, 1, 2],
      ]);
    });

    test('a page that has a neighbour reserves room for the arrow', () {
      // 3 x 100 = 303 with separators; with the arrow reserved (40) 343 > 330 so the third moves on
      final pages = paginateToolbar([100, 100, 100, 100], 330);
      expect(pages.length, greaterThan(1));
      for (final p in pages) {
        expect(p, isNotEmpty);
      }
      expect(pages.expand((p) => p).toList(), [
        0,
        1,
        2,
        3,
      ], reason: 'every button on exactly one page, in order');
    });

    test('a button wider than the screen still gets a page of its own', () {
      final pages = paginateToolbar([500, 80], 300);
      expect(pages.expand((p) => p).toList(), [0, 1]);
      expect(pages.first, [0]);
    });

    test('no page is wider than the screen (arrows included)', () {
      final widths = <double>[90, 70, 110, 95, 120, 60, 100];
      for (final max in <double>[240, 300, 360, 500]) {
        final pages = paginateToolbar(widths, max);
        for (var k = 0; k < pages.length; k++) {
          var w = 0.0;
          if (k > 0) w += 40;
          if (k < pages.length - 1) w += 40;
          for (final i in pages[k]) {
            w += widths[i] + 1;
          }
          // a lone oversized button is the only allowed excess
          if (pages[k].length > 1)
            expect(w, lessThanOrEqualTo(max + 1), reason: 'page $k at $max');
        }
      }
    });

    test('nothing, one button', () {
      expect(paginateToolbar([], 300), isEmpty);
      expect(paginateToolbar([50], 300), [
        [0],
      ]);
    });
  });

  testWidgets(
    'a long menu on a narrow screen does not overflow and can be paged through',
    (tester) async {
      tester.view
        ..physicalSize = const Size(320, 640)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final pressed = <String>[];
      final labels = ['Cut', 'Copy', 'Paste', 'Look Up', 'Search Web', 'Share'];
      await tester.pumpWidget(host(items(labels, pressed)));
      await tester.pump();

      expect(tester.takeException(), isNull, reason: 'no RIGHT OVERFLOWED');
      final bar = tester.getRect(find.byType(GlassSelectionToolbar));
      expect(bar.right, lessThanOrEqualTo(320));
      expect(find.bySemanticsLabel('Next'), findsOneWidget);
      expect(find.bySemanticsLabel('Previous'), findsNothing);
      expect(
        find.text('Share'),
        findsNothing,
        reason: 'the last one is on a later page',
      );

      // листаем вперёд до конца, собирая всё, что показывали
      final seen = <String>{};
      for (var guard = 0; guard < 10; guard++) {
        for (final l in labels) {
          if (find.text(l).evaluate().isNotEmpty) seen.add(l);
        }
        final next = find.bySemanticsLabel('Next');
        if (next.evaluate().isEmpty) break;
        await tester.tap(next);
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
      expect(seen, labels.toSet(), reason: 'every item is reachable');
      expect(find.bySemanticsLabel('Previous'), findsOneWidget);

      await tester.tap(find.text('Share'));
      expect(pressed, ['Share']);

      await tester.tap(find.bySemanticsLabel('Previous'));
      await tester.pump();
      expect(find.text('Share'), findsNothing);
    },
  );

  testWidgets('a short menu has no arrows', (tester) async {
    final pressed = <String>[];
    await tester.pumpWidget(host(items(['Paste', 'Select All'], pressed)));
    await tester.pump();
    expect(find.bySemanticsLabel('Next'), findsNothing);
    expect(find.bySemanticsLabel('Previous'), findsNothing);
    await tester.tap(find.text('Paste'));
    expect(pressed, ['Paste']);
  });

  testWidgets(
    'the Live Text entry is left out and an empty menu draws nothing',
    (tester) async {
      await tester.pumpWidget(
        host([
          ContextMenuButtonItem(
            type: ContextMenuButtonType.liveTextInput,
            onPressed: () {},
          ),
          ContextMenuButtonItem(
            type: ContextMenuButtonType.paste,
            onPressed: () {},
          ),
        ]),
      );
      await tester.pump();
      expect(find.text('Paste'), findsOneWidget);

      await tester.pumpWidget(
        host([
          ContextMenuButtonItem(
            type: ContextMenuButtonType.liveTextInput,
            onPressed: () {},
          ),
        ]),
      );
      await tester.pump();
      expect(find.byType(GlassSurface), findsNothing);
    },
  );
}
