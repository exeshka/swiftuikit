import 'package:example/src/core/router/router.dart';
import 'package:example/src/screens/swift_zoom_gallery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('auto_route drag keeps the selected gallery page', (
    tester,
  ) async {
    final router = AppRouter();

    await tester.pumpWidget(
      MaterialApp.router(
        theme: ThemeData.dark(),
        routerConfig: router.config(),
      ),
    );
    await tester.pumpAndSettle();

    final galleryTitle = find.text('SwiftZoomHero · dynamic target');
    await tester.scrollUntilVisible(
      galleryTitle,
      500,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Espresso Shot').first);
    await tester.pumpAndSettle();

    final gallery = find.byType(SwiftZoomGalleryScreen);
    final galleryState = tester.state(gallery);
    final pageView = find.byKey(
      const ValueKey('swift-zoom-vertical-page-view'),
    );
    final pageViewState = tester.state(pageView);

    await tester.drag(pageView, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.drag(pageView, const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('3 / 4'), findsOneWidget);

    final dismissGesture = await tester.startGesture(const Offset(250, 350));
    await dismissGesture.moveBy(const Offset(24, 12));
    await tester.pump();
    await dismissGesture.moveBy(const Offset(100, 58));
    await tester.pump();

    expect(tester.state(gallery), same(galleryState));
    expect(tester.state(pageView), same(pageViewState));
    expect(find.text('3 / 4'), findsOneWidget);

    await dismissGesture.cancel();
    await tester.pumpAndSettle();

    expect(find.text('3 / 4'), findsOneWidget);
    expect(tester.state(gallery), same(galleryState));
    expect(tester.state(pageView), same(pageViewState));
    expect(tester.takeException(), isNull);
  });
}
