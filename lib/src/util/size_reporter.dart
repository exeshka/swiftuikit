import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Tells [onSize] the height of [child] after the frame it was laid out in (never during layout).
class SizeReporter extends SingleChildRenderObjectWidget {
  const SizeReporter({required this.onSize, super.child});
  final ValueChanged<double> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderSizeReporter(onSize);

  @override
  void updateRenderObject(BuildContext context, RenderSizeReporter r) =>
      r.onSize = onSize;
}

class RenderSizeReporter extends RenderProxyBox {
  RenderSizeReporter(this.onSize);
  ValueChanged<double> onSize;
  double? _last;

  @override
  void performLayout() {
    super.performLayout();
    final h = size.height;
    if (h != _last) {
      _last = h;
      // never notify during layout
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (attached) onSize(h);
      });
      WidgetsBinding.instance.ensureVisualUpdate();
    }
  }
}
