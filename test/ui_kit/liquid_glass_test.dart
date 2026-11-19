import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftuikit/swiftuikit.dart';

import 'test_app.dart';

void main() {
  glassSmallnessTests();
  testWidgets('LiquidGlass falls back to flat glass without shader support', (
    tester,
  ) async {
    setPhoneSize(tester);
    await tester.pumpWidget(
      testApp(
        const Center(child: LiquidGlass.circle(size: 52, child: Text('x'))),
      ),
    );
    expect(LiquidGlass.supported, isFalse); // no Impeller in flutter test
    expect(find.text('x'), findsOneWidget);
    expect(tester.getSize(find.byType(GlassSurface)), const Size(52, 52));
  });

  testWidgets(
    'LiquidGlassPresence drives presence 0..1 and clear/presence params build',
    (tester) async {
      setPhoneSize(tester);
      final seen = <double>[];
      var show = false;
      late StateSetter set;
      await tester.pumpWidget(
        testApp(
          StatefulBuilder(
            builder: (c, s) {
              set = s;
              return LiquidGlassPresence(
                show: show,
                duration: const Duration(milliseconds: 100),
                builder: (c, p) {
                  seen.add(p);
                  return LiquidGlass.circle(
                    size: 40,
                    clear: true,
                    presence: p,
                    presenceOrigin: const Offset(-50, 0),
                  );
                },
              );
            },
          ),
        ),
      );
      set(() => show = true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      await tester.pumpAndSettle();
      expect(seen.last, closeTo(1, 1e-6));
      expect(seen.any((v) => v > 0.05 && v < 0.95), isTrue);
    },
  );

  testWidgets('interactive glass tracks press and drag without eating taps', (
    tester,
  ) async {
    setPhoneSize(tester);
    var taps = 0;
    await tester.pumpWidget(
      testApp(
        Center(
          child: GestureDetector(
            onTap: () => taps++,
            child: const LiquidGlass(
              width: 200,
              height: 80,
              interactive: true,
              child: Text('btn'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('btn'));
    await tester.pumpAndSettle();
    expect(taps, 1);
    final g = await tester.startGesture(tester.getCenter(find.text('btn')));
    await tester.pump(const Duration(milliseconds: 50));
    await g.moveBy(const Offset(120, 0));
    await tester.pump(const Duration(milliseconds: 100));
    await g.up();
    await tester.pumpAndSettle();
    expect(find.text('btn'), findsOneWidget);
  });

  testWidgets(
    'GlassCircleButton still renders and taps with liquid tokens on',
    (tester) async {
      setPhoneSize(tester);
      var taps = 0;
      await tester.pumpWidget(
        testApp(
          Center(
            child: GlassCircleButton(
              icon: RavelIcon(RavelIconKind.search),
              onPressed: () => taps++,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(GlassCircleButton));
      expect(taps, 1);
      expect(
        SwiftUiTheme.of(tester.element(find.byType(GlassCircleButton)))
            .glass
            .useLiquidGlass,
        isTrue,
      );
    },
  );

  test('tokens interpolate the liquid parameters', () {
    final a = SwiftUiThemeData.dark();
    final b = a.copyWith(
      glass: a.glass.copyWith(liquidRefraction: 32, useLiquidGlass: false),
    );
    final m = a.lerp(b, 0.5);
    expect(
      m.glass.liquidRefraction,
      closeTo((a.glass.liquidRefraction + 32) / 2, 1e-9),
    );
  });
}

void glassSmallnessTests() {
  test(
    'glassSmallness blends the two materials instead of cutting at 68 pt',
    () {
      expect(glassSmallness(44), 1);
      expect(glassSmallness(glassSmallEdge - glassSmallBlend), 1);
      expect(glassSmallness(glassSmallEdge), closeTo(0.5, 1e-9));
      expect(glassSmallness(glassSmallEdge + glassSmallBlend), 0);
      expect(glassSmallness(110), 0);
      // monotonic: a growing plate only ever loses the small material
      var last = 1.0;
      for (var side = 40.0; side <= 100; side += 1) {
        final s = glassSmallness(side);
        expect(s, lessThanOrEqualTo(last));
        last = s;
      }
    },
  );
}
