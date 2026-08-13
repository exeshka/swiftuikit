import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftuikit/swiftuikit.dart';

void main() {
  testWidgets('interactive pop keeps page and hero geometry continuous', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final navigatorKey = GlobalKey<NavigatorState>();
    const frameKey = ValueKey('swift-page-golden-frame');

    await tester.pumpWidget(
      RepaintBoundary(
        key: frameKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          home: const ColoredBox(color: Color(0xff07111f)),
        ),
      ),
    );

    navigatorKey.currentState!.push(
      SwiftPageRoute<void>(
        settings: const RouteSettings(name: 'golden-home'),
        radius: 34,
        child: const _GoldenPage(
          background: Color(0xff102a43),
          heroAlignment: Alignment(-0.62, -0.38),
          heroSize: 78,
          accentAlignment: Alignment(0.55, 0.62),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final detailRoute = SwiftPageRoute<void>(
      settings: const RouteSettings(name: 'golden-detail'),
      radius: 34,
      child: const _GoldenPage(
        background: Color(0xfff4efe8),
        heroAlignment: Alignment(0.48, -0.08),
        heroSize: 126,
        accentAlignment: Alignment(-0.58, 0.58),
      ),
    );
    navigatorKey.currentState!.push(detailRoute);
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(const Offset(1, 422));
    await gesture.moveBy(const Offset(220, 0));
    await tester.pump();

    expect(detailRoute.animation!.value, closeTo(1 - 220 / 390, 0.001));
    await expectLater(
      find.byKey(frameKey),
      matchesGoldenFile('goldens/swift_page_interactive_drag.png'),
    );

    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));

    expect(detailRoute.animation!.value, lessThan(1 - 220 / 390));
    await expectLater(
      find.byKey(frameKey),
      matchesGoldenFile('goldens/swift_page_interactive_settle.png'),
    );

    await tester.pumpAndSettle();
  });
}

class _GoldenPage extends StatelessWidget {
  const _GoldenPage({
    required this.background,
    required this.heroAlignment,
    required this.heroSize,
    required this.accentAlignment,
  });

  final Color background;
  final Alignment heroAlignment;
  final double heroSize;
  final Alignment accentAlignment;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: background,
      child: Stack(
        children: [
          Align(
            alignment: accentAlignment,
            child: Container(
              width: 148,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xff2dd4bf).withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          Align(
            alignment: heroAlignment,
            child: Hero(
              tag: 'golden-hero',
              transitionOnUserGestures: true,
              child: Container(
                width: heroSize,
                height: heroSize,
                decoration: BoxDecoration(
                  color: const Color(0xffff9f1c),
                  borderRadius: BorderRadius.circular(heroSize * 0.28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
