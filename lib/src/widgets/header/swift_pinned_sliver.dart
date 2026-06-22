import 'package:flutter/material.dart';
import 'swift_header_chrome.dart';

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
    this.heroTag = 'swift_header',
  });

  final Widget child;
  final Widget? foregroundChild;
  final bool foregroundInChrome;
  final double height;
  final bool includeTopSafeArea;
  final bool pinned;
  final bool floating;
  final bool trackAtRest;
  final Object? heroTag;

  @override
  State<SwiftSliverHeader> createState() => _SwiftSliverHeaderState();
}

class _SwiftSliverHeaderState extends State<SwiftSliverHeader> {
  final Object _chromeId = Object();
  final LayerLink _link = LayerLink();

  SwiftPinnedHeaderChromeController? _chromeController;

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
          width: MediaQuery.sizeOf(context).width,
          height: extent,
          child: headerChild,
        );

        final Widget inlineHeroChild = widget.heroTag != null
            ? Hero(
                tag: widget.heroTag!,
                transitionOnUserGestures: true,
                flightShuttleBuilder: (
                  BuildContext flightContext,
                  Animation<double> animation,
                  HeroFlightDirection flightDirection,
                  BuildContext fromHeroContext,
                  BuildContext toHeroContext,
                ) {
                  final Hero fromHero = fromHeroContext.widget as Hero;
                  final Hero toHero = toHeroContext.widget as Hero;

                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, _) {
                      final double t = animation.value;
                      final bool isPush =
                          flightDirection == HeroFlightDirection.push;

                      final double topOpacity = t.clamp(0.0, 1.0);
                      final double bottomOpacity = (1.0 - t).clamp(0.0, 1.0);

                      final double topTranslation = 30.0 * (1.0 - t);
                      final double bottomTranslation = -30.0 * t;

                      final Widget bottomWidget =
                          isPush ? fromHero.child : toHero.child;
                      final Widget topWidget =
                          isPush ? toHero.child : fromHero.child;

                      return SizedBox(
                        width: MediaQuery.sizeOf(context).width,
                        height: extent,
                        child: Stack(
                          children: [
                            Transform.translate(
                              offset: Offset(bottomTranslation, 0.0),
                              child: Opacity(
                                opacity: bottomOpacity,
                                child: bottomWidget,
                              ),
                            ),
                            Transform.translate(
                              offset: Offset(topTranslation, 0.0),
                              child: Opacity(
                                opacity: topOpacity,
                                child: topWidget,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                child: plainChild,
              )
            : plainChild;

        // Update the controller for height measurement of the blur/gradient overlay.
        if (_chromeController != null) {
          _chromeController!.update(
            id: _chromeId,
            height: extent,
            child: plainChild,
            link: _link,
            signature: '${MediaQuery.sizeOf(context).width}',
            pinned: trackedByChrome,
          );
        }

        final route = ModalRoute.of(context);
        final animation = route?.animation;
        final secondaryAnimation = route?.secondaryAnimation;
        final transitionListenable = Listenable.merge([
          ?animation,
          ?secondaryAnimation,
        ]);

        Widget result;
        if (_chromeController == null) {
          result = inlineHeroChild;
        } else {
          result = CompositedTransformTarget(
            link: _link,
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

                final showInline = isTransitioning || !trackedByChrome;

                return IgnorePointer(
                  ignoring: !showInline,
                  child: Opacity(
                    opacity: showInline ? 1.0 : 0.0,
                    child: inlineHeroChild,
                  ),
                );
              },
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
