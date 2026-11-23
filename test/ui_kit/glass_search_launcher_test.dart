import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftuikit/swiftuikit.dart';

import 'test_app.dart';

void main() {
  testWidgets('a tap opens the search layer, typing feeds the results, cancel closes it and clears the query', (tester) async {
    setPhoneSize(tester);
    final changed = <String>[];
    var opened = 0;
    var closed = 0;
    await tester.pumpWidget(
      testApp(
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 100, 16, 0),
            child: GlassSearchLauncher(
              hintText: 'Ticker',
              liquid: false,
              onChanged: changed.add,
              onOpened: () => opened++,
              onClosed: () => closed++,
              resultsBuilder: (context, query) => Text('results for "$query"'),
              bottomBuilder: (context) => const SizedBox(key: ValueKey('bottom'), height: 40),
            ),
          ),
        ),
      ),
    );
    // closed: only the launcher, no layer, no editable text
    expect(find.byType(EditableText), findsOneWidget); // the launcher's own (absorbed) field
    expect(find.textContaining('results for'), findsNothing);

    await tester.tap(find.byType(GlassSearchLauncher));
    await tester.pumpAndSettle();
    expect(opened, 1);
    expect(find.textContaining('results for'), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom')), findsOneWidget);

    await tester.enterText(find.byType(EditableText).last, 'sol');
    await tester.pump();
    expect(changed.last, 'sol');
    expect(find.text('results for "sol"'), findsOneWidget);

    // the cancel button of the layer
    await tester.tap(find.bySemanticsLabel('Cancel').last);
    await tester.pumpAndSettle();
    expect(closed, 1);
    expect(find.textContaining('results for'), findsNothing);
    expect(find.byKey(const ValueKey('bottom')), findsNothing);
  });

  testWidgets('the system back closes the layer too', (tester) async {
    setPhoneSize(tester);
    var closed = 0;
    await tester.pumpWidget(
      testApp(
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 100),
            child: SizedBox(
              width: 300,
              child: GlassSearchLauncher(
                liquid: false,
                onClosed: () => closed++,
                resultsBuilder: (context, query) => const Text('results'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(GlassSearchLauncher));
    await tester.pumpAndSettle();
    expect(find.text('results'), findsOneWidget);
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.pop();
    await tester.pumpAndSettle();
    expect(find.text('results'), findsNothing);
    expect(closed, 1);
  });
}
