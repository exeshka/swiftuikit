import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftuikit/swiftuikit.dart';

import 'test_app.dart';

Widget bar({int n = 3, int selected = 0, bool minimized = false, ValueChanged<int>? onSelected, VoidCallback? onExpand}) =>
    testApp(
      Align(
        alignment: Alignment.bottomCenter,
        child: GlassTabBar(
          tabs: [for (var i = 0; i < n; i++) GlassTab(icon: const SizedBox(width: 26, height: 26), label: 'Tab $i')],
          selectedIndex: selected,
          onSelected: onSelected ?? (_) {},
          minimized: minimized,
          onExpand: onExpand,
        ),
      ),
    );

void main() {
  testWidgets('native size: 62 pt high, 3 tabs 274 pt wide (measured on a TabView)', (tester) async {
    setPhoneSize(tester);
    await tester.pumpWidget(bar());
    final surface = tester.getSize(find.byType(GlassSurface).first);
    expect(surface.width, closeTo(3 * 85.7 + 17, 0.01));
    expect(surface.height, 62);
  });

  testWidgets('five tabs shrink to leave ~21 pt of margin on a 402 pt screen', (tester) async {
    setPhoneSize(tester);
    await tester.pumpWidget(bar(n: 5));
    final surface = tester.getSize(find.byType(GlassSurface).first);
    expect(surface.width, lessThanOrEqualTo(402 - 43 + 0.01));
    expect(surface.width, greaterThan(350));
  });

  testWidgets('a tap selects the tab', (tester) async {
    setPhoneSize(tester);
    int? got;
    await tester.pumpWidget(bar(onSelected: (i) => got = i));
    await tester.tap(find.text('Tab 2').first);
    await tester.pump(const Duration(milliseconds: 400));
    expect(got, 2);
  });

  testWidgets('minimized: collapses to a 47.7 pt round button at the left, a tap expands it', (tester) async {
    setPhoneSize(tester);
    var expanded = 0;
    await tester.pumpWidget(bar(minimized: true, onExpand: () => expanded++));
    await tester.pump(const Duration(seconds: 2));
    final surface = find.byType(GlassSurface).first;
    expect(tester.getSize(surface).width, closeTo(47.7, 0.1));
    expect(tester.getSize(surface).height, closeTo(47.7, 0.1));
    expect(tester.getTopLeft(surface).dx, closeTo(28.3, 0.1));
    await tester.tapAt(tester.getCenter(surface));
    await tester.pump(const Duration(milliseconds: 400));
    expect(expanded, 1);
  });

  testWidgets('accessory: a plate over the bar (47.7 pt, 8.7 pt gap) that moves in line with the collapsed button', (tester) async {
    setPhoneSize(tester);
    var taps = 0;
    final placements = <GlassTabBarAccessoryPlacement>[];
    Widget acc({required bool minimized}) => testApp(
      Align(
        alignment: Alignment.bottomCenter,
        child: GlassTabBar(
          tabs: [for (var i = 0; i < 3; i++) GlassTab(icon: const SizedBox(width: 26, height: 26), label: 'Tab $i')],
          selectedIndex: 0,
          onSelected: (_) {},
          minimized: minimized,
          accessoryBuilder: (context, p) {
            placements.add(p);
            return Text(p.name);
          },
          onAccessoryTap: () => taps++,
        ),
      ),
    );
    await tester.pumpWidget(acc(minimized: false));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('expanded'), findsOneWidget);
    final surfaces = find.byType(GlassSurface);
    // the plate and the bar share the same width (402 - 43) and the plate is 47.7 pt high, 8.7 pt over the bar
    final plate = tester.getRect(surfaces.at(0)).height < 50 ? tester.getRect(surfaces.at(0)) : tester.getRect(surfaces.at(1));
    final bar = tester.getRect(surfaces.at(0)).height < 50 ? tester.getRect(surfaces.at(1)) : tester.getRect(surfaces.at(0));
    expect(plate.height, closeTo(47.7, 0.1));
    expect(plate.width, closeTo(402 - 43, 0.1));
    expect(bar.width, closeTo(402 - 43, 0.1));
    expect(bar.top - plate.bottom, closeTo(8.7, 0.1));
    await tester.tap(find.text('expanded'));
    expect(taps, 1);
    await tester.pumpWidget(acc(minimized: true));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('inline'), findsOneWidget);
    final inline = tester.getRect(find.byType(GlassSurface).at(1).evaluate().isEmpty ? surfaces.at(0) : surfaces.at(0));
    expect(inline.height, greaterThan(0));
    expect(placements, contains(GlassTabBarAccessoryPlacement.inline));
  });

  testWidgets('accessory: the progress builder follows the collapse continuously, the builder cross-fades both layouts', (tester) async {
    setPhoneSize(tester);
    final seen = <double>[];
    Widget host({required bool minimized, bool progress = true}) => testApp(
      Align(
        alignment: Alignment.bottomCenter,
        child: GlassTabBar(
          tabs: [for (var i = 0; i < 3; i++) GlassTab(icon: const SizedBox(width: 26, height: 26), label: 'T$i')],
          selectedIndex: 0,
          onSelected: (_) {},
          minimized: minimized,
          accessoryProgressBuilder: progress
              ? (context, p) {
                  seen.add(p);
                  return const SizedBox();
                }
              : null,
          accessoryBuilder: progress ? null : (context, placement) => Text(placement.name),
        ),
      ),
    );
    await tester.pumpWidget(host(minimized: false));
    await tester.pump(const Duration(seconds: 1));
    expect(seen.last, closeTo(0, 0.001));
    seen.clear();
    await tester.pumpWidget(host(minimized: true));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 25));
    }
    expect(seen.where((p) => p > 0.1 && p < 0.9), isNotEmpty, reason: 'passes through the middle');
    await tester.pump(const Duration(seconds: 2));
    expect(seen.last, closeTo(1, 0.01));

    // the builder: in the middle of the transition both layouts exist (cross-fade), at rest one of them
    await tester.pumpWidget(host(minimized: false, progress: false));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('inline'), findsNothing);
    await tester.pumpWidget(host(minimized: true, progress: false));
    var both = false;
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      if (find.text('expanded').evaluate().isNotEmpty && find.text('inline').evaluate().isNotEmpty) both = true;
    }
    expect(both, isTrue);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('expanded'), findsNothing);
  });
}
