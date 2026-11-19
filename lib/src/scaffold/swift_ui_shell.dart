import 'package:flutter/widgets.dart';

import '../components/liquid_glass.dart' show LiquidGlassGroup;
import '../theme/swift_ui_theme.dart';
import '../util/size_reporter.dart';

/// The height (bottom) a surrounding [SwiftUiShell] covers with its bar. A `ChromeScaffold` / `SwiftUiScaffold` below it lifts its
/// content and its own bottom bar by this much and lets its bottom blur zone cover the shell's bar.
class SwiftUiShellScope extends InheritedWidget {
  const SwiftUiShellScope({
    super.key,
    required this.bottomInset,
    required super.child,
  });

  final double bottomInset;

  /// The inset of the nearest shell, 0 outside one. Rebuilds the caller when it changes.
  static double bottomOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<SwiftUiShellScope>()
          ?.bottomInset ??
      0;

  @override
  bool updateShouldNotify(SwiftUiShellScope old) =>
      old.bottomInset != bottomInset;
}

/// The part of an app that stays while the pages change: a bar (the tab bar) over the bottom of [body]. The pages under it are
/// independent screens, each with its own header, its own scroll and its own edge effect; this widget is the one place that
/// knows about the bar, like the shell route of a router (`StatefulShellRoute`, `AutoTabsRouter`) but without depending on one:
/// give it whatever shows the pages as [body] (a [SwiftUiPageSwitcher], a router's child) and the bar as [bottomBar].
///
///  * The bar floats over the content, as iOS 26's does; the pages under it get the room for it (their content, their bottom
///    bars) and their bottom blur zone covers it, so no page declares the bar.
///  * The bar is built once, whatever the pages do: switching a page does not touch it (no flicker).
///  * While the keyboard is open the bar slides away ([hideBarWithKeyboard]) and the pages get the room back.
///  * Pages are still free to put a bar of their own (a composer) above this one.
///
/// ```dart
/// SwiftUiShell(
///   bottomBar: GlassTabBar(tabs: tabs, selectedIndex: i, onSelected: select),
///   body: SwiftUiPageSwitcher(index: i, children: const [InboxPage(), TasksPage()]),
/// )
/// ```
class SwiftUiShell extends StatefulWidget {
  const SwiftUiShell({
    super.key,
    required this.body,
    this.bottomBar,
    this.hideBarWithKeyboard = true,
    this.bottomBarSafeAreaShare,
  });

  final Widget body;

  /// Placed over the bottom of [body]. A glass tab bar, or anything.
  final Widget? bottomBar;

  /// Slide the bar away while the keyboard is up.
  final bool hideBarWithKeyboard;

  /// 0..1: the share of the bottom safe area (the home indicator) kept below the bar (null: [SwiftUiChromeTheme.bottomBarSafeAreaShare]).
  final double? bottomBarSafeAreaShare;

  @override
  State<SwiftUiShell> createState() => _SwiftUiShellState();
}

class _SwiftUiShellState extends State<SwiftUiShell>
    with SingleTickerProviderStateMixin {
  // 1 = the bar is shown, 0 = slid away (the keyboard)
  late final AnimationController _shown = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  );
  double _barHeight = 0;

  @override
  void dispose() {
    _shown.dispose();
    super.dispose();
  }

  void _onSize(double h) {
    if (h == _barHeight) return;
    setState(() => _barHeight = h);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final share =
        widget.bottomBarSafeAreaShare ??
        SwiftUiTheme.of(context).chrome.bottomBarSafeAreaShare;
    final lift = mq.padding.bottom * share;
    final hide = widget.hideBarWithKeyboard && mq.viewInsets.bottom > 0;
    if (hide && _shown.value > 0 && _shown.status != AnimationStatus.reverse) {
      _shown.reverse();
    } else if (!hide &&
        _shown.value < 1 &&
        _shown.status != AnimationStatus.forward) {
      _shown.forward();
    }
    final bar = widget.bottomBar;
    // the pages see no home-indicator area of their own: the bar's block (the lift plus the bar) replaces it
    final pageData = mq.copyWith(
      padding: mq.padding.copyWith(bottom: 0),
      viewPadding: mq.viewPadding.copyWith(bottom: 0),
    );
    return AnimatedBuilder(
      animation: _shown,
      builder: (context, _) {
        final k = Curves.easeOutCubic.transform(_shown.value);
        final block = bar == null ? 0.0 : (lift + _barHeight) * k;
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: SwiftUiShellScope(
                bottomInset: block,
                child: MediaQuery(data: pageData, child: widget.body),
              ),
            ),
            if (bar != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: lift - (lift + _barHeight) * (1 - k),
                child: IgnorePointer(
                  ignoring: k < 0.5,
                  child: SizeReporter(
                    onSize: _onSize,
                    child: LiquidGlassGroup(child: bar),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
