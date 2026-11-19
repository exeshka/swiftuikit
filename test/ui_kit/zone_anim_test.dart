import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftuikit/swiftuikit.dart';

import 'test_app.dart';

void main() {
  testWidgets('zone grows over several frames when a header sticks', (
    tester,
  ) async {
    final c = ChromeController();
    await tester.pumpWidget(
      testApp(
        ChromeScaffold(
          controller: c,
          topBar: const ChromeBar(child: SizedBox(height: 52)),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              const SliverChromeInset.top(),
              const SliverToBoxAdapter(child: SizedBox(height: 200)),
              PinnedHeader(height: 56, child: const Text('strip')),
              SliverList.builder(
                itemCount: 40,
                itemBuilder: (_, i) => SizedBox(height: 50, child: Text('r$i')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    final g = await tester.startGesture(const Offset(200, 500));
    final seen = <double>[];
    for (var i = 0; i < 40; i++) {
      await g.moveBy(const Offset(0, -12));
      await tester.pump(const Duration(milliseconds: 16));
      seen.add(c.inset(ChromeEdge.top));
    }
    print(seen.map((e) => e.toStringAsFixed(1)).join(' '));
    await g.up();
  });
}
