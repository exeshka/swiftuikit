import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:swiftuikit/src/core/widgets/morph_id.dart';
import 'swift_header_chrome.dart';
import 'swift_header.dart';

class SwiftSliverHeader extends StatefulWidget {
  const SwiftSliverHeader({
    super.key,
    required this.child,
    this.foregroundChild,
    this.foregroundInChrome = true,
    this.height = 44 + 4 + 4,
    this.includeTopSafeArea = true,
    this.pinned = true,
    this.floating = false,
    this.trackAtRest = true,
    this.heroEnabled = false,
    this.heroId = const MorphId('swift_header'),
  });

  final Widget child;
  final Widget? foregroundChild;
  final bool foregroundInChrome;
  final double height;
  final bool includeTopSafeArea;
  final bool pinned;
  final bool floating;
  final bool trackAtRest;
  final bool heroEnabled;
  final MorphId heroId;

  @override
  State<SwiftSliverHeader> createState() => _SwiftSliverHeaderState();
}

class _SwiftSliverHeaderState extends State<SwiftSliverHeader> {
  final Object _chromeId = Object();
  final LayerLink _link = LayerLink();

  SwiftPinnedHeaderChromeController? _chromeController;
  Size _size = Size.zero;
  bool _disposed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextController = SwiftPinnedHeaderChromeScope.maybeOf(context);
    if (_chromeController != nextController) {
      _chromeController?.remove(_chromeId);
      _chromeController = nextController;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _chromeController?.remove(_chromeId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = widget.includeTopSafeArea
        ? MediaQuery.paddingOf(context).top
        : 0.0;
    final extent = topPadding + widget.height;
    Widget paddedHeader(Widget child) {
      return SizedBox(
        height: extent,
        child: Padding(
          padding: EdgeInsets.only(top: topPadding),
          child: SizedBox(height: widget.height, child: child),
        ),
      );
    }

    final headerChild = paddedHeader(
      widget.foregroundInChrome
          ? widget.foregroundChild ?? widget.child
          : widget.child,
    );

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final isFirstHeader = constraints.precedingScrollExtent == 0;
        final tracksAtRestHere = widget.trackAtRest && isFirstHeader;
        final isPinnedToChrome =
            widget.pinned &&
            (tracksAtRestHere ||
                constraints.scrollOffset > 0 ||
                constraints.overlap.abs() > 0);
        final isFloatingOverContent =
            widget.floating && constraints.overlap.abs() > 0;
        final trackedByChrome =
            _chromeController != null &&
            (isPinnedToChrome || isFloatingOverContent);

        // The plain content — used for the overlay child (visible above blur).
        final plainChild = SizedBox(
          width: _size.width > 0 ? _size.width : MediaQuery.sizeOf(context).width,
          height: extent,
          child: headerChild,
        );

        // Update the controller for height measurement of the blur/gradient overlay.
        if (_chromeController != null) {
          _chromeController!.update(
            id: _chromeId,
            height: extent,
            child: plainChild,
            link: _link,
            signature: '${_size.width}',
            pinned: trackedByChrome,
          );
        }

        // Content wrapped with Hero — placed in the inline position so that
        // localToGlobal returns the correct render tree position for Hero
        // flight calculations.
        final Widget heroChild = widget.heroEnabled
            ? Hero(
                tag: widget.heroId,
                transitionOnUserGestures: true,
                flightShuttleBuilder: defaultHeaderFlightShuttleBuilder,
                child: plainChild,
              )
            : plainChild;

        // Build with route transition listening.
        final route = ModalRoute.of(context);
        final animation = route?.animation;
        final secondaryAnimation = route?.secondaryAnimation;
        final transitionListenable = Listenable.merge([
          ?animation,
          ?secondaryAnimation,
        ]);

        Widget result;
        if (_chromeController == null) {
          result = heroChild;
        } else {
          result = CompositedTransformTarget(
            link: _link,
            child: _SwiftMeasureSize(
              onChange: (newSize) {
                if (!_disposed && mounted && _size != newSize) {
                  setState(() => _size = newSize);
                }
              },
              child: AnimatedBuilder(
                animation: transitionListenable,
                builder: (context, _) {
                  final isTransitioning =
                      (animation != null &&
                          !animation.isCompleted &&
                          !animation.isDismissed) ||
                      (secondaryAnimation != null &&
                          !secondaryAnimation.isCompleted &&
                          !secondaryAnimation.isDismissed);

                  // When transitioning, render inline child at Opacity(1.0).
                  // Otherwise, when pinned, render inline child at Opacity(0.0)
                  // because the overlay copy is visible.
                  final showInline = isTransitioning || !trackedByChrome;

                  return IgnorePointer(
                    ignoring: !showInline,
                    child: Opacity(
                      opacity: showInline ? 1.0 : 0.0,
                      child: heroChild,
                    ),
                  );
                },
              ),
            ),
          );
        }

        return SliverPersistentHeader(
          pinned: widget.pinned,
          floating: widget.floating,
          delegate: SwiftSliverHeaderDelegate(height: extent, child: result),
        );
      },
    );
  }
}

class SwiftSliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  const SwiftSliverHeaderDelegate({required this.child, required this.height});

  final Widget child;
  final double height;

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
    return child;
  }

  @override
  bool shouldRebuild(covariant SwiftSliverHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}

class _SwiftMeasureSize extends SingleChildRenderObjectWidget {
  const _SwiftMeasureSize({required this.onChange, required super.child});

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _SwiftMeasureSizeRenderObject(onChange);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _SwiftMeasureSizeRenderObject renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class _SwiftMeasureSizeRenderObject extends RenderProxyBox {
  _SwiftMeasureSizeRenderObject(this.onChange);

  ValueChanged<Size> onChange;
  Size? _oldSize;

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child?.size ?? Size.zero;
    if (_oldSize == newSize) return;

    _oldSize = newSize;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onChange(newSize);
    });
  }
}
