import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftuikit/swiftuikit.dart';

import 'test_app.dart';

Future<SwiftUiWindowInfo> _info(
  WidgetTester tester,
  Size size, {
  List<DisplayFeature> features = const [],
}) async {
  late SwiftUiWindowInfo info;
  await tester.pumpWidget(
    SwiftUiApp(
      warmUp: false,
      themeMode: ThemeMode.dark,
      home: MediaQuery(
        data: MediaQueryData(size: size, displayFeatures: features),
        child: Builder(
          builder: (context) {
            info = SwiftUiWindowInfo.of(context);
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  return info;
}

void main() {
  group('SwiftUiWindowInfo', () {
    testWidgets(
      'the outer display of a foldable is compact, the inner regular',
      (tester) async {
        final outer = await _info(tester, const Size(466, 678));
        expect(outer.isCompactWidth, isTrue);
        expect(outer.isRegularHeight, isTrue);
        final inner = await _info(tester, const Size(669, 951));
        expect(inner.isRegularWidth, isTrue);
        expect(inner.isRegularHeight, isTrue);
      },
    );

    testWidgets('a phone in landscape is compact in height', (tester) async {
      final w = await _info(tester, const Size(874, 402));
      expect(w.isRegularWidth, isTrue);
      expect(w.isCompactHeight, isTrue);
    });

    testWidgets('the fold comes from the display features, or from a scope', (
      tester,
    ) async {
      final w = await _info(
        tester,
        const Size(800, 600),
        features: const [
          DisplayFeature(
            bounds: Rect.fromLTWH(390, 0, 20, 600),
            type: DisplayFeatureType.fold,
            state: DisplayFeatureState.postureHalfOpened,
          ),
        ],
      );
      expect(w.fold!.bounds.left, 390);
      expect(w.reservedRegions.single.kind, SwiftUiReservedRegionKind.fold);
    });

    testWidgets('it follows the window while the app runs (a fold)', (
      tester,
    ) async {
      final sizes = <Size>[];
      Widget app(Size s) => SwiftUiApp(
        warmUp: false,
        home: MediaQuery(
          data: MediaQueryData(size: s),
          child: Builder(
            builder: (c) {
              sizes.add(SwiftUiWindowInfo.of(c).size);
              return Text(
                SwiftUiWindowInfo.of(c).horizontal.name,
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );
      await tester.pumpWidget(app(const Size(466, 678)));
      expect(find.text('compact'), findsOneWidget);
      await tester.pumpWidget(app(const Size(669, 951)));
      expect(find.text('regular'), findsOneWidget);
    });
  });

  group('SwiftUiScaffold', () {
    testWidgets('a title builds the default large-title header', (
      tester,
    ) async {
      setPhoneSize(tester);
      await tester.pumpWidget(
        testApp(
          SwiftUiScaffold(
            title: 'Contacts',
            body: ListView(children: rows(30)),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(LargeTitleHeader), findsOneWidget);
      expect(find.text('Contacts'), findsWidgets);
    });

    testWidgets(
      'a custom topBar is wrapped, so the content makes room for it',
      (tester) async {
        setPhoneSize(tester);
        await tester.pumpWidget(
          testApp(
            SwiftUiScaffold(
              topBar: const SizedBox(height: 52, child: Text('mine')),
              body: ListView(children: rows(30)),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('mine'), findsOneWidget);
        expect(
          tester.getTopLeft(find.byKey(const ValueKey('row0'))).dy,
          59 + 52,
        );
      },
    );

    testWidgets('builders get the window', (tester) async {
      setPhoneSize(tester);
      SwiftUiWindowInfo? seen;
      await tester.pumpWidget(
        testApp(
          SwiftUiScaffold(
            topBarBuilder: (context, w) =>
                SizedBox(height: 52, child: Text('${w.horizontal.name} bar')),
            bodyBuilder: (context, w) {
              seen = w;
              return ListView(children: rows(30));
            },
          ),
        ),
      );
      await tester.pump();
      expect(find.text('compact bar'), findsOneWidget);
      expect(seen!.isCompactWidth, isTrue);
    });

    testWidgets('chrome styles pass through to the scaffold', (tester) async {
      setPhoneSize(tester);
      await tester.pumpWidget(
        testApp(
          SwiftUiScaffold(
            topBar: const SizedBox(height: 52),
            topChrome: const ChromeStyle.solid(),
            body: ListView(children: rows(30)),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ProgressiveBlur), findsNothing);
    });
  });
}
