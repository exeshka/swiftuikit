import 'package:flutter/material.dart';

class ScrollOverlapListener extends StatefulWidget {
  final ScrollController controller;
  final double maxOverlap;
  final Widget Function(BuildContext context, double overlap) builder;

  const ScrollOverlapListener({
    super.key,
    required this.controller,
    required this.maxOverlap,
    required this.builder,
  });

  @override
  State<ScrollOverlapListener> createState() => _ScrollOverlapListenerState();
}

class _ScrollOverlapListenerState extends State<ScrollOverlapListener> {
  final _overlap = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (!widget.controller.hasClients) return;
    final pixels = widget.controller.offset;
    final overscroll = pixels < 0 ? -pixels : 0.0;
    _overlap.value = overscroll.clamp(0.0, widget.maxOverlap);
  }

  @override
  void didUpdateWidget(covariant ScrollOverlapListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    _overlap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _overlap,
      builder: (context, overlap, _) => widget.builder(context, overlap),
    );
  }
}
