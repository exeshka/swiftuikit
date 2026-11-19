import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../theme/swift_ui_theme.dart';
import 'glass_lens.dart';

/// iOS 26 slider: a thin track and a white capsule thumb that swells under the finger on a spring.
class GlassSlider extends StatefulWidget {
  const GlassSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.activeColor,
    this.debugPressed = false,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final double min;
  final double max;

  /// Snap to this many equal steps.
  final int? divisions;
  final Color? activeColor;

  /// Shows the pressed look permanently (for tuning the glass).
  final bool debugPressed;

  @override
  State<GlassSlider> createState() => _GlassSliderState();
}

class _GlassSliderState extends State<GlassSlider>
    with SingleTickerProviderStateMixin {
  static const _spring = SpringDescription(
    mass: 1,
    stiffness: 520,
    damping: 28,
  );
  static const _thumbW = 37.0;
  static const _thumbH = 23.5;

  late final AnimationController _press = AnimationController.unbounded(
    vsync: this,
    value: 0,
  );
  bool _dragging = false;
  double _live = 0;

  double get _norm =>
      ((widget.value - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);

  void _setPressed(bool v) {
    _press.animateWith(
      SpringSimulation(_spring, _press.value, v ? 1 : 0, _press.velocity),
    );
  }

  double _valueAt(double dx, double width) {
    var n = ((dx - _thumbW / 2) / (width - _thumbW)).clamp(0.0, 1.0);
    final d = widget.divisions;
    if (d != null && d > 0) n = (n * d).round() / d;
    return widget.min + n * (widget.max - widget.min);
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final enabled = widget.onChanged != null;
    final active =
        widget.activeColor ??
        (t.isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF));
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: SizedBox(
        height: 40,
        child: LayoutBuilder(
          builder: (context, c) {
            void update(Offset p) {
              final v = _valueAt(p.dx, c.maxWidth);
              _live = v;
              widget.onChanged?.call(v);
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: enabled
                  ? (d) {
                      _dragging = true;
                      _setPressed(true);
                      widget.onChangeStart?.call(widget.value);
                      update(d.localPosition);
                    }
                  : null,
              onHorizontalDragUpdate: enabled
                  ? (d) => update(d.localPosition)
                  : null,
              onHorizontalDragEnd: enabled
                  ? (_) {
                      _dragging = false;
                      _setPressed(false);
                      widget.onChangeEnd?.call(_live);
                    }
                  : null,
              onTapDown: enabled
                  ? (d) {
                      _setPressed(true);
                      update(d.localPosition);
                    }
                  : null,
              onTapUp: enabled
                  ? (_) {
                      _setPressed(false);
                      widget.onChangeEnd?.call(_live);
                    }
                  : null,
              onTapCancel: enabled ? () => _setPressed(_dragging) : null,
              child: AnimatedBuilder(
                animation: _press,
                builder: (context, _) {
                  final k = widget.debugPressed
                      ? 1.0
                      : _press.value.clamp(0.0, 1.3);
                  final x = _thumbW / 2 + _norm * (c.maxWidth - _thumbW);
                  // pressed: the thumb turns into a glass bubble, wider and taller than the capsule
                  final lw = _thumbW + 24 * k;
                  final lh = _thumbH + 12 * k;
                  final rest = 1 - glassSmoothstep(0.05, 0.75, k);
                  return Stack(
                    alignment: Alignment.centerLeft,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 6,
                        decoration: ShapeDecoration(
                          shape: const StadiumBorder(),
                          color: t.colors.foreground.withValues(alpha: 0.22),
                        ),
                      ),
                      Container(
                        width: x,
                        height: 6,
                        decoration: ShapeDecoration(
                          shape: const StadiumBorder(),
                          color: active,
                        ),
                      ),
                      if (k > 0.02)
                        Positioned(
                          left: x - lw / 2,
                          top: (40 - lh) / 2,
                          child: GlassLens(
                            width: lw,
                            height: lh,
                            shadowColor: active,
                          ),
                        ),
                      Positioned(
                        left: x - _thumbW / 2,
                        top: (40 - _thumbH) / 2,
                        width: _thumbW,
                        height: _thumbH,
                        child: Opacity(
                          opacity: rest,
                          child: const DecoratedBox(
                            decoration: ShapeDecoration(
                              shape: StadiumBorder(),
                              color: Color(0xFFFFFFFF),
                              shadows: [
                                BoxShadow(
                                  color: Color(0x40000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 1.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

/// iOS stepper: a pill with "−" and "+" halves. Each half highlights while pressed and repeats while held.
class GlassStepper extends StatefulWidget {
  const GlassStepper({
    super.key,
    required this.onIncrement,
    required this.onDecrement,
    this.canIncrement = true,
    this.canDecrement = true,
  });

  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final bool canIncrement;
  final bool canDecrement;

  @override
  State<GlassStepper> createState() => _GlassStepperState();
}

class _GlassStepperState extends State<GlassStepper> {
  int _down = 0; // -1 minus, 1 plus
  bool _held = false;

  Future<void> _repeat(int dir) async {
    _held = true;
    await Future<void>.delayed(const Duration(milliseconds: 450));
    while (_held && mounted && _down == dir) {
      (dir > 0 ? widget.onIncrement : widget.onDecrement)?.call();
      await Future<void>.delayed(const Duration(milliseconds: 90));
    }
  }

  Widget _half(SwiftUiThemeData t, int dir, bool enabled) {
    final cb = dir > 0 ? widget.onIncrement : widget.onDecrement;
    final on = enabled && cb != null;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: on
            ? (_) {
                setState(() => _down = dir);
                _repeat(dir);
              }
            : null,
        onTapUp: on
            ? (_) {
                _held = false;
                setState(() => _down = 0);
                cb();
              }
            : null,
        onTapCancel: () {
          _held = false;
          if (_down == dir) setState(() => _down = 0);
        },
        child: Container(
          decoration: BoxDecoration(
            color: _down == dir
                ? t.colors.foreground.withValues(alpha: 0.14)
                : const Color(0x00000000),
          ),
          child: Center(
            child: CustomPaint(
              size: const Size(16, 16),
              painter: _PlusMinusPainter(
                plus: dir > 0,
                color: t.colors.foreground.withValues(alpha: on ? 1 : 0.3),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    return SizedBox(
      width: 100,
      height: 36,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: const StadiumBorder(),
          color: t.colors.foreground.withValues(alpha: t.isDark ? 0.14 : 0.08),
        ),
        child: ClipPath(
          clipper: const _StadiumClipper(),
          child: Row(
            children: [
              _half(t, -1, widget.canDecrement),
              Container(
                width: 1,
                height: 18,
                color: t.colors.foreground.withValues(alpha: 0.25),
              ),
              _half(t, 1, widget.canIncrement),
            ],
          ),
        ),
      ),
    );
  }
}

class _StadiumClipper extends CustomClipper<Path> {
  const _StadiumClipper();
  @override
  Path getClip(Size s) => Path()
    ..addRRect(
      RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(s.height / 2)),
    );
  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}

class _PlusMinusPainter extends CustomPainter {
  _PlusMinusPainter({required this.plus, required this.color});
  final bool plus;
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, s.height / 2), Offset(s.width, s.height / 2), p);
    if (plus)
      canvas.drawLine(Offset(s.width / 2, 0), Offset(s.width / 2, s.height), p);
  }

  @override
  bool shouldRepaint(_PlusMinusPainter old) =>
      old.plus != plus || old.color != color;
}
