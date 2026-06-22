import 'package:flutter/material.dart';
import 'package:inspire_blur/inspire_blur.dart';

typedef SwiftPinnedHeaderChromeBuilder =
    Widget Function(
      BuildContext context,
      SwiftPinnedHeaderChromeSnapshot state,
    );

typedef SwiftPinnedHeaderOpacityGradientBuilder =
    LinearGradient? Function(
      BuildContext context,
      SwiftPinnedHeaderChromeSnapshot state,
    );

class SwiftPinnedHeaderChrome extends StatefulWidget {
  const SwiftPinnedHeaderChrome({
    super.key,
    required this.child,
    this.chromeBuilder = _defaultChromeBuilder,
    this.contentOpacityGradientBuilder = _defaultContentOpacityGradientBuilder,
    this.chromeAnimationDuration = const Duration(milliseconds: 260),
    this.chromeAnimationCurve = Curves.easeOutCubic,
  });

  final Widget child;
  final SwiftPinnedHeaderChromeBuilder chromeBuilder;
  final SwiftPinnedHeaderOpacityGradientBuilder contentOpacityGradientBuilder;
  final Duration chromeAnimationDuration;
  final Curve chromeAnimationCurve;

  @override
  State<SwiftPinnedHeaderChrome> createState() =>
      _SwiftPinnedHeaderChromeState();

  static Widget _defaultChromeBuilder(
    BuildContext context,
    SwiftPinnedHeaderChromeSnapshot state,
  ) {
    return SwiftProgressiveBlurChrome(
      height: state.totalHeight,
      maxBlurSigma: 20,
    );
  }

  static LinearGradient? _defaultContentOpacityGradientBuilder(
    BuildContext context,
    SwiftPinnedHeaderChromeSnapshot state,
  ) {
    if (state.totalHeight == 0) return null;

    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Theme.of(context).colorScheme.surface, Colors.transparent],
      stops: [0, 1],
    );
  }
}

class SwiftProgressiveBlurChrome extends StatelessWidget {
  const SwiftProgressiveBlurChrome({
    super.key,
    required this.height,
    this.maxBlurSigma = 20,
    this.blurSteps = 14,
    this.blurGradientBegin = Alignment.bottomCenter,
    this.blurGradientEnd = Alignment.topCenter,
    this.border,
  });

  final double height;
  final double maxBlurSigma;
  final int blurSteps;
  final AlignmentGeometry blurGradientBegin;
  final AlignmentGeometry blurGradientEnd;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    if (height == 0) {
      return const SizedBox.shrink();
    }

    final resolvedBegin = blurGradientBegin.resolve(Directionality.of(context));
    final resolvedEnd = blurGradientEnd.resolve(Directionality.of(context));

    return SizedBox(
      height: height,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Inspire.backdropBlur(
              config: InspireBlurConfig.directional(
                start: resolvedEnd,
                end: resolvedBegin,
                sigma: maxBlurSigma,
                fadeCurve: Curves.linear,
              ),
              clipBehavior: Clip.hardEdge,
            ),
            DecoratedBox(decoration: BoxDecoration(border: border)),
          ],
        ),
      ),
    );
  }
}

class _SwiftPinnedHeaderChromeState extends State<SwiftPinnedHeaderChrome> {
  late final SwiftPinnedHeaderChromeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SwiftPinnedHeaderChromeController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final animation = route?.animation;
    final secondaryAnimation = route?.secondaryAnimation;
    final transitionListenable = Listenable.merge([
      ?animation,
      ?secondaryAnimation,
    ]);

    return SwiftPinnedHeaderChromeScope(
      controller: _controller,
      child: Stack(
        children: [
          widget.child,
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final snapshot = _controller.snapshot;
              return _AnimatedChromeLayer(
                snapshot: snapshot,
                duration: widget.chromeAnimationDuration,
                curve: widget.chromeAnimationCurve,
                builder: (context, animatedSnapshot) {
                  final opacityGradient = widget.contentOpacityGradientBuilder(
                    context,
                    animatedSnapshot,
                  );
                  if (animatedSnapshot.totalHeight == 0 ||
                      opacityGradient == null) {
                    return const SizedBox.shrink();
                  }

                  return Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: animatedSnapshot.totalHeight,
                    child: IgnorePointer(
                      child: RepaintBoundary(
                        child: DecoratedBox(
                          decoration: BoxDecoration(gradient: opacityGradient),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final snapshot = _controller.snapshot;
              return _AnimatedChromeLayer(
                snapshot: snapshot,
                duration: widget.chromeAnimationDuration,
                curve: widget.chromeAnimationCurve,
                builder: (context, animatedSnapshot) {
                  return Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: animatedSnapshot.totalHeight,
                    child: IgnorePointer(
                      child: RepaintBoundary(
                        child: widget.chromeBuilder(context, animatedSnapshot),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          AnimatedBuilder(
            animation: Listenable.merge([_controller, transitionListenable]),
            builder: (context, _) {
              final snapshot = _controller.snapshot;
              final isTransitioning =
                  (animation != null &&
                      !animation.isCompleted &&
                      !animation.isDismissed) ||
                  (secondaryAnimation != null &&
                      !secondaryAnimation.isCompleted &&
                      !secondaryAnimation.isDismissed);

              return Stack(
                children: [
                  for (final entry in snapshot.entries)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: CompositedTransformFollower(
                        link: entry.link,
                        showWhenUnlinked: false,
                        child: Opacity(
                          opacity: isTransitioning ? 0.0 : 1.0,
                          child: IgnorePointer(
                            ignoring: isTransitioning,
                            child: entry.child,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class SwiftPinnedHeaderChromeSnapshot {
  const SwiftPinnedHeaderChromeSnapshot({
    required this.entries,
    required this.totalHeight,
  });

  final List<SwiftPinnedHeaderChromeEntry> entries;
  final double totalHeight;
}

typedef _AnimatedChromeLayerBuilder =
    Widget Function(
      BuildContext context,
      SwiftPinnedHeaderChromeSnapshot state,
    );

class _AnimatedChromeLayer extends StatelessWidget {
  const _AnimatedChromeLayer({
    required this.snapshot,
    required this.duration,
    required this.curve,
    required this.builder,
  });

  final SwiftPinnedHeaderChromeSnapshot snapshot;
  final Duration duration;
  final Curve curve;
  final _AnimatedChromeLayerBuilder builder;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: snapshot.totalHeight),
      duration: duration,
      curve: curve,
      builder: (context, animatedHeight, _) {
        return builder(
          context,
          SwiftPinnedHeaderChromeSnapshot(
            entries: snapshot.entries,
            totalHeight: animatedHeight,
          ),
        );
      },
    );
  }
}

class SwiftPinnedHeaderChromeEntry {
  const SwiftPinnedHeaderChromeEntry({
    required this.id,
    required this.height,
    required this.child,
    required this.link,
  });

  final Object id;
  final double height;
  final Widget child;
  final LayerLink link;
}

class SwiftPinnedHeaderChromeController extends ChangeNotifier {
  final _entries = <Object, _SwiftPinnedHeaderChromeTrackedEntry>{};
  var _notifyScheduled = false;

  SwiftPinnedHeaderChromeSnapshot get snapshot {
    final entries = List<SwiftPinnedHeaderChromeEntry>.unmodifiable(
      _entries.values.map((entry) => entry.chromeEntry),
    );

    return SwiftPinnedHeaderChromeSnapshot(
      entries: entries,
      totalHeight: entries.fold(0, (height, entry) => height + entry.height),
    );
  }

  void update({
    required Object id,
    required double height,
    required Widget child,
    required LayerLink link,
    required String signature,
    required bool pinned,
  }) {
    if (!pinned) {
      if (_entries.remove(id) != null) {
        _scheduleNotify();
      }

      return;
    }

    final existing = _entries[id];
    if (existing != null &&
        existing.chromeEntry.height == height &&
        existing.chromeEntry.link == link &&
        existing.signature == signature) {
      return;
    }

    _entries[id] = _SwiftPinnedHeaderChromeTrackedEntry(
      signature: signature,
      chromeEntry: SwiftPinnedHeaderChromeEntry(
        id: id,
        height: height,
        child: child,
        link: link,
      ),
    );

    _scheduleNotify();
  }

  void remove(Object id) {
    if (_entries.remove(id) != null) {
      _scheduleNotify();
    }
  }

  void _scheduleNotify() {
    if (_notifyScheduled) return;
    _notifyScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!hasListeners) {
        _notifyScheduled = false;
        return;
      }

      _notifyScheduled = false;
      notifyListeners();
    });
  }
}

class _SwiftPinnedHeaderChromeTrackedEntry {
  const _SwiftPinnedHeaderChromeTrackedEntry({
    required this.signature,
    required this.chromeEntry,
  });

  final String signature;
  final SwiftPinnedHeaderChromeEntry chromeEntry;
}

class SwiftPinnedHeaderChromeScope extends InheritedWidget {
  const SwiftPinnedHeaderChromeScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final SwiftPinnedHeaderChromeController controller;

  static SwiftPinnedHeaderChromeController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SwiftPinnedHeaderChromeScope>()
        ?.controller;
  }

  @override
  bool updateShouldNotify(covariant SwiftPinnedHeaderChromeScope oldWidget) {
    return oldWidget.controller != controller;
  }
}
