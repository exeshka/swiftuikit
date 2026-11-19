import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

import 'tech_page.dart';

/// One 44 pt glass circle button in the middle of a black screen, to drag it around and watch the stretch
/// (native counterpart: tools/native_glass_ref `center`).
@RoutePage()
class LiquidCenterScreen extends StatelessWidget {
  const LiquidCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TechPage(
      title: 'Liquid glass center',
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: GlassCircleButton(
            icon: RavelIcon(RavelIconKind.plus),
            size: 44,
            onPressed: () {},
          ),
        ),
      ),
    );
  }
}
