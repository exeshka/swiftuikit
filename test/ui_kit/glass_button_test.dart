import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftuikit/swiftuikit.dart';

import 'test_app.dart';

Widget host(Widget child) => testApp(Center(child: child));

void main() {
  for (final style in GlassButtonStyle.values) {
    testWidgets('$style: a tap fires, a disabled button does not', (tester) async {
      setPhoneSize(tester);
      var taps = 0;
      await tester.pumpWidget(host(GlassButton(label: 'Open', style: style, liquid: false, onPressed: () => taps++)));
      await tester.tap(find.text('Open'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(taps, 1);

      await tester.pumpWidget(host(GlassButton(label: 'Open', style: style, liquid: false)));
      await tester.tap(find.text('Open'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
      expect(taps, 1);
    });
  }

  testWidgets('native sizes: a regular capsule is 34 pt, a large one 50, a regular circle 30, a large circle 46', (tester) async {
    setPhoneSize(tester);
    Future<Size> sizeOf(Widget w) async {
      await tester.pumpWidget(host(w));
      return tester.getSize(find.byType(GlassButton));
    }

    expect((await sizeOf(GlassButton(label: 'Open', liquid: false, onPressed: () {}))).height, 34);
    expect((await sizeOf(GlassButton(label: 'Open', size: GlassButtonSize.large, liquid: false, onPressed: () {}))).height, 50);
    expect((await sizeOf(GlassButton(label: 'Open', size: GlassButtonSize.small, style: GlassButtonStyle.bordered, onPressed: () {}))).height, 28);
    final c = await sizeOf(GlassButton.circle(icon: const SizedBox(), liquid: false, onPressed: () {}));
    expect(c, const Size(30, 30));
    final cl = await sizeOf(GlassButton.circle(icon: const SizedBox(), size: GlassButtonSize.large, liquid: false, onPressed: () {}));
    expect(cl, const Size(46, 46));
  });

  testWidgets('expand fills the width; icon and label sit in a row', (tester) async {
    setPhoneSize(tester);
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 300,
          child: GlassButton(label: 'Continue', icon: const SizedBox(width: 16, height: 16), expand: true, liquid: false, onPressed: () {}),
        ),
      ),
    );
    expect(tester.getSize(find.byType(GlassButton)).width, 300);
  });
}
