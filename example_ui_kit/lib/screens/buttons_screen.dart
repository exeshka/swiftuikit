import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

/// Every [GlassButton] look next to the native ones (`tools/native_buttons_ref`): the six styles, the five sizes, the circle and the
/// destructive / disabled / full width variants, over a colourful backdrop so the glass shows. The prominent glass button rests as a
/// flat tinted fill and melts into liquid glass while pressed (and back, smoothly).
@RoutePage()
class ButtonsScreen extends StatelessWidget {
  const ButtonsScreen({super.key});

  Widget _row(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12)),
        ),
        Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: children),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF4B6E), Color(0xFFB02CFF), Color(0xFF1E6BFF), Color(0xFF00B7D4)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.only(top: 80, bottom: 60),
          children: [
            _row('glass / glassProminent / bordered / borderedProminent / borderless / plain', [
              for (final s in GlassButtonStyle.values) GlassButton(label: s.name, style: s, onPressed: () {}),
            ]),
            _row('sizes: mini small regular large extraLarge (glassProminent)', [
              for (final z in GlassButtonSize.values)
                GlassButton(label: z.name, style: GlassButtonStyle.glassProminent, size: z, onPressed: () {}),
            ]),
            _row('sizes (glass)', [
              for (final z in GlassButtonSize.values) GlassButton(label: z.name, size: z, onPressed: () {}),
            ]),
            _row('circles: glass / glassProminent / bordered', [
              GlassButton.circle(icon: RavelIcon(RavelIconKind.plus), onPressed: () {}),
              GlassButton.circle(icon: RavelIcon(RavelIconKind.search), style: GlassButtonStyle.glassProminent, onPressed: () {}),
              GlassButton.circle(icon: RavelIcon(RavelIconKind.menu), style: GlassButtonStyle.bordered, onPressed: () {}),
              GlassButton.circle(icon: RavelIcon(RavelIconKind.plus), size: GlassButtonSize.large, onPressed: () {}),
            ]),
            _row('destructive / tinted / disabled', [
              GlassButton(label: 'Delete', destructive: true, onPressed: () {}),
              GlassButton(label: 'Delete', destructive: true, style: GlassButtonStyle.glassProminent, onPressed: () {}),
              GlassButton(label: 'Orange', tint: Colors.orange, style: GlassButtonStyle.borderedProminent, onPressed: () {}),
              const GlassButton(label: 'Disabled'),
              const GlassButton(label: 'Disabled', style: GlassButtonStyle.glassProminent),
            ]),
            _row('the messenger OPEN pill (flat blue, glass while pressed)', [
              GlassButton(
                label: 'OPEN',
                style: GlassButtonStyle.glassProminent,
                size: GlassButtonSize.small,
                tint: const Color(0xFF4C9BF5),
                onPressed: () {},
              ),
              GlassButton(
                label: 'OPEN',
                style: GlassButtonStyle.glassProminent,
                size: GlassButtonSize.small,
                tint: const Color(0xFF4C9BF5),
                glassOnPress: false,
                onPressed: () {},
              ),
            ]),
            _row('full width', [
              SizedBox(
                width: MediaQuery.sizeOf(context).width - 40,
                child: GlassButton(label: 'Continue', style: GlassButtonStyle.glassProminent, size: GlassButtonSize.large, expand: true, onPressed: () {}),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
