import 'package:flutter/widgets.dart';

/// Tap target with the small iOS "squish" feedback.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onPressed,
    this.scale = 0.94,
    this.semanticLabel,
    this.squish = true,
  });

  final Widget child;

  /// false: no scale feedback (the child shows its own press effect, e.g. interactive liquid glass).
  final bool squish;
  final VoidCallback? onPressed;
  final double scale;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _down && widget.squish ? widget.scale : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
