import 'dart:io';

import 'package:example/src/screens/swift_text_player_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftuikit/swiftuikit.dart';

const _goldenKey = ValueKey('swiftTextPlayerGolden');

void main() {
  testWidgets('player is English and retargets every track label', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const CupertinoApp(
        home: RepaintBoundary(key: _goldenKey, child: SwiftTextPlayerScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Now Playing'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is SwiftText && widget.data == 'Now Playing',
      ),
      findsNothing,
    );
    expect(find.text('Favorite'), findsOneWidget);
    expect(find.text('AirPlay'), findsOneWidget);
    expect(find.text('Queue'), findsOneWidget);
    expect(find.byType(SwiftText), findsAtLeastNWidgets(4));
    await expectLater(
      find.byKey(_goldenKey),
      matchesGoldenFile('goldens/swift_text_player_phone.png'),
    );

    final initialTitle = tester.widget<SwiftText>(
      find.byKey(const ValueKey('playerTitle')),
    );
    expect(initialTitle.data, 'The Lake');

    await tester.tap(find.byKey(const ValueKey('playerNext')));
    await tester.pump();

    final nextTitle = tester.widget<SwiftText>(
      find.byKey(const ValueKey('playerTitle')),
    );
    final nextArtist = tester.widget<SwiftText>(
      find.byKey(const ValueKey('playerArtist')),
    );
    expect(nextTitle.data, 'Midnight Peaks');
    expect(nextArtist.data, 'Blue Hour');
    expect(tester.takeException(), isNull);

    final source = File(
      'lib/src/screens/swift_text_player_screen.dart',
    ).readAsStringSync();
    expect(RegExp(r'[А-Яа-яЁё]').hasMatch(source), isFalse);
  });

  testWidgets('player uses the wide two-column layout without overflow', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1024, 768);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const CupertinoApp(
        home: RepaintBoundary(key: _goldenKey, child: SwiftTextPlayerScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('playerProgress')), findsOneWidget);
    expect(find.byKey(const ValueKey('playerVolume')), findsOneWidget);
    await expectLater(
      find.byKey(_goldenKey),
      matchesGoldenFile('goldens/swift_text_player_wide.png'),
    );
    expect(tester.takeException(), isNull);
  });
}
