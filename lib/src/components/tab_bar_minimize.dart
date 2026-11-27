import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Decides when a [GlassTabBar] collapses and expands while a page scrolls (iOS 26 `tabBarMinimizeBehavior(.onScrollDown)`), with
/// hysteresis: the bar collapses once the page has been scrolled down by [collapseAfter] in one go, and expands again only after
/// it has been scrolled back up by [expandAfter] in one go (or when the page is back at its top). A flick of a few points the other
/// way, a bounce at the end of the list or a finger that wobbles does not toggle it, which a plain "direction changed" rule does
/// all the time.
///
/// ```dart
/// final minimize = TabBarMinimizeController();
/// ...
/// TabBarMinimizeScope(
///   controller: minimize,
///   child: pages,
/// ),
/// ValueListenableBuilder<bool>(
///   valueListenable: minimize,
///   builder: (context, minimized, _) => GlassTabBar(minimized: minimized, onExpand: minimize.expand, ...),
/// )
/// ```
class TabBarMinimizeController extends ValueNotifier<bool> {
  TabBarMinimizeController({this.collapseAfter = 80, this.expandAfter = 56})
    : super(false);

  /// How far the page has to be scrolled down, in one go, for the bar to collapse (logical px).
  final double collapseAfter;

  /// How far the page has to be scrolled back up, in one go, for the bar to expand (logical px).
  final double expandAfter;

  double _run = 0; // how far the current scroll direction has gone
  int _dir = 0; // 1 down (content moves up), -1 up

  bool get minimized => value;

  /// Expands the bar (a tap on the collapsed button).
  void expand() {
    _run = 0;
    value = false;
  }

  /// Feed a scroll notification of a vertical page; returns false (never absorbs it).
  bool handle(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    final m = n.metrics;
    if (n is ScrollStartNotification) {
      _run = 0;
      _dir = 0;
    } else if (n is ScrollUpdateNotification) {
      // a bounce past the ends is not the user scrolling the page
      if (m.outOfRange) return false;
      final d = n.scrollDelta ?? 0;
      if (d == 0) return false;
      final dir = d > 0 ? 1 : -1;
      if (dir != _dir) {
        _dir = dir;
        _run = 0;
      }
      _run += d.abs();
      if (dir > 0 &&
          !value &&
          _run >= collapseAfter &&
          m.pixels > collapseAfter) {
        value = true;
      } else if (dir < 0 && value && (_run >= expandAfter || m.pixels <= 0)) {
        value = false;
      }
    }
    return false;
  }
}

/// Feeds the vertical scrolling of [child] to a [TabBarMinimizeController].
class TabBarMinimizeScope extends StatelessWidget {
  const TabBarMinimizeScope({
    super.key,
    required this.controller,
    required this.child,
  });

  final TabBarMinimizeController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: controller.handle,
      child: child,
    );
  }
}
