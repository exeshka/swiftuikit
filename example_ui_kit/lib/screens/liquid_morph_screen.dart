import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

import 'tech_page.dart';

/// Pairs of 60 pt glass circles at different gaps inside a LiquidGlassGroup
/// (spacing 40): they melt into one shape as they get closer, like SwiftUI's
/// GlassEffectContainer. Drag the slider to animate the gap.
@RoutePage()
class LiquidMorphScreen extends StatefulWidget {
  const LiquidMorphScreen({super.key});
  @override
  State<LiquidMorphScreen> createState() => _LiquidMorphScreenState();
}

class _LiquidMorphScreenState extends State<LiquidMorphScreen> {
  static const gaps = [90.0, 60.0, 45.0, 35.0, 25.0, 15.0, 5.0, -10.0];
  double _live = 60;

  @override
  Widget build(BuildContext context) {
    return TechPage(
      title: 'Liquid glass morph',
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF404040), Color(0xFF8C8C8C)],
                  ),
                ),
                child: const SizedBox.expand(),
              ),
            ),
            for (var r = 0; r <= gaps.length; r++)
              Positioned.fill(
                child: LiquidGlassGroup(
                  spacing: 40,
                  child: Stack(
                    children: _pair(
                      60.0 + r * 100,
                      r < gaps.length ? gaps[r] : _live,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Slider(
                value: _live,
                min: -20,
                max: 120,
                onChanged: (v) => setState(() => _live = v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _pair(double y, double gap) {
    final x0 = 200 - (120 + gap) / 2;
    Widget plate(double x) =>
        Positioned(left: x, top: y, child: const LiquidGlass.circle(size: 60));
    return [plate(x0), plate(x0 + 60 + gap)];
  }
}
