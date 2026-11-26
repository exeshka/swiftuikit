import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftuikit/swiftuikit.dart';

import 'test_app.dart';

class _Content extends StatelessWidget {
  const _Content();
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: ChromeScaffold(
      backgroundColor: Colors.transparent,
      minTopInset: 22,
      topBar: ChromeBar(
        child: TitleBar(
          automaticallyImplyLeading: false,
          leading: GlassCircleButton(icon: RavelIcon(RavelIconKind.close), liquid: false, onPressed: () {}),
          title: 'Filters',
          trailing: [GlassButton(label: 'Done', liquid: false, size: GlassButtonSize.small, onPressed: () {})],
        ),
      ),
      bottomBar: ChromeBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GlassButton(label: 'Show results', liquid: false, size: GlassButtonSize.large, expand: true, onPressed: () {}),
        ),
      ),
      body: ListView.builder(
        controller: GlassSheet.scrollControllerOf(context),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: 30,
        itemBuilder: (context, i) => SizedBox(height: 56, child: Text('Filter $i')),
      ),
    ),
  );
}

void main() {
  testWidgets('a ChromeScaffold inside the sheet: it opens at the medium detent and drags down', (tester) async {
    setPhoneSize(tester);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final c = GlassSheetController();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      testApp(
        Builder(
          builder: (context) => GestureDetector(
            key: const ValueKey('open'),
            behavior: HitTestBehavior.opaque,
            onTap: () => showGlassSheet<void>(context, controller: c, scrollable: false, liquid: false, child: const _Content()),
            child: const SizedBox(width: 100, height: 100),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open')));
    await tester.pumpAndSettle();
    final medium = c.extent;
    expect(medium, lessThan(0.6), reason: 'it opens at the medium detent, not at the large one (extent $medium)');
    await tester.drag(find.text('Filter 2'), const Offset(0, 200));
    await tester.pump(const Duration(milliseconds: 30));
    expect(c.extent, lessThan(medium), reason: 'a drag down moves the sheet down');
    await tester.pumpAndSettle();
  });

  testWidgets('a ChromeScaffold inside the sheet: from the large detent a drag down moves the sheet', (tester) async {
    setPhoneSize(tester);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final c = GlassSheetController();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      testApp(
        Builder(
          builder: (context) => GestureDetector(
            key: const ValueKey('open'),
            behavior: HitTestBehavior.opaque,
            onTap: () => showGlassSheet<void>(context, controller: c, scrollable: false, liquid: false, child: const _Content()),
            child: const SizedBox(width: 100, height: 100),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open')));
    await tester.pumpAndSettle();
    c.expand();
    await tester.pumpAndSettle();
    final large = c.extent;
    await tester.drag(find.text('Filter 3'), const Offset(0, 250));
    await tester.pump(const Duration(milliseconds: 30));
    expect(c.extent, lessThan(large), reason: 'a drag down at the top of the list moves the sheet down');
  });

  testWidgets('a slow drag down with small steps (a finger) pulls the sheet down from the large detent', (tester) async {
    setPhoneSize(tester);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final c = GlassSheetController();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      testApp(
        Builder(
          builder: (context) => GestureDetector(
            key: const ValueKey('open'),
            behavior: HitTestBehavior.opaque,
            onTap: () => showGlassSheet<void>(context, controller: c, scrollable: false, liquid: false, child: const _Content()),
            child: const SizedBox(width: 100, height: 100),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open')));
    await tester.pumpAndSettle();
    c.expand();
    await tester.pumpAndSettle();
    final large = c.extent;
    final g = await tester.startGesture(tester.getCenter(find.text('Filter 3')));
    for (var i = 0; i < 50; i++) {
      await g.moveBy(const Offset(0, 4));
      await tester.pump(const Duration(milliseconds: 12));
    }
    // ignore: avoid_print
    print('SLOW large=$large now=${c.extent}');
    expect(c.extent, lessThan(large - 0.1), reason: 'the sheet follows the finger (200 pt of 874)');
    await g.up();
    await tester.pumpAndSettle();
  });
}
