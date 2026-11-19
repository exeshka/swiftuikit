import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

/// Liquid glass showcase over a colorful, high-detail background.
@RoutePage()
class LiquidScreen extends StatelessWidget {
  const LiquidScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    return Scaffold(
      body: ChromeScaffold(
        topBar: LargeTitleHeader(
          title: 'Liquid glass',
          trailing: [
            LiquidGlass.circle(
              size: t.metrics.circleButtonSize,
              child: Center(
                child: RavelIcon(
                  RavelIconKind.search,
                  color: t.glass.glassIcon,
                ),
              ),
            ),
          ],
        ),
        bottomBar: ChromeBar(
          edge: ChromeEdge.bottom,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                LiquidGlass(
                  height: t.metrics.pillHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RavelIcon(
                          RavelIconKind.plus,
                          color: t.colors.foreground,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'New chat',
                          style: t.typography.title.copyWith(
                            fontSize: 19,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                LiquidGlass.circle(
                  size: t.metrics.avatarSize,
                  child: Center(
                    child: Text(
                      'M',
                      style: t.typography.title.copyWith(fontSize: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: ListView.builder(
          itemCount: 40,
          itemBuilder: (context, i) => Container(
            height: 132,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  HSLColor.fromAHSL(1, (i * 41.0) % 360, 0.8, 0.5).toColor(),
                  HSLColor.fromAHSL(
                    1,
                    (i * 41.0 + 70) % 360,
                    0.8,
                    0.4,
                  ).toColor(),
                ],
              ),
            ),
            child: Stack(
              children: [
                // fine detail to make refraction readable
                Positioned.fill(child: CustomPaint(painter: _Stripes(i))),
                Center(
                  child: Wrap(
                    spacing: 14,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      LiquidGlass.circle(
                        size: 52,
                        child: Center(
                          child: RavelIcon(
                            RavelIconKind.search,
                            color: t.glass.glassIcon,
                          ),
                        ),
                      ),
                      LiquidGlass(
                        height: 48,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Liquid',
                                style: t.typography.title.copyWith(
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      LiquidGlass(
                        width: 92,
                        height: 64,
                        cornerRadius: 22,
                        child: Center(
                          child: RavelIcon(
                            RavelIconKind.compose,
                            size: 28,
                            color: t.glass.glassIcon,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stripes extends CustomPainter {
  _Stripes(this.seed);
  final int seed;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 3;
    for (var x = -size.height; x < size.width; x += 18) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), p);
    }
    final dot = Paint()..color = const Color(0x55000000);
    for (var i = 0; i < 12; i++) {
      canvas.drawCircle(
        Offset((i * 53 + seed * 17) % size.width, (i * 31) % size.height),
        6,
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(_Stripes old) => false;
}
