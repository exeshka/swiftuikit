import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftuikit/swiftuikit.dart';

import 'test_app.dart';

void main() {
  testWidgets('pinned strip moves with the content when pulled down', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        ChromeScaffold(
          topBar: const ChromeBar(child: SizedBox(height: 52)),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              const SliverChromeInset.top(),
              const SliverToBoxAdapter(
                child: SizedBox(height: 200, child: Text('banner')),
              ),
              PinnedHeader(
                height: 56,
                animateZone: false,
                child: const Text('strip'),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 60, child: Text('title')),
              ),
              SliverList.builder(
                itemCount: 30,
                itemBuilder: (_, i) => SizedBox(height: 50, child: Text('r$i')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    List<double> ys(String s) => [
      for (final e in find.text(s).evaluate())
        tester.getTopLeft(find.byElementPredicate((x) => x == e)).dy,
    ];
    double y(String s) => ys(s).first;
    final s0 = y('strip'), t0 = y('title'), b0 = y('banner');
    final g = await tester.startGesture(const Offset(200, 300));
    for (var i = 0; i < 8; i++) {
      await g.moveBy(const Offset(0, 25));
      await tester.pump(const Duration(milliseconds: 16));
    }
    final d = y('banner') - b0;
    expect(d, greaterThan(50));
    for (final v in ys('strip')) {
      expect(
        v - s0,
        closeTo(d, 1),
        reason: 'the strip travels with the content, not twice as far',
      );
    }
    expect(y('title') - t0, closeTo(d, 1));
    await g.up();
  });
}
