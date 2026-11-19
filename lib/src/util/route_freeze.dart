import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../components/liquid_glass.dart';

/// Replaces the page with a snapshot of itself while another route moves over it (push, pop, swipe-back).
///
/// Why: every `BackdropFilter` (progressive blur, glass) breaks the render pass and costs ~1 ms of GPU on iPhone no
/// matter how small it is, and during a transition the filters of BOTH pages are alive (8 on a ChatGPT-like page:
/// ~10-12 ms raster per frame, the budget is 8.3 ms at 120 Hz). The page under a transition does not change, so its
/// pixels are captured once (filters included) and drawn as one image; the page stays in the tree (state, scroll
/// position) and goes live again when the transition ends.
class FreezeUnderRoute extends StatefulWidget {
  const FreezeUnderRoute({super.key, required this.child, this.enabled = true});
  final Widget child;

  /// false: the page stays live under a transition (no snapshot).
  final bool enabled;

  @override
  State<FreezeUnderRoute> createState() => _FreezeUnderRouteState();
}

class _FreezeUnderRouteState extends State<FreezeUnderRoute> {
  Animation<double>? _b;
  bool _frozen = false;

  bool get _covered {
    final b = _b;
    return b != null &&
        b.status != AnimationStatus.completed &&
        b.status != AnimationStatus.dismissed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final b = ModalRoute.of(context)?.secondaryAnimation;
    if (b != _b) {
      _b?.removeStatusListener(_onStatus);
      _b = b;
      _b?.addStatusListener(_onStatus);
    }
  }

  void _onStatus(AnimationStatus _) {
    // after the frame that started the transition: the page has been painted, so its layer can be captured
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final want = _covered;
      if (want != _frozen) setState(() => _frozen = want);
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _b?.removeStatusListener(_onStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _Freeze(
    frozen: _frozen && widget.enabled,
    devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
    child: widget.child,
  );
}

class _Freeze extends SingleChildRenderObjectWidget {
  const _Freeze({
    required this.frozen,
    required this.devicePixelRatio,
    super.child,
  });
  final bool frozen;
  final double devicePixelRatio;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderFreeze(frozen, devicePixelRatio);

  @override
  void updateRenderObject(BuildContext context, _RenderFreeze r) {
    r
      ..devicePixelRatio = devicePixelRatio
      ..frozen = frozen;
  }
}

class _RenderFreeze extends RenderProxyBox {
  _RenderFreeze(this._frozen, this._dpr);

  bool _frozen;
  double _dpr;
  ui.Image? _image;

  set devicePixelRatio(double v) => _dpr = v;

  set frozen(bool v) {
    if (v == _frozen) return;
    _frozen = v;
    if (v) {
      _capture();
      // no snapshot (never painted, or not capturable): keep the live page
      if (_image == null) _frozen = false;
    } else {
      _release();
    }
    markNeedsPaint();
  }

  void _capture() {
    _release();
    final l = layer;
    if (l is! OffsetLayer || !hasSize || size.isEmpty) return;
    try {
      // the glass inside must place its plates relative to this layer while the capture re-builds the scene
      _image = GlassSnapshot.capture(
        l,
        _dpr,
        () => l.toImageSync(Offset.zero & size, pixelRatio: _dpr),
      );
    } catch (_) {
      _image = null;
    }
  }

  void _release() {
    _image?.dispose();
    _image = null;
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    final img = _image;
    if (_frozen && img != null) {
      final src = Rect.fromLTWH(
        0,
        0,
        img.width.toDouble(),
        img.height.toDouble(),
      );
      context.canvas.drawImageRect(
        img,
        src,
        offset & size,
        Paint()..filterQuality = FilterQuality.none,
      );
      return;
    }
    super.paint(context, offset);
  }

  @override
  void detach() {
    _release();
    super.detach();
  }
}
