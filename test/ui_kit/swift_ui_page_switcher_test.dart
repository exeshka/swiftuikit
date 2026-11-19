import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftuikit/swiftuikit.dart';

import 'test_app.dart';

class _Counter extends StatefulWidget {
  const _Counter(this.name, {this.onBuild});
  final String name;
  final VoidCallback? onBuild;
  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int n = 0;
  @override
  Widget build(BuildContext context) {
    widget.onBuild?.call();
    return TextButton(
      key: Key('btn-${widget.name}'),
      onPressed: () => setState(() => n++),
      child: Text('${widget.name}:$n'),
    );
  }
}

Widget _app(
  int index, {
  List<String> built = const [],
  SwiftUiSwitchTransition transition = SwiftUiSwitchTransition.fadeThrough,
  bool lazy = true,
}) => testApp(
  SwiftUiPageSwitcher(
    index: index,
    transition: transition,
    lazy: lazy,
    children: [
      for (final n in ['a', 'b', 'c']) _Counter(n),
    ],
  ),
);

void main() {
  _pagesOwn();
  testWidgets('shows only the selected page', (tester) async {
    await tester.pumpWidget(_app(0));
    expect(find.text('a:0'), findsOneWidget);
    expect(find.text('b:0'), findsNothing);
  });

  testWidgets('pages keep their state while they are not shown', (
    tester,
  ) async {
    await tester.pumpWidget(_app(0));
    await tester.tap(find.byKey(const Key('btn-a')));
    await tester.pump();
    expect(find.text('a:1'), findsOneWidget);
    await tester.pumpWidget(_app(1));
    await tester.pumpAndSettle();
    expect(find.text('b:0'), findsOneWidget);
    expect(find.text('a:1'), findsNothing); // not shown
    await tester.pumpWidget(_app(0));
    await tester.pumpAndSettle();
    expect(find.text('a:1'), findsOneWidget);
  });

  testWidgets('lazy: a page is built when it is first shown', (tester) async {
    var built = 0;
    Widget app(int i, bool lazy) => testApp(
      SwiftUiPageSwitcher(
        index: i,
        lazy: lazy,
        children: [
          const _Counter('a'),
          _Counter('b', onBuild: () => built++),
        ],
      ),
    );
    await tester.pumpWidget(app(0, true));
    expect(built, 0);
    await tester.pumpWidget(app(1, true));
    await tester.pumpAndSettle();
    expect(built, greaterThan(0));
  });

  testWidgets('not lazy: every page is built at start', (tester) async {
    var built = 0;
    await tester.pumpWidget(
      testApp(
        SwiftUiPageSwitcher(
          index: 0,
          lazy: false,
          children: [
            const _Counter('a'),
            _Counter('b', onBuild: () => built++),
          ],
        ),
      ),
    );
    expect(built, greaterThan(0));
  });

  testWidgets('fade through: covers halfway, never an offscreen layer', (
    tester,
  ) async {
    Widget app(int i) => testApp(
      SwiftUiPageSwitcher(
        index: i,
        // plain pages: nothing in them draws an opacity layer, so any layer found belongs to the switcher
        children: const [
          Text('a', textDirection: TextDirection.ltr),
          Text('b', textDirection: TextDirection.ltr),
        ],
      ),
    );
    await tester.pumpWidget(app(0));
    await tester.pumpWidget(app(1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 130)); // halfway
    final inSwitcher = find.descendant(
      of: find.byType(SwiftUiPageSwitcher),
      matching: find.byType(Opacity),
    );
    expect(inSwitcher, findsNothing);
    expect(
      find.descendant(
        of: find.byType(SwiftUiPageSwitcher),
        matching: find.byType(FadeTransition),
      ),
      findsNothing,
    );
    // the cover: a plain coloured box over the pages
    expect(
      find.descendant(
        of: find.byType(SwiftUiPageSwitcher),
        matching: find.byType(ColoredBox),
      ),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
    expect(find.text('b'), findsOneWidget);
    expect(find.text('a'), findsNothing);
  });

  testWidgets('slide: both pages are on screen while it runs', (tester) async {
    await tester.pumpWidget(_app(0, transition: SwiftUiSwitchTransition.slide));
    await tester.pumpWidget(_app(1, transition: SwiftUiSwitchTransition.slide));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('a:0'), findsOneWidget);
    expect(find.text('b:0'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('a:0'), findsNothing);
    expect(find.text('b:0'), findsOneWidget);
  });

  testWidgets('none: switches at once', (tester) async {
    await tester.pumpWidget(_app(0, transition: SwiftUiSwitchTransition.none));
    await tester.pumpWidget(_app(1, transition: SwiftUiSwitchTransition.none));
    await tester.pump();
    expect(find.text('b:0'), findsOneWidget);
    expect(find.text('a:0'), findsNothing);
  });

  testWidgets('a switch in the middle of another ends on the last page', (
    tester,
  ) async {
    await tester.pumpWidget(_app(0));
    await tester.pumpWidget(_app(1));
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pumpWidget(_app(2));
    await tester.pumpAndSettle();
    expect(find.text('c:0'), findsOneWidget);
    expect(find.text('b:0'), findsNothing);
  });

  testWidgets('the blur zone of a page keeps working in the shown page', (
    tester,
  ) async {
    setPhoneSize(tester);
    await tester.pumpWidget(
      testApp(
        SwiftUiPageSwitcher(
          index: 1,
          children: [
            const SizedBox(),
            SwiftUiScaffold(
              topBar: const SizedBox(height: 52),
              body: ListView(children: rows(30)),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ProgressiveBlur), findsOneWidget);
  });
}

void _pagesOwn() {
  testWidgets('every page has its own scaffold: header state is not shared', (
    tester,
  ) async {
    setPhoneSize(tester);
    Widget app(int i) => testApp(
      SwiftUiPageSwitcher(
        index: i,
        transition: SwiftUiSwitchTransition.none,
        children: [
          for (final n in ['one', 'two'])
            SwiftUiScaffold(
              title: n,
              body: ListView(key: PageStorageKey(n), children: rows(60)),
            ),
        ],
      ),
    );
    await tester.pumpWidget(app(0));
    await tester.pumpAndSettle();
    final c0 = ChromeScaffoldScope.controllerOf(
      tester.element(find.byType(ListView)),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    final scrolled = c0.scrollOffset.value;
    expect(scrolled, greaterThan(100));

    await tester.pumpWidget(app(1));
    await tester.pumpAndSettle();
    final c1 = ChromeScaffoldScope.controllerOf(
      tester.element(find.byType(ListView)),
    );
    expect(identical(c0, c1), isFalse);
    expect(
      c1.scrollOffset.value,
      lessThan(1),
    ); // the second page's header is untouched

    await tester.pumpWidget(app(0));
    await tester.pumpAndSettle();
    expect(c0.scrollOffset.value, scrolled); // and the first keeps its own
  });
}
