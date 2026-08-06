import 'dart:io';

import 'package:swiftuikit/swiftuikit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) {
  return MediaQuery(
    data: const MediaQueryData(),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: DefaultTextStyle(
        style: const TextStyle(fontSize: 30, color: Color(0xff000000)),
        child: Center(child: child),
      ),
    ),
  );
}

bool effectiveCountsDown(WidgetTester tester) {
  return (tester.renderObject(find.byType(SwiftText)) as dynamic).countsDown
      as bool;
}

Rect presentedGlyphRect(WidgetTester tester, String text) {
  final dynamic render = tester.renderObject(find.byType(SwiftText));
  final texts = List<String>.from(render.debugPresentedGlyphTexts as List);
  final rects = List<Rect>.from(render.debugPresentedGlyphRects as List);
  final index = texts.indexOf(text);
  expect(index, isNonNegative, reason: 'Presented glyph "$text" was missing');
  return rects[index];
}

double presentedGlyphOpacity(WidgetTester tester, String text) {
  final dynamic render = tester.renderObject(find.byType(SwiftText));
  final texts = List<String>.from(render.debugPresentedGlyphTexts as List);
  final opacities = List<double>.from(render.debugPresentedOpacities as List);
  final index = texts.indexOf(text);
  expect(index, isNonNegative, reason: 'Presented glyph "$text" was missing');
  return opacities[index];
}

void main() {
  test('plain and rich constructors share the 450 ms default', () {
    const plain = SwiftText('42');
    const rich = SwiftText.rich(TextSpan(text: '42'));
    expect(plain.duration, const Duration(milliseconds: 450));
    expect(rich.duration, plain.duration);
  });

  test('SwiftTextSmoothCurve keeps exact endpoints and is monotonic', () {
    const curve = SwiftTextSmoothCurve();
    expect(curve.settlingRatio, closeTo(0.9 / 0.55, 0.0000001));
    expect(curve.transform(0), 0);
    expect(curve.transform(1), 1);
    var previous = 0.0;
    for (var i = 1; i <= 100; i++) {
      final value = curve.transform(i / 100);
      expect(value, greaterThanOrEqualTo(previous));
      previous = value;
    }
    // One perceptual duration is one natural spring period. The remaining
    // distance is the physical settling tail, not an endpoint-normalized ease.
    expect(
      curve.transform(1 / curve.settlingRatio),
      closeTo(0.986399, 0.000001),
    );
    expect(1 - curve.transform(0.999), greaterThan(0.0001));
    expect(1 - curve.transform(0.999), lessThan(0.003));
  });

  test('motion implementation has no bounce or perspective path', () {
    final source = <String>[
      File(
        'lib/src/widgets/swift_text/swift_text_motion.dart',
      ).readAsStringSync(),
      File(
        'lib/src/widgets/swift_text/swift_text_rendering.dart',
      ).readAsStringSync(),
      File(
        'lib/src/widgets/swift_text/swift_text_scene.dart',
      ).readAsStringSync(),
    ].join();
    for (final removedPrimitive in <String>[
      'Matrix4',
      'rotateX',
      'setEntry(',
      '_glyphSettleResponse',
    ]) {
      expect(source, isNot(contains(removedPrimitive)));
    }
  });

  testWidgets('opacity lands smoothly before the physical geometry tail', (
    tester,
  ) async {
    const source = 'ABCDEFGHIJ';
    const target = 'KLMNOPQRST';
    var value = source;
    late StateSetter update;

    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return SwiftText(value);
          },
        ),
      ),
    );

    update(() => value = target);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 390));
    final earlyLanding = presentedGlyphOpacity(tester, 'T');
    await tester.pump(const Duration(milliseconds: 30));
    final lateLanding = presentedGlyphOpacity(tester, 'T');
    await tester.pump(const Duration(milliseconds: 30));
    final perceptualEnd = presentedGlyphOpacity(tester, 'T');

    expect(earlyLanding, lessThan(lateLanding));
    expect(lateLanding, lessThan(perceptualEnd));
    expect(perceptualEnd, greaterThanOrEqualTo(0.999));
    expect(perceptualEnd - lateLanding, lessThan(lateLanding - earlyLanding));
    for (final glyph in source.split('')) {
      expect(presentedGlyphOpacity(tester, glyph), lessThanOrEqualTo(0.002));
    }
    for (final glyph in target.split('')) {
      expect(presentedGlyphOpacity(tester, glyph), greaterThanOrEqualTo(0.999));
    }
    final dynamic render = tester.renderObject(find.byType(SwiftText));
    expect(
      render.debugBlurPassCount as int,
      0,
      reason: 'No late blur bucket may make a landed glyph look translucent',
    );

    await tester.pump(const Duration(milliseconds: 30));
    expect(presentedGlyphOpacity(tester, 'T') - perceptualEnd, lessThan(0.001));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('animates plain text and exposes the final semantics', (
    tester,
  ) async {
    var value = 'Загрузка: 9%';
    late StateSetter update;
    var completions = 0;

    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return SwiftText(
              value,
              duration: const Duration(milliseconds: 550),
              onEnd: () => completions++,
            );
          },
        ),
      ),
    );

    update(() => value = 'Загрузка: 42%');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 330));
    expect(completions, 0);
    await tester.pump(const Duration(milliseconds: 349));
    expect(completions, 0);
    await tester.pump(const Duration(milliseconds: 20));

    final semantics = tester.getSemantics(find.byType(SwiftText));
    expect(semantics.label, 'Загрузка: 42%');
    expect(completions, 1);
  });

  testWidgets('supports count-down, multiline and changing dimensions', (
    tester,
  ) async {
    var value = '100';
    var countsDown = false;
    late StateSetter update;

    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return SwiftText(
              value,
              countsDown: countsDown,
              textAlign: TextAlign.center,
            );
          },
        ),
      ),
    );
    final initial = tester.getSize(find.byType(SwiftText));

    update(() {
      value = 'Первая строка\nВторая строка стала длиннее';
      countsDown = true;
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    final middle = tester.getSize(find.byType(SwiftText));
    await tester.pumpAndSettle();
    final end = tester.getSize(find.byType(SwiftText));

    expect(middle.height, greaterThan(initial.height));
    expect(end.height, greaterThan(middle.height));
    expect(tester.takeException(), isNull);
  });

  testWidgets('settled size and baseline match TextPainter', (tester) async {
    const target = 'Первая строка\nВторая строка стала длиннее';
    const style = TextStyle(fontSize: 30, color: Color(0xff000000));
    var value = 'Одна строка';
    late StateSetter update;

    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return SwiftText(value, textAlign: TextAlign.center);
          },
        ),
      ),
    );
    update(() => value = target);
    await tester.pumpAndSettle();

    final box = tester.renderObject<RenderBox>(find.byType(SwiftText));
    final painter = TextPainter(
      text: const TextSpan(text: target, style: style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      textWidthBasis: TextWidthBasis.parent,
    )..layout(maxWidth: box.constraints.maxWidth);
    expect(box.size.width, closeTo(painter.width, 0.001));
    expect(box.size.height, closeTo(painter.height, 0.001));
    final dynamic render = box;
    expect(
      render.debugAlphabeticBaseline as double?,
      closeTo(
        painter.computeDistanceToActualBaseline(TextBaseline.alphabetic),
        0.001,
      ),
    );
  });

  testWidgets('animates rich TextSpan content', (tester) async {
    var alternate = false;
    late StateSetter update;

    TextSpan content() {
      return TextSpan(
        children: [
          TextSpan(
            text: alternate ? 'Новый RichText: ' : 'RichText: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: alternate
                  ? const Color(0xff800080)
                  : const Color(0xff0000ff),
            ),
          ),
          TextSpan(
            text: alternate ? '42' : '17',
            style: const TextStyle(color: Color(0xffff8c00)),
          ),
        ],
      );
    }

    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return SwiftText.rich(content());
          },
        ),
      ),
    );
    update(() => alternate = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.byType(SwiftText)).label,
      'Новый RichText: 42',
    );
  });

  testWidgets('rebuilds layout when inherited text style changes', (
    tester,
  ) async {
    var fontSize = 18.0;
    late StateSetter update;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return DefaultTextStyle(
                  style: TextStyle(
                    fontSize: fontSize,
                    color: const Color(0xff000000),
                  ),
                  child: const SwiftText('Ambient style'),
                );
              },
            ),
          ),
        ),
      ),
    );
    final initialSize = tester.getSize(find.byType(SwiftText));

    update(() => fontSize = 42);
    await tester.pump();
    final updatedSize = tester.getSize(find.byType(SwiftText));

    expect(updatedSize.width, greaterThan(initialSize.width * 2));
    expect(updatedSize.height, greaterThan(initialSize.height * 2));
  });

  testWidgets('style-only updates do not start a glyph transition', (
    tester,
  ) async {
    var color = const Color(0xff000000);
    var completions = 0;
    late StateSetter update;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return SwiftText(
                'Stable content',
                style: TextStyle(color: color),
                onEnd: () => completions++,
              );
            },
          ),
        ),
      ),
    );

    update(() => color = const Color(0xffffffff));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(completions, 0);
  });

  testWidgets('inherits locale and relayouts when system fonts change', (
    tester,
  ) async {
    var locale = const Locale('tr');
    late StateSetter update;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return Localizations(
                locale: locale,
                delegates: const <LocalizationsDelegate<dynamic>>[
                  DefaultWidgetsLocalizations.delegate,
                ],
                child: const SwiftText('123'),
              );
            },
          ),
        ),
      ),
    );

    final dynamic render = tester.renderObject(find.byType(SwiftText));
    expect(render.debugLocale as Locale?, const Locale('tr'));
    final initialGeneration = render.debugLayoutGeneration as int;

    const message = <String, dynamic>{'type': 'fontsChange'};
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/system',
      SystemChannels.system.codec.encodeMessage(message),
      (_) {},
    );
    await tester.pump();
    await tester.pump();
    expect(render.debugLayoutGeneration as int, greaterThan(initialGeneration));

    update(() => locale = const Locale('kk'));
    await tester.pump();
    expect(render.debugLocale as Locale?, const Locale('kk'));
  });

  testWidgets('auto-detects direction from the numeric content', (
    tester,
  ) async {
    var value = '100';
    late StateSetter update;

    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return SwiftText(value);
          },
        ),
      ),
    );

    update(() => value = '50');
    await tester.pumpAndSettle();
    expect(effectiveCountsDown(tester), isTrue);

    update(() => value = '75');
    await tester.pumpAndSettle();
    expect(effectiveCountsDown(tester), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('auto-detects formatted and exact numeric values', (
    tester,
  ) async {
    var value = '999';
    late StateSetter update;

    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return SwiftText(value);
          },
        ),
      ),
    );

    update(() => value = '1,000');
    await tester.pump();
    expect(effectiveCountsDown(tester), isFalse);
    await tester.pumpAndSettle();

    update(() => value = '999');
    await tester.pump();
    expect(effectiveCountsDown(tester), isTrue);
    await tester.pumpAndSettle();

    update(() => value = '1 000');
    await tester.pump();
    expect(effectiveCountsDown(tester), isFalse);
    await tester.pumpAndSettle();

    update(() => value = '9007199254740992');
    await tester.pumpAndSettle();
    update(() => value = '9007199254740993');
    await tester.pump();
    expect(effectiveCountsDown(tester), isFalse);
    await tester.pumpAndSettle();

    update(() => value = '1.9');
    await tester.pumpAndSettle();
    update(() => value = '1.10');
    await tester.pump();
    expect(effectiveCountsDown(tester), isTrue);
    await tester.pumpAndSettle();

    update(() => value = '−10');
    await tester.pumpAndSettle();
    update(() => value = '−11');
    await tester.pump();
    expect(effectiveCountsDown(tester), isTrue);
  });

  testWidgets('auto-detects direction from rich TextSpan content', (
    tester,
  ) async {
    var value = '100';
    late StateSetter update;

    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return SwiftText.rich(TextSpan(text: value));
          },
        ),
      ),
    );

    update(() => value = '30');
    await tester.pump();
    expect(effectiveCountsDown(tester), isTrue);

    await tester.pumpAndSettle();
  });

  testWidgets('keeps the previous direction when text has no numeric signal', (
    tester,
  ) async {
    var value = '100';
    late StateSetter update;

    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return SwiftText(value);
          },
        ),
      ),
    );

    update(() => value = '50');
    await tester.pumpAndSettle();
    expect(effectiveCountsDown(tester), isTrue);

    update(() => value = 'Готово');
    await tester.pumpAndSettle();
    expect(effectiveCountsDown(tester), isTrue);
  });

  testWidgets('countsDown override wins over auto-detection', (tester) async {
    var value = '10';
    var countsDown = true;
    late StateSetter update;

    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return SwiftText(value, countsDown: countsDown);
          },
        ),
      ),
    );

    update(() => value = '99');
    await tester.pumpAndSettle();
    expect(effectiveCountsDown(tester), isTrue);

    countsDown = false;
    update(() => value = '100');
    await tester.pumpAndSettle();
    expect(effectiveCountsDown(tester), isFalse);
  });

  testWidgets('respects disabled animations', (tester) async {
    var value = '9';
    late StateSetter update;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return SwiftText(value);
            },
          ),
        ),
      ),
    );
    update(() => value = '42');
    await tester.pump();

    expect(tester.getSemantics(find.byType(SwiftText)).label, '42');
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('implements fade overflow instead of hard clipping', (
    tester,
  ) async {
    const fadeKey = ValueKey<String>('numericTextFadeGolden');
    await tester.pumpWidget(
      _host(
        const RepaintBoundary(
          key: fadeKey,
          child: ColoredBox(
            color: Color(0xffffffff),
            child: SizedBox(
              width: 90,
              height: 36,
              child: SwiftText(
                'A very long value that must fade',
                softWrap: false,
                overflow: TextOverflow.fade,
              ),
            ),
          ),
        ),
      ),
    );

    final dynamic render = tester.renderObject(find.byType(SwiftText));
    expect(render.debugHasOverflowFade as bool, isTrue);
    await expectLater(
      find.byKey(fadeKey),
      matchesGoldenFile('goldens/swift_text_fade.png'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses a vertical fade when maxLines truncates wrapped text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 90,
          height: 36,
          child: SwiftText(
            'First line wraps into several more lines',
            overflow: TextOverflow.fade,
            maxLines: 1,
          ),
        ),
      ),
    );

    final dynamic render = tester.renderObject(find.byType(SwiftText));
    expect(render.debugHasVerticalOverflowFade as bool, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps a shrinking outgoing string inside paint bounds', (
    tester,
  ) async {
    var value = 'Осталось: 7 сек.';
    late StateSetter update;

    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return SwiftText(value, textAlign: TextAlign.center);
          },
        ),
      ),
    );
    update(() => value = 'Готово: 100%');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final renderObject = tester.renderObject(find.byType(SwiftText));
    final box = renderObject as RenderBox;
    expect(renderObject.paintBounds.left, lessThan(0));
    expect(renderObject.paintBounds.width, greaterThan(box.size.width));
    expect(tester.takeException(), isNull);
  });

  testWidgets('retargets rapid updates from the current visual layout', (
    tester,
  ) async {
    var value = '1';
    late StateSetter update;
    var completions = 0;

    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return SwiftText(
              value,
              duration: const Duration(milliseconds: 500),
              onEnd: () => completions++,
            );
          },
        ),
      ),
    );

    update(() => value = '888888');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 134));
    final beforeVelocitySample = tester.getSize(find.byType(SwiftText));
    await tester.pump(const Duration(milliseconds: 16));
    final beforeRapidUpdate = tester.getSize(find.byType(SwiftText));
    expect(beforeRapidUpdate.width, greaterThan(beforeVelocitySample.width));

    update(() => value = '22');
    await tester.pump();
    final afterRapidUpdate = tester.getSize(find.byType(SwiftText));

    // Resetting the controller must not reset the presentation to the fully
    // laid-out intermediate target.
    expect(afterRapidUpdate, beforeRapidUpdate);
    expect(tester.getSemantics(find.byType(SwiftText)).label, '22');

    await tester.pump(const Duration(milliseconds: 16));
    final afterMomentumStep = tester.getSize(find.byType(SwiftText));
    // Even though the new target is much narrower, the growing presentation
    // keeps moving for a moment instead of stopping and reversing instantly.
    expect(afterMomentumStep.width, greaterThan(beforeRapidUpdate.width));

    update(() => value = '3333');
    await tester.pump(const Duration(milliseconds: 80));
    update(() => value = '4');
    await tester.pump();
    expect(tester.getSemantics(find.byType(SwiftText)).label, '4');

    // Completion is timed from the latest retarget. A queued implementation
    // would still be replaying the earlier values here.
    await tester.pump(const Duration(milliseconds: 850));
    expect(
      tester.getSize(find.byType(SwiftText)).width,
      lessThan(beforeRapidUpdate.width),
    );
    expect(completions, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('retarget preserves the previous glyph velocity', (tester) async {
    var value = 'A';
    late StateSetter update;

    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return SwiftText(
              value,
              duration: const Duration(milliseconds: 450),
              style: const TextStyle(fontSize: 60),
            );
          },
        ),
      ),
    );

    update(() => value = 'B');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 104));
    final before = presentedGlyphRect(tester, 'B').center;
    await tester.pump(const Duration(milliseconds: 16));
    final atRetarget = presentedGlyphRect(tester, 'B').center;
    final previousStep = atRetarget.dy - before.dy;
    expect(previousStep, lessThan(-0.5));

    update(() => value = 'C');
    await tester.pump();
    expect(
      presentedGlyphRect(tester, 'B').center.dy,
      closeTo(atRetarget.dy, 0.001),
    );
    await tester.pump(const Duration(milliseconds: 16));
    final continued = presentedGlyphRect(tester, 'B').center;
    final continuedStep = continued.dy - atRetarget.dy;
    expect(continuedStep, lessThan(-0.5));
    expect(
      continuedStep.abs() / previousStep.abs(),
      inInclusiveRange(0.6, 1.8),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('multiline transition replaces a shared ordinary-text line', (
    tester,
  ) async {
    var value = 'Первая строка\nВторая строка';
    late StateSetter update;

    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return SwiftText(
              value,
              style: const TextStyle(fontSize: 25),
              textAlign: TextAlign.center,
            );
          },
        ),
      ),
    );

    // SwiftUI replaces ordinary letters even when a whole line is identical;
    // it does not move a sharp shared line to the recentered block geometry.
    update(() => value = 'Первая строка\nСовершенно другая вторая строка');
    await tester.pump();
    final dynamic render = tester.renderObject(find.byType(SwiftText));
    expect(render.debugUnchangedGlyphRects as List, isEmpty);
    await tester.pump(const Duration(milliseconds: 120));
    expect(render.debugUnchangedGlyphRects as List, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.byType(SwiftText)).label,
      'Первая строка\nСовершенно другая вторая строка',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('multiline stagger is one block-wide wave', (tester) async {
    var value = 'AB\nCD';
    late StateSetter update;

    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return SwiftText(value);
          },
        ),
      ),
    );

    update(() => value = 'WX\nYZ');
    await tester.pump();
    final dynamic render = tester.renderObject(find.byType(SwiftText));
    final indices = List<int>.from(render.debugWaveIndices as List);
    final counts = List<int>.from(render.debugWaveCounts as List);
    expect(indices, List<int>.generate(indices.length, (index) => index));
    expect(indices.length, greaterThan(2));
    expect(counts, everyElement(indices.length));
  });

  testWidgets('native 2-to-4 text does not move the shared second line', (
    tester,
  ) async {
    var value = 'Первая строка\nВторая строка';
    late StateSetter update;

    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return SwiftText(
              value,
              duration: const Duration(milliseconds: 550),
              textAlign: TextAlign.center,
            );
          },
        ),
      ),
    );

    update(
      () => value =
          'Короткий заголовок\n'
          'Вторая строка стала заметно длиннее\n'
          'И появилась третья',
    );
    await tester.pump();
    final dynamic render = tester.renderObject(find.byType(SwiftText));
    expect(render.debugUnchangedGlyphRects as List, isEmpty);

    await tester.pump(const Duration(milliseconds: 180));
    expect(render.debugUnchangedGlyphRects as List, isEmpty);
    final blurPasses = render.debugBlurPassCount as int;
    final effectGlyphs = render.debugEffectGlyphCount as int;
    expect(blurPasses, inInclusiveRange(1, 8));
    expect(effectGlyphs, greaterThan(blurPasses));

    for (var frame = 0; frame < 20; frame++) {
      final scales = List<double>.from(render.debugPresentedScales as List);
      expect(scales, everyElement(inInclusiveRange(0.62, 1.0)));
      await tester.pump(const Duration(milliseconds: 30));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('matching numeric slots remain sharp', (tester) async {
    var value = '17';
    late StateSetter update;

    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return SwiftText(value);
          },
        ),
      ),
    );

    update(() => value = '18');
    await tester.pump();
    final dynamic render = tester.renderObject(find.byType(SwiftText));
    expect(render.debugUnchangedGlyphRects as List, hasLength(1));
  });

  testWidgets(
    'stable single-line numeric template keeps non-numeric glyphs sharp',
    (tester) async {
      var value = 'Загрузка: 9%';
      late StateSetter update;

      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return SwiftText(
                value,
                duration: const Duration(milliseconds: 550),
                textAlign: TextAlign.center,
              );
            },
          ),
        ),
      );

      update(() => value = 'Загрузка: 42%');
      await tester.pump();
      final renderBox =
          tester.renderObject(find.byType(SwiftText)) as RenderBox;
      final dynamic render = renderBox;
      var unchanged = List<Rect>.from(render.debugUnchangedGlyphRects as List);
      expect(unchanged, hasLength('Загрузка: %'.runes.length));
      expect(List<int>.from(render.debugWaveIndices as List), [0, 1]);
      final startLeading = renderBox.localToGlobal(unchanged.first.center);
      final startTrailing = renderBox.localToGlobal(unchanged.last.center);

      await tester.pump(const Duration(milliseconds: 220));
      unchanged = List<Rect>.from(render.debugUnchangedGlyphRects as List);
      final movingLeading = renderBox.localToGlobal(unchanged.first.center);
      final movingTrailing = renderBox.localToGlobal(unchanged.last.center);
      expect(movingLeading.dx, lessThan(startLeading.dx));
      expect(movingTrailing.dx, greaterThan(startTrailing.dx));

      await tester.pumpAndSettle();
      update(() => value = 'Осталось: 7 сек.');
      await tester.pump();
      expect(render.debugUnchangedGlyphRects as List, isEmpty);
    },
  );

  testWidgets(
    'multiline with fewer lines and a changed line completes cleanly',
    (tester) async {
      var value = 'Одна строка';
      late StateSetter update;

      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return SwiftText(value, style: const TextStyle(fontSize: 25));
            },
          ),
        ),
      );

      update(
        () => value = 'Первая строка\nВторая строка стала длиннее\nИ третья',
      );
      await tester.pump();
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 30));
      }
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.byType(SwiftText)).label,
        'Первая строка\nВторая строка стала длиннее\nИ третья',
      );
    },
  );

  testWidgets('multiline native cycle retargets immediately', (tester) async {
    const values = <String>[
      'Одна строка',
      'Новый текст\nснова занимает\nтри строки',
      'Первая строка\nВторая строка',
      'Короткий заголовок\nВторая строка стала заметно длиннее\nИ появилась третья',
    ];
    var value = values.first;
    late StateSetter update;
    var completions = 0;

    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return SwiftText(
              value,
              duration: const Duration(milliseconds: 550),
              style: const TextStyle(fontSize: 29),
              textAlign: TextAlign.center,
              onEnd: () => completions++,
            );
          },
        ),
      ),
    );

    for (final next in values.skip(1)) {
      update(() => value = next);
      await tester.pump(const Duration(milliseconds: 180));
      expect(tester.getSemantics(find.byType(SwiftText)).label, next);
      expect(tester.takeException(), isNull);
    }
    update(() => value = values.first);
    await tester.pump();
    expect(tester.getSemantics(find.byType(SwiftText)).label, values.first);

    await tester.pump(const Duration(milliseconds: 950));
    expect(completions, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('completed transitions retain only the stable text layout', (
    tester,
  ) async {
    var value = '1';
    late StateSetter update;

    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return SwiftText(value);
          },
        ),
      ),
    );

    for (final next in <String>['22', '333', '4', '55555']) {
      update(() => value = next);
      await tester.pumpAndSettle();
      final dynamic render = tester.renderObject(find.byType(SwiftText));
      expect(render.debugOwnedLayoutCount as int, 1);
    }
  });

  testWidgets('key transition frames match the visual baseline', (
    tester,
  ) async {
    const goldenKey = ValueKey<String>('numericTextGolden');
    var value = '19';
    late StateSetter update;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 1),
          child: Center(
            child: RepaintBoundary(
              key: goldenKey,
              child: ColoredBox(
                color: const Color(0xff101114),
                child: SizedBox(
                  width: 320,
                  height: 120,
                  child: Center(
                    child: StatefulBuilder(
                      builder: (context, setState) {
                        update = setState;
                        return SwiftText(
                          value,
                          countsDown: false,
                          style: const TextStyle(
                            color: Color(0xfff4f4f5),
                            fontSize: 52,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final golden = find.byKey(goldenKey);
    await expectLater(
      golden,
      matchesGoldenFile('goldens/swift_text_initial.png'),
    );

    update(() => value = '2048');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    await expectLater(
      golden,
      matchesGoldenFile('goldens/swift_text_mid_transition.png'),
    );

    update(() => value = '7');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    await expectLater(
      golden,
      matchesGoldenFile('goldens/swift_text_rapid_retarget.png'),
    );

    await tester.pumpAndSettle();
    await expectLater(
      golden,
      matchesGoldenFile('goldens/swift_text_settled.png'),
    );
  });
}
