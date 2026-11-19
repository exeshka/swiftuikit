import 'dart:async';

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../theme/swift_ui_theme.dart';
import 'glass_lens.dart' show glassSmoothstep;
import 'glass_segment_parts.dart';
import 'glass_surface.dart';
import 'liquid_glass.dart' show LiquidGlassGroup;

/// One tab of a [GlassTabBar].
class GlassTab {
  const GlassTab({required this.icon, required this.label});

  /// Any widget: it gets the tab's color (accent while selected) and size 26 through an [IconTheme].
  final Widget icon;
  final String label;
}

/// The floating tab bar of iOS 26 (measured on a native `TabView`): a compact glass capsule (58 pt high, 90 pt per tab,
/// centered, not full width) with an icon over a label for every tab. The selected tab is tinted with the accent color and
/// sits on its own capsule, which behaves like the thumb of [GlassSegmentedControl]: a touch pulls it to the tab under the
/// finger and turns it into a glass lens, it can be dragged along the bar (rubber band past the ends) and settles on the
/// nearest tab on a spring; a flick carries on.
///
/// Put it into [BottomDock.navBar].
class GlassTabBar extends StatefulWidget {
  const GlassTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    this.height = 58,
    this.tabWidth = 90,
    this.debugPressed = false,
  });

  final List<GlassTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double height;
  final double tabWidth;

  /// Shows the pressed look permanently (for tuning the glass).
  final bool debugPressed;

  @override
  State<GlassTabBar> createState() => _GlassTabBarState();
}

class _GlassTabBarState extends State<GlassTabBar>
    with TickerProviderStateMixin {
  // the same springs as the segmented control and the switch (the thumb behaves alike)
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
  static const _inset = 4.0;
  static const _bandLimit = 8.5;

  late final AnimationController _pos = AnimationController.unbounded(
    vsync: this,
    value: widget.selectedIndex.toDouble(),
  );
  late final AnimationController _press = AnimationController.unbounded(
    vsync: this,
    value: 0,
  );
  bool _down = false;
  bool _dragging = false;
  bool _tap = false;
  double _dragRaw = 0;
  double _releaseVelocity = 0;

  @override
  void didUpdateWidget(GlassTabBar old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex && !_dragging && !_down) {
      _animatePos(widget.selectedIndex.toDouble());
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

  // past the ends the thumb follows with growing resistance and springs back on release
  double _rubber(double raw) {
    final max = widget.tabs.length - 1.0;
    if (raw >= 0 && raw <= max) return raw;
    final over = raw > max ? raw - max : -raw;
    final shown =
        (1 - 1 / (over * widget.tabWidth * 0.7 / _bandLimit + 1)) * _bandLimit;
    final o = shown / widget.tabWidth;
    return raw > max ? max + o : -o;
  }

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
    if (i != widget.selectedIndex) widget.onSelected(i);
    _animatePos(i.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final w = widget.tabWidth;
    final h = widget.height;
    final n = widget.tabs.length;
    int indexAt(double dx) => ((dx - _inset) / w).floor().clamp(0, n - 1);
    return Center(
      // room below the bar for the pressed lens, which overhangs it (the dock clips its content)
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: SizedBox(
          width: w * n + _inset * 2,
          height: h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: GlassSurface(
                  shape: const StadiumBorder(),
                  interactive: false,
                  child: SizedBox(
                    width: w * n + _inset * 2,
                    height: h,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      dragStartBehavior: DragStartBehavior.down,
                      onTapDown: (d) {
                        _pressDown();
                        _animatePos(indexAt(d.localPosition.dx).toDouble());
                      },
                      onTapUp: (d) {
                        _pressUp(tap: true);
                        _select(indexAt(d.localPosition.dx));
                      },
                      onTapCancel: () {
                        if (_dragging) return;
                        _pressUp(hold: false);
                        _animatePos(widget.selectedIndex.toDouble());
                      },
                      onHorizontalDragStart: (_) {
                        _dragging = true;
                        _dragRaw = _pos.value;
                        _pos.stop();
                        _pressDown();
                      },
                      onHorizontalDragUpdate: (d) {
                        _dragRaw += d.delta.dx / w;
                        _pos.value = _rubber(_dragRaw);
                      },
                      onHorizontalDragEnd: (d) {
                        _dragging = false;
                        _pressUp();
                        final v = (d.velocity.pixelsPerSecond.dx / w).clamp(
                          -14.0,
                          14.0,
                        );
                        _releaseVelocity = v;
                        _select((_dragRaw + v * 0.12).round().clamp(0, n - 1));
                      },
                      onHorizontalDragCancel: () {
                        _dragging = false;
                        _pressUp(hold: false);
                        _animatePos(widget.selectedIndex.toDouble());
                      },
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_pos, _press]),
                        builder: (context, _) {
                          final k = widget.debugPressed ? 1.0 : _press.value;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // the selected tab's capsule: a thumb at rest, a glass lens while pressed (as in the segmented control)
                              ...SegmentVisuals.thumb(
                                t,
                                left: _inset + w * _pos.value,
                                top: _inset,
                                width: w,
                                height: h - _inset * 2,
                                k: k,
                                restColor: t.colors.foreground.withValues(
                                  alpha: 0.12,
                                ),
                                // the lens overhangs a dark bar: a gentle rim, or the bar's edges bend into a bow tie
                                lens: false,
                              ),
                              Positioned.fill(
                                left: _inset,
                                right: _inset,
                                child: Row(
                                  children: [
                                    for (var i = 0; i < n; i++)
                                      SizedBox(
                                        width: w,
                                        child: _TabItem(
                                          tab: widget.tabs[i],
                                          selected: 0,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // the same row in the accent colour, visible only inside the capsule / lens (as in the native
                              // bar: the part of an icon under the lens is tinted, the rest keeps its colour)
                              Positioned.fill(
                                child: ClipPath(
                                  clipper: _CapsuleClip(
                                    Rect.fromLTWH(
                                      _inset + w * _pos.value - 15 * k,
                                      _inset - 13 * k,
                                      w + 30 * k,
                                      h - _inset * 2 + 26 * k,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: _inset,
                                    ),
                                    child: Row(
                                      children: [
                                        for (var i = 0; i < n; i++)
                                          SizedBox(
                                            width: w,
                                            child: _TabItem(
                                              tab: widget.tabs[i],
                                              selected: 1,
                                            ),
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
                    ),
                  ),
                ),
              ),
              // the lens is its own layer ABOVE the bar and its icons: only then does its backdrop include them
              // (inside the bar's glass it would sample the page below and ignore the icons)
              Positioned.fill(
                child: IgnorePointer(
                  // its own group: inside the scaffold's shared one the lens would sample the page below the bar
                  child: LiquidGlassGroup(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_pos, _press]),
                      builder: (context, _) {
                        final k = widget.debugPressed ? 1.0 : _press.value;
                        // the distortion grows with the press and is gone before the lens turns into the flat capsule
                        final dist = glassSmoothstep(
                          0.1,
                          0.9,
                          k.clamp(0.0, 1.0),
                        );
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ...SegmentVisuals.thumb(
                              t,
                              left: _inset + w * _pos.value,
                              top: _inset,
                              width: w,
                              height: h - _inset * 2,
                              k: k,
                              rest: false,
                              lensBlur: 0.15,
                              darkToneLift: 0.12 * dist,
                              refraction: 1.1 * dist,
                              bezel: 10,
                              magnify: 1 - 0.1 * dist,
                              growWidth: 30,
                              growHeight: 26,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.tab, required this.selected});
  final GlassTab tab;

  /// 0..1, how much the tab is the selected one (follows the thumb while it moves).
  final double selected;

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final color = Color.lerp(t.glass.glassIcon, t.colors.accent, selected)!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconTheme(
          data: IconThemeData(color: color, size: 26),
          child: tab.icon,
        ),
        const SizedBox(height: 2),
        Text(
          tab.label,
          maxLines: 1,
          style: t.typography.caption.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _CapsuleClip extends CustomClipper<Path> {
  const _CapsuleClip(this.rect);
  final Rect rect;
  @override
  Path getClip(Size size) => Path()
    ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)));
  @override
  bool shouldReclip(_CapsuleClip old) => old.rect != rect;
}
