import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart' show Theme;

import 'dart:async';

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../theme/swift_ui_theme.dart';
import 'liquid_glass.dart';

/// The iOS 26 switch (measured on a native `Toggle`): a 63 x 28 pt capsule track and a 37 x 24 pt white thumb. While it is
/// pressed the thumb turns into a clear liquid glass pill (~56 x 37 pt, taller than the track) and follows the finger; on
/// release it settles on the nearer side as a white thumb again and the track cross-fades between gray and [activeColor].
class GlassSwitch extends StatefulWidget {
  const GlassSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangedAsync,
    this.activeColor,
    this.trackColor,
    this.width = 63,
    this.height = 28,
    this.loading = false,
    this.debugPressed = false,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Like [onChanged], but the request is awaited: while the returned future runs the switch shows the spinner in its thumb
  /// and is locked (cannot be pressed, dragged or toggled). Update [value] from the callback once the request has gone
  /// through; if it throws or the value is left alone, the thumb stays where it was. Takes precedence over [onChanged].
  final Future<void> Function(bool next)? onChangedAsync;

  /// Track color when on. Default: iOS green, in the system's dark variant (#30D158, measured on a native dark Toggle)
  /// when the theme is dark and #34C759 otherwise.
  final Color? activeColor;

  /// Track color when off; default follows the theme.
  final Color? trackColor;
  final double width;
  final double height;

  /// Shows the pressed look permanently (for tuning the glass).
  /// Shows an activity indicator inside the white thumb (a request is in flight) and locks the switch: it cannot be pressed,
  /// dragged or toggled until [loading] is false again.
  final bool loading;

  final bool debugPressed;

  @override
  State<GlassSwitch> createState() => _GlassSwitchState();
}

class _GlassSwitchState extends State<GlassSwitch>
    with TickerProviderStateMixin {
  // thumb position (native glides, it does not snap: ~0.18 s to the other side, a hair of overshoot: omega 19.5, zeta .67); press (glass thumb grows): a little bouncier, like the native press
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

  // glass -> white thumb: soft, ~0.4 s (omega 11, zeta .8)
  static const _releaseSpring = SpringDescription(
    mass: 1,
    stiffness: 120,
    damping: 17.5,
  );

  // tap: the lens turns back into the white thumb while it jumps across, about 0.15-0.2 s (native: lens kept ~0.3 s after the jump, then frosts over to white)
  static const _tapReleaseSpring = SpringDescription(
    mass: 1,
    stiffness: 220,
    damping: 22,
  );

  late final AnimationController _pos = AnimationController.unbounded(
    vsync: this,
    value: widget.value ? 1 : 0,
  );
  late final AnimationController _press = AnimationController.unbounded(
    vsync: this,
    value: 0,
  );
  bool _down = false;
  bool _dragging = false;
  // where the finger would put the thumb, unclamped (thumb-travel units): the thumb only starts to come back once the
  // finger is back over it, however far it was pulled past the end
  double _dragRaw = 0;

  double get _travel => widget.width - 4 - _thumbW;
  static const _thumbW = 37.0;
  static const _thumbH = 24.0;
  static const _glassW = 59.0;
  static const _glassH = 37.6;
  static const _lensMagnify = 1.5;
  static const _lensRefraction = 1.4;
  static const _lensBezel = 7.0;
  static const _lensSpecular = 1.6;

  @override
  void didUpdateWidget(GlassSwitch old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && !_dragging) {
      _animatePos(widget.value ? 1 : 0);
    }
  }

  // Past the ends the thumb follows the finger with growing resistance (UIScrollView-style rubber band, pt -> pt) and
  // springs back on release (native: the lens can be pulled at most ~8 pt beyond its rest position at the track ends).
  static const _bandLimit = 8.5;
  double _rubber(double raw) {
    if (raw >= 0 && raw <= 1) return raw;
    final over = raw > 1 ? raw - 1 : -raw;
    final pt = over * _travel;
    final shown = (1 - 1 / (pt * 0.7 / _bandLimit + 1)) * _bandLimit;
    final o = shown / _travel;
    return raw > 1 ? 1 + o : -o;
  }

  static double _smooth(double a, double b, double x) {
    final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  // finger velocity at the release (thumb-travel units / s), handed to the spring so a flick carries on physically
  double _releaseVelocity = 0;

  void _animatePos(double to) {
    final v = _releaseVelocity != 0 ? _releaseVelocity : _pos.velocity;
    _releaseVelocity = 0;
    _pos.animateWith(SpringSimulation(_posSpring, _pos.value, to, v));
  }

  // A quick tap still shows the lens, but it turns back into the white thumb right as the thumb lands (a "jump" across,
  // not a stop followed by a change); the turn-back itself is slow and eased (_releaseSpring)
  static const _minLens = Duration(milliseconds: 170);
  static const _tapLens = Duration(milliseconds: 300);
  DateTime _downAt = DateTime.now();
  Timer? _releaseTimer;
  bool _tap = false;

  void _pressDown() {
    _releaseTimer?.cancel();
    _releaseTimer = null;
    _downAt = DateTime.now();
    _setDown(true);
  }

  void _pressUp({bool hold = true, bool tap = false}) {
    _tap = tap;
    // tap: the lens stays while the thumb jumps across (~0.3 s after the release, as in native), then turns back into the white thumb
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

  bool _busy = false;

  void _request(bool next) {
    final async = widget.onChangedAsync;
    if (async == null) {
      widget.onChanged?.call(next);
      _settleOnValue();
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    async(next).whenComplete(() {
      if (!mounted) return;
      setState(() => _busy = false);
      _settleOnValue();
    });
  }

  void _toggle() => _request(!widget.value);

  // The parent decides: if it did not take the new value (it is loading, or refused), the thumb goes back to the value it has
  void _settleOnValue() {
    final v = widget.value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _dragging || widget.value != v) return;
      _animatePos(v ? 1 : 0);
    });
  }

  @override
  void dispose() {
    _releaseTimer?.cancel();
    _pos.dispose();
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final off =
        widget.trackColor ??
        (t.isDark ? const Color(0xFF464649) : const Color(0xFFE9E9EB));
    final on =
        widget.activeColor ??
        (t.isDark ? const Color(0xFF30D158) : const Color(0xFF34C759));
    final enabled = widget.onChanged != null || widget.onChangedAsync != null;
    // locked while loading: the thumb cannot be pressed, dragged or toggled (the switch is not dimmed)
    final loading = widget.loading || _busy;
    final active = enabled && !loading;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // the thumb follows the finger from the touch-down point (no lost touch-slop travel)
        dragStartBehavior: DragStartBehavior.down,
        onTapDown: active ? (_) => _pressDown() : null,
        onTapUp: active ? (_) => _pressUp(tap: true) : null,
        onTapCancel: active ? () => _pressUp(hold: false) : null,
        onTap: active ? _toggle : null,
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
                _dragRaw += d.delta.dx / _travel;
                _pos.value = _rubber(_dragRaw);
              }
            : null,
        onHorizontalDragEnd: enabled
            ? (d) {
                _dragging = false;
                _pressUp();
                // the finger's velocity feeds the spring; a flick decides like a projected 0.12 s of travel
                final v = (d.velocity.pixelsPerSecond.dx / _travel).clamp(
                  -14.0,
                  14.0,
                );
                _releaseVelocity = v;
                final on = _dragRaw + v * 0.12 > 0.5;
                if (on != widget.value) {
                  _request(on);
                } else {
                  _animatePos(on ? 1 : 0);
                }
              }
            : null,
        onHorizontalDragCancel: enabled
            ? () {
                _dragging = false;
                _pressUp(hold: false);
                _animatePos(widget.value ? 1 : 0);
              }
            : null,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: AnimatedBuilder(
            animation: Listenable.merge([_pos, _press]),
            builder: (context, _) {
              final p = _pos.value;
              final k = widget.debugPressed ? 1.0 : _press.value;
              final track = Color.lerp(off, on, p.clamp(0.0, 1.0))!;
              // thumb size grows with the press: white thumb -> glass pill
              final w = _thumbW + (_glassW - _thumbW) * k;
              final h = _thumbH + (_glassH - _thumbH) * k;
              // the glass pill is centered on the thumb and overhangs the track ends (native), where it refracts the dark
              // background: the "C"-shaped dark bands at the ends of the lens
              // pulled past the end the lens only slides on (resisted, max ~8 pt: native), its width stays the same
              final left = 2 + _thumbW / 2 + _travel * p - w / 2;
              final gw = w;
              final gleft = left;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: track,
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                  // soft shadow of the lens (the clear glass draws none): the glass covers it inside, so it only shows around
                  if (k > 0.02)
                    Positioned(
                      left: gleft,
                      top: (widget.height - h) / 2,
                      width: gw,
                      height: h,
                      child: Opacity(
                        opacity: _smooth(0.05, 0.6, k),
                        child: DecoratedBox(
                          decoration: ShapeDecoration(
                            shape: const StadiumBorder(),
                            shadows: [
                              BoxShadow(
                                color: track.withValues(alpha: 0.30),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                              const BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (k > 0.02)
                    Positioned(
                      left: gleft,
                      top: (widget.height - h) / 2,
                      width: gw,
                      height: h,
                      child: OverflowBox(
                        minWidth: 0,
                        minHeight: 0,
                        maxWidth: gw,
                        maxHeight: h,
                        // thin rim lens: the center stays calm, the ends show the dark background bent in (native thumb)
                        // the native lens minifies what is under it (the track shows ~0.6x inside), so tokens get magnify > 1
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            extensions: [
                              t.copyWith(
                                glass: t.glass.copyWith(
                                  liquidMagnify: _lensMagnify,
                                  liquidSpecular: _lensSpecular,
                                ),
                              ),
                            ],
                          ),
                          child: LiquidGlass(
                            width: gw,
                            height: h,
                            clear: true,
                            blur: 0.5,
                            refraction: _lensRefraction,
                            bezel: _lensBezel,
                            presence: 1,
                            shadow: false,
                          ),
                        ),
                      ),
                    ),
                  // the white thumb, ABOVE the lens: it turns frosted-white over the full-size lens and then is the thumb (native: no
                  // shrinking glass blob in between)
                  Positioned(
                    left: left,
                    top: (widget.height - h) / 2,
                    width: w,
                    height: h,
                    child: Opacity(
                      opacity: 1 - _smooth(0.05, 0.75, k),
                      child: DecoratedBox(
                        decoration: const ShapeDecoration(
                          color: Color(0xFFFFFFFF),
                          shape: StadiumBorder(),
                          shadows: [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 4,
                              offset: Offset(0, 1.5),
                            ),
                          ],
                        ),
                        child: loading
                            ? const Center(child: _ThumbSpinner())
                            : null,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// iOS-style activity indicator for the thumb: 8 ticks, a bright head with a fading tail, one turn per second.
class _ThumbSpinner extends StatefulWidget {
  const _ThumbSpinner();
  @override
  State<_ThumbSpinner> createState() => _ThumbSpinnerState();
}

class _ThumbSpinnerState extends State<_ThumbSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: const Size.square(14),
        painter: _SpinnerPainter(_c),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  _SpinnerPainter(this.t) : super(repaint: t);
  final Animation<double> t;

  static const _ticks = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final head = (t.value * _ticks)
        .floor(); // steps like UIActivityIndicatorView
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = r * 0.26;
    for (var i = 0; i < _ticks; i++) {
      final age = (head - i) % _ticks; // 0 = head
      paint.color = const Color(0xFF3C3C43)
          .withValues(alpha: (1 - age / _ticks).clamp(0.12, 1.0) * 0.6);
      final a = (i / _ticks) * 2 * 3.141592653589793 - 3.141592653589793 / 2;
      final d = Offset(Offset.fromDirection(a).dx, Offset.fromDirection(a).dy);
      canvas.drawLine(c + d * (r * 0.5), c + d * (r * 0.95), paint);
    }
  }

  @override
  bool shouldRepaint(_SpinnerPainter old) => false;
}
