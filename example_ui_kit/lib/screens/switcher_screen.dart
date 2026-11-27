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
  // the tab bar collapses while a page scrolls down and expands after a real scroll back up (iOS 26 tabBarMinimizeBehavior)
  final _minimize = TabBarMinimizeController();
  SwiftUiSwitchTransition _transition = SwiftUiSwitchTransition.fadeThrough;
  static const _hues = [210.0, 20.0, 130.0];

  @override
  void dispose() {
    _minimize.dispose();
    super.dispose();
  }

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

  static const _names = ['Chats', 'Tasks', 'Files'];

  /// One page: its own header (title, glass button), its own scroll and edge effect, like the root of a tab's navigation stack.
  Widget _scaffold(BuildContext context, int tab) => SwiftUiScaffold(
    title: _names[tab],
    subtitle: 'transition: ${_transition.name} (tap the menu)',
    actions: [
      GlassCircleButton(
        icon: const RavelIcon(RavelIconKind.menu),
        onPressed: () => setState(() {
          const all = SwiftUiSwitchTransition.values;
          _transition = all[(_transition.index + 1) % all.length];
        }),
      ),
    ],
    body: _page(context, tab),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // the shell keeps the tab bar (built once); every page under it is a screen of its own with its own header
      body: SwiftUiShell(
        bottomBar: ValueListenableBuilder<bool>(
          valueListenable: _minimize,
          builder: (context, minimized, _) => GlassTabBar(
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
            minimized: minimized,
            onExpand: _minimize.expand,
            // the mini player of a music app: a plate over the bar, in the row of the collapsed button while the bar is collapsed
            // shared elements travel with the transition: the icon and the play button stay, the title and the next button
            // fade as `progress` (0 expanded .. 1 inline) goes
            accessoryProgressBuilder: (context, progress) =>
                _MiniPlayer(progress),
            onAccessoryTap: () {},
          ),
        ),
        body: TabBarMinimizeScope(
          controller: _minimize,
          child: SwiftUiPageSwitcher(
            index: _tab,
            transition: _transition,
            children: [for (var i = 0; i < 3; i++) _scaffold(context, i)],
          ),
        ),
      ),
    );
  }
}

/// The content of the bar's accessory, driven by the transition itself: `progress` 0 = over the bar, 1 = in the row of the
/// collapsed button. The icon and the play button are the same elements in both places; the two-line title turns into the
/// short "Playing" and the next button folds away, all by `progress` (no swap).
class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer(this.progress);
  final double progress;

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final p = progress.clamp(0.0, 1.0);
    final title = (1 - p * 2).clamp(
      0.0,
      1.0,
    ); // the two lines go in the first half
    final short = (p * 2 - 1).clamp(0.0, 1.0); // "Playing" comes in the second
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          // the icon: the same widget, a little smaller inline
          Transform.scale(
            scale: 1 - 0.1 * p,
            child: Icon(Icons.music_note, color: t.colors.foreground, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Opacity(
                  opacity: title,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Now Playing',
                        maxLines: 1,
                        softWrap: false,
                        style: t.typography.body.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'Artist',
                        maxLines: 1,
                        softWrap: false,
                        style: t.typography.caption.copyWith(
                          fontSize: 12,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                Opacity(
                  opacity: short,
                  child: Text(
                    'Playing',
                    maxLines: 1,
                    softWrap: false,
                    style: t.typography.body.copyWith(fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.play_arrow_rounded, color: t.colors.foreground, size: 26),
          // the next button folds away (its width goes with its alpha)
          ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: 1 - p,
              child: Opacity(
                opacity: 1 - p,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Icon(
                    Icons.fast_forward_rounded,
                    color: t.colors.foreground,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
