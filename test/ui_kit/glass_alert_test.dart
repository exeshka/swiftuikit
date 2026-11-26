import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftuikit/swiftuikit.dart';

import 'test_app.dart';

Future<void> open(WidgetTester tester, VoidCallback Function(BuildContext) onOpen) async {
  setPhoneSize(tester);
  await tester.pumpWidget(
    testApp(
      Builder(
        builder: (context) => Center(
          child: GestureDetector(
            key: const ValueKey('open'),
            onTap: onOpen(context),
            child: const SizedBox(width: 100, height: 100, child: Text('open')),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const ValueKey('open')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('two buttons sit side by side, the cancel one first; the tapped one returns its value', (tester) async {
    Object? result = 'none';
    await open(tester, (context) => () async {
      result = await showGlassAlert<bool>(
        context,
        title: 'Delete?',
        message: 'This cannot be undone.',
        actions: const [
          GlassAlertAction(label: 'OK', value: true),
          GlassAlertAction(label: 'Cancel', role: GlassAlertRole.cancel, value: false),
        ],
      );
    });
    expect(find.text('Delete?'), findsOneWidget);
    final cancel = tester.getCenter(find.text('Cancel'));
    final ok = tester.getCenter(find.text('OK'));
    expect(cancel.dy, ok.dy);
    expect(cancel.dx, lessThan(ok.dx));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(result, true);
    expect(find.text('Delete?'), findsNothing);
  });

  testWidgets('three buttons stack with the cancel one last; a tap outside does not close an alert', (tester) async {
    await open(tester, (context) => () {
      showGlassAlert<int>(
        context,
        title: 'Conflict',
        actions: const [
          GlassAlertAction(label: 'Cancel', role: GlassAlertRole.cancel),
          GlassAlertAction(label: 'Keep both', value: 1),
          GlassAlertAction(label: 'Replace', value: 2),
        ],
      );
    });
    final ys = [for (final l in ['Keep both', 'Replace', 'Cancel']) tester.getCenter(find.text(l)).dy];
    expect(ys[0], lessThan(ys[1]));
    expect(ys[1], lessThan(ys[2]));
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('Conflict'), findsOneWidget);
  });

  testWidgets('a text field in the alert feeds its controller', (tester) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    await open(tester, (context) => () {
      showGlassAlert<void>(
        context,
        title: 'Name',
        fields: [GlassAlertField(controller: c, placeholder: 'Type here')],
        actions: const [GlassAlertAction(label: 'OK')],
      );
    });
    expect(find.text('Type here'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'abc');
    await tester.pump();
    expect(c.text, 'abc');
    expect(find.text('Type here'), findsNothing);
  });

  testWidgets('an action dialog hides its cancel button; a tap outside closes it', (tester) async {
    await open(tester, (context) => () {
      showGlassActionDialog<void>(
        context,
        title: 'Choose',
        actions: const [
          GlassAlertAction(label: 'Duplicate'),
          GlassAlertAction(label: 'Delete', role: GlassAlertRole.destructive),
          GlassAlertAction(label: 'Cancel', role: GlassAlertRole.cancel),
        ],
      );
    });
    expect(find.text('Duplicate'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('Duplicate'), findsNothing);
  });
}
