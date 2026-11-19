import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

import 'tech_page.dart';

/// Two 80 pt glass circles in a LiquidGlassGroup(spacing 40); tapping the
/// screen makes the second one shrink into the first and grow back
/// (LiquidGlassPresence), like SwiftUI's glassEffectID transition.
@RoutePage()
class LiquidPresenceScreen extends StatefulWidget {
  const LiquidPresenceScreen({super.key});
  @override
  State<LiquidPresenceScreen> createState() => _LiquidPresenceScreenState();
}

class _LiquidPresenceScreenState extends State<LiquidPresenceScreen> {
  bool _on = true;

  @override
  Widget build(BuildContext context) {
    return TechPage(
      title: 'Liquid glass presence',
      child: Scaffold(
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _on = !_on),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF404040), Color(0xFF999999)],
                    ),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned.fill(
                child: LiquidGlassGroup(
                  spacing: 40,
                  child: Stack(
                    children: [
                      const Positioned(
                        left: 100,
                        top: 300,
                        child: LiquidGlass.circle(size: 80),
                      ),
                      Positioned(
                        left: 200,
                        top: 300,
                        child: LiquidGlassPresence(
                          show: _on,
                          duration: const Duration(milliseconds: 1500),
                          builder: (context, p) => LiquidGlass.circle(
                            size: 80,
                            presence: p,
                            presenceOrigin: const Offset(-100, 0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
