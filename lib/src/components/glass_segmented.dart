import 'dart:async';

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../theme/swift_ui_theme.dart';
import 'glass_segment_parts.dart';

/// One segment of a [GlassSegmentedControl].
class GlassSegment<T> {
  const GlassSegment({required this.value, this.label, this.icon, this.badge})
    : assert(label != null || icon != null);
  final T value;
  final String? label;

  /// Shown instead of / before the label.
  final Widget? icon;

  /// Small counter after the label (used by the scrollable strip).
  final String? badge;
}

/// iOS 26 segmented control: a capsule track with a thumb that slides to the selected segment on a spring, can be dragged,
/// and swells a little while it is pressed.
class GlassSegmentedControl<T> extends StatefulWidget {
  const GlassSegmentedControl({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.height = 32,
    this.debugPressed = false,
  });

  final List<GlassSegment<T>> segments;
  final T value;
  final ValueChanged<T>? onChanged;
  final double height;

  /// Shows the pressed look permanently (for tuning the glass).
  final bool debugPressed;

  @override
  State<GlassSegmentedControl<T>> createState() =>
      _GlassSegmentedControlState<T>();
}

class _GlassSegmentedControlState<T> extends State<GlassSegmentedControl<T>>
    with TickerProviderStateMixin {
  // The same behavior as GlassSwitch (see there for the measurements): the thumb glides on a spring, but while it is dragged
  // it sticks to the finger 1:1 (no easing), past the ends it is rubber-banded, a flick carries on through the spring.
  static const _posSpring = SpringDescription(
    mass: 1,
    stiffness: 380,
    damping: 26,
  );
  static const _pressSpring = SpringDescription(
    mass: 1,
    stiffness: 420,
    damping: 28,
  );
  static const _releaseSpring = SpringDescription(
    mass: 1,
    stiffness: 120,
    damping: 17.5,
  );
  static const _tapReleaseSpring = SpringDescription(
    mass: 1,
    stiffness: 220,
    damping: 22,
  );
  static const _padding = 2.0;
  static const _bandLimit = 8.5;

  late final AnimationController _pos = AnimationController.unbounded(
    vsync: this,
    value: _index.toDouble(),
  );
  late final AnimationController _press = AnimationController.unbounded(
    vsync: this,
    value: 0,
  );
  bool _down = false;
  bool _dragging = false;
  bool _tap = false;
  // where the finger would put the thumb, unclamped (segment units)
  double _dragRaw = 0;
  double _segW = 1;
  double _releaseVelocity = 0;

  int get _index => widget.segments
      .indexWhere((s) => s.value == widget.value)
      .clamp(0, widget.segments.length - 1);

  @override
  void didUpdateWidget(GlassSegmentedControl<T> old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && !_dragging && !_down) {
      _animatePos(_index.toDouble());
    }
  }

  @override
  void dispose() {
    _releaseTimer?.cancel();
    _pos.dispose();
    _press.dispose();
    super.dispose();
  }

  void _animatePos(double to) {
    final v = _releaseVelocity != 0 ? _releaseVelocity : _pos.velocity;
    _releaseVelocity = 0;
    _pos.animateWith(SpringSimulation(_posSpring, _pos.value, to, v));
  }

  // past the ends the thumb follows with growing resistance (rubber band) and springs back on release
  double _rubber(double raw) {
    final max = widget.segments.length - 1.0;
    if (raw >= 0 && raw <= max) return raw;
    final over = raw > max ? raw - max : -raw;
    final shown = (1 - 1 / (over * _segW * 0.7 / _bandLimit + 1)) * _bandLimit;
    final o = shown / _segW;
    return raw > max ? max + o : -o;
  }

  // the lens stays at least a moment even for a quick tap, and turns back into the white thumb as the thumb lands
  static const _minLens = Duration(milliseconds: 170);
  static const _tapLens = Duration(milliseconds: 300);
  DateTime _downAt = DateTime.now();
  Timer? _releaseTimer;

  void _pressDown() {
    _releaseTimer?.cancel();
    _releaseTimer = null;
    _downAt = DateTime.now();
    _setDown(true);
  }

  void _pressUp({bool hold = true, bool tap = false}) {
    _tap = tap;
    final left = tap ? _tapLens : _minLens - DateTime.now().difference(_downAt);
    if (!hold || left <= Duration.zero) {
      _setDown(false);
      return;
    }
    _releaseTimer?.cancel();
    _releaseTimer = Timer(left, () {
      _releaseTimer = null;
      if (mounted && !_dragging) _setDown(false);
    });
  }

  void _setDown(bool v) {
    if (_down == v) return;
    _down = v;
    _press.animateWith(
      SpringSimulation(
        v ? _pressSpring : (_tap ? _tapReleaseSpring : _releaseSpring),
        _press.value,
        v ? 1 : 0,
        _press.velocity,
      ),
    );
  }

  void _select(int i) {
    if (widget.onChanged != null && widget.segments[i].value != widget.value) {
      widget.onChanged!(widget.segments[i].value);
    }
    _animatePos(i.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final n = widget.segments.length;
    final enabled = widget.onChanged != null;
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, c) {
          final segW = (c.maxWidth - _padding * 2) / n;
          _segW = segW;
          int indexAt(double dx) =>
              ((dx - _padding) / segW).floor().clamp(0, n - 1);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            // the thumb follows the finger from the touch-down point (no lost touch-slop travel)
            dragStartBehavior: DragStartBehavior.down,
            onTapDown: enabled
                ? (d) {
                    _pressDown();
                    // the thumb is pulled to the touched segment right away
                    _animatePos(indexAt(d.localPosition.dx).toDouble());
                  }
                : null,
            onTapUp: enabled
                ? (d) {
                    _pressUp(tap: true);
                    _select(indexAt(d.localPosition.dx));
                  }
                : null,
            onTapCancel: enabled
                ? () {
                    if (_dragging) return;
                    _pressUp(hold: false);
                    _animatePos(_index.toDouble());
                  }
                : null,
            onHorizontalDragStart: enabled
                ? (_) {
                    _dragging = true;
                    _dragRaw = _pos.value;
                    _pos.stop();
                    _pressDown();
                  }
                : null,
            onHorizontalDragUpdate: enabled
                ? (d) {
                    _dragRaw += d.delta.dx / segW;
                    _pos.value = _rubber(_dragRaw);
                  }
                : null,
            onHorizontalDragEnd: enabled
                ? (d) {
                    _dragging = false;
                    _pressUp();
                    // a flick decides like a projected 0.12 s of travel and feeds the spring
                    final v = (d.velocity.pixelsPerSecond.dx / segW).clamp(
                      -14.0,
                      14.0,
                    );
                    _releaseVelocity = v;
                    _select((_dragRaw + v * 0.12).round().clamp(0, n - 1));
                  }
                : null,
            onHorizontalDragCancel: enabled
                ? () {
                    _dragging = false;
                    _pressUp(hold: false);
                    _animatePos(_index.toDouble());
                  }
                : null,
            child: AnimatedBuilder(
              animation: Listenable.merge([_pos, _press]),
              builder: (context, _) {
                final k = widget.debugPressed ? 1.0 : _press.value;
                final thumbH = widget.height - _padding * 2;
                final left = _padding + _pos.value * segW;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(child: SegmentVisuals.track(t)),
                    ...SegmentVisuals.thumb(
                      t,
                      left: left,
                      top: _padding,
                      width: segW,
                      height: thumbH,
                      k: k,
                    ),
                    Row(
                      children: [
                        const SizedBox(width: _padding),
                        for (var i = 0; i < n; i++)
                          SizedBox(
                            width: segW,
                            child: Center(
                              child: _label(
                                t,
                                widget.segments[i],
                                (1 - (_pos.value - i).abs()).clamp(0.0, 1.0),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _label(SwiftUiThemeData t, GlassSegment<T> s, double selected) {
    final style = SegmentVisuals.labelStyle(t, selected);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (s.icon != null)
          IconTheme(
            data: IconThemeData(color: style.color, size: 18),
            child: s.icon!,
          ),
        if (s.icon != null && s.label != null) const SizedBox(width: 6),
        if (s.label != null)
          Flexible(
            child: Text(
              s.label!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
      ],
    );
  }
}
