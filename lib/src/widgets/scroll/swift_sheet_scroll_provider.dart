import 'package:flutter/material.dart';

class SwiftSheetScrollProvider extends InheritedWidget {
  final ScrollController controller;

  const SwiftSheetScrollProvider({
    super.key,
    required this.controller,
    required super.child,
  });

  static SwiftSheetScrollProvider? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SwiftSheetScrollProvider>();
  }

  static ScrollController of(BuildContext context) {
    final provider = maybeOf(context);
    assert(provider != null, 'No SwiftSheetScrollProvider found in context');
    return provider!.controller;
  }

  @override
  bool updateShouldNotify(SwiftSheetScrollProvider oldWidget) =>
      controller != oldWidget.controller;
}

class SwiftSheetScrollBinding extends StatefulWidget {
  final Widget child;

  const SwiftSheetScrollBinding({super.key, required this.child});

  @override
  State<SwiftSheetScrollBinding> createState() =>
      _SwiftSheetScrollBindingState();
}

class _SwiftSheetScrollBindingState extends State<SwiftSheetScrollBinding> {
  final _fallbackController = ScrollController();

  @override
  void dispose() {
    _fallbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller =
        PrimaryScrollController.maybeOf(context) ?? _fallbackController;
    return SwiftSheetScrollProvider(
      controller: controller,
      child: widget.child,
    );
  }
}
