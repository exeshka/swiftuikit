import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftuikit/swiftuikit.dart';
import 'package:swiftuikit/src/components/glass_surface.dart' show flatFill;

void main() {
  pressTests();
  meltTests();
  shadowEverywhereTests();
  test('the flat fill is solid and a touch darker than the glass over the same background', () {
    const glass = Color(0x99303034);
    const bg = Color(0xFF000000);
    final flat = flatFill(glass, bg);
    expect(flat.a, 1, reason: 'fully filled, not translucent');
    final onBg = Color.alphaBlend(glass, bg);
    expect(flat.r, lessThan(onBg.r));
    expect(flat.g, lessThan(onBg.g));
    expect(flat.b, lessThan(onBg.b));
  });

  test('on the light theme the flat plate is plain white', () {
    expect(flatFill(const Color(0x80FFFFFF), const Color(0xFFF2F2F7), isDark: false), const Color(0xFFFFFFFF));
  });

  Future<List<int>> flatPlate(WidgetTester tester, {required bool shadow}) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      SwiftUiApp(
        warmUp: false,
        theme: SwiftUiThemeData.dark(),
        home: Center(
          child: RepaintBoundary(
            key: key,
            child: Container(
              color: const Color(0xFF808080),
              padding: const EdgeInsets.all(30),
              child: GlassSurface(liquid: false, width: 120, height: 60, shape: const StadiumBorder(), shadow: shadow),
            ),
          ),
        ),
      ),
    );
    late ByteData data;
    late ui.Image image;
    await tester.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      image = await boundary.toImage();
      data = (await image.toByteData())!;
    });
    int px(int x, int y) {
      final i = (y * image.width + x) * 4;
      return (data.getUint8(i) << 16) | (data.getUint8(i + 1) << 8) | data.getUint8(i + 2);
    }

    final k = image.width / 180.0; // logical -> image pixels (the plate is 120x60 inside 30 of padding)
    final cx = (90 * k).round(), mid = (60 * k).round();
    return [
      px(cx, mid), // centre
      px(cx, (30 * k).round()), // first row inside the top edge
      px(cx, (90 * k).round() - 1), // last row inside the bottom edge
      px(cx, (90 * k).round() + (3 * k).round()), // just below the plate
    ];
  }

  testWidgets('a flat plate is one solid colour: no rim, no highlight', (tester) async {
    final p = await flatPlate(tester, shadow: true);
    expect(p[0], isNot(0x808080), reason: 'the plate is drawn');
    expect(p[1], p[0], reason: 'no outline or highlight on the top edge');
    expect(p[2], p[0], reason: 'no outline on the bottom edge');
  });

  testWidgets('a flat plate keeps its soft drop shadow, and `shadow: false` removes it', (tester) async {
    expect((await flatPlate(tester, shadow: true))[3], isNot(0x808080), reason: 'a shadow darkens the page under the plate');
    expect((await flatPlate(tester, shadow: false))[3], 0x808080, reason: 'no shadow: the page shows as it is');
  });
}

/// Every element built on the glass keeps its drop shadow when it is flat: a shadow darkens the page right under it.
void shadowEverywhereTests() {
  final elements = <String, Widget Function()>{
    'GlassCircleButton (interactive)': () => GlassCircleButton(liquid: false, size: 44, icon: const SizedBox(), onPressed: () {}),
    'GlassCircleButton (not interactive)': () =>
        GlassCircleButton(liquid: false, interactive: false, size: 44, icon: const SizedBox(), onPressed: () {}),
    'GlassAvatarButton': () => const GlassAvatarButton(liquid: false, initials: 'E'),
    'GlassSurface (rounded rectangle, interactive)': () => const GlassSurface(
      liquid: false,
      interactive: true,
      width: 120,
      height: 60,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
    ),
    'GlassSurface (blurred backdrop)': () =>
        const GlassSurface(liquid: false, backdropBlur: true, width: 120, height: 60, shape: StadiumBorder()),
    'GlassTextField': () => const SizedBox(width: 160, child: GlassTextField(liquid: false, interactive: false)),
    'GlassTextField (interactive)': () => const SizedBox(width: 160, child: GlassTextField(liquid: false)),
  };
  const bg = 0x808080;
  for (final e in elements.entries) {
    testWidgets('flat ${e.key} has a drop shadow', (tester) async {
      final key = GlobalKey();
      final inner = GlobalKey();
      await tester.pumpWidget(
        SwiftUiApp(
          warmUp: false,
          theme: SwiftUiThemeData.dark(),
          home: Center(
            child: RepaintBoundary(
              key: key,
              child: Container(
                color: const Color(0xFF808080),
                padding: const EdgeInsets.all(40),
                child: KeyedSubtree(key: inner, child: e.value()),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final boundaryRect = tester.getRect(find.byKey(key));
      final rect = tester.getRect(find.byKey(inner));
      late ui.Image image;
      late ByteData data;
      await tester.runAsync(() async {
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        image = await boundary.toImage();
        data = (await image.toByteData())!;
      });
      final k = image.width / boundaryRect.width;
      final x = ((rect.center.dx - boundaryRect.left) * k).round();
      final y = ((rect.bottom - boundaryRect.top + 3) * k).round();
      final i = (y * image.width + x) * 4;
      final px = (data.getUint8(i) << 16) | (data.getUint8(i + 1) << 8) | data.getUint8(i + 2);
      expect(px, isNot(bg), reason: 'the page under the element must be darkened by its shadow');
    });
  }
}

void meltTests() {
  testWidgets('flat plates of a group melt into one shape while one is pressed, like the glass', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      SwiftUiApp(
        warmUp: false,
        theme: SwiftUiThemeData.dark(),
        home: Center(
          child: RepaintBoundary(
            key: key,
            child: Container(
              color: const Color(0xFF000000),
              padding: const EdgeInsets.all(30),
              child: LiquidGlassGroup(
                spacing: 24,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GlassCircleButton(liquid: false, size: 44, icon: const SizedBox(), onPressed: () {}),
                    const SizedBox(width: 22),
                    GlassCircleButton(liquid: false, size: 44, icon: const SizedBox(), onPressed: () {}),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // 44 + 22 + 44 = 110 wide, 44 high, inside 30 of padding: the gap is x 104..126 around y = 52 (px / k)
    Future<int> gap() async {
      late ui.Image image;
      late ByteData data;
      await tester.runAsync(() async {
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        image = await boundary.toImage();
        data = (await image.toByteData())!;
      });
      final k = image.width / 170.0;
      final i = ((52 * k).round() * image.width + (( 30 + 44 + 11) * k).round()) * 4;
      return (data.getUint8(i) << 16) | (data.getUint8(i + 1) << 8) | data.getUint8(i + 2);
    }

    expect(await gap(), 0, reason: 'at rest the plates are separate');
    final g = await tester.startGesture(tester.getCenter(find.byType(GlassCircleButton).first));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(await gap(), isNot(0), reason: 'the pressed plate melts into its neighbour: the gap is bridged');
    await g.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    expect(await gap(), 0, reason: 'and they part again');
  });
}

void pressTests() {
  testWidgets('a flat button answers a press like the glass: it grows and lights up, then settles back', (tester) async {
    final key = GlobalKey();
    var taps = 0;
    await tester.pumpWidget(
      SwiftUiApp(
        warmUp: false,
        theme: SwiftUiThemeData.dark(),
        home: Center(
          child: RepaintBoundary(
            key: key,
            child: Container(
              color: const Color(0xFF000000),
              padding: const EdgeInsets.all(30),
              child: GlassCircleButton(
                liquid: false,
                size: 44,
                icon: const SizedBox(),
                onPressed: () => taps++,
              ),
            ),
          ),
        ),
      ),
    );

    late List<int> rest, pressed, after;
    Future<List<int>> snap() async {
      late ui.Image image;
      late ByteData data;
      await tester.runAsync(() async {
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        image = await boundary.toImage();
        data = (await image.toByteData())!;
      });
      final k = image.width / 104.0; // 44 + 2 * 30 logical px
      int px(double x, double y) {
        final i = ((y * k).round() * image.width + (x * k).round()) * 4;
        return (data.getUint8(i) << 16) | (data.getUint8(i + 1) << 8) | data.getUint8(i + 2);
      }

      // [centre, just outside the resting circle (3 pt beyond its edge), further out (6 pt beyond)]
      return [px(52, 52), px(52, 52 - 22 - 3), px(52, 52 - 22 - 6)];
    }

    rest = await snap();
    expect(rest[1], 0, reason: 'at rest nothing is drawn outside the circle');

    final g = await tester.startGesture(tester.getCenter(find.byType(GlassCircleButton)));
    await tester.pump(); // the animation starts on this frame
    await tester.pump(const Duration(milliseconds: 400));
    pressed = await snap();
    expect(pressed[1], isNot(0), reason: 'the plate grew past its resting edge');
    expect(pressed[0], greaterThan(rest[0]), reason: 'the plate lights up under the finger');

    await g.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // the minimum hold of the press elapses
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    after = await snap();
    expect(after[1], 0, reason: 'it settles back to its size');
    expect(taps, 1, reason: 'the press response must not eat the tap');
  });
}
