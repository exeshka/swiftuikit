import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../components/liquid_glass.dart'
    show LiquidPressCanceller, LiquidPressScope;
import '../theme/swift_ui_theme.dart';

/// A side menu under the app that slides the page to the right (the drawer of ChatGPT and Claude on iOS).
///
/// The menu is closed at first. A drag from the left edge moves the page with the finger like an interactive back swipe, a
/// quick, clearly horizontal flick to the right opens it from anywhere, and while it is open the page follows a drag anywhere
/// and a tap on the page closes it. On release the page settles open or closed on a spring: by the fling when it is fast,
/// otherwise to the nearer end. The page is dimmed and rounded while it moves.
///
/// While the menu is closed the drawer does not take part in the gesture arena for a touch that starts away from the edge, so
/// a vertical scroll (even a slightly diagonal one) is never taken away from the page's own lists; the flick from the middle
/// is read from the raw pointer events instead.
///
/// ```dart
/// SwiftUiDrawer(
///   menu: const MenuPage(),
///   body: const HomeShell(),   // a page's own button calls SwiftUiDrawer.of(context).toggle()
/// )
/// ```
class SwiftUiDrawer extends StatefulWidget {
  const SwiftUiDrawer({
    super.key,
    required this.menu,
    required this.body,
    this.menuFraction = 0.8,
    this.cornerRadius = 44,
    this.pageColor,
    this.menuBackground,
    this.initiallyOpen = false,
  });

  /// The menu under the page.
  final Widget menu;

  /// The app (or the page) that slides.
  final Widget body;

  /// The width of the menu as a share of the screen width.
  final double menuFraction;

  /// The corner radius of the page while it is moved away (the radius of the device's screen looks best).
  final double cornerRadius;

  /// The colour under the page (what shows while the page is rounded and dimmed); null: the theme's background.
  final Color? pageColor;

  /// The colour of the whole area behind the page, also to the right of the menu where the rounded page leaves the corners
  /// bare. Give it the menu's own background; null: black, as before.
  final Color? menuBackground;

  final bool initiallyOpen;

  /// The drawer above [context], to open or close it from a button of the page.
  static SwiftUiDrawerState of(BuildContext context) {
    final state = maybeOf(context);
    assert(state != null, 'No SwiftUiDrawer found in context');
    return state!;
  }

  static SwiftUiDrawerState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<SwiftUiDrawerState>();

  @override
  State<SwiftUiDrawer> createState() => SwiftUiDrawerState();
}

class SwiftUiDrawerState extends State<SwiftUiDrawer>
    with SingleTickerProviderStateMixin {
  // critically damped, about 0.35 s: no bounce
  static final _spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 380,
    ratio: 1,
  );
  static const _menuStartScale = 0.85;
  // opening is deliberately hard: from the left edge the page follows the finger, from anywhere else only a quick, clearly
  // horizontal flick opens it
  static const _edgeZone = 24.0;
  static const _flickVelocity = 800.0;
  // a flick counts as horizontal when it travels (and moves) at least twice as far across as up or down
  static const _flickSlope = 0.5;
  static const _flickMinDistance = 56.0;

  // 0 = closed, 1 = open
  late final AnimationController _progress = AnimationController.unbounded(
    vsync: this,
    value: widget.initiallyOpen ? 1 : 0,
  );
  // a drag that takes a touch over from glass buttons tells them to let go instead of stretching
  final _glass = LiquidPressCanceller();
  late bool _committedOpen = widget.initiallyOpen;
  double _menuWidth = 1;

  // the flick from the middle of a closed page, read from raw pointers (it never claims the gesture)
  VelocityTracker? _flickTracker;
  Offset? _flickStart;

  bool get isOpen => _progress.value > 0.5;

  /// 0..1: how far the page has moved (for tests).
  @visibleForTesting
  double get progress => _progress.value;

  // The spring stops within its tolerance of the end, not exactly on it: a page that "rests" at 0.0008 must count as at rest
  // (otherwise the layer that closes the menu on a tap stays over the page and the drag still takes every touch).
  static const _eps = 0.002;
  bool get _atRest => _progress.value < _eps;
  void open() => _settle(1, 0);
  void close() => _settle(0, 0);
  void toggle() => isOpen ? close() : open();

  void _settle(double to, double velocity) {
    final open = to == 1;
    if (open) FocusManager.instance.primaryFocus?.unfocus();
    if (open != _committedOpen) {
      _committedOpen = open;
      HapticFeedback.lightImpact();
    }
    _progress
        .animateWith(SpringSimulation(_spring, _progress.value, to, velocity))
        // land exactly on the end (a cancelled animation, started over by a new touch, never gets here)
        .then((_) {
          if (mounted && !_progress.isAnimating) _progress.value = to;
        });
  }

  double _localX(Offset global) {
    final box = context.findRenderObject();
    return box is RenderBox ? box.globalToLocal(global).dx : global.dx;
  }

  // The drag recognizer joins the arena only for a touch that can move the page: any touch while it is away from the edge of
  // the screen (open, or on its way), or one that starts at the left edge.
  bool _canStartDrag(Offset global) => !_atRest || _localX(global) <= _edgeZone;

  void _onDragStart(DragStartDetails d) {
    // An open keyboard would stay over the moving page: hide it as soon as the menu starts to move.
    FocusManager.instance.primaryFocus?.unfocus();
    _glass.cancel();
    _progress.stop();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _progress.value = (_progress.value + d.delta.dx / _menuWidth).clamp(
      0.0,
      1.0,
    );
  }

  void _onDragEnd(DragEndDetails d) {
    final v = d.velocity.pixelsPerSecond.dx / _menuWidth; // progress per second
    // a quick flick decides by direction, a slow release by the nearer end
    final to = v.abs() > 1.2
        ? (v > 0 ? 1.0 : 0.0)
        : (_progress.value > 0.5 ? 1.0 : 0.0);
    _settle(to, v);
  }

  void _flickDown(PointerDownEvent e) {
    if (!_atRest || _localX(e.position) <= _edgeZone) {
      _flickTracker = null;
      return;
    }
    _flickStart = e.position;
    _flickTracker = VelocityTracker.withKind(e.kind)
      ..addPosition(e.timeStamp, e.position);
  }

  void _flickMove(PointerMoveEvent e) =>
      _flickTracker?.addPosition(e.timeStamp, e.position);

  void _flickUp(PointerUpEvent e) {
    final tracker = _flickTracker;
    final start = _flickStart;
    _flickTracker = null;
    if (tracker == null || start == null || !_atRest) return;
    tracker.addPosition(e.timeStamp, e.position);
    final travel = e.position - start;
    final v = tracker.getVelocity().pixelsPerSecond;
    final horizontal =
        travel.dx >= _flickMinDistance &&
        travel.dy.abs() <= travel.dx * _flickSlope &&
        v.dx > _flickVelocity &&
        v.dy.abs() <= v.dx * _flickSlope;
    if (horizontal) _settle(1, v.dx / _menuWidth);
  }

  void _flickCancel(PointerCancelEvent e) => _flickTracker = null;

  @override
  void dispose() {
    _progress.dispose();
    _glass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = SwiftUiTheme.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        _menuWidth = box.maxWidth * widget.menuFraction;
        return LiquidPressScope(
          canceller: _glass,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _flickDown,
            onPointerMove: _flickMove,
            onPointerUp: _flickUp,
            onPointerCancel: _flickCancel,
            child: RawGestureDetector(
              behavior: HitTestBehavior.translucent,
              gestures: {
                _DrawerDragRecognizer:
                    GestureRecognizerFactoryWithHandlers<_DrawerDragRecognizer>(
                      () => _DrawerDragRecognizer(canStart: _canStartDrag),
                      (r) => r
                        ..onStart = _onDragStart
                        ..onUpdate = _onDragUpdate
                        ..onEnd = _onDragEnd,
                    ),
              },
              child: AnimatedBuilder(
                animation: _progress,
                // the menu does not depend on the progress: built once per layout
                child: SizedBox(width: _menuWidth, child: widget.menu),
                builder: (context, menu) {
                  final p = _progress.value.clamp(0.0, 1.0);
                  return ColoredBox(
                    color: widget.menuBackground ?? const Color(0xFF000000),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: _menuWidth,
                          // fully covered when closed: not painted at all
                          child: Offstage(
                            offstage: p < _eps,
                            // the menu starts smaller and grows to its size as the page slides away
                            child: Transform.scale(
                              scale:
                                  _menuStartScale + (1 - _menuStartScale) * p,
                              child: menu,
                            ),
                          ),
                        ),
                        Positioned(
                          left: p * _menuWidth,
                          top: 0,
                          bottom: 0,
                          width: box.maxWidth,
                          child: _page(theme, p),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _page(SwiftUiThemeData theme, double p) {
    // at rest the page has square corners and no border; any movement gives it the full radius and the border at once
    final moved = p >= _eps;
    final radius = BorderRadius.circular(moved ? widget.cornerRadius : 0);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: widget.pageColor ?? theme.colors.background,
        borderRadius: radius,
        border: moved ? Border.all(color: theme.colors.separator) : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(child: widget.body),
            if (moved) ...[
              // the page dims as it moves away; a plain box, never an opacity layer
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: const Color(0xFF000000)
                        .withValues(alpha: (theme.isDark ? 0.5 : 0.1) * p),
                  ),
                ),
              ),
              // while open, a tap anywhere on the page closes the menu
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: close,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The drag of the drawer. It takes part in the gesture arena only for a touch [canStart] accepts (one that can move the
/// page); every other touch, a vertical scroll of a list in the page above all, never meets it.
class _DrawerDragRecognizer extends HorizontalDragGestureRecognizer {
  _DrawerDragRecognizer({required this.canStart});

  final bool Function(Offset globalPosition) canStart;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (canStart(event.position)) super.addAllowedPointer(event);
  }
}
