import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:swiftuikit/swiftuikit.dart';

Widget host(Widget child) => SwiftUiApp(
  warmUp: false,
  theme: SwiftUiThemeData.dark(),
  home: Center(child: SizedBox(width: 300, child: child)),
);

void main() {
  testWidgets('a tap focuses the field', (tester) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      host(GlassTextField(focusNode: focus, hintText: 'x')),
    );
    expect(focus.hasFocus, isFalse);
    await tester.tap(find.byType(EditableText));
    await tester.pump();
    expect(focus.hasFocus, isTrue);
  });

  testWidgets('a double tap selects a word', (tester) async {
    final c = TextEditingController(text: 'hello world');
    addTearDown(c.dispose);
    await tester.pumpWidget(host(GlassTextField(controller: c)));
    await tester.tap(find.byType(EditableText));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(c.selection.isCollapsed, isFalse, reason: 'a word must be selected');
    final state = tester.state<EditableTextState>(find.byType(EditableText));
    expect(
      state.selectionOverlay?.toolbarIsVisible ?? false,
      isTrue,
      reason: 'menu after double tap',
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('a long press selects and shows the copy / paste menu', (
    tester,
  ) async {
    final c = TextEditingController(text: 'hello world');
    addTearDown(c.dispose);
    await tester.pumpWidget(host(GlassTextField(controller: c)));
    await tester.longPress(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(c.selection.isCollapsed, isFalse);
    final state = tester.state<EditableTextState>(find.byType(EditableText));
    expect(
      state.selectionOverlay?.toolbarIsVisible ?? false,
      isTrue,
      reason: 'copy/paste menu is shown',
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('a selection gets the glass menu with Cut and Copy', (
    tester,
  ) async {
    final c = TextEditingController(text: 'hello world');
    addTearDown(c.dispose);
    await tester.pumpWidget(host(GlassTextField(controller: c)));
    await tester.longPress(find.byType(EditableText));
    await tester.pumpAndSettle();

    expect(
      find.byType(GlassSelectionToolbar),
      findsOneWidget,
      reason: 'our glass menu, not the system one',
    );
    expect(find.text('Cut'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('a tap on the caret offers Select All and it works', (
    tester,
  ) async {
    final c = TextEditingController(text: 'hello world');
    addTearDown(c.dispose);
    await tester.pumpWidget(host(GlassTextField(controller: c)));
    await tester.tap(find.byType(EditableText));
    await tester.pump(const Duration(milliseconds: 600)); // not a double tap
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();

    expect(find.byType(GlassSelectionToolbar), findsOneWidget);
    await tester.tap(find.text('Select All'));
    await tester.pumpAndSettle();
    expect(c.selection.start, 0);
    expect(c.selection.end, 'hello world'.length);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('Copy puts the selection on the clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData')
          copied = (call.arguments as Map)['text'] as String?;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final c = TextEditingController(text: 'hello world');
    addTearDown(c.dispose);
    await tester.pumpWidget(host(GlassTextField(controller: c)));
    await tester.longPress(find.byType(EditableText));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();
    expect(copied, isNotNull);
    expect(copied, isNotEmpty);
    expect('hello world'.contains(copied!), isTrue);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets(
    'the toolbar stays on the screen and above the field when there is room',
    (tester) async {
      final c = TextEditingController(text: 'hello world');
      addTearDown(c.dispose);
      await tester.pumpWidget(
        SwiftUiApp(
          warmUp: false,
          theme: SwiftUiThemeData.dark(),
          home: Align(
            alignment: Alignment.center,
            child: SizedBox(width: 300, child: GlassTextField(controller: c)),
          ),
        ),
      );
      await tester.longPress(find.byType(EditableText));
      await tester.pumpAndSettle();
      final bar = tester.getRect(find.byType(GlassSelectionToolbar));
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(bar.left, greaterThanOrEqualTo(-0.01)); // float noise is not an overflow
      expect(bar.right, lessThanOrEqualTo(screen.width + 0.01));
      final glass = tester.getRect(
        find.descendant(
          of: find.byType(GlassSelectionToolbar),
          matching: find.byType(GlassSurface),
        ),
      );
      expect(
        glass.bottom,
        lessThanOrEqualTo(tester.getRect(find.byType(EditableText)).top + 4),
        reason: 'above the selection',
      );
      expect(glass.top, greaterThanOrEqualTo(0));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
