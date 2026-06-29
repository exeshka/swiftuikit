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
  });

  final Widget child;
  final SwiftPinnedHeaderChromeBuilder chromeBuilder;
  final SwiftPinnedHeaderOpacityGradientBuilder contentOpacityGradientBuilder;

  @override
  State<SwiftPinnedHeaderChrome> createState() =>
      _SwiftPinnedHeaderChromeState();

  static Widget _defaultChromeBuilder(
    BuildContext context,
    SwiftPinnedHeaderChromeSnapshot state,
  ) {
    if (state.animatedHeight <= 0) return const SizedBox.shrink();
    return ColoredBox(color: Colors.red.withAlpha(120));
  }

  static LinearGradient? _defaultContentOpacityGradientBuilder(
    BuildContext context,
    SwiftPinnedHeaderChromeSnapshot state,
  ) {
    return null;
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
    return SwiftPinnedHeaderChromeScope(
      controller: _controller,
      child: Stack(
        children: [
          widget.child,
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final ah = _controller.snapshot.totalHeight;
              _controller.animatedHeight = ah;

              if (ah <= 0) return const SizedBox.shrink();

              return Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: ah,
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: ColoredBox(color: Colors.red.withAlpha(120)),
                  ),
                ),
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
    this.animatedHeight = 0,
  });

  final List<SwiftPinnedHeaderChromeEntry> entries;
  final double totalHeight;
  final double animatedHeight;
}

class SwiftPinnedHeaderChromeEntry {
  const SwiftPinnedHeaderChromeEntry({
    required this.id,
    required this.height,
    required this.visibleHeight,
    required this.child,
    required this.link,
  });

  final Object id;
  final double height;
  final double visibleHeight;
  final Widget child;
  final LayerLink link;
}

class SwiftPinnedHeaderChromeController extends ChangeNotifier {
  final _entries = <Object, _SwiftPinnedHeaderChromeTrackedEntry>{};
  var _notifyScheduled = false;

  double animatedHeight = 0;

  SwiftPinnedHeaderChromeSnapshot get snapshot {
    final entries = List<SwiftPinnedHeaderChromeEntry>.unmodifiable(
      _entries.values.map((entry) => entry.chromeEntry),
    );

    return SwiftPinnedHeaderChromeSnapshot(
      entries: entries,
      totalHeight: entries.fold(
        0.0,
        (sum, entry) => sum + entry.visibleHeight,
      ),
      animatedHeight: animatedHeight,
    );
  }

  void update({
    required Object id,
    required double height,
    required double visibleHeight,
    required Widget child,
    required LayerLink link,
    required String signature,
    bool replaceAll = false,
  }) {
    if (visibleHeight <= 0) {
      if (_entries.remove(id) != null) {
        _scheduleNotify();
      }
      return;
    }

    if (replaceAll) {
      final hadEntries = _entries.isNotEmpty;
      _entries.clear();
      if (hadEntries) _scheduleNotify();
    }

    final existing = _entries[id];
    if (existing != null &&
        existing.chromeEntry.height == height &&
        existing.chromeEntry.visibleHeight == visibleHeight &&
        existing.chromeEntry.link == link &&
        existing.signature == signature) {
      return;
    }

    _entries[id] = _SwiftPinnedHeaderChromeTrackedEntry(
      signature: signature,
      chromeEntry: SwiftPinnedHeaderChromeEntry(
        id: id,
        height: height,
        visibleHeight: visibleHeight,
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
  _SwiftPinnedHeaderChromeTrackedEntry({
    required this.signature,
    required this.chromeEntry,
  });

  final String signature;
  SwiftPinnedHeaderChromeEntry chromeEntry;
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
