import 'package:flutter/material.dart';

import '../../services/screen_radius_service.dart';

const double _pagePositionTolerance = 0.0001;

class SwiftPageViewAnimation extends StatefulWidget {
  const SwiftPageViewAnimation({
    super.key,
    required this.child,
    required this.controller,
    this.itemBuilder,
    this.itemCount,
    this.onPageChanged,
    this.physics,
    this.pageSnapping = true,
    this.allowImplicitScrolling = false,
    this.borderRadius,
    this.radius,
    this.clipBehavior = Clip.antiAlias,
    this.minScale = 0.95,
    this.coverPreviousPage = true,
    this.pageOverlapFraction = 0.20,
    this.alignment = Alignment.center,
    this.parallaxIndexes,
    this.initialPage = 0,
  }) : assert(
         itemBuilder == null && itemCount == null,
         'Use SwiftPageViewAnimation.pageView to build pages.',
       );

  const SwiftPageViewAnimation.pageView({
    super.key,
    required this.itemBuilder,
    required this.itemCount,
    this.onPageChanged,
    this.controller,
    this.physics,
    this.pageSnapping = true,
    this.allowImplicitScrolling = false,
    this.borderRadius,
    this.radius,
    this.clipBehavior = Clip.antiAlias,
    this.minScale = 0.95,
    this.coverPreviousPage = true,
    this.pageOverlapFraction = 0.20,
    this.alignment = Alignment.center,
    this.parallaxIndexes,

    this.initialPage = 0,
  }) : child = null;

  final Widget? child;
  final PageController? controller;
  final IndexedWidgetBuilder? itemBuilder;
  final int? itemCount;
  final ValueChanged<int>? onPageChanged;
  final ScrollPhysics? physics;
  final bool pageSnapping;
  final bool allowImplicitScrolling;
  final BorderRadius? borderRadius;
  final double? radius;
  final Clip clipBehavior;
  final double minScale;
  final bool coverPreviousPage;
  final double pageOverlapFraction;
  final Alignment alignment;
  final List<int>? parallaxIndexes;
  final int initialPage;

  // Добавь после autoTabsBuilder
  static Widget autoTabsPageView({
    Key? key,
    required List<Widget> children,
    required PageController controller,
    ValueChanged<int>? onPageChanged,
    ScrollPhysics? physics,
    bool pageSnapping = true,
    bool allowImplicitScrolling = false,
    BorderRadius? borderRadius,
    double? radius,
    Clip clipBehavior = Clip.antiAlias,
    double minScale = 0.95,
    bool coverPreviousPage = true,
    double pageOverlapFraction = 0.20,
    Alignment alignment = Alignment.center,
    List<int>? parallaxIndexes,
  }) {
    return SwiftPageViewAnimation.pageView(
      key: key,
      controller: controller,
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
      onPageChanged: onPageChanged,
      physics: physics,
      pageSnapping: pageSnapping,
      allowImplicitScrolling: allowImplicitScrolling,
      borderRadius: borderRadius,
      radius: radius,
      clipBehavior: clipBehavior,
      minScale: minScale,
      coverPreviousPage: coverPreviousPage,
      pageOverlapFraction: pageOverlapFraction,
      alignment: alignment,
      parallaxIndexes: parallaxIndexes,
    );
  }

  @override
  State<SwiftPageViewAnimation> createState() => _SwiftPageViewAnimationState();
}

class _SwiftPageViewAnimationState extends State<SwiftPageViewAnimation> {
  PageController? _controller;

  PageController get _effectiveController =>
      widget.controller ??
      (_controller ??= PageController(initialPage: widget.initialPage));
  @override
  void didUpdateWidget(covariant SwiftPageViewAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == null && widget.controller != null) {
      _controller?.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  BorderRadius _targetBorderRadius() {
    return widget.borderRadius ??
        (widget.radius != null
            ? BorderRadius.circular(widget.radius!)
            : ScreenRadiusService.instance.radius);
  }

  BorderRadius _borderRadiusForPage(int index) {
    final page = _currentPage;
    final diff = (page - index).abs();
    return diff > _pagePositionTolerance
        ? _targetBorderRadius()
        : BorderRadius.zero;
  }

  double get _currentPage {
    return _effectiveController.hasClients
        ? _effectiveController.page ??
              _effectiveController.initialPage.toDouble()
        : _effectiveController.initialPage.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return _buildChild();
  }

  Widget _buildChild() {
    final child = widget.child;
    if (child != null) {
      return child;
    }

    return PageView.builder(
      controller: _effectiveController,
      itemCount: widget.itemCount,
      onPageChanged: widget.onPageChanged,
      physics: widget.physics,
      pageSnapping: widget.pageSnapping,
      allowImplicitScrolling: widget.allowImplicitScrolling,
      clipBehavior: Clip.none,
      itemBuilder: (context, index) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedBuilder(
              animation: _effectiveController,
              builder: (context, child) {
                final overlapOffset = _pageOverlapOffset(
                  index: index,
                  width: constraints.maxWidth,
                );
                final scale = _pageScale(index: index);
                final borderRadius = _borderRadiusForPage(index);

                return Transform.translate(
                  offset: Offset(overlapOffset, 0),
                  child: Transform.scale(
                    scale: scale,
                    alignment: widget.alignment,
                    child: ClipRRect(
                      borderRadius: borderRadius,
                      clipBehavior: widget.clipBehavior,
                      child: child,
                    ),
                  ),
                );
              },
              child: widget.itemBuilder!(context, index),
            );
          },
        );
      },
    );
  }

  bool _shouldApplyEffect(int index) {
    final indexes = widget.parallaxIndexes;
    if (indexes == null) {
      return true;
    }
    return indexes.contains(index);
  }

  double _pageOverlapOffset({required int index, required double width}) {
    if (!widget.coverPreviousPage || width == 0 || !_shouldApplyEffect(index)) {
      return 0;
    }

    final page = _currentPage;
    final diff = page - index;
    if (diff >= 0) {
      final clampedDiff = diff.clamp(0.0, 1.0);
      return clampedDiff * width * (1 - widget.pageOverlapFraction);
    } else {
      return 0.0;
    }
  }

  double _pageScale({required int index}) {
    if (!widget.coverPreviousPage || !_shouldApplyEffect(index)) {
      return 1.0;
    }

    final page = _currentPage;
    final diff = page - index;
    if (diff >= 0) {
      final clampedDiff = diff.clamp(0.0, 1.0);
      return 1.0 - ((1.0 - widget.minScale) * clampedDiff);
    } else {
      return 1.0;
    }
  }
}
