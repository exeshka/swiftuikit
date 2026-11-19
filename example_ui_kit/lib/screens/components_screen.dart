import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

/// All kit components over a colorful scroll background.
@RoutePage()
class ComponentsScreen extends StatelessWidget {
  const ComponentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    return Scaffold(
      body: SwiftUiScaffold(
        title: 'Components',
        body: ListView(
          children: [
            for (var i = 0; i < 24; i++)
              Container(
                height: 90,
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(t.metrics.cardRadius),
                  gradient: LinearGradient(
                    colors: [
                      HSLColor.fromAHSL(
                        1,
                        (i * 37.0) % 360,
                        0.7,
                        0.45,
                      ).toColor(),
                      HSLColor.fromAHSL(
                        1,
                        (i * 37.0 + 50) % 360,
                        0.7,
                        0.35,
                      ).toColor(),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: Wrap(
                  spacing: 12,
                  children: [
                    GlassCircleButton(
                      icon: RavelIcon(RavelIconKind.search),
                      liquid: false,
                      onPressed: () {},
                    ),
                    GlassCircleButton(
                      icon: RavelIcon(RavelIconKind.menu),
                      liquid: false,
                      onPressed: () {},
                    ),
                    GlassCircleButton(
                      icon: RavelIcon(RavelIconKind.plus),
                      liquid: false,
                      onPressed: () {},
                    ),
                    GlassAvatarButton(
                      initials: 'JD',
                      accented: true,
                      liquid: false,
                      onPressed: () {},
                    ),
                  ],
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
                FloatingPillButton(
                  label: 'New chat',
                  icon: RavelIcon(RavelIconKind.plus),
                  onPressed: () {},
                ),
                GlassAvatarButton(initials: 'J', onPressed: () {}),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
