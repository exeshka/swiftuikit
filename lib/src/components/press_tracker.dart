import 'package:flutter/widgets.dart';

/// Follows the finger over the buttons of a dialog or the rows of a menu: the button under it is the highlighted one, whichever it came down on, and
/// the one it is lifted over is activated. A press that ends outside every button does nothing.
class PressTracker<A extends Object> extends StatefulWidget {
  const PressTracker({
    super.key,
    required this.onActivate,
    required this.builder,
  });

  final void Function(A) onActivate;
  final Widget Function(
    BuildContext context,
    A? hot,
    GlobalKey Function(A) keyOf,
  )
  builder;

  @override
  State<PressTracker<A>> createState() => PressTrackerState<A>();
}

class PressTrackerState<A extends Object> extends State<PressTracker<A>> {
  final _keys = <A, GlobalKey>{};
  A? _hot;

  GlobalKey _keyOf(A a) => _keys.putIfAbsent(a, GlobalKey.new);

  void _track(Offset global) {
    A? found;
    for (final e in _keys.entries) {
      final box = e.value.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached || !box.hasSize) continue;
      final local = box.globalToLocal(global);
      if (box.size.contains(local)) {
        found = e.key;
        break;
      }
    }
    if (found != _hot) setState(() => _hot = found);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) => _track(e.position),
      onPointerMove: (e) => _track(e.position),
      onPointerUp: (e) {
        final hot = _hot;
        setState(() => _hot = null);
        if (hot != null) widget.onActivate(hot);
      },
      onPointerCancel: (_) => setState(() => _hot = null),
      child: widget.builder(context, _hot, _keyOf),
    );
  }
}
