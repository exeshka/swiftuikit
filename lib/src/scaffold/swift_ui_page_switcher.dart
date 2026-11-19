import 'package:flutter/widgets.dart';

import '../theme/swift_ui_theme.dart';

/// How [SwiftUiPageSwitcher] moves from one page to another. None of them draws a page into an offscreen layer (`Opacity`,
/// `FadeTransition`, `ShaderMask`...): a backdrop blur or a glass plate inside such a layer reads an empty backdrop and stops
/// working, so the pages are only ever moved or covered, never faded.
enum SwiftUiSwitchTransition {
  /// No animation: the page is replaced at once.
  none,

  /// The outgoing page is covered by the page background, then uncovered to show the incoming one (the "fade through" of
  /// Material, done with a plain translucent cover instead of an opacity layer). The default.
  fadeThrough,

  /// The pages slide sideways, the incoming one from the side of its index.
  slide,
}

/// Shows one of [children] and switches between them with an animation. Nothing else: no tab bar, no router, no inset
/// bookkeeping; put the bar where you want it and give this the pages. Drive [index] from wherever your app keeps its
/// selection (a `setState`, a router's tab index in its builder, a bloc).
///
///  * The pages keep their state while they are not shown (like an `IndexedStack`): scroll positions, text, controllers.
///    A page that is not shown does not paint, take touches or tick its animations.
///  * With [lazy] a page is built the first time it is shown, not at start.
///  * The transition never uses an offscreen layer, so the blur zones of a `ChromeScaffold` and the liquid glass plates keep
///    working while it runs (see [SwiftUiSwitchTransition]).
///
/// ```dart
/// SwiftUiPageSwitcher(
///   index: tab,
///   children: const [ChatsPage(), SettingsPage()],
/// )
/// ```
class SwiftUiPageSwitcher extends StatefulWidget {
  const SwiftUiPageSwitcher({
    super.key,
    required this.index,
    required this.children,
    this.transition = SwiftUiSwitchTransition.fadeThrough,
    this.duration = const Duration(milliseconds: 260),
    this.curve = Curves.easeInOut,
    this.lazy = true,
    this.coverColor,
  }) : assert(children.length > 0, 'Give at least one page');

  /// The page that is shown.
  final int index;
  final List<Widget> children;
  final SwiftUiSwitchTransition transition;
  final Duration duration;
  final Curve curve;

  /// Build a page when it is first shown (true) or all of them at once (false).
  final bool lazy;

  /// The colour [SwiftUiSwitchTransition.fadeThrough] goes through (null: the theme's background).
  final Color? coverColor;

  @override
  State<SwiftUiPageSwitcher> createState() => _SwiftUiPageSwitcherState();
}

class _SwiftUiPageSwitcherState extends State<SwiftUiPageSwitcher>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: 1,
  );
  late int _from = _clamp(widget.index);
  late int _to = _from;
  late final Set<int> _built = {
    if (widget.lazy)
      _to
    else
      ...List.generate(widget.children.length, (i) => i),
  };

  int _clamp(int i) => i.clamp(0, widget.children.length - 1);

  double get _t => widget.curve.transform(_controller.value);

  /// The page that is the visible one right now (fade through swaps halfway).
  int get _current =>
      widget.transition == SwiftUiSwitchTransition.fadeThrough && _t < 0.5
      ? _from
      : _to;

  @override
  void didUpdateWidget(SwiftUiPageSwitcher old) {
    super.didUpdateWidget(old);
    _controller.duration = widget.duration;
    if (!widget.lazy)
      _built.addAll(List.generate(widget.children.length, (i) => i));
    final next = _clamp(widget.index);
    if (next == _to) return;
    // a switch in the middle of another: continue from the page that is on screen
    _from = _controller.isAnimating ? _current : _to;
    _to = next;
    _built.add(next);
    if (widget.transition == SwiftUiSwitchTransition.none ||
        widget.duration == Duration.zero) {
      _from = _to;
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _page(int i, bool visible, Widget child) => TickerMode(
    enabled: visible,
    child: Offstage(offstage: !visible, child: child),
  );

  @override
  Widget build(BuildContext context) {
    final cover =
        widget.coverColor ?? SwiftUiTheme.of(context).colors.background;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _t;
        final running = _controller.value < 1 && _from != _to;
        final slide =
            running && widget.transition == SwiftUiSwitchTransition.slide;
        final dir = _to >= _from ? 1.0 : -1.0;
        final current = _current;
        final pages = <Widget>[
          for (var i = 0; i < widget.children.length; i++)
            if (!_built.contains(i))
              const SizedBox.shrink()
            else
              KeyedSubtree(
                key: ValueKey(i),
                child: _page(
                  i,
                  slide ? (i == _from || i == _to) : i == current,
                  slide && i == _to
                      ? FractionalTranslation(
                          translation: Offset(dir * (1 - t), 0),
                          child: widget.children[i],
                        )
                      : slide && i == _from
                      ? FractionalTranslation(
                          translation: Offset(-dir * t * 0.25, 0),
                          child: widget.children[i],
                        )
                      : widget.children[i],
                ),
              ),
        ];
        // the cover: 0 at the ends, 1 halfway; a plain translucent box, no layer
        final coverAlpha =
            running && widget.transition == SwiftUiSwitchTransition.fadeThrough
            ? 1 - (2 * t - 1).abs()
            : 0.0;
        return Stack(
          fit: StackFit.expand,
          children: [
            ...pages,
            if (coverAlpha > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: cover.withValues(alpha: cover.a * coverAlpha),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
