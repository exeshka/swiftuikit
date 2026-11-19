import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftuikit/swiftuikit.dart';

import 'test_app.dart';

// The implied back button belongs to the ROUTE (ModalRoute.canPop: is there a route below this one), not to the navigator
// (Navigator.canPop: are there two routes): the page under a pushed one must not grow a back button when it rebuilds.

class _Page extends StatefulWidget {
  const _Page(this.name, {this.next, this.fullscreenDialog = false});
  final String name;
  final bool fullscreenDialog;
  final Widget? next;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  int rebuilds = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TitleBar(title: widget.name),
        TextButton(
          key: Key('push-${widget.name}'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              fullscreenDialog: widget.fullscreenDialog,
              builder: (_) => widget.next!,
            ),
          ),
          child: const Text('push'),
        ),
        TextButton(
          key: Key('rebuild-${widget.name}'),
          onPressed: () => setState(() => rebuilds++),
          child: Text('rebuild $rebuilds'),
        ),
      ],
    );
  }
}

Finder _backIn(String page) => find.descendant(
  of: find.byWidgetPredicate(
    (w) => w is _Page && w.name == page,
    skipOffstage: false,
  ),
  matching: find.byType(GlassBackButton, skipOffstage: false),
);

void main() {
  testWidgets('the page below a pushed one does not grow a back button', (
    tester,
  ) async {
    setPhoneSize(tester);
    await tester.pumpWidget(testApp(const _Page('A', next: _Page('B'))));
    expect(_backIn('A'), findsNothing);

    await tester.tap(find.byKey(const Key('push-A')));
    await tester.pumpAndSettle();
    expect(_backIn('B'), findsOneWidget);
    expect(_backIn('A'), findsNothing);

    // whatever rebuilds the covered page (a keyboard, a theme change, its own state) must not change that
    final a = find.byWidgetPredicate(
      (w) => w is _Page && w.name == 'A',
      skipOffstage: false,
    );
    (tester.state(find.byType(_Page, skipOffstage: false).first) as State)
        .setState(() {});
    await tester.pump();
    expect(a, findsOneWidget);
    expect(_backIn('A'), findsNothing);
  });

  testWidgets('a fullscreen dialog does not get the back chevron', (
    tester,
  ) async {
    setPhoneSize(tester);
    await tester.pumpWidget(
      testApp(const _Page('A', next: _Page('B'), fullscreenDialog: true)),
    );
    await tester.tap(find.byKey(const Key('push-A')));
    await tester.pumpAndSettle();
    expect(_backIn('B'), findsNothing);
  });
}
