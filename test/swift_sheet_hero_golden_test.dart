import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftuikit/swiftuikit.dart';

void main() {
  testWidgets(
    'SwiftSheet Hero stays continuous through slow and fast dismiss',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final navigatorKey = GlobalKey<NavigatorState>();
      final backgroundController = ScrollController();
      addTearDown(backgroundController.dispose);
      const frameKey = ValueKey('swift-sheet-hero-golden-frame');

      await tester.pumpWidget(
        RepaintBoundary(
          key: frameKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            navigatorKey: navigatorKey,
            home: _GoldenSheetBackground(controller: backgroundController),
          ),
        ),
      );

      final route = SwiftSheetRoute<void>(
        settings: const RouteSettings(name: 'sheet-hero-golden'),
        sheetRadius: 34,
        showDragHandle: true,
        scrollableBuilder: (context, controller) =>
            _GoldenSheetContent(controller: controller),
      );
      navigatorKey.currentState!.push(route);
      await tester.pumpAndSettle();

      final settledSheetHeroRect = tester.getRect(
        find.byKey(const ValueKey('golden-sheet-content-hero')),
      );

      final gesture = await tester.startGesture(const Offset(195, 250));
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 190));
      await tester.pump();

      expect(route.animation!.value, lessThan(1));
      expect(
        find.byKey(const ValueKey('golden-sheet-hero-flight')),
        findsOneWidget,
      );
      final slowFlightRect = tester.getRect(
        find.byKey(const ValueKey('golden-sheet-hero-flight')),
      );
      expect(
        (slowFlightRect.top - settledSheetHeroRect.top).abs(),
        lessThan(30),
      );
      await expectLater(
        find.byKey(frameKey),
        matchesGoldenFile('goldens/swift_sheet_hero_slow_drag.png'),
      );

      await gesture.moveBy(const Offset(0, 180));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(route.animation!.status, AnimationStatus.reverse);
      expect(navigatorKey.currentState!.userGestureInProgress, isFalse);

      final scrollGesture = await tester.startGesture(const Offset(195, 110));
      await scrollGesture.moveBy(const Offset(0, -70));
      await tester.pump(const Duration(milliseconds: 50));

      expect(backgroundController.offset, greaterThan(0));
      expect(route.animation!.value, greaterThan(0));
      expect(
        find.byKey(const ValueKey('golden-sheet-hero-flight')),
        findsOneWidget,
      );
      await expectLater(
        find.byKey(frameKey),
        matchesGoldenFile('goldens/swift_sheet_hero_fast_dismiss_scroll.png'),
      );

      await scrollGesture.up();
      await tester.pumpAndSettle();

      expect(route.isActive, isFalse);
      expect(
        find.byKey(const ValueKey('golden-sheet-hero-flight')),
        findsNothing,
      );
    },
  );
}

class _GoldenSheetBackground extends StatelessWidget {
  const _GoldenSheetBackground({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff102a43),
      body: ListView(
        key: const ValueKey('golden-sheet-background-list'),
        controller: controller,
        padding: const EdgeInsets.fromLTRB(24, 82, 24, 80),
        children: [
          const Text(
            'Live background',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'This list remains interactive while the sheet finishes closing.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerRight,
            child: Hero(
              key: const ValueKey('golden-sheet-background-hero'),
              tag: 'golden-sheet-hero',
              transitionOnUserGestures: true,
              flightShuttleBuilder: _goldenSheetHeroFlight,
              child: const SizedBox.square(
                dimension: 92,
                child: _GoldenSheetHeroArtwork(),
              ),
            ),
          ),
          const SizedBox(height: 28),
          ...List.generate(
            10,
            (index) => Container(
              height: 70,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Background item ${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldenSheetContent extends StatelessWidget {
  const _GoldenSheetContent({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xffecfdf5),
      child: ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
        children: [
          Center(
            child: Hero(
              key: const ValueKey('golden-sheet-content-hero'),
              tag: 'golden-sheet-hero',
              transitionOnUserGestures: true,
              flightShuttleBuilder: _goldenSheetHeroFlight,
              child: const SizedBox.square(
                dimension: 210,
                child: _GoldenSheetHeroArtwork(),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Interactive Hero',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xff062f2a),
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Drag slowly to inspect the flight, or dismiss fast and scroll behind it.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xff062f2a).withValues(alpha: 0.62),
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 26),
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              children: [
                Icon(CupertinoIcons.hand_draw_fill, color: Color(0xff0f766e)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'The destination follows background scrolling.',
                    style: TextStyle(
                      color: Color(0xff062f2a),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _goldenSheetHeroFlight(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  return const _GoldenSheetHeroArtwork(
    key: ValueKey('golden-sheet-hero-flight'),
  );
}

class _GoldenSheetHeroArtwork extends StatelessWidget {
  const _GoldenSheetHeroArtwork({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(38),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff5eead4), Color(0xff14b8a6), Color(0xff0f766e)],
        ),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x440f766e),
            blurRadius: 32,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: const FractionallySizedBox(
        widthFactor: 0.46,
        heightFactor: 0.46,
        child: FittedBox(
          child: Icon(CupertinoIcons.layers_alt_fill, color: Colors.white),
        ),
      ),
    );
  }
}
