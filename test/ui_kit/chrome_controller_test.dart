import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftuikit/swiftuikit.dart';

void main() {
  group('ChromeController', () {
    testWidgets('sums heights per edge and tracks padding', (tester) async {
      final c = ChromeController();
      addTearDown(c.dispose);
      c.register(ChromeEdge.top, height: 52);
      c.register(ChromeEdge.top, height: 36, padding: 0, sticky: true);
      c.register(ChromeEdge.bottom, height: 48);
      expect(c.inset(ChromeEdge.top), 88);
      expect(c.padding(ChromeEdge.top), 52);
      expect(c.fixedInset(ChromeEdge.top), 52);
      expect(c.inset(ChromeEdge.bottom), 48);
      expect(c.padding(ChromeEdge.bottom), 48);
    });

    testWidgets('minPadding falls back to padding and is clamped', (
      tester,
    ) async {
      final c = ChromeController();
      addTearDown(c.dispose);
      c.register(ChromeEdge.top, height: 108, padding: 108, minPadding: 52);
      c.register(ChromeEdge.top, height: 10);
      expect(c.minPadding(ChromeEdge.top), 62);
    });

    testWidgets('update without animation is immediate and notifies', (
      tester,
    ) async {
      final c = ChromeController();
      addTearDown(c.dispose);
      final e = c.register(ChromeEdge.top, height: 50);
      var n = 0;
      c.addListener(() => n++);
      e.update(height: 80);
      expect(c.inset(ChromeEdge.top), 80);
      expect(
        c.padding(ChromeEdge.top),
        80,
        reason: 'padding follows height by default',
      );
      expect(n, 1);
    });

    testWidgets('animated update eases to the target over the duration', (
      tester,
    ) async {
      final c = ChromeController();
      addTearDown(c.dispose);
      final e = c.register(ChromeEdge.top, height: 0);
      e.update(
        height: 100,
        animate: true,
        duration: const Duration(milliseconds: 200),
      );
      expect(c.targetInset(ChromeEdge.top), 100);
      await tester.pump(); // first frame: animation starts
      await tester.pump(const Duration(milliseconds: 100));
      final mid = c.inset(ChromeEdge.top);
      expect(mid, greaterThan(10));
      expect(mid, lessThan(100));
      await tester.pump(const Duration(milliseconds: 150));
      expect(c.inset(ChromeEdge.top), 100);
      // no frames left scheduled
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('release removes the entry; animated release shrinks first', (
      tester,
    ) async {
      final c = ChromeController();
      addTearDown(c.dispose);
      final a = c.register(ChromeEdge.top, height: 40);
      final b = c.register(ChromeEdge.top, height: 60);
      a.release();
      expect(c.inset(ChromeEdge.top), 60);
      expect(a.isReleased, isTrue);
      b.release(animate: true, duration: const Duration(milliseconds: 100));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(c.inset(ChromeEdge.top), inExclusiveRange(0, 60));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(c.inset(ChromeEdge.top), 0);
      expect(c.entries(ChromeEdge.top), isEmpty);
    });

    testWidgets('stuck overlays are ordered by the moment they stuck', (
      tester,
    ) async {
      final c = ChromeController();
      addTearDown(c.dispose);
      final a = c.register(ChromeEdge.top, height: 0, sticky: true);
      final b = c.register(ChromeEdge.top, height: 0, sticky: true);
      b.setOverlay(const SizedBox(), height: 30);
      a.setOverlay(const SizedBox(), height: 30);
      expect(c.overlayEntries(), hasLength(2));
      expect(
        c.stuckOverlays(),
        isEmpty,
        reason: 'mounted overlays are painted only while stuck',
      );
      b.setStuck(true);
      a.setStuck(true);
      expect(c.stuckOverlays(), [b, a]);
      b.setStuck(false);
      expect(c.stuckOverlays(), [a]);
    });

    testWidgets('updates on a released entry are ignored', (tester) async {
      final c = ChromeController();
      addTearDown(c.dispose);
      final e = c.register(ChromeEdge.top, height: 40);
      e.release();
      e.update(height: 99);
      expect(c.inset(ChromeEdge.top), 0);
    });
  });
}
