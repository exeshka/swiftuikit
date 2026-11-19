import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../theme/swift_ui_theme.dart';
import 'glass_segment_parts.dart';
import 'glass_segmented.dart' show GlassSegment;

/// Where a tapped segment is scrolled to when it does not already sit there.
enum GlassSegmentAlign {
  /// Scrolls only as much as it takes to bring the segment fully into view.
  nearest,

  /// The segment goes to the start (left) edge of the strip.
  start,

  /// The segment goes to the middle of the strip.
  center,

  /// The segment goes to the end (right) edge of the strip.
  end,
}

/// Keeps the scroll position of several [GlassScrollSegments] in step. Needed when the same strip is built twice, as a
/// [PinnedHeader] does (the copy in the list and the copy the scaffold shows above the blur while it is stuck): without it
/// the strip jumps back to its start when the header sticks or unsticks after it was scrolled sideways.
class GlassScrollSegmentsController extends ChangeNotifier {
  double _offset = 0;
  double get offset => _offset;

  void _set(double v) {
    if ((v - _offset).abs() < 0.01) return;
    _offset = v;
    notifyListeners();
  }
}

/// A horizontally scrollable strip of segments (folders / filters, like the chat folders of messengers): the same glass
/// track, white thumb and pressed glass lens as [GlassSegmentedControl], but the segments take the width of their
/// content and the strip scrolls when they do not fit. The thumb glides to the tapped segment on a spring and the strip
/// scrolls to keep it in view.
class GlassScrollSegments<T> extends StatefulWidget {
  const GlassScrollSegments({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.height = 36,
    this.itemPadding = 14,
    this.controller,
    this.glass = false,
    this.thumbColor,
    this.position,
    this.scrollAlign = GlassSegmentAlign.center,
    this.debugPressed = false,
  });

  /// The track is a liquid glass capsule (messenger look) instead of the faint frosted one.
  final bool glass;

  /// Color of the thumb at rest; null: the default of the theme.
  final Color? thumbColor;

  /// Where a segment goes when it is selected (tapped, or selected from outside): the strip scrolls there smoothly. The ends
  /// clamp, so the first and the last segments never leave a gap.
  final GlassSegmentAlign scrollAlign;

  /// Drives the thumb (a fractional segment index) instead of the strip's own spring: for a strip that follows a pager
  /// (`PageView.controller.page`) while it is swiped. The strip then only reports taps through [onChanged]; the owner moves
  /// the pager and the thumb follows it.
  final ValueListenable<double>? position;

  /// Share one between the copies of the strip, see [GlassScrollSegmentsController].
  final GlassScrollSegmentsController? controller;

  final List<GlassSegment<T>> segments;
  final T value;
  final ValueChanged<T>? onChanged;
  final double height;

  /// Horizontal padding inside every segment.
  final double itemPadding;

  /// Shows the pressed look permanently (for tuning the glass).
  final bool debugPressed;

  @override
  State<GlassScrollSegments<T>> createState() => _GlassScrollSegmentsState<T>();
}

class _GlassScrollSegmentsState<T> extends State<GlassScrollSegments<T>>
    with TickerProviderStateMixin {
  // same springs as GlassSegmentedControl / GlassSwitch
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
  static const _gap = 2.0;

  late final AnimationController _pos = AnimationController.unbounded(
    vsync: this,
    value: _index.toDouble(),
  );
  late final AnimationController _press = AnimationController.unbounded(
    vsync: this,
    value: 0,
  );
  late final ScrollController _scroll = ScrollController(
    initialScrollOffset: widget.controller?.offset ?? 0,
  );
  bool _applying = false;
  bool _down = false;
  bool _tap = false;
  Timer? _releaseTimer;
  DateTime _downAt = DateTime.now();

  // measured item geometry (content coordinates), recomputed when the strip is laid out
  List<double> _lefts = const [];
  List<double> _widths = const [];
  double _viewport = 0;
  double _content = 0;

  int get _index => widget.segments
      .indexWhere((s) => s.value == widget.value)
      .clamp(0, widget.segments.length - 1);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScrolled);
    widget.controller?.addListener(_onShared);
    widget.position?.addListener(_onPosition);
    _onPosition();
  }

  void _onPosition() {
    final pos = widget.position;
    if (pos == null || !mounted) return;
    _pos.stop();
    _pos.value = pos.value.clamp(0.0, widget.segments.length - 1.0);
  }

  void _onScrolled() {
    if (_applying || !_scroll.hasClients) return;
    widget.controller?._set(_scroll.offset);
  }

  void _onShared() {
    final c = widget.controller;
    if (c == null || !_scroll.hasClients) return;
    if ((_scroll.offset - c.offset).abs() < 0.5) return;
    _applying = true;
    _scroll.jumpTo(
      c.offset.clamp(
        _scroll.position.minScrollExtent,
        _scroll.position.maxScrollExtent,
      ),
    );
    _applying = false;
  }

  @override
  void didUpdateWidget(GlassScrollSegments<T> old) {
    super.didUpdateWidget(old);
    if (old.position != widget.position) {
      old.position?.removeListener(_onPosition);
      widget.position?.addListener(_onPosition);
      _onPosition();
    }
    if (old.controller != widget.controller) {
      old.controller?.removeListener(_onShared);
      widget.controller?.addListener(_onShared);
    }
    if (old.value != widget.value && !_down) {
      _animatePos(_index.toDouble());
      _reveal(_index);
    }
  }

  @override
  void dispose() {
    _releaseTimer?.cancel();
    _delayTimer?.cancel();
    widget.controller?.removeListener(_onShared);
    widget.position?.removeListener(_onPosition);
    _scroll.removeListener(_onScrolled);
    _pos.dispose();
    _press.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _animatePos(double to) {
    if (widget.position != null) return; // the owner drives the thumb
    _pos.animateWith(
      SpringSimulation(_posSpring, _pos.value, to, _pos.velocity),
    );
  }

  /// Scrolls the strip so that item [i] sits where [GlassSegmentAlign] says, smoothly (it clamps at both ends).
  void _reveal(int i) {
    if (!_scroll.hasClients || _lefts.isEmpty || _content <= _viewport) return;
    const margin = 12.0;
    final itemLeft = _lefts[i];
    final itemW = _widths[i];
    double target;
    switch (widget.scrollAlign) {
      case GlassSegmentAlign.start:
        target = itemLeft - margin;
      case GlassSegmentAlign.center:
        target = itemLeft + itemW / 2 - _viewport / 2;
      case GlassSegmentAlign.end:
        target = itemLeft + itemW - _viewport + margin;
      case GlassSegmentAlign.nearest:
        final left = itemLeft - _scroll.offset;
        final right = left + itemW;
        if (left < margin) {
          target = itemLeft - margin;
        } else if (right > _viewport - margin) {
          target = itemLeft + itemW - _viewport + margin;
        } else {
          return;
        }
    }
    target = target.clamp(0.0, _content - _viewport);
    if ((target - _scroll.offset).abs() < 0.5) return;
    _scroll.animateTo(
      target,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  // A finger that lands on the strip may be about to scroll the page (or the strip), not to tap. The press (lens and the pull
  // of the thumb) therefore starts a moment after the touch; a scroll that takes over within that moment never shows it.
  static const _pressDelay = Duration(milliseconds: 110);
  Timer? _delayTimer;
  bool _pressStarted = false;

  void _touchDown(int i) {
    _delayTimer?.cancel();
    _pressStarted = false;
    _delayTimer = Timer(_pressDelay, () {
      _delayTimer = null;
      _pressStarted = true;
      _pressDown();
      _animatePos(i.toDouble());
    });
  }

  /// A tap before the delay ran out: start the press now, so a quick tap still shows it.
  void _touchTap(int i) {
    if (_delayTimer != null) {
      _delayTimer!.cancel();
      _delayTimer = null;
      _pressDown();
    }
    _pressStarted = false;
  }

  void _touchCancel() {
    final started = _pressStarted;
    _delayTimer?.cancel();
    _delayTimer = null;
    _pressStarted = false;
    if (!started) return;
    _pressUp(hold: false);
    _animatePos(_index.toDouble());
  }

  void _pressDown() {
    _releaseTimer?.cancel();
    _releaseTimer = null;
    _downAt = DateTime.now();
    _setDown(true);
  }

  void _pressUp({bool hold = true, bool tap = false}) {
    _tap = tap;
    final left = tap
        ? const Duration(milliseconds: 300)
        : const Duration(milliseconds: 170) -
              DateTime.now().difference(_downAt);
    if (!hold || left <= Duration.zero) {
      _setDown(false);
      return;
    }
    _releaseTimer?.cancel();
    _releaseTimer = Timer(left, () {
      _releaseTimer = null;
      if (mounted) _setDown(false);
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

  void _measure(SwiftUiThemeData t, double viewport) {
    final n = widget.segments.length;
    final style = SegmentVisuals.labelStyle(
      t,
      1,
    ); // the widest (selected, semibold) look, so nothing jumps
    final w = <double>[];
    for (final s in widget.segments) {
      var width = widget.itemPadding * 2;
      if (s.icon != null) width += 18 + (s.label != null ? 6 : 0);
      if (s.label != null) {
        final tp = TextPainter(
          text: TextSpan(text: s.label, style: style),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();
        width += tp.width;
      }
      if (s.badge != null) width += 6 + 18;
      w.add(width);
    }
    var total =
        w.fold<double>(0, (a, b) => a + b) + _gap * (n - 1) + _padding * 2;
    // everything fits: spread over the full width like a plain segmented control
    if (total < viewport) {
      final extra = (viewport - total) / n;
      for (var i = 0; i < n; i++) {
        w[i] += extra;
      }
      total = viewport;
    }
    final l = <double>[];
    var x = _padding;
    for (final width in w) {
      l.add(x);
      x += width + _gap;
    }
    _widths = w;
    _lefts = l;
    _content = total;
    _viewport = viewport;
  }

  double _lerpIdx(List<double> v, double p) {
    final i = p.floor().clamp(0, v.length - 1);
    final j = (i + 1).clamp(0, v.length - 1);
    return v[i] + (v[j] - v[i]) * (p - i).clamp(0.0, 1.0);
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
          Text(s.label!, maxLines: 1, softWrap: false, style: style),
        if (s.badge != null) ...[
          const SizedBox(width: 6),
          Container(
            constraints: const BoxConstraints(minWidth: 18),
            height: 18,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              shape: const StadiumBorder(),
              color: t.colors.foreground.withValues(
                alpha: selected > 0.5 ? 0.18 : 0.12,
              ),
            ),
            child: Text(
              s.badge!,
              style: t.typography.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: style.color,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final enabled = widget.onChanged != null;
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, c) {
          _measure(t, c.maxWidth);
          final thumbH = widget.height - _padding * 2;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: widget.glass
                    ? SegmentVisuals.glassTrack(c.maxWidth, widget.height)
                    : SegmentVisuals.track(t),
              ),
              // The thumb layers live outside the scroll view so that the pressed lens (bigger than the thumb) is not cut by the
              // edge of the strip; they follow the scroll offset themselves. Clipped to the strip, with room for the lens.
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_pos, _press, _scroll]),
                  builder: (context, _) {
                    final k = widget.debugPressed ? 1.0 : _press.value;
                    final off = _scroll.hasClients
                        ? _scroll.offset
                        : (widget.controller?.offset ?? 0.0);
                    final room =
                        (SegmentVisuals.growW / 2 + 2) * k.clamp(0.0, 1.0);
                    return ClipRect(
                      clipper: _HorizontalClip(room),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: SegmentVisuals.thumb(
                          t,
                          left: _lerpIdx(_lefts, _pos.value) - off,
                          top: _padding,
                          width: _lerpIdx(_widths, _pos.value),
                          height: thumbH,
                          k: k,
                          restColor: widget.thumbColor,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned.fill(
                // clip to the strip horizontally only: the lens overhangs the track at the top and bottom
                child: ClipRect(
                  clipper: _HorizontalClip(0),
                  child: SingleChildScrollView(
                    controller: _scroll,
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    physics: const BouncingScrollPhysics(),
                    dragStartBehavior: DragStartBehavior.down,
                    child: SizedBox(
                      width: _content,
                      height: widget.height,
                      child: AnimatedBuilder(
                        animation: _pos,
                        builder: (context, _) {
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              for (var i = 0; i < widget.segments.length; i++)
                                Positioned(
                                  left: _lefts[i],
                                  top: 0,
                                  width: _widths[i],
                                  height: widget.height,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTapDown: enabled
                                        ? (_) {
                                            _touchDown(i);
                                          }
                                        : null,
                                    onTapUp: enabled
                                        ? (_) {
                                            _touchTap(i);
                                            _pressUp(tap: true);
                                            if (widget.segments[i].value !=
                                                widget.value) {
                                              widget.onChanged!(
                                                widget.segments[i].value,
                                              );
                                            }
                                            _animatePos(i.toDouble());
                                            _reveal(i);
                                          }
                                        : null,
                                    // a scroll took over: the thumb goes back to the selected segment
                                    onTapCancel: enabled
                                        ? () {
                                            _touchCancel();
                                          }
                                        : null,
                                    child: Center(
                                      child: _label(
                                        t,
                                        widget.segments[i],
                                        (1 - (_pos.value - i).abs()).clamp(
                                          0.0,
                                          1.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HorizontalClip extends CustomClipper<Rect> {
  _HorizontalClip(this.room);

  /// How far the clip reaches past the strip on the left and the right.
  final double room;
  @override
  Rect getClip(Size s) =>
      Rect.fromLTRB(-room, -40, s.width + room, s.height + 40);
  @override
  bool shouldReclip(covariant _HorizontalClip old) => old.room != room;
}
