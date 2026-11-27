import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../theme/swift_ui_theme.dart';
import 'glass_lens.dart' show glassSmoothstep;
import 'glass_segment_parts.dart';
import 'glass_surface.dart';
import 'liquid_glass.dart' show LiquidGlassGroup;

/// Where a [GlassTabBar] accessory is: a separate glass plate over the bar ([expanded]) or, while the bar is collapsed into its
/// round button, in the same row to the right of it ([inline]). Natively `tabViewBottomAccessoryPlacement`.
enum GlassTabBarAccessoryPlacement { expanded, inline }

/// One tab of a [GlassTabBar].
class GlassTab {
  const GlassTab({required this.icon, required this.label});

  /// Any widget: it gets the tab's color (accent while selected) and size 26 through an [IconTheme].
  final Widget icon;
  final String label;
}

/// The floating tab bar of iOS 26 (measured on a native `TabView`): a compact glass capsule (62 pt high, 85.7 pt per tab,
/// centered, not full width; the tabs shrink to fit a narrow screen) with an icon over a label for every tab. The selected tab is tinted with the accent color and
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
    this.height = 62,
    this.tabWidth = 85.7,
    this.debugPressed = false,
    this.minimized = false,
    this.onExpand,
    this.accessory,
    this.accessoryBuilder,
    this.accessoryProgressBuilder,
    this.accessoryCrossfade = true,
    this.onAccessoryTap,
    this.accessoryGlass = true,
  });

  final List<GlassTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double height;
  final double tabWidth;

  /// Collapses the bar into a round button with the selected tab's icon at the left (iOS 26 `tabBarMinimizeBehavior`, which the
  /// native bar does while its page scrolls down). The app drives it from its scroll position; [onExpand] is called on a tap on the
  /// collapsed button.
  final bool minimized;
  final VoidCallback? onExpand;

  /// A plate next to the bar (the mini player of a music app, natively `tabViewBottomAccessory`). Over the bar while it is
  /// expanded; in the row of the collapsed button, right of it, while the bar is collapsed ([minimized]). With an accessory the
  /// bar is as wide as the screen allows (native: 21.5 pt margins) and the tabs share its width. Measured: the plate is 47.7 pt
  /// high in both places, 8.7 pt over the bar when expanded and 8.3 pt from the round button when inline, which keeps the
  /// bar's centre line. [accessoryBuilder] gets the placement (the content is rebuilt for it, early in the transition);
  /// [accessory] is the same content for both.
  final Widget? accessory;
  final Widget Function(
    BuildContext context,
    GlassTabBarAccessoryPlacement placement,
  )?
  accessoryBuilder;

  /// A tap on the accessory (it gets the pressed glass response when set).
  final VoidCallback? onAccessoryTap;

  /// Draw the glass plate behind the accessory (false: the accessory brings its own surface).
  final bool accessoryGlass;

  /// For an accessory whose shared elements travel: gets the transition itself, `progress` 0 = expanded .. 1 = inline (follows the
  /// collapse of the bar continuously, springs included: it may leave 0..1 a little). Wins over [accessoryBuilder] / [accessory].
  final Widget Function(BuildContext context, double progress)?
  accessoryProgressBuilder;

  /// With [accessoryBuilder]: build both layouts during the transition and cross-fade them (true, the default) instead of swapping
  /// them at once. Natively the content is cut over in a single frame (measured, a few ms) with the icon and the play button staying
  /// at the edges of the plate; the layouts here fill the plate and are cut to its shape, so they stay at the edges as well.
  final bool accessoryCrossfade;

  /// Shows the pressed look permanently (for tuning the glass).
  final bool debugPressed;

  @override
  State<GlassTabBar> createState() => _GlassTabBarState();
}

class _GlassTabBarState extends State<GlassTabBar>
    with TickerProviderStateMixin {
  // the lens travelling to the tapped tab: fitted to the native bar (slow-motion recording, lens centre, rmse 1.3 pt):
  // omega 16 rad/s, zeta 0.85 (no overshoot)
  static const _posSpring = SpringDescription(
    mass: 1,
    stiffness: 256,
    damping: 27.2,
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
  static const _pad = 8.5; // bar edge to the first tab
  static const _inset = 4.15; // bar edge to the selected capsule (top)
  double _ext = 3.8; // the capsule is wider than its tab on each side (a little more on wide tabs: native 3.8 pt at 85.7, 4.9 at 114)
  static const _bandLimit = 8.5;

  late final AnimationController _pos = AnimationController.unbounded(
    vsync: this,
    value: widget.selectedIndex.toDouble(),
  );
  late final AnimationController _min = AnimationController.unbounded(
    vsync: this,
    value: widget.minimized ? 1 : 0,
  );
  // fitted to the native bar's accessory plate (slow-motion recording, rmse 1.2-1.3 px): the plate travels down on a slower, softer
  // spring (omega 12 rad/s, zeta 0.6) and back up on a quicker one (omega 22, zeta 0.75, a 2 pt undershoot)
  static const _collapseSpring = SpringDescription(
    mass: 1,
    stiffness: 144,
    damping: 14.4,
  );
  static const _expandSpring = SpringDescription(
    mass: 1,
    stiffness: 484,
    damping: 33,
  );
  static const _accH = 47.7;
  static const _accGap = 8.7;
  static const _minSize = 47.7; // the collapsed button (native)
  static const _minLeft = 28.3;
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
    if (old.minimized != widget.minimized) {
      _min.animateWith(
        SpringSimulation(
          widget.minimized ? _collapseSpring : _expandSpring,
          _min.value,
          widget.minimized ? 1 : 0,
          _min.velocity,
        ),
      );
    }
    if (old.selectedIndex != widget.selectedIndex && !_dragging && !_down) {
      _animatePos(widget.selectedIndex.toDouble());
    }
  }

  @override
  void dispose() {
    _releaseTimer?.cancel();
    _holdTimer?.cancel();
    _pos.dispose();
    _press.dispose();
    _min.dispose();
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
  static const _tapLens = Duration(milliseconds: 170);
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

  // native: a quick tap swells the lens to ~0.68 of its held size (106 pt wide instead of 115), holding grows it on
  static const _tapK = 0.8;
  // how much of the held lens size a press value gives: a quick tap (k = _tapK) reaches 68 % of the width growth and
  // 88 % of the height growth (native, measured on the lens travelling to a tapped tab)
  static double _wk(double k) =>
      k <= _tapK ? k * 0.85 : 0.68 + (k - _tapK) / (1 - _tapK) * 0.32;
  static double _hk(double k) =>
      k <= _tapK ? k * 1.1 : 0.88 + (k - _tapK) / (1 - _tapK) * 0.12;
  static const _holdAfter = Duration(milliseconds: 320);
  Timer? _holdTimer;

  void _pressTo(double k) {
    _press.animateWith(
      SpringSimulation(_pressSpring, _press.value, k, _press.velocity),
    );
  }

  void _setDown(bool v) {
    if (_down == v) return;
    _down = v;
    _holdTimer?.cancel();
    if (v) {
      _pressTo(_tapK);
      _holdTimer = Timer(_holdAfter, () {
        if (mounted && _down) _pressTo(1);
      });
      return;
    }
    _press.animateWith(
      SpringSimulation(
        _tap ? _tapReleaseSpring : _releaseSpring,
        _press.value,
        0,
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
    final h = widget.height;
    final n = widget.tabs.length;
    return LayoutBuilder(
      builder: (context, c) {
        // five tabs on a 402 pt screen: the bar keeps ~21 pt of margin and the tabs shrink to fit
        final hasAcc =
            widget.accessory != null ||
            widget.accessoryBuilder != null ||
            widget.accessoryProgressBuilder != null;
        final fit = c.maxWidth.isFinite
            ? (c.maxWidth - 43 - _pad * 2) / n
            : widget.tabWidth;
        // with an accessory the bar takes the whole width and the tabs share it
        final w = hasAcc && c.maxWidth.isFinite
            ? fit
            : widget.tabWidth.clamp(0.0, fit);
        _ext = 3.8 + (w - 85.7).clamp(0.0, double.infinity) * 0.0386;
        int indexAt(double dx) => ((dx - _pad) / w).floor().clamp(0, n - 1);
        final dark = t.brightness == Brightness.dark;
        return AnimatedBuilder(
          animation: _min,
          builder: (context, _) {
            final m = _min.value.clamp(0.0, 1.0);
            final bw = lerpDouble(w * n + _pad * 2, _minSize, m)!;
            final bh = lerpDouble(h, _minSize, m)!;
            // the tab row slides so that the selected tab ends up in the middle of the collapsed button
            final rowLeft = lerpDouble(
              _pad,
              _minSize / 2 - w * (widget.selectedIndex + 0.5),
              m,
            )!;
            final sel = widget.selectedIndex;
            // the layout height never changes (the collapsed button is centred in it): the pages under the bar keep their insets
            final barBox = SizedBox(
              height: h + 14,
              child: Padding(
                padding: EdgeInsets.only(left: _minLeft * m),
                child: Align(
                  alignment: Alignment(-m, 0),
                  // room below the bar for the pressed lens, which overhangs it (the dock clips its content)
                  // the native bar sits 21.3 pt above the bottom edge: 3 pt lower than the dock's padding alone would put it
                  child: Transform.translate(
                    // the collapsed button keeps the bar's vertical centre (native)
                    offset: const Offset(0, 3),
                    // the whole bar swells while it is pressed (native: x1.054, measured on a held tab)
                    child: AnimatedBuilder(
                      animation: _press,
                      builder: (context, child) => Transform.scale(
                        scale:
                            1 +
                            0.054 *
                                _wk(
                                  (widget.debugPressed ? 1.0 : _press.value)
                                      .clamp(0.0, 1.2),
                                ),
                        child: child,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: SizedBox(
                          width: bw,
                          height: bh,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned.fill(
                                child: GlassSurface(
                                  shape: const StadiumBorder(),
                                  interactive: false,
                                  child: SizedBox(
                                    width: bw,
                                    height: bh,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      dragStartBehavior: DragStartBehavior.down,
                                      onTapUp: (d) {
                                        if (m > 0.5) {
                                          widget.onExpand?.call();
                                          return;
                                        }
                                        _pressUp(tap: true);
                                        _select(indexAt(d.localPosition.dx));
                                      },
                                      onTapCancel: () {
                                        if (_dragging) return;
                                        _pressUp(hold: false);
                                        _animatePos(
                                          widget.selectedIndex.toDouble(),
                                        );
                                      },
                                      onHorizontalDragStart: (_) {
                                        if (m > 0.5) return;
                                        _dragging = true;
                                        _dragRaw = _pos.value;
                                        _pos.stop();
                                        _pressDown();
                                      },
                                      onHorizontalDragUpdate: (d) {
                                        if (m > 0.5) return;
                                        _dragRaw += d.delta.dx / w;
                                        _pos.value = _rubber(_dragRaw);
                                      },
                                      onHorizontalDragEnd: (d) {
                                        _dragging = false;
                                        _pressUp();
                                        final v =
                                            (d.velocity.pixelsPerSecond.dx / w)
                                                .clamp(-14.0, 14.0);
                                        _releaseVelocity = v;
                                        _select(
                                          (_dragRaw + v * 0.12 - 1e-6)
                                              .round()
                                              .clamp(0, n - 1),
                                        );
                                      },
                                      onHorizontalDragCancel: () {
                                        // also fired by every plain tap (the drag recogniser is rejected): that one is no drag
                                        if (!_dragging) return;
                                        _dragging = false;
                                        _pressUp(hold: false);
                                        _animatePos(
                                          widget.selectedIndex.toDouble(),
                                        );
                                      },
                                      child: AnimatedBuilder(
                                        animation: Listenable.merge([
                                          _pos,
                                          _press,
                                        ]),
                                        builder: (context, _) {
                                          final k = widget.debugPressed
                                              ? 1.0
                                              : _press.value;
                                          final capsule = Rect.fromLTWH(
                                            _pad -
                                                _ext +
                                                w * _pos.value -
                                                7.9 * _wk(k),
                                            _inset - 7.3 * _hk(k),
                                            w + _ext * 2 + 15.8 * _wk(k),
                                            h - _inset * 2 + 14.6 * _hk(k),
                                          );
                                          final dist = glassSmoothstep(
                                            0.1,
                                            0.9,
                                            k.clamp(0.0, 1.0),
                                          );
                                          return Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              // the selected tab's capsule: a thumb at rest, a glass lens while pressed (as in the segmented control)
                                              ...SegmentVisuals.thumb(
                                                t,
                                                left:
                                                    _pad -
                                                    _ext +
                                                    w * _pos.value,
                                                top: _inset,
                                                width: w + _ext * 2,
                                                height: h - _inset * 2,
                                                k: k,
                                                // measured on the native bar: white 20 % over a dark bar, black 6.5 % over a light one
                                                restColor:
                                                    (dark
                                                            ? const Color(
                                                                0xFFFFFFFF,
                                                              )
                                                            : const Color(
                                                                0xFF000000,
                                                              ))
                                                        .withValues(
                                                          alpha:
                                                              (dark
                                                                  ? 0.20
                                                                  : 0.065) *
                                                              (1 - m),
                                                        ),
                                                // the lens overhangs a dark bar: a gentle rim, or the bar's edges bend into a bow tie
                                                lens: false,
                                              ),

                                              Positioned.fill(
                                                child: ClipPath(
                                                  clipper: _OutsideCapsuleClip(
                                                    capsule,
                                                  ),
                                                  child: Stack(
                                                    children: [
                                                      Positioned(
                                                        left: rowLeft,
                                                        top: 0,
                                                        bottom: 0,
                                                        width: w * n,
                                                        child: Row(
                                                          children: [
                                                            for (
                                                              var i = 0;
                                                              i < n;
                                                              i++
                                                            )
                                                              SizedBox(
                                                                width: w,
                                                                child: _TabItem(
                                                                  tab: widget
                                                                      .tabs[i],
                                                                  selected:
                                                                      i == sel
                                                                      ? m
                                                                      : 0,
                                                                  collapse:
                                                                      i == sel
                                                                      ? null
                                                                      : m,
                                                                  labelFade: m,
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              // the same row in the accent colour, visible only inside the capsule / lens (as in the native bar: the part of an icon
                                              // under the lens is tinted, the rest keeps its colour); inside the lens it is magnified, as the glass does natively
                                              Positioned.fill(
                                                child: ClipPath(
                                                  clipper: _CapsuleClip(
                                                    capsule,
                                                  ),
                                                  child: Stack(
                                                    children: [
                                                      Positioned(
                                                        left: rowLeft,
                                                        top: 0,
                                                        bottom: 0,
                                                        width: w * n,
                                                        child: Transform(
                                                          transform:
                                                              Matrix4.diagonal3Values(
                                                                1 + 0.22 * dist,
                                                                1 + 0.22 * dist,
                                                                1,
                                                              ),
                                                          origin: Offset(
                                                            capsule.center.dx -
                                                                rowLeft,
                                                            h / 2,
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              for (
                                                                var i = 0;
                                                                i < n;
                                                                i++
                                                              )
                                                                SizedBox(
                                                                  width: w,
                                                                  child: _TabItem(
                                                                    tab: widget
                                                                        .tabs[i],
                                                                    selected: 1,
                                                                    collapse:
                                                                        i == sel
                                                                        ? null
                                                                        : m,
                                                                    labelFade:
                                                                        m,
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
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
                                      animation: Listenable.merge([
                                        _pos,
                                        _press,
                                      ]),
                                      builder: (context, _) {
                                        final k = widget.debugPressed
                                            ? 1.0
                                            : _press.value;
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
                                              left:
                                                  _pad - _ext + w * _pos.value,
                                              top: _inset,
                                              width: w + _ext * 2,
                                              height: h - _inset * 2,
                                              k: k,
                                              rest: false,
                                              lensBlur: 0.15,
                                              darkToneLift: 0.02 * dist,
                                              refraction: 0.9 * dist,
                                              lightBand: false,
                                              specular: 2.8,
                                              bezel: 10,
                                              magnify: 1,
                                              growWidth: k > 0.001
                                                  ? 15.8 * _wk(k) / k
                                                  : 15.8,
                                              growHeight: k > 0.001
                                                  ? 14.6 * _hk(k) / k
                                                  : 14.6,
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              // the press starts with the finger: a tap recogniser would report its down only after the press
                              // timeout (a drag competes with it), the lens would swell once the finger is already up
                              Positioned.fill(
                                child: Listener(
                                  behavior: HitTestBehavior.translucent,
                                  onPointerDown: (e) {
                                    if (m > 0.5) return;
                                    _pressDown();
                                    _animatePos(
                                      indexAt(e.localPosition.dx).toDouble(),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            return _withAccessory(context, barBox, m, c.maxWidth, bw, h);
          },
        );
      },
    );
  }

  // the bar's own box (76 pt) sits 53.4 pt below the top of the stack, so that its visible top (3 pt lower, see above) is 56.4 =
  // accessory + gap below the top
  Widget _withAccessory(
    BuildContext context,
    Widget barBox,
    double m,
    double maxWidth,
    double barWidth,
    double h,
  ) {
    final builder = widget.accessoryBuilder;
    final progress = widget.accessoryProgressBuilder;
    if (builder == null && progress == null && widget.accessory == null) {
      return barBox;
    }
    if (!maxWidth.isFinite) return barBox;
    const barTop = _accH + _accGap - 3;
    // expanded: as wide as the bar, above it; inline: from the right of the round button to the same margin the button has
    final left = lerpDouble(21.5, _minLeft + _minSize + 8.3, m)!;
    final right = lerpDouble(maxWidth - 21.5, maxWidth - _minLeft, m)!;
    final top = lerpDouble(0, barTop + 3 + h / 2 + 0 - _accH / 2, m)!;
    final placement = m < 0.2
        ? GlassTabBarAccessoryPlacement.expanded
        : GlassTabBarAccessoryPlacement.inline;
    Widget content;
    if (progress != null) {
      content = progress(context, m);
    } else if (builder != null && widget.accessoryCrossfade) {
      // both layouts, each at its own weight (an alpha inside the plate: nothing is composited over the glass)
      final inline = glassSmoothstep(0.1, 0.3, m.clamp(0.0, 1.0));
      content = Stack(
        fit: StackFit.expand,
        children: [
          if (inline < 1)
            Opacity(
              opacity: 1 - inline,
              child: builder(context, GlassTabBarAccessoryPlacement.expanded),
            ),
          if (inline > 0)
            Opacity(
              opacity: inline,
              child: builder(context, GlassTabBarAccessoryPlacement.inline),
            ),
        ],
      );
    } else if (builder != null) {
      content = builder(context, placement);
    } else {
      content = widget.accessory!;
    }
    // cut to the plate while it changes shape
    content = ClipRRect(
      borderRadius: BorderRadius.circular(_accH / 2),
      child: content,
    );
    if (widget.onAccessoryTap != null) {
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onAccessoryTap,
        child: content,
      );
    }
    final plate = widget.accessoryGlass
        ? GlassSurface(
            shape: const StadiumBorder(),
            interactive: widget.onAccessoryTap != null,
            width: right - left,
            height: _accH,
            child: content,
          )
        : SizedBox(width: right - left, height: _accH, child: content);
    return SizedBox(
      height: barTop + h + 14,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: barTop,
            height: h + 14,
            child: barBox,
          ),
          Positioned(
            left: left,
            top: top,
            width: right - left,
            height: _accH,
            child: plate,
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.tab,
    required this.selected,
    this.collapse,
    this.labelFade = 0,
  });
  final GlassTab tab;

  /// 0..1 while the bar collapses: the icon of a tab fades out (null for the selected tab, which stays).
  final double? collapse;

  /// 0..1: the label fades out while the bar collapses.
  final double labelFade;

  /// 0..1, how much the tab is the selected one (follows the thumb while it moves).
  final double selected;

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final color = Color.lerp(t.glass.glassIcon, t.colors.accent, selected)!;
    // measured: icon glyph top 12.7 pt below the bar's top, label caps start 41.3 pt below it, 10 pt label
    return OverflowBox(
      alignment: Alignment.topCenter,
      minHeight: 0,
      maxHeight: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Opacity(
            opacity: 1 - (collapse ?? 0).clamp(0.0, 1.0),
            child: IconTheme(
              data: IconThemeData(color: color, size: 28),
              child: tab.icon,
            ),
          ),
          const SizedBox(height: 3.3),
          Opacity(
            opacity: 1 - labelFade.clamp(0.0, 1.0),
            child: Text(
              tab.label,
              maxLines: 1,
              style: t.typography.caption.copyWith(
                fontSize: 10,
                height: 1.0,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutsideCapsuleClip extends CustomClipper<Path> {
  const _OutsideCapsuleClip(this.rect);
  final Rect rect;
  @override
  Path getClip(Size size) => Path.combine(
    PathOperation.difference,
    Path()..addRect(Offset.zero & size),
    Path()..addRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)),
    ),
  );
  @override
  bool shouldReclip(_OutsideCapsuleClip old) => old.rect != rect;
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
