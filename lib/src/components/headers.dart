import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../chrome/chrome_controller.dart';
import '../chrome/chrome_scaffold.dart';
import 'buttons.dart';
import 'glass_toolbar.dart';
import 'liquid_glass.dart';
import '../theme/swift_ui_theme.dart';

/// The leading widget of a bar: [leading], or - when there is none and [auto] is on - a [GlassBackButton] if THIS route can be
/// popped (there is a route below it), the way `CupertinoNavigationBar` and `AppBar` decide.
///
/// It must be the route's own `ModalRoute.canPop`, not `Navigator.canPop()`: the latter is true for the whole navigator as soon
/// as two routes are on the stack, so the page under a pushed one grew a back button whenever it rebuilt (and it stays painted
/// during the push and the swipe-back). `ModalRoute.of` also subscribes the header to the route, so it follows changes.
/// A fullscreen dialog has no back chevron (a modal is closed, not navigated back from): pass a [leading] for it.
Widget? _impliedLeading(
  BuildContext context,
  Widget? leading,
  bool auto,
  VoidCallback? onBack,
) {
  if (leading != null || !auto) return leading;
  final route = ModalRoute.of(context);
  if (route == null || !route.canPop) return null;
  if (route is PageRoute && route.fullscreenDialog) return null;
  return GlassBackButton(onPressed: onBack);
}

/// The back button a bar shows when its route has somewhere to return to, for a custom bar: the same decision the kit's own
/// headers make ([ModalRoute.canPop] of the page the bar is on, no chevron on a fullscreen dialog).
class SwiftUiBackButton {
  const SwiftUiBackButton._();

  /// A [GlassBackButton] when the route of [context] can be popped, else null. [onBack] replaces the default pop.
  static Widget? maybeOf(BuildContext context, {VoidCallback? onBack}) =>
      _impliedLeading(context, null, true, onBack);
}

/// Simple title bar for [ChromeBar]: title (left) and trailing actions.
class TitleBar extends StatelessWidget {
  const TitleBar({
    super.key,
    this.title,
    this.titleStyle,
    this.leading,
    this.trailing = const [],
    this.automaticallyImplyLeading = true,
    this.onBack,
  });
  final String? title;
  final TextStyle? titleStyle;
  final Widget? leading;
  final List<Widget> trailing;

  /// With no [leading]: show the back button when the route can be popped.
  final bool automaticallyImplyLeading;

  /// What the implied back button does; default: pops the route.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final lead = _impliedLeading(
      context,
      leading,
      automaticallyImplyLeading,
      onBack,
    );
    return SizedBox(
      height: t.metrics.barHeight,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: t.metrics.pageInset),
        child: Row(
          children: [
            if (lead != null) ...[lead, const SizedBox(width: 12)],
            if (title != null)
              Expanded(
                child: Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  style:
                      titleStyle ??
                      t.typography.title.copyWith(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              )
            else
              const Spacer(),
            for (var i = 0; i < trailing.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              trailing[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// How the title is shown, like SwiftUI's `navigationBarTitleDisplayMode`.
enum NavTitleStyle {
  /// Large title below the bar that scrolls away with the content and hands over to a small title in the bar.
  large,

  /// Small title centered in the bar, always visible.
  inline,
}

/// iOS 26 style navigation header (metrics, fades and the hand-over measured on native `NavigationStack`): a 44 pt
/// bar row with glass buttons, an optional large title (34 pt bold) with an optional subtitle under it, or a small
/// centered title. Registers itself in the scaffold: content padding is the expanded height, the blur zone follows
/// the collapsing height.
///
/// Behaviour of the large style (native): the large title scrolls with the content and fades out over the first
/// ~80 pt (no hard clip: it goes under the bar's blur), the small title in the bar fades in over ~0.25 s once the
/// content has scrolled ~72 pt.
class LargeTitleHeader extends StatefulWidget {
  const LargeTitleHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.style = NavTitleStyle.large,
    this.leading,
    this.trailing = const [],
    this.automaticallyImplyLeading = true,
    this.onBack,
    this.largeTitleHeight,
    this.barHeight = 44,
    this.glassSpacing = 14,
  });

  final String title;

  /// Second line: under the large title, or under the small title for [NavTitleStyle.inline].
  final String? subtitle;
  final NavTitleStyle style;
  final Widget? leading;
  final List<Widget> trailing;

  /// With no [leading]: show the back button when the route can be popped.
  final bool automaticallyImplyLeading;

  /// What the implied back button does; default: pops the route.
  final VoidCallback? onBack;

  /// Height of the large-title block below the bar. Default (native): 61 pt, 83 pt with a subtitle.
  final double? largeTitleHeight;

  /// Height of the bar row (native: 44, the height of its buttons).
  final double barHeight;

  /// Glass morph distance of the bar buttons (see [LiquidGlassGroup.spacing]); 0 keeps every plate separate.
  final double glassSpacing;

  @override
  State<LargeTitleHeader> createState() => _LargeTitleHeaderState();
}

class _LargeTitleHeaderState extends State<LargeTitleHeader> {
  ChromeController? _controller;
  ChromeInsetEntry? _entry;

  double get _offset => _controller?.scrollOffset.value ?? 0;
  bool get _isLarge => widget.style == NavTitleStyle.large;
  double get _l => !_isLarge
      ? 0
      : (widget.largeTitleHeight ?? (widget.subtitle != null ? 83 : 61));
  double get _bar => widget.barHeight;

  /// Number of actions on the right (a [GlassToolbarCapsule] counts its items).
  int get _actionCount => widget.trailing.fold(
    0,
    (n, w) => n + (w is GlassToolbarCapsule ? w.items.length : 1),
  );

  double _titleWidth(BuildContext context, TextStyle title, TextStyle sub) {
    // measured the way the Text widgets will lay out: merged into the ambient DefaultTextStyle (its letter spacing, font
    // features...) and scaled by the text scaler. Measuring the bare style gave a width that was a bit too small, and the
    // Text then faded the last letter of the title although there was plenty of room.
    final base = DefaultTextStyle.of(context).style;
    final scaler = MediaQuery.textScalerOf(context);
    double w(String text, TextStyle style) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: base.merge(style)),
        maxLines: 1,
        textScaler: scaler,
        textDirection: TextDirection.ltr,
      )..layout();
      final width = tp.width;
      tp.dispose();
      return width;
    }

    var r = w(widget.title, title);
    if (widget.subtitle != null) {
      r = math.max(r, w(widget.subtitle!, sub));
    }
    // a little slack: the Text must never see a width smaller than its content (that would fade the last letter)
    return r.ceilToDouble() + 4;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = ChromeScaffoldScope.controllerOf(context);
    if (c != _controller) {
      _controller?.scrollOffset.removeListener(_onScroll);
      _entry?.release();
      _controller = c;
      c.scrollOffset.addListener(_onScroll);
      _entry = c.register(
        ChromeEdge.top,
        height: _currentHeight(),
        padding: _bar + _l,
        minPadding: _bar,
        label: 'LargeTitleHeader',
      );
    }
  }

  double _currentHeight() => _bar + (_l - _offset).clamp(0.0, _l);

  void _onScroll() {
    _entry?.update(height: _currentHeight());
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(LargeTitleHeader old) {
    super.didUpdateWidget(old);
    _entry?.update(height: _currentHeight(), padding: _bar + _l);
  }

  @override
  void dispose() {
    _controller?.scrollOffset.removeListener(_onScroll);
    _entry?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final l = _l;
    // not clamped: pulling down (negative offset) takes the large title along with the content
    final o = _offset;
    final large = (1 - (o - 20) / 60).clamp(0.0, 1.0);
    final showSmall = !_isLarge || o > 72;
    final total = _bar + (l - math.max(o, 0)).clamp(0.0, l);
    final secondary = t.typography.caption.copyWith(fontSize: 13, height: 1.15);
    final smallTitle = t.typography.title.copyWith(
      fontSize: 17,
      fontWeight: FontWeight.w600,
    );
    Widget smallBlock(bool atStart) {
      final column = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: atStart
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Text(
            widget.title,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
            style: smallTitle,
          ),
          if (widget.subtitle != null)
            Text(
              widget.subtitle!,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
              style: secondary.copyWith(fontSize: 12),
            ),
        ],
      );
      return AnimatedOpacity(
        opacity: showSmall ? 1 : 0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: column,
      );
    }

    // The glass group wraps ONLY the bar row: its backdrop pass is painted before its children, so everything painted
    // earlier in this Stack (the large title sliding up) is part of what the buttons refract and blur, i.e. goes UNDER them.
    return SizedBox(
      height: total,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // keyed: the large title comes and goes with the style, the bar buttons must keep their state (press animation)
          if (_isLarge)
            Positioned(
              key: const ValueKey('ravel-large-title'),
              top: _bar,
              left: 0,
              right: 0,
              height: l,
              child: Transform.translate(
                offset: Offset(0, -o),
                child: Opacity(
                  opacity: large,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          style: t.typography.largeTitle.copyWith(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (widget.subtitle != null)
                          Text(widget.subtitle!, maxLines: 1, style: secondary),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // The bar row: leading button, centered small title, trailing group. The title never runs under the buttons: it is
          // limited to the free space between them and fades out at its end (no hard clip); when it does not fit centered
          // (long title, or more than 2 actions) it slides to the start on a spring.
          Positioned(
            key: const ValueKey('ravel-bar'),
            top: 0,
            left: 0,
            right: 0,
            height: _bar,
            // spacing: plates that come closer than this (a pressed button grows over its neighbour) melt into one
            // shape, like a native glass container; the resting gap between bar buttons (12 pt) stays below the bridge
            child: LiquidGlassGroup(
              spacing: widget.glassSpacing,
              child: _BarRow(
                leading: _impliedLeading(
                  context,
                  widget.leading,
                  widget.automaticallyImplyLeading,
                  widget.onBack,
                ),
                trailing: widget.trailing.isEmpty
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < widget.trailing.length; i++) ...[
                            if (i > 0) const SizedBox(width: 12),
                            widget.trailing[i],
                          ],
                        ],
                      ),
                titleBuilder: smallBlock,
                titleWidth: _titleWidth(
                  context,
                  smallTitle,
                  secondary.copyWith(fontSize: 12),
                ),
                forceStart: _actionCount > 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sticky section header (sliver). While stuck against the top it registers
/// its [height] in the [ChromeController], which grows the blur zone.
class PinnedHeader extends StatelessWidget {
  const PinnedHeader({
    super.key,
    required this.height,
    this.child,
    this.builder,
    this.replaceGroup,
    this.animateZone = true,
  }) : assert(child != null || builder != null);

  /// true: the blur zone eases (380 ms) to cover the header when it sticks. false: it covers it in the very frame the
  /// header sticks. A header with content that stays visible under the bar (a strip of tabs, say) wants false: with the
  /// ease the rows scrolling under it show sharp for a moment and then get blurred, which reads as a flash.
  final bool animateZone;

  /// Headers with the same non-null group replace each other (the blur zone
  /// grows by one header, not by all stuck ones). Use [PinnedSection].
  final Object? replaceGroup;

  final double height;
  final Widget? child;

  /// Alternative to [child]: receives whether the header is currently stuck.
  final Widget Function(BuildContext context, bool stuck)? builder;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _PinnedDelegate(
        height,
        child,
        builder,
        replaceGroup,
        animateZone,
      ),
    );
  }
}

class _PinnedDelegate extends SliverPersistentHeaderDelegate {
  _PinnedDelegate(
    this.height,
    this.child,
    this.builder,
    this.replaceGroup,
    this.animateZone,
  );
  final bool animateZone;
  final Object? replaceGroup;
  final double height;
  final Widget? child;
  final Widget Function(BuildContext, bool)? builder;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return _PullCompensate(
      child: _StickyRegistrar(
        height: height,
        stuck: overlapsContent,
        replaceGroup: replaceGroup,
        animateZone: animateZone,
        stuckChild: builder != null ? builder!(context, true) : child!,
        child: SizedBox(
          height: height,
          child: builder != null ? builder!(context, overlapsContent) : child!,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_PinnedDelegate old) =>
      old.height != height ||
      old.child != child ||
      old.builder != builder ||
      old.replaceGroup != replaceGroup ||
      old.animateZone != animateZone;
}

/// A pinned sliver is painted twice as far down as the content while the list is pulled past its top (the viewport's overlap
/// is added to the paint origin of a pinned header): it would run over the rows below. Moves it back by the overscroll, so it
/// travels with the content.
class _PullCompensate extends StatelessWidget {
  const _PullCompensate({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = ChromeScaffoldScope.controllerOf(context);
    return ValueListenableBuilder<double>(
      valueListenable: c.scrollOffset,
      child: child,
      builder: (context, o, child) =>
          Transform.translate(offset: Offset(0, o < 0 ? o : 0), child: child),
    );
  }
}

class _StickyRegistrar extends StatefulWidget {
  const _StickyRegistrar({
    required this.height,
    required this.stuck,
    required this.child,
    required this.stuckChild,
    this.replaceGroup,
    this.animateZone = true,
  });
  final Object? replaceGroup;
  final bool animateZone;
  final double height;
  final bool stuck;
  final Widget child;

  /// How the header looks while stuck (shown by the scaffold above the blur).
  final Widget stuckChild;

  @override
  State<_StickyRegistrar> createState() => _StickyRegistrarState();
}

class _StickyRegistrarState extends State<_StickyRegistrar> {
  ChromeInsetEntry? _entry;
  final _link = LayerLink();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _entry ??= ChromeScaffoldScope.controllerOf(context).register(
      ChromeEdge.top,
      height: 0,
      padding: 0,
      sticky: true,
      replaceGroup: widget.replaceGroup,
      label: 'PinnedHeader',
    );
    _entry!.setOverlay(widget.stuckChild, height: widget.height, link: _link);
    _entry!.measureBottom = _measureBottom;
    _sync();
  }

  double? _measureBottom(RenderBox scaffold) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero, ancestor: scaffold).dy +
        widget.height;
  }

  @override
  void didUpdateWidget(_StickyRegistrar old) {
    super.didUpdateWidget(old);
    if (old.height != widget.height || old.stuckChild != widget.stuckChild) {
      _entry?.setOverlay(widget.stuckChild, height: widget.height, link: _link);
    }
    if (old.stuck != widget.stuck || old.height != widget.height) _sync();
  }

  void _sync() {
    final stuck = widget.stuck;
    if (!widget.animateZone) {
      // Both the zone and the copy the scaffold shows above the blur change a frame late, but the copy's switch is
      // immediate (it only repaints) while the zone rebuilds. Without care the header shows blurred or darkened for a frame:
      //  * sticking: cover it by the zone only after the copy is there (the copy is placed after the frame, it follows the
      //    header), so the zone follows two frames later;
      //  * unsticking: shrink the zone at once and drop the copy only after it (the copy follows the header's real
      //    position, so it does not jump while it lingers).
      if (stuck) {
        _entry?.setStuck(true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !widget.stuck) return;
            _entry?.update(height: widget.height, animate: false);
          });
        });
      } else {
        _entry?.update(height: 0, animate: false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || widget.stuck) return;
            _entry?.setStuck(false);
          });
        });
      }
      return;
    }
    // Painting switches in this very frame (listeners only repaint); the zone
    // height eases in.
    _entry?.setStuck(stuck);
    _entry?.update(
      height: stuck ? widget.height : 0,
      animate: true,
      // slow enough to read as a fade-in of the darkening (the default ease-out is over in the first few frames)
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _entry?.release(animate: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = CompositedTransformTarget(
      link: _link,
      child: PaintWhenStuck(entry: _entry!, invert: true, child: widget.child),
    );
    // A pinned sliver stays at the top while the list is pulled down past its start (rubber band). The header goes down
    // with the content instead (the stuck copy above the blur follows it through the link).
    return ValueListenableBuilder<double>(
      valueListenable: ChromeScaffoldScope.controllerOf(context).scrollOffset,
      builder: (context, offset, child) => offset < 0
          ? Transform.translate(offset: Offset(0, -offset), child: child)
          : child!,
      child: target,
    );
  }
}

/// A top bar with a collapsible section under it (a search field, a banner, a segmented control): [bar] stays, the
/// [section] below it scrolls away with the content and is cut off at the bar's lower edge, so it never lingers as a
/// blurred ghost under the bar and, once it is gone, paints nothing at all (whatever it holds). It registers like
/// [LargeTitleHeader]: the content padding is the open height, the blur zone follows the collapsing height.
///
/// Scroll the list by [sectionHeight] to hide the section; pulling down past the top reveals it again and takes it along.
/// How the collapsible section of a [CollapsibleBar] leaves.
///
/// [shrink] (default, what the native large-title apps do): the section stays where it is and shrinks in height while its
/// content fades out (see [SectionProgress]) while the container stays solid and just gets lower.
/// [slide]: the section rides up with the list and is cut at the bar's lower edge.
enum SectionCollapse { shrink, slide }

class CollapsibleBar extends StatefulWidget {
  const CollapsibleBar({
    super.key,
    required this.bar,
    this.section,
    this.sectionHeight = 0,
    this.barHeight,
    this.footer,
    this.footerHeight = 0,
    this.initiallyCollapsed = false,
    this.glassSpacing = 14,
    this.collapse = SectionCollapse.shrink,
  }) : assert(footer == null || footerHeight > 0),
       assert((section == null) == (sectionHeight == 0));

  /// The always visible row (buttons, title). [barHeight] tall.
  final Widget bar;

  /// The part that collapses; laid out at [sectionHeight] and cut to what is left of it. Optional: without it this is a bar
  /// with a [footer] (a strip of tabs) and nothing collapses.
  final Widget? section;
  final double sectionHeight;

  /// Default: `SwiftUiThemeData.barHeight`.
  final double? barHeight;

  /// true: the section starts hidden and is revealed by pulling the list down (what messengers do with their search). The
  /// kit puts every list in the body at the collapsed offset when it appears (the lists of a pager follow the state the bar
  /// is in) and leaves enough scroll room, even for a short list. false: the section starts open.
  final bool initiallyCollapsed;

  /// A row under the section that never collapses (a strip of tabs): it sits right under the bar once the section is
  /// gone. As part of the bar it is always above the blur and needs no pinned header (nothing to hand over while scrolling).
  final Widget? footer;
  final double footerHeight;

  /// Glass morph distance of the bar row buttons (see [LiquidGlassGroup.spacing]); the footer and the section are separate
  /// layers (a pressed lens must not melt into the buttons above). 0 keeps every bar plate separate.
  final double glassSpacing;

  /// How the section leaves while the list scrolls.
  final SectionCollapse collapse;

  @override
  State<CollapsibleBar> createState() => _CollapsibleBarState();
}

class _CollapsibleBarState extends State<CollapsibleBar> {
  ChromeInsetEntry? _entry;
  ChromeController? _controller;
  double _bar = 52;

  double get _offset => _pending ? _h : (_controller?.scrollOffset.value ?? 0);
  double get _h => widget.sectionHeight;
  double get _f => widget.footer == null ? 0 : widget.footerHeight;
  // until the first scroll the bar is drawn collapsed, so a collapsed start has no open frame
  late bool _pending = widget.initiallyCollapsed && widget.section != null;
  double _zoneHeight() => _bar + (_h - _offset).clamp(0.0, _h) + _f;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bar = widget.barHeight ?? SwiftUiTheme.of(context).metrics.barHeight;
    final c = ChromeScaffoldScope.controllerOf(context);
    if (c != _controller) {
      _controller?.scrollOffset.removeListener(_onScroll);
      _entry?.release();
      _controller = c;
      c.scrollOffset.addListener(_onScroll);
      _entry =
          c.register(
              ChromeEdge.top,
              height: _zoneHeight(),
              padding: _bar + _h + _f,
              minPadding: _bar + _f,
              label: 'CollapsibleBar',
            )
            ..scrollSlack = _h
            ..snapExtra = 0
            ..initialScroll =
                widget.initiallyCollapsed && widget.section != null ? _h : null;
    }
  }

  void _onScroll() {
    _pending = false;
    _entry?.update(height: _zoneHeight());
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(CollapsibleBar old) {
    super.didUpdateWidget(old);
    _entry?.update(height: _zoneHeight(), padding: _bar + _h + _f);
  }

  @override
  void dispose() {
    _controller?.scrollOffset.removeListener(_onScroll);
    _entry?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final o = _offset;
    // pulling down (negative offset) grows the window and takes the section along with the content
    final window = (_h - o).clamp(0.0, double.infinity);
    // Only the bar row is a glass group (its buttons morph into each other, like a native glass container). The footer
    // and the section stay OUTSIDE it: a pressed lens (the thumb of a strip of tabs) must be a layer of its own above its
    // track, and must not melt into the buttons of the bar above.
    return SizedBox(
      height: _bar + window + _f,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _bar,
            child: LiquidGlassGroup(
              spacing: widget.glassSpacing,
              child: widget.bar,
            ),
          ),
          if (widget.footer != null)
            Positioned(
              top: _bar + window,
              left: 0,
              right: 0,
              height: _f,
              child: widget.footer!,
            ),
          if (widget.section != null && window > 0)
            Positioned(
              top: _bar,
              left: 0,
              right: 0,
              height: window,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minHeight: _h,
                  maxHeight: _h,
                  child: widget.collapse == SectionCollapse.slide
                      // the section rides up with the content; the window cuts it at the bar's lower edge
                      ? Transform.translate(
                          offset: Offset(0, -o),
                          child: widget.section!,
                        )
                      // the section stays put and shrinks to the window; its content fades out faster than the height
                      // closes (squared), so what is left while it closes up is the empty container. Pulling down
                      // (o < 0) still takes it along with the content.
                      : Transform.translate(
                          offset: Offset(0, o < 0 ? -o : 0),
                          child: _ShrinkSection(
                            t: (window / _h).clamp(0.0, 1.0),
                            child: widget.section!,
                          ),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// How open the collapsing section of a [CollapsibleBar] is: 1 fully open, 0 closed. Content inside the section (a search
/// field's icon and hint) reads it with [SectionProgress.of] to shrink and fade out while the container itself stays solid.
/// 1 when there is no [CollapsibleBar] around.
class SectionProgress extends InheritedWidget {
  const SectionProgress({super.key, required this.open, required super.child});
  final double open;

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SectionProgress>()?.open ??
      1.0;

  /// Opacity curve for the content of a closing section: fades out faster than the height closes.
  static double fade(double open) => open * open;

  @override
  bool updateShouldNotify(SectionProgress old) => open != old.open;
}

/// Shrinks [child] vertically to [t] (0..1) from its top edge. The container is NOT faded here: it stays solid and just
/// gets lower; the content fades itself through [SectionProgress].
class _ShrinkSection extends StatelessWidget {
  const _ShrinkSection({required this.t, required this.child});
  final double t;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SectionProgress(
      open: t,
      child: t >= 1
          ? child
          : Transform(
              alignment: Alignment.topCenter,
              transform: Matrix4.diagonal3Values(1, t, 1),
              child: child,
            ),
    );
  }
}

const _replacing = Object();

/// A section whose [header] sticks to the top and is pushed out by the next
/// section's header (iOS grouped-list behaviour), instead of stacking under it.
class PinnedSection extends StatelessWidget {
  const PinnedSection({
    super.key,
    required this.headerHeight,
    this.header,
    this.headerBuilder,
    required this.slivers,
  }) : assert(header != null || headerBuilder != null);

  final double headerHeight;
  final Widget? header;
  final Widget Function(BuildContext context, bool stuck)? headerBuilder;
  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        PinnedHeader(
          height: headerHeight,
          builder: headerBuilder,
          replaceGroup: _replacing,
          child: header,
        ),
        ...slivers,
      ],
    );
  }
}

/// The bar row of [LargeTitleHeader]: lays out the leading button, the trailing group and the small title between them.
class _BarRow extends StatefulWidget {
  const _BarRow({
    required this.leading,
    required this.trailing,
    required this.titleBuilder,
    required this.titleWidth,
    required this.forceStart,
  });

  final Widget? leading;
  final Widget? trailing;

  /// Builds the title block; the flag says whether it sits at the start (left-aligned lines) or is centered.
  final Widget Function(bool atStart) titleBuilder;

  /// Natural width of the title block, pt.
  final double titleWidth;

  /// Keep the title at the start even when it would fit centered (more than 2 actions).
  final bool forceStart;

  @override
  State<_BarRow> createState() => _BarRowState();
}

class _BarRowState extends State<_BarRow> with SingleTickerProviderStateMixin {
  // zeta ~0.75: one soft overshoot, settles in ~0.45 s
  static const _spring = SpringDescription(
    mass: 1,
    stiffness: 190,
    damping: 20.6,
  );
  late final AnimationController _c = AnimationController.unbounded(
    vsync: this,
    value: 0,
  );
  bool _fits = true;
  bool _started = false;

  bool get _atStart => widget.forceStart || !_fits;

  void _setFits(bool v) {
    if (v == _fits) return;
    setState(() => _fits = v);
    _retarget();
  }

  void _retarget() {
    final to = _atStart ? 1.0 : 0.0;
    if (!_started) {
      // first layout: no animation
      _started = true;
      _c.value = to;
      return;
    }
    _c.animateWith(SpringSimulation(_spring, _c.value, to, _c.velocity));
  }

  @override
  void didUpdateWidget(_BarRow old) {
    super.didUpdateWidget(old);
    if (old.forceStart != widget.forceStart) _retarget();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomMultiChildLayout(
      delegate: _BarDelegate(
        t: _c,
        hasLeading: widget.leading != null,
        hasTrailing: widget.trailing != null,
        titleWidth: widget.titleWidth,
        onFit: (fits) {
          // layout time: defer the state change
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _setFits(fits);
          });
        },
      ),
      children: [
        LayoutId(id: 'title', child: widget.titleBuilder(_atStart)),
        if (widget.leading != null)
          LayoutId(
            key: const ValueKey('ravel-leading'),
            id: 'leading',
            child: widget.leading!,
          ),
        if (widget.trailing != null)
          LayoutId(
            key: const ValueKey('ravel-trailing'),
            id: 'trailing',
            child: widget.trailing!,
          ),
      ],
    );
  }
}

class _BarDelegate extends MultiChildLayoutDelegate {
  _BarDelegate({
    required this.t,
    required this.hasLeading,
    required this.hasTrailing,
    required this.titleWidth,
    required this.onFit,
  }) : super(relayout: t);

  final AnimationController t;
  final bool hasLeading;
  final bool hasTrailing;
  final double titleWidth;
  final ValueChanged<bool> onFit;

  static const _pad = 16.0;
  static const _gap = 12.0;

  @override
  void performLayout(Size size) {
    final loose = BoxConstraints.loose(size);
    var left = _pad;
    var right = size.width - _pad;
    if (hasLeading) {
      final s = layoutChild('leading', loose);
      positionChild('leading', Offset(_pad, (size.height - s.height) / 2));
      left = _pad + s.width + _gap;
    }
    if (hasTrailing) {
      final s = layoutChild('trailing', loose);
      positionChild(
        'trailing',
        Offset(size.width - _pad - s.width, (size.height - s.height) / 2),
      );
      right = size.width - _pad - s.width - _gap;
    }
    final free = math.max(0.0, right - left);
    final w = math.min(titleWidth, free);
    final room = 2 * math.min(size.width / 2 - left, right - size.width / 2);
    onFit(titleWidth <= room);
    final ts = layoutChild('title', BoxConstraints.tightFor(width: w));
    final centeredX = (size.width - w) / 2;
    final x = centeredX + (left - centeredX) * t.value;
    positionChild('title', Offset(x, (size.height - ts.height) / 2));
  }

  @override
  bool shouldRelayout(_BarDelegate old) =>
      old.hasLeading != hasLeading ||
      old.hasTrailing != hasTrailing ||
      old.titleWidth != titleWidth;
}
