import 'package:flutter/widgets.dart';
import 'package:flutter/scheduler.dart';

import '../blur/progressive_blur.dart';
import '../components/liquid_glass.dart';

/// Compiles the kit's GPU pipelines before the first real screen needs them.
///
/// Impeller builds a pipeline the first time a shader is drawn, which costs tens of milliseconds on a phone and shows
/// up as a hitch (or a dropped route transition) the first time a page with a blur zone or glass opens.
/// `RavelWarmUp` draws a tiny progressive blur zone and glass plates once, under [child] (so nothing is visible), then
/// removes them after a few frames. Put it above the navigator, e.g. in `MaterialApp.builder`, and call
/// `preloadRavelUiKit()` before `runApp`.
class RavelWarmUp extends StatefulWidget {
  const RavelWarmUp({super.key, required this.child});
  final Widget child;

  @override
  State<RavelWarmUp> createState() => _RavelWarmUpState();
}

class _RavelWarmUpState extends State<RavelWarmUp> {
  static bool _done = false;
  int _frames = 0;
  late bool _show = !_done;

  @override
  void initState() {
    super.initState();
    if (_show) _tick();
  }

  void _tick() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (++_frames >= 3) {
        _done = true;
        setState(() => _show = false);
      } else {
        SchedulerBinding.instance.scheduleFrame();
        _tick();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final warm = _show && ProgressiveBlur.shaderSupported;
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        // keep the child at the same position in the tree when the warm-up goes away: no state loss
        if (warm)
          const Positioned(
            left: 0,
            top: 0,
            width: 64,
            height: 64,
            child: IgnorePointer(child: _WarmUpContent()),
          )
        else
          const SizedBox.shrink(),
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

class _WarmUpContent extends StatelessWidget {
  const _WarmUpContent();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      textDirection: TextDirection.ltr,
      children: [
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          child: ProgressiveBlur(
            height: 24,
            edge: BlurEdge.top,
            maxSigma: 10,
            tint: Color(0xFF000000),
          ),
        ),
        Positioned(
          left: 0,
          top: 28,
          child: LiquidGlassGroup(child: LiquidGlass.circle(size: 16)),
        ),
        Positioned(
          left: 24,
          top: 28,
          child: LiquidGlass.circle(size: 16, highQuality: true),
        ),
        Positioned(
          left: 44,
          top: 28,
          child: LiquidGlass.circle(size: 16, interactive: true),
        ),
      ],
    );
  }
}
