import 'package:flutter/material.dart';

class ScrollValueListener extends StatefulWidget {
  final ScrollController controller;
  final Widget Function(BuildContext context, double offset) builder;

  const ScrollValueListener({
    super.key,
    required this.controller,
    required this.builder,
  });

  @override
  State<ScrollValueListener> createState() => _ScrollValueListenerState();
}

class _ScrollValueListenerState extends State<ScrollValueListener> {
  final _offset = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
    _syncImmediately();
  }

  @override
  void didUpdateWidget(covariant ScrollValueListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
      _syncImmediately(); // подхватываем актуальный offset нового контроллера сразу, не дожидаясь его скролла
    }
  }

  void _syncImmediately() {
    if (widget.controller.hasClients) {
      _offset.value = widget.controller.offset;
    }
  }

  void _onScroll() {
    if (!widget.controller.hasClients) return;
    _offset.value = widget.controller.offset;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    _offset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _offset,
      builder: (context, offset, _) => widget.builder(context, offset),
    );
  }
}
