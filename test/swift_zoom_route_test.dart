import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftuikit/swiftuikit.dart';

void main() {
  testWidgets('the current PageView item dismisses into its own source', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: _ZoomSources()),
      ),
    );

    final route = SwiftZoomRoute<void>(builder: (_) => const _ZoomViewer());
    navigatorKey.currentState!.push(route);
    await tester.pumpAndSettle();

    double sourceOpacity(String key) {
      return tester
          .widgetList<Opacity>(
            find.ancestor(
              of: find.byKey(ValueKey(key)),
              matching: find.byType(Opacity),
            ),
          )
          .map((opacity) => opacity.opacity)
          .reduce(math.min);
    }

    expect(find.text('Viewer A'), findsOneWidget);
    expect(sourceOpacity('source-a'), 0.0);
    expect(sourceOpacity('source-b'), 1.0);

    await tester.drag(find.byType(PageView), const Offset(0, -420));
    await tester.pumpAndSettle();

    expect(find.text('Viewer B'), findsOneWidget);
    expect(sourceOpacity('source-a'), 1.0);
    expect(sourceOpacity('source-b'), 0.0);
    expect(route.animation!.status, AnimationStatus.completed);
    final viewerState = tester.state(find.byType(_ZoomViewer));

    final dismissGesture = await tester.startGesture(const Offset(400, 300));
    await dismissGesture.moveBy(const Offset(180, 0));
    await tester.pump();

    expect(tester.state(find.byType(_ZoomViewer)), same(viewerState));
    expect(find.text('Viewer B'), findsOneWidget);
    expect(sourceOpacity('source-a'), 1.0);
    expect(sourceOpacity('source-b'), 0.0);

    await dismissGesture.moveBy(const Offset(180, 0));
    await tester.pump();
    await dismissGesture.moveBy(const Offset(180, 0));
    await tester.pump();
    await dismissGesture.up();
    await tester.pump(const Duration(milliseconds: 160));

    expect(route.animation!.status, AnimationStatus.reverse);
    expect(tester.state(find.byType(_ZoomViewer)), same(viewerState));
    expect(find.text('Viewer B'), findsOneWidget);
    final viewerRect = tester.getRect(
      find.byKey(const ValueKey('zoom-viewer')),
    );
    expect(viewerRect.width, lessThan(800));
    expect(viewerRect.center.dx, greaterThan(400));

    for (var frame = 0; frame < 40; frame++) {
      expect(find.byKey(const ValueKey('source-b')), findsOneWidget);
      if (route.animation!.isDismissed) break;
      await tester.pump(const Duration(milliseconds: 16));
    }

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('zoom-viewer')), findsNothing);
    expect(find.byKey(const ValueKey('source-b')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a missing destination uses the route scale fallback', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final currentId = ValueNotifier<String>('a');

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(
          body: Center(
            child: SwiftZoomHero(
              id: 'a',
              child: SizedBox(
                key: ValueKey('fallback-source'),
                width: 120,
                height: 180,
              ),
            ),
          ),
        ),
      ),
    );

    final route = SwiftZoomRoute<void>(
      builder: (_) => ValueListenableBuilder<String>(
        valueListenable: currentId,
        builder: (_, id, _) {
          return SwiftZoomHero(
            id: id,
            child: const ColoredBox(
              key: ValueKey('fallback-page'),
              color: Colors.blue,
            ),
          );
        },
      ),
    );
    navigatorKey.currentState!.push(route);
    await tester.pumpAndSettle();

    currentId.value = 'missing';
    await tester.pump();
    navigatorKey.currentState!.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final fallbackPage = find.byKey(const ValueKey('fallback-page'));
    expect(fallbackPage, findsOneWidget);
    expect(
      tester
          .widgetList<FadeTransition>(
            find.ancestor(
              of: fallbackPage,
              matching: find.byType(FadeTransition),
            ),
          )
          .any((fade) => fade.opacity.value < 1.0),
      isTrue,
    );

    await tester.pumpAndSettle();

    expect(fallbackPage, findsNothing);
    expect(tester.takeException(), isNull);
    currentId.dispose();
  });

  testWidgets('the first source survives repeated push and drag pop flights', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: _ZoomSources()),
      ),
    );

    final initialSourceRect = tester.getRect(
      find.byKey(const ValueKey('source-a')),
    );

    double sourceOpacity(String key) {
      return tester
          .widgetList<Opacity>(
            find.ancestor(
              of: find.byKey(ValueKey(key)),
              matching: find.byType(Opacity),
            ),
          )
          .map((opacity) => opacity.opacity)
          .reduce(math.min);
    }

    for (var cycle = 0; cycle < 3; cycle++) {
      final route = SwiftZoomRoute<void>(
        dismissDirection: SwiftZoomDismissDirection.horizontal,
        builder: (_) => const SwiftZoomHero(
          id: 'a',
          child: ColoredBox(
            key: ValueKey('repeated-first-page'),
            color: Colors.blue,
          ),
        ),
      );
      navigatorKey.currentState!.push(route);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('repeated-first-page')), findsOneWidget);
      expect(sourceOpacity('source-a'), 0.0);
      expect(sourceOpacity('source-b'), 1.0);

      final dismissGesture = await tester.startGesture(const Offset(400, 300));
      await dismissGesture.moveBy(const Offset(24, 8));
      await tester.pump();
      await dismissGesture.moveBy(const Offset(420, 30));
      await tester.pump();
      await dismissGesture.up();

      for (var frame = 0; frame < 50; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(find.byKey(const ValueKey('source-a')), findsOneWidget);
        if (route.animation!.isDismissed) break;
      }
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('repeated-first-page')), findsNothing);
      expect(
        tester.getRect(find.byKey(const ValueKey('source-a'))),
        initialSourceRect,
      );
      expect(sourceOpacity('source-a'), 1.0);
      expect(sourceOpacity('source-b'), 1.0);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('a second zoom does not fade the closing hero', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    SwiftZoomRoute<void>? secondRoute;

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: _ZoomSources()),
      ),
    );

    final firstRoute = SwiftZoomRoute<void>(
      dismissDirection: SwiftZoomDismissDirection.horizontal,
      builder: (_) => const SwiftZoomHero(
        id: 'a',
        child: ColoredBox(key: ValueKey('first-zoom-page'), color: Colors.blue),
      ),
    );
    navigatorKey.currentState!.push(firstRoute);
    await tester.pumpAndSettle();

    final dismissGesture = await tester.startGesture(const Offset(400, 300));
    await dismissGesture.moveBy(const Offset(430, 0));
    await tester.pump();
    await dismissGesture.up();
    await tester.pump(const Duration(milliseconds: 16));

    expect(firstRoute.animation!.status, AnimationStatus.reverse);

    secondRoute = SwiftZoomRoute<void>(
      builder: (_) => const SwiftZoomHero(
        id: 'b',
        child: ColoredBox(
          key: ValueKey('second-zoom-page'),
          color: Colors.green,
        ),
      ),
    );
    navigatorKey.currentState!.push(secondRoute);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 96));

    expect(secondRoute.animation!.status, AnimationStatus.forward);
    expect(find.byKey(const ValueKey('first-zoom-page')), findsOneWidget);
    final outgoingFlightFades = tester.widgetList<FadeTransition>(
      find.ancestor(
        of: find.byKey(const ValueKey('first-zoom-page')),
        matching: find.byType(FadeTransition),
      ),
    );
    expect(outgoingFlightFades, isNotEmpty);
    expect(
      outgoingFlightFades.every((fade) => fade.opacity.value == 1.0),
      isTrue,
    );

    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const ValueKey('second-zoom-page'))),
      const Size(800, 600),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('drag and pop keep the selected PageController index', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final viewerKey = GlobalKey<_ControlledZoomViewerState>();
    final pageChanges = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: _ZoomSources()),
      ),
    );

    final route = SwiftZoomRoute<void>(
      builder: (_) =>
          _ControlledZoomViewer(key: viewerKey, onPageChanged: pageChanges.add),
    );
    navigatorKey.currentState!.push(route);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    final pageViewStateDuringFlight = tester.state(
      find.byKey(const ValueKey('controlled-page-view')),
    );

    await tester.pumpAndSettle();

    expect(viewerKey.currentState!.currentIndex, 2);
    expect(find.text('3 / 4'), findsOneWidget);
    expect(
      tester.state(find.byKey(const ValueKey('controlled-page-view'))),
      same(pageViewStateDuringFlight),
    );
    pageChanges.clear();

    final dismissGesture = await tester.startGesture(const Offset(400, 300));
    await dismissGesture.moveBy(const Offset(180, 0));
    await tester.pump();

    expect(viewerKey.currentState!.currentIndex, 2);
    expect(find.text('3 / 4'), findsOneWidget);
    expect(pageChanges, isEmpty);

    await dismissGesture.moveBy(const Offset(180, 0));
    await tester.pump();
    await dismissGesture.moveBy(const Offset(180, 0));
    await dismissGesture.up();
    await tester.pump(const Duration(milliseconds: 120));

    expect(viewerKey.currentState!.currentIndex, 2);
    expect(pageChanges, isEmpty);
    expect(route.animation!.status, AnimationStatus.reverse);

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('drag keeps an item selected by scrolling after push', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final viewerKey = GlobalKey<_ControlledZoomViewerState>();
    final pageChanges = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: _ZoomSources()),
      ),
    );

    final route = SwiftZoomRoute<void>(
      dismissDirection: SwiftZoomDismissDirection.horizontal,
      builder: (_) => _ControlledZoomViewer(
        key: viewerKey,
        initialIndex: 0,
        onPageChanged: pageChanges.add,
      ),
    );
    navigatorKey.currentState!.push(route);
    await tester.pumpAndSettle();

    final pageView = find.byKey(const ValueKey('controlled-page-view'));
    final pageViewState = tester.state(pageView);

    await tester.drag(pageView, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.drag(pageView, const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(viewerKey.currentState!.currentIndex, 2);
    expect(viewerKey.currentState!.pageController.page, 2.0);
    expect(find.text('3 / 4'), findsOneWidget);

    pageChanges.clear();
    final dismissGesture = await tester.startGesture(const Offset(400, 300));
    await dismissGesture.moveBy(const Offset(24, 12));
    await tester.pump();
    await dismissGesture.moveBy(const Offset(96, 58));
    await tester.pump();

    expect(viewerKey.currentState!.currentIndex, 2);
    expect(viewerKey.currentState!.pageController.page, 2.0);
    expect(find.text('3 / 4'), findsOneWidget);
    expect(tester.state(pageView), same(pageViewState));
    expect(pageChanges, isEmpty);
    expect(tester.getRect(pageView).center.dy, greaterThan(300.0));

    await dismissGesture.cancel();
    await tester.pumpAndSettle();

    expect(viewerKey.currentState!.currentIndex, 2);
    expect(viewerKey.currentState!.pageController.page, 2.0);
    expect(find.text('3 / 4'), findsOneWidget);
    expect(tester.state(pageView), same(pageViewState));
    expect(pageChanges, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('diagonal drag reveals the background without an axis jump', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: _ZoomSources()),
      ),
    );

    final route = SwiftZoomRoute<void>(
      builder: (_) => const SwiftZoomHero(
        id: 'a',
        child: ColoredBox(
          key: ValueKey('continuous-drag-page'),
          color: Colors.blue,
        ),
      ),
    );
    navigatorKey.currentState!.push(route);
    await tester.pumpAndSettle();

    double backgroundScale() {
      final transforms = tester
          .widgetList<Transform>(
            find.ancestor(
              of: find.byKey(const ValueKey('zoom-sources')),
              matching: find.byType(Transform),
            ),
          )
          .map((transform) => transform.transform.storage[0])
          .toList();
      return transforms.where((scale) => scale < 1.0).reduce(math.min);
    }

    bool hasFullBackgroundRadius() {
      return tester
          .widgetList<ClipRSuperellipse>(
            find.ancestor(
              of: find.byKey(const ValueKey('zoom-sources')),
              matching: find.byType(ClipRSuperellipse),
            ),
          )
          .any(
            (clip) =>
                clip.borderRadius ==
                const BorderRadius.all(Radius.circular(38)),
          );
    }

    final restingScale = backgroundScale();
    expect(hasFullBackgroundRadius(), isTrue);
    final drag = await tester.startGesture(const Offset(400, 300));
    await drag.moveBy(const Offset(90, 100));
    await tester.pump();
    final verticalDominantScale = backgroundScale();
    expect(hasFullBackgroundRadius(), isTrue);

    await drag.moveBy(const Offset(20, 0));
    await tester.pump();
    final horizontalDominantScale = backgroundScale();
    expect(hasFullBackgroundRadius(), isTrue);

    expect(verticalDominantScale, greaterThan(restingScale));
    expect(
      horizontalDominantScale,
      greaterThanOrEqualTo(verticalDominantScale),
    );

    await drag.cancel();
    for (var frame = 0; frame < 40; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(backgroundScale(), greaterThanOrEqualTo(restingScale - 0.0001));
    }
    await tester.pumpAndSettle();

    expect(backgroundScale(), closeTo(restingScale, 0.0001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the live hero crossfades at both ends of the flight', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: _ZoomSources()),
      ),
    );

    final route = SwiftZoomRoute<void>(
      builder: (_) => const SwiftZoomHero(
        id: 'a',
        child: ColoredBox(key: ValueKey('crossfade-page'), color: Colors.blue),
      ),
    );
    navigatorKey.currentState!.push(route);
    await tester.pump();
    route.routeController!.value = 0.1;
    await tester.pump();

    expect(
      tester
          .widgetList<Opacity>(
            find.ancestor(
              of: find.byKey(const ValueKey('source-a')),
              matching: find.byType(Opacity),
            ),
          )
          .any((opacity) => opacity.opacity > 0.0 && opacity.opacity < 1.0),
      isTrue,
    );
    expect(
      tester
          .widgetList<Opacity>(
            find.ancestor(
              of: find.byKey(const ValueKey('crossfade-page')),
              matching: find.byType(Opacity),
            ),
          )
          .every((opacity) => opacity.opacity == 1.0),
      isTrue,
    );

    await tester.pumpAndSettle();
    navigatorKey.currentState!.pop();
    await tester.pump();
    route.routeController!.value = 0.1;
    await tester.pump();

    expect(
      tester
          .widgetList<Opacity>(
            find.ancestor(
              of: find.byKey(const ValueKey('source-a')),
              matching: find.byType(Opacity),
            ),
          )
          .any((opacity) => opacity.opacity > 0.0 && opacity.opacity < 1.0),
      isTrue,
    );
    expect(
      tester
          .widgetList<Opacity>(
            find.ancestor(
              of: find.byKey(const ValueKey('crossfade-page')),
              matching: find.byType(Opacity),
            ),
          )
          .every((opacity) => opacity.opacity == 1.0),
      isTrue,
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('drag rounds the page and any direction accepts upward pop', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: _ZoomSources()),
      ),
    );

    final route = SwiftZoomRoute<void>(
      builder: (_) => const SwiftZoomHero(
        id: 'a',
        child: ColoredBox(
          key: ValueKey('rounded-drag-page'),
          color: Colors.blue,
        ),
      ),
    );
    navigatorKey.currentState!.push(route);
    await tester.pumpAndSettle();

    final drag = await tester.startGesture(const Offset(400, 300));
    await drag.moveBy(const Offset(100, 70));
    await tester.pump();

    expect(
      tester
          .widgetList<ClipRSuperellipse>(
            find.ancestor(
              of: find.byKey(const ValueKey('rounded-drag-page')),
              matching: find.byType(ClipRSuperellipse),
            ),
          )
          .any(
            (clip) =>
                clip.borderRadius ==
                const BorderRadius.all(Radius.circular(38)),
          ),
      isTrue,
    );

    await drag.cancel();
    await tester.pumpAndSettle();

    final upwardDrag = await tester.startGesture(const Offset(400, 500));
    await upwardDrag.moveBy(const Offset(0, -180));
    await tester.pump();
    await upwardDrag.moveBy(const Offset(0, -180));
    await tester.pump();
    await upwardDrag.moveBy(const Offset(0, -180));
    await tester.pump();
    await upwardDrag.up();
    await tester.pump(const Duration(milliseconds: 80));

    expect(route.animation!.status, AnimationStatus.reverse);

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

class _ZoomSources extends StatelessWidget {
  const _ZoomSources();

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('zoom-sources'),
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: const [
        SwiftZoomHero(
          id: 'a',
          borderRadius: BorderRadius.all(Radius.circular(24)),
          child: ColoredBox(
            key: ValueKey('source-a'),
            color: Colors.orange,
            child: SizedBox(width: 120, height: 180),
          ),
        ),
        SwiftZoomHero(
          id: 'b',
          borderRadius: BorderRadius.all(Radius.circular(24)),
          child: ColoredBox(
            key: ValueKey('source-b'),
            color: Colors.green,
            child: SizedBox(width: 120, height: 180),
          ),
        ),
        SwiftZoomHero(
          id: 'c',
          borderRadius: BorderRadius.all(Radius.circular(24)),
          child: ColoredBox(
            key: ValueKey('source-c'),
            color: Colors.purple,
            child: SizedBox(width: 120, height: 180),
          ),
        ),
        SwiftZoomHero(
          id: 'd',
          borderRadius: BorderRadius.all(Radius.circular(24)),
          child: ColoredBox(
            key: ValueKey('source-d'),
            color: Colors.teal,
            child: SizedBox(width: 120, height: 180),
          ),
        ),
      ],
    );
  }
}

class _ZoomViewer extends StatefulWidget {
  const _ZoomViewer();

  @override
  State<_ZoomViewer> createState() => _ZoomViewerState();
}

class _ZoomViewerState extends State<_ZoomViewer> {
  static const ids = ['a', 'b'];
  var currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SwiftZoomHero(
      id: ids[currentIndex],
      borderRadius: const BorderRadius.all(Radius.circular(38)),
      child: ColoredBox(
        key: const ValueKey('zoom-viewer'),
        color: Colors.black,
        child: PageView(
          scrollDirection: Axis.vertical,
          onPageChanged: (index) => setState(() => currentIndex = index),
          children: const [
            ColoredBox(
              color: Colors.blue,
              child: Center(child: Text('Viewer A')),
            ),
            ColoredBox(
              color: Colors.green,
              child: Center(child: Text('Viewer B')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlledZoomViewer extends StatefulWidget {
  const _ControlledZoomViewer({
    super.key,
    this.initialIndex = 2,
    required this.onPageChanged,
  });

  final int initialIndex;
  final ValueChanged<int> onPageChanged;

  @override
  State<_ControlledZoomViewer> createState() => _ControlledZoomViewerState();
}

class _ControlledZoomViewerState extends State<_ControlledZoomViewer> {
  late final PageController pageController;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    pageController = PageController(initialPage: currentIndex);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SwiftZoomHero(
      id: const ['a', 'b', 'c', 'd'][currentIndex],
      child: PageView.builder(
        key: const ValueKey('controlled-page-view'),
        controller: pageController,
        scrollDirection: Axis.vertical,
        itemCount: 4,
        onPageChanged: (index) {
          widget.onPageChanged(index);
          setState(() => currentIndex = index);
        },
        itemBuilder: (_, index) {
          return ColoredBox(
            color: Colors.primaries[index],
            child: Center(child: Text('${index + 1} / 4')),
          );
        },
      ),
    );
  }
}
