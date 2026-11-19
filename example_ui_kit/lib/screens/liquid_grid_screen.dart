import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

import 'tech_page.dart';

/// Draggable liquid glass plates over a white grid with black lines, to see
/// refraction and morphing. All plates share one LiquidGlassGroup(spacing: 40):
/// bring them close and they melt together, tints blend across the bridge.
// --dart-define=PRE=0 : shader-only blur (no engine prefilter), to judge aliasing on thin lines
const _pre = String.fromEnvironment('PRE');

@RoutePage()
class LiquidGridScreen extends StatefulWidget {
  const LiquidGridScreen({super.key});
  @override
  State<LiquidGridScreen> createState() => _LiquidGridScreenState();
}

class _P {
  _P(this.pos, this.w, this.h, this.radius, this.tint);
  Offset pos;
  final double w;
  final double h;
  final double? radius;
  final Color? tint;
}

class _LiquidGridScreenState extends State<LiquidGridScreen> {
  double _spacing = 40;
  final _plates = <_P>[
    _P(const Offset(40, 180), 96, 96, null, const Color(0x59FF3B30)), // red
    _P(const Offset(180, 200), 96, 96, null, const Color(0x590A84FF)), // blue
    _P(
      const Offset(60, 360),
      200,
      60,
      null,
      const Color(0x5934C759),
    ), // green pill
    _P(
      const Offset(230, 460),
      120,
      120,
      36,
      const Color(0x59FFD60A),
    ), // yellow squircle
    _P(const Offset(40, 560), 96, 96, null, null), // untinted
    _P(const Offset(160, 660), 70, 70, null, const Color(0x59BF5AF2)), // purple
  ];

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.paddingOf(context);
    final base = SwiftUiTheme.of(context);
    return TechPage(
      title: 'Liquid glass grid',
      child: Theme(
        data: _pre.isEmpty
            ? Theme.of(context)
            : SwiftUiTheme.dark(
                data: base.withGlass(liquidPrefilter: double.parse(_pre)),
              ),
        child: _scaffold(context, safe),
      ),
    );
  }

  Widget _scaffold(BuildContext context, EdgeInsets safe) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _GridPainter()),
          Positioned.fill(
            child: LiquidGlassGroup(
              spacing: _spacing,
              child: Stack(
                children: [
                  for (final p in _plates)
                    Positioned(
                      left: p.pos.dx,
                      top: p.pos.dy,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: (d) => setState(() => p.pos += d.delta),
                        child: LiquidGlass(
                          width: p.w,
                          height: p.h,
                          cornerRadius: p.radius,
                          tint: p.tint,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: safe.bottom + 8,
            child: Row(
              children: [
                const Text(
                  'merge',
                  style: TextStyle(color: Colors.black, fontSize: 13),
                ),
                Expanded(
                  child: Slider(
                    value: _spacing,
                    min: 0,
                    max: 80,
                    onChanged: (v) => setState(() => _spacing = v),
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    _spacing.round().toString(),
                    style: const TextStyle(color: Colors.black, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final thin = Paint()
      ..color = Colors.black
      ..strokeWidth = 1;
    final bold = Paint()
      ..color = Colors.black
      ..strokeWidth = 3;
    for (var x = 0.0; x <= size.width; x += 20) {
      final i = (x / 20).round();
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        i % 5 == 0 ? bold : thin,
      );
    }
    for (var y = 0.0; y <= size.height; y += 20) {
      final i = (y / 20).round();
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        i % 5 == 0 ? bold : thin,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
