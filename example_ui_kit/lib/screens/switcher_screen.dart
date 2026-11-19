import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

/// SwiftUiPageSwitcher: three pages behind one tab bar. The bar and the header stay put, the pages are switched with the chosen
/// transition (none of them uses an opacity layer, so the blur under the bars and the glass keep working while it runs); every
/// page keeps its scroll position.
@RoutePage()
class SwitcherScreen extends StatefulWidget {
  const SwitcherScreen({super.key});

  @override
  State<SwitcherScreen> createState() => _SwitcherScreenState();
}

class _SwitcherScreenState extends State<SwitcherScreen> {
  int _tab = 0;
  SwiftUiSwitchTransition _transition = SwiftUiSwitchTransition.fadeThrough;
  static const _hues = [210.0, 20.0, 130.0];

  Widget _page(BuildContext context, int tab) {
    final t = SwiftUiTheme.of(context);
    return ListView(
      key: PageStorageKey('page$tab'),
      children: [
        for (var i = 0; i < 40; i++)
          Container(
            height: 84,
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(t.metrics.cardRadius),
              color: HSLColor.fromAHSL(
                1,
                (_hues[tab] + i * 6) % 360,
                0.65,
                0.42,
              ).toColor(),
            ),
            alignment: Alignment.center,
            child: Text(
              'Page ${tab + 1} · row $i',
              style: t.typography.body.copyWith(color: Colors.white),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SwiftUiScaffold(
        title: 'Switcher',
        actions: [
          GlassCircleButton(
            icon: const RavelIcon(RavelIconKind.menu),
            onPressed: () => setState(() {
              const all = SwiftUiSwitchTransition.values;
              _transition = all[(_transition.index + 1) % all.length];
            }),
          ),
        ],
        subtitle: 'transition: ${_transition.name} (tap the menu)',
        bottomBar: BottomDock(
          navBar: GlassTabBar(
            tabs: const [
              GlassTab(icon: RavelIcon(RavelIconKind.chat), label: 'Chats'),
              GlassTab(icon: RavelIcon(RavelIconKind.tasks), label: 'Tasks'),
              GlassTab(
                icon: RavelIcon(RavelIconKind.artifacts),
                label: 'Files',
              ),
            ],
            selectedIndex: _tab,
            onSelected: (i) => setState(() => _tab = i),
          ),
        ),
        body: SwiftUiPageSwitcher(
          index: _tab,
          transition: _transition,
          children: [for (var i = 0; i < 3; i++) _page(context, i)],
        ),
      ),
    );
  }
}
