import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/cupertino.dart' show CupertinoSliverRefreshControl;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../theme/swift_ui_theme.dart';
import 'glass_lens.dart' show glassSmoothstep;
import 'ravel_icon.dart';

/// Inset grouped list section (Settings style): an optional small header, a rounded card with hairline separators between
/// the rows, an optional footer. Put [GroupedRow]s, [SwipeActionRow]s or any widget in [children].
class ListSection extends StatelessWidget {
  const ListSection({
    super.key,
    required this.children,
    this.header,
    this.footer,
    this.separatorInset = 16,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 28),
  });

  final List<Widget> children;
  final String? header;
  final String? footer;

  /// Left inset of the separators (use 62 when every row has a 30 pt icon).
  final double separatorInset;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final card = t.isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);
    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                header!,
                style: t.typography.body.copyWith(
                  fontSize: 13,
                  color: t.colors.foregroundSecondary,
                ),
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: ColoredBox(
              color: card,
              child: Column(
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    children[i],
                    if (i < children.length - 1)
                      Padding(
                        padding: EdgeInsets.only(left: separatorInset),
                        child: Container(
                          height: 0.5,
                          color: t.colors.separator,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                footer!,
                style: t.typography.body.copyWith(
                  fontSize: 13,
                  color: t.colors.foregroundSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A row for [ListSection]: optional colored icon tile (30 pt, like Settings), title, optional subtitle / value on the
/// right, a chevron when it navigates, or any [trailing] widget (switch, stepper...).
class GroupedRow extends StatelessWidget {
  const GroupedRow({
    super.key,
    required this.title,
    this.subtitle,
    this.value,
    this.icon,
    this.iconColor,
    this.trailing,
    this.chevron = false,
    this.onTap,
    this.destructive = false,
  });

  final String title;
  final String? subtitle;

  /// Secondary text on the right.
  final String? value;
  final Widget? icon;
  final Color? iconColor;
  final Widget? trailing;
  final bool chevron;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final row = Container(
      constraints: BoxConstraints(minHeight: subtitle == null ? 52 : 64),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: iconColor ?? t.colors.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: IconTheme(
                data: const IconThemeData(color: Color(0xFFFFFFFF), size: 18),
                child: icon!,
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.typography.body.copyWith(
                    fontSize: 17,
                    color: destructive
                        ? const Color(0xFFFF453A)
                        : t.colors.foreground,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.typography.body.copyWith(
                      fontSize: 14,
                      color: t.colors.foregroundSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: 12),
            Text(
              value!,
              style: t.typography.body.copyWith(
                fontSize: 17,
                color: t.colors.foregroundSecondary,
              ),
            ),
          ],
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          if (chevron) ...[
            const SizedBox(width: 8),
            RavelIcon(
              RavelIconKind.chevronRight,
              size: 16,
              color: t.colors.foregroundTertiary,
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return _Highlight(onTap: onTap!, child: row);
  }
}

class _Highlight extends StatefulWidget {
  const _Highlight({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;
  @override
  State<_Highlight> createState() => _HighlightState();
}

class _HighlightState extends State<_Highlight> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: ColoredBox(
        color: _down
            ? t.colors.foreground.withValues(alpha: 0.08)
            : const Color(0x00000000),
        child: widget.child,
      ),
    );
  }
}

/// A button revealed by swiping a [SwipeActionRow] sideways.
class SwipeAction {
  const SwipeAction({
    required this.label,
    required this.onPressed,
    this.color = const Color(0xFFFF4245),
    this.dismisses = false,
  });

  /// The action removes the row: the row slides out, collapses upwards (its bottom edge rises) and only then [onPressed] runs, so
  /// the list can drop the item without a jump.
  final bool dismisses;
  final String label;
  final Color color;
  final VoidCallback onPressed;
}

/// Row with trailing swipe actions (swipe left), fitted frame by frame to a native iOS 26 `swipeActions` list:
///  * the row slides away, lights up, and its trailing edge rounds off into a half circle;
///  * the buttons (63 x 43 pt) wait in their final slots; each one grows (scale + fade) with the finger, exactly as its slot is
///    freed, so it is never under the row. The FIRST action is the outermost (rightmost). Let go with the first button fully
///    shown and the row carries on until every button is visible;
///  * pulled past fully open, the row follows the finger, the other buttons ride on its edge and fade, and the first action
///    stretches over the gap with its label staying at the left edge; letting go there performs it.
class SwipeActionRow extends StatefulWidget {
  const SwipeActionRow({
    super.key,
    required this.child,
    this.actions = const [],
    this.leadingActions = const [],
    this.rowColor,
    this.pageColor,
  });

  final Widget child;

  /// Buttons revealed by swiping left (the first one is the outermost, rightmost).
  final List<SwipeAction> actions;

  /// Buttons revealed by swiping right (mirrored: the first one is the outermost, leftmost).
  final List<SwipeAction> leadingActions;

  /// Row background (default: the grouped card color).
  final Color? rowColor;

  /// Background the buttons float on (default: the page color, black in dark mode).
  final Color? pageColor;

  @override
  State<SwipeActionRow> createState() => _SwipeActionRowState();
}

class _SwipeActionRowState extends State<SwipeActionRow>
    with TickerProviderStateMixin {
  static const _spring = SpringDescription(
    mass: 1,
    stiffness: 210,
    damping: 25,
  ); // release: carries the finger's velocity
  static const _assistSpring = SpringDescription(
    mass: 1,
    stiffness: 120,
    damping: 17,
  ); // the pull-on to ~90%: slower, soft landing
  static const _btnW = 63.0;
  static const _btnH = 43.0;
  static const _gap =
      10.3; // between buttons and between the row and the first button
  static const _margin = 10.7; // right margin of the last button
  static const _radius = 17.0;
  static const _labelStyle = TextStyle(
    color: Color(0xFFFFFFFF),
    fontSize: 16,
    fontWeight: FontWeight.w400,
    decoration: TextDecoration.none,
  );

  late final AnimationController _x = AnimationController.unbounded(
    vsync: this,
    value: 0,
  ); // <= 0: row offset
  // armed: pulled so far that letting go performs the first action; the label then jumps to the left edge
  late final AnimationController _collapse = AnimationController(
    vsync: this,
    value: 0,
  ); // 0 = full height, 1 = gone
  late final AnimationController _arm = AnimationController(
    vsync: this,
    value: 0,
  );
  double _width = 0;

  // Button scale is a spring that the swipe merely TRIGGERS (target 1 once its slot starts to free, 0 when closed). The drawn scale
  // is capped by the finger-driven geometric limit (`_pop`), so a button can grow smoothly but never slips under the row.
  static const _grow = SpringDescription(mass: 1, stiffness: 120, damping: 15);
  late final List<AnimationController> _scales = [
    for (
      var i = 0;
      i < math.max(widget.actions.length, widget.leadingActions.length);
      i++
    )
      AnimationController.unbounded(vsync: this, value: 0),
  ];
  late final List<double> _scaleTarget = [
    for (var i = 0; i < _scales.length; i++) 0.0,
  ];

  // the side being pulled: right swipe (x > 0) reveals the leading actions, left swipe the trailing ones
  bool get _lead => _x.value > 0;
  // a side the touch has locked itself out of only bounces: it never shows buttons
  bool _lockedOut(double x) => _side != 0 && x != 0 && x.sign != _side;
  List<SwipeAction> get _acts => _lockedOut(_x.value)
      ? const []
      : (_lead ? widget.leadingActions : widget.actions);

  void _syncScales() {
    final reveal = _x.value.abs();
    for (var i = 0; i < _scales.length; i++) {
      final target = i < _acts.length && _popRaw(i, reveal) > 0.02 ? 1.0 : 0.0;
      if (target != _scaleTarget[i]) {
        _scaleTarget[i] = target;
        _scales[i].animateWith(
          SpringSimulation(
            _grow,
            _scales[i].value,
            target,
            _scales[i].velocity,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _x.addListener(_syncArm);
    _x.addListener(_syncScales);
  }

  @override
  void dispose() {
    _x.dispose();
    _arm.dispose();
    _collapse.dispose();
    for (final c in _scales) {
      c.dispose();
    }
    super.dispose();
  }

  double get _open =>
      _margin + _gap + _acts.length * _btnW + (_acts.length - 1) * _gap;

  // The stretched first button's left edge is at (width - reveal) + gap + (n - 1) buttons; native flips the label to the left
  // edge once that edge has passed about the middle of the row (measured on frames of a native list)
  bool get _armed {
    if (_width <= 0 || _acts.isEmpty) return false;
    final n = _acts.length;
    final reveal = _x.value.abs();
    final left = _width - reveal + _gap + (n - 1) * (_btnW + _gap);
    return reveal > _open && left <= _width * 0.5;
  }

  // Everything about the buttons is a pure function of the finger (`reveal`): scale + fade + position, never a lagging spring.
  double _popRaw(int i, double reveal) {
    // Native: the button stays centred in its slot and is scaled so that its left edge is always `_gap` right of the row edge
    // (scale = free width / full width), so it can never slip under the row.
    final center =
        _margin +
        i * (_btnW + _gap) +
        _btnW / 2; // slot centre, measured from the right edge
    return (reveal - center - _gap) / (_btnW / 2);
  }

  double _pop(int i, double reveal) =>
      math.min(_scales[i].value, _popRaw(i, reveal)).clamp(0.0, 1.1);

  double _extra(double reveal) => reveal - _open > 0 ? reveal - _open : 0.0;

  void _syncArm() {
    final armed = _armed;
    final on = _arm.value > 0.5 || _arm.status == AnimationStatus.forward;
    if (armed != on) {
      _arm.animateTo(
        armed ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _perform(SwipeAction a, double sign, {required bool fly}) async {
    if (a.dismisses) {
      _animate(sign * _width);
      await Future<void>.delayed(const Duration(milliseconds: 160));
      if (!mounted) return;
      await _collapse.animateTo(
        1,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
      if (!mounted) return;
      a.onPressed();
      // the list may keep this State for the next row: leave it closed and at full height
      _x.value = 0;
      _collapse.value = 0;
    } else if (fly) {
      _animate(sign * _width);
      a.onPressed();
      Future<void>.delayed(const Duration(milliseconds: 280), () {
        if (mounted) _animate(0);
      });
    } else {
      _animate(0);
      a.onPressed();
    }
  }

  Future<void> _animate(
    double to, [
    double v = 0,
    SpringDescription spring = _spring,
  ]) {
    return _x
        .animateWith(SpringSimulation(spring, _x.value, to, v))
        .orCancel
        .catchError((_) {});
  }

  // Native assist: once the swipe is armed (the label has jumped to the left edge) the row is pulled on to ~90% of the width.
  // It fires once per touch: pulling back and arming again in the same gesture does not trigger it again.
  Duration _lastT = Duration.zero;
  double _dragVel = 0; // finger velocity (px/s) from the last drag updates, handed to the assist spring
  bool _assisted = false;
  double _side = 0; // the side this touch committed to (-1 trailing, +1 leading, 0 not yet): the other side is locked out
  bool _assisting = false;

  void _assist() {
    _assisted = true;
    _assisting = true;
    _animate(
      (_lead ? 1 : -1) * _width * 0.9,
      _dragVel,
      _assistSpring,
    ).whenComplete(() => _assisting = false);
  }

  double _labelWidth(String text) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: _labelStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return tp.width;
  }

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final rowColor =
        widget.rowColor ??
        (t.isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF));
    final pageColor =
        widget.pageColor ??
        (t.isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7));
    return LayoutBuilder(
      builder: (context, c) {
        _width = c.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          // count the drag from the touch-down point: otherwise the first ~18 pt of travel (the touch slop) are lost and the
          // row lags behind the finger
          dragStartBehavior: DragStartBehavior.down,
          onHorizontalDragStart: (_) {
            _x.stop();
            _side = _x.value.sign;
            _assisted = false;
            _assisting = false;
            _lastT = Duration.zero;
            _dragVel = 0;
          },
          onHorizontalDragUpdate: (d) {
            if (_assisting) {
              // the assist is carrying the row on; pulling back takes over at once, from where the row is NOW (the finger's
              // old position no longer matters), further pulling the same way is absorbed by the assist
              if (_lead ? d.delta.dx >= 0 : d.delta.dx <= 0) return;
              _x.stop();
              _assisting = false;
            }
            final dt = (d.sourceTimeStamp ?? Duration.zero) - _lastT;
            if (dt.inMicroseconds > 0 && _lastT != Duration.zero) {
              _dragVel =
                  0.6 * _dragVel + 0.4 * d.delta.dx / (dt.inMicroseconds / 1e6);
            }
            _lastT = d.sourceTimeStamp ?? Duration.zero;
            var v = _x.value + d.delta.dx;
            // native guard: once the touch has started pulling one way, dragging back through closed and on never opens the
            // other side's buttons; the row just stays shut until the finger lets go
            if (_side == 0 && v != 0) _side = v.sign;
            // ...but the row still gives: a rubber-band bounce toward the locked-out side, with no buttons
            if (_side < 0 && v > 0)
              v =
                  (_x.value > 0
                          ? _x.value +
                                (d.delta.dx > 0 ? d.delta.dx * 0.3 : d.delta.dx)
                          : v * 0.3)
                      .clamp(0.0, 60.0);
            if (_side > 0 && v < 0)
              v =
                  (_x.value < 0
                          ? _x.value +
                                (d.delta.dx < 0 ? d.delta.dx * 0.3 : d.delta.dx)
                          : v * 0.3)
                      .clamp(-60.0, 0.0);
            // a little rubber past closed on a side that has no actions
            if (_side != 0 && v.sign == -_side) {
              // already handled above
            } else if (v > 0 && widget.leadingActions.isEmpty) {
              v = v * 0.3;
            } else if (v < 0 && widget.actions.isEmpty) {
              v = v * 0.3;
            }
            // past the buttons the row follows the finger 1:1 (a long swipe), up to the full width
            _x.value = v.clamp(
              widget.actions.isEmpty ? -0.5 : -c.maxWidth,
              widget.leadingActions.isEmpty ? 0.5 : c.maxWidth,
            );
            if (!_assisted && _armed) _assist();
          },
          onHorizontalDragEnd: (d) {
            final vel = d.velocity.pixelsPerSecond.dx;
            final sign = _lead ? 1.0 : -1.0;
            final fwd = vel * sign; // velocity in the opening direction
            final shown = _x.value.abs() + fwd * 0.15;
            if (_acts.isNotEmpty &&
                (_armed || (_x.value.abs() > _open && fwd > 1800))) {
              _perform(_acts.first, sign, fly: true);
            } else if (_acts.isNotEmpty && shown > _margin + _btnW) {
              // the first button is fully shown: letting go carries on until ALL the buttons are visible
              _animate(sign * _open, vel);
            } else {
              _animate(0, vel);
            }
          },
          child: ClipRect(
            child: AnimatedBuilder(
              animation: Listenable.merge([_x, _arm, _collapse, ..._scales]),
              builder: (context, _) {
                final x = _x.value;
                final reveal = x.abs();
                final lead = x > 0;
                final acts = _lockedOut(x)
                    ? const <SwipeAction>[]
                    : (lead ? widget.leadingActions : widget.actions);
                final n = acts.length;
                // the row end rounds off into a half circle as it opens, and the row lights up while it is held / open
                final round = glassSmoothstep(
                  0,
                  6,
                  reveal,
                ); // 0..1: a full capsule within the first few points
                final lit = glassSmoothstep(0, 24, reveal);
                final rowBg = Color.lerp(
                  rowColor,
                  t.isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                  lit,
                )!;
                // past fully open (a long swipe) the others ride on the row edge and fade, the first one stretches
                final extra = _extra(reveal);
                final fade =
                    1 -
                    0.55 *
                        glassSmoothstep(
                          0,
                          90,
                          extra,
                        ); // native: dims gently to about half, no sharp swing
                final visible =
                    reveal > 0 || _scales.any((c) => c.value > 0.01);
                final stack = Stack(
                  children: [
                    if (visible) ...[
                      Positioned.fill(child: ColoredBox(color: pageColor)),
                      for (var i = n - 1; i >= 0; i--)
                        _button(
                          i,
                          n,
                          extra,
                          i == 0 ? 1.0 : fade,
                          c.maxWidth,
                          _pop(i, reveal),
                          acts,
                          lead,
                        ),
                    ],
                    // native: the row's fixed edge stays put and rounds off too (a full capsule), only the other edge travels
                    ClipRRect(
                      clipper: _RowClipper(x, round),
                      child: Transform.translate(
                        offset: Offset(x, 0),
                        child: ColoredBox(color: rowBg, child: widget.child),
                      ),
                    ),
                  ],
                );
                // collapsing after a dismissing action: the bottom edge rises (the top stays put)
                return Align(
                  alignment: Alignment.topCenter,
                  heightFactor: (1 - _collapse.value).clamp(0.0, 1.0),
                  child: stack,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _button(
    int i,
    int n,
    double extra,
    double fade,
    double width,
    double pop,
    List<SwipeAction> acts,
    bool lead,
  ) {
    var left = width - _margin - _btnW - i * (_btnW + _gap);
    var w = _btnW;
    if (extra > 0) {
      // chain: row | gap | button n-1 ... | gap | button 0 (stretched to the right margin); the row edge is `open + extra`
      // from the right edge
      final rowRight = width - _open - extra;
      left = rowRight + _gap + (n - 1 - i) * (_btnW + _gap);
      if (i == 0) w = width - _margin - left;
    }
    final label = acts[i].label;
    if (lead)
      left =
          width -
          left -
          w; // mirrored: the same layout measured from the left edge
    return Positioned(
      left: left,
      top: 0,
      bottom: 0,
      width: w,
      child: Opacity(
        opacity: (pop * fade).clamp(0.0, 1.0),
        child: Center(
          child: Transform.scale(
            scale: pop,
            child: SizedBox(
              width: w,
              height: _btnH,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _perform(acts[i], lead ? 1.0 : -1.0, fly: false),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: acts[i].color,
                    borderRadius: BorderRadius.circular(_radius),
                  ),
                  // centered while the button stretches; the label jumps to the left edge once the swipe is armed
                  child: Align(
                    alignment: lead
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Padding(
                      // the label moves to the edge next to the row (left for trailing actions, right for leading ones)
                      padding: EdgeInsets.only(
                        left: lead
                            ? 0
                            : math.max(
                                0.0,
                                ui.lerpDouble(
                                  (w - _labelWidth(label)) / 2,
                                  16,
                                  i == 0 ? _arm.value : 0,
                                )!,
                              ),
                        right: lead
                            ? math.max(
                                0.0,
                                ui.lerpDouble(
                                  (w - _labelWidth(label)) / 2,
                                  16,
                                  i == 0 ? _arm.value : 0,
                                )!,
                              )
                            : 0,
                      ),
                      child: Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                        style: _labelStyle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Clips the swiped row to a capsule: the edge it is anchored to is fixed, the other one follows the row.
class _RowClipper extends CustomClipper<RRect> {
  const _RowClipper(this.x, this.radius);
  final double x;
  final double radius;

  @override
  RRect getClip(Size size) => RRect.fromLTRBR(
    math.min(size.width, math.max(0.0, x)),
    0,
    math.max(0.0, size.width + math.min(0.0, x)),
    size.height,
    Radius.circular(radius * size.height / 2),
  );

  @override
  bool shouldReclip(_RowClipper old) => old.x != x || old.radius != radius;
}

/// Pull-to-refresh for a `CustomScrollView` (iOS style: the content stays pulled down with a spinner while [onRefresh]
/// runs). Use it as the first sliver and give the scroll view `BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())`.
class RavelRefreshControl extends StatelessWidget {
  const RavelRefreshControl({super.key, required this.onRefresh});
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) =>
      CupertinoSliverRefreshControl(onRefresh: onRefresh);
}
