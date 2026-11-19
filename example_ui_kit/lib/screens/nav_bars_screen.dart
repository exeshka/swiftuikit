import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

/// Navigation header variants copied from native iOS 26 `NavigationStack` (see tools/native_glass_ref `nav`):
/// large title, large title with subtitle, small (inline) title, inline with subtitle.
// --dart-define=NAV=large|subtitle|inline|inlinesub chooses the variant when the screen is opened directly.
const _navDefault = String.fromEnvironment('NAV', defaultValue: 'large');
// --dart-define=NAVEMPTY=true: no rows (to measure the bar buttons against the native reference).
const _navEmpty = bool.fromEnvironment('NAVEMPTY');
// --dart-define=NAVTITLE=...: a custom (e.g. very long) title.
// --dart-define=NAVNOLEADING=true: no leading button.
const _navNoLeading = bool.fromEnvironment('NAVNOLEADING');
const _navTitle = String.fromEnvironment('NAVTITLE', defaultValue: 'Library');

@RoutePage()
class NavBarsScreen extends StatefulWidget {
  const NavBarsScreen({super.key});
  @override
  State<NavBarsScreen> createState() => _NavBarsScreenState();
}

class _NavBarsScreenState extends State<NavBarsScreen> {
  late String _mode = _navDefault;
  bool _swap = false;
  bool _third = false;
  static const _modes = ['large', 'subtitle', 'inline', 'inlinesub'];

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final inline = _mode.startsWith('inline');
    final sub = _mode == 'subtitle' || _mode == 'inlinesub';
    return Scaffold(
      body: ChromeScaffold(
        // the kit's default edge effect (no hand-set tint / sigma)
        bottomBlur: false,
        topBar: LargeTitleHeader(
          title: _navTitle,
          subtitle: sub ? '60 items' : null,
          style: inline ? NavTitleStyle.inline : NavTitleStyle.large,
          // this page tests the bar with and without a leading button
          automaticallyImplyLeading: false,
          leading: _navNoLeading
              ? null
              : GlassCircleButton(
                  icon: RavelIcon(RavelIconKind.menu),
                  onPressed: () => setState(
                    () => _mode =
                        _modes[(_modes.indexOf(_mode) + 1) % _modes.length],
                  ),
                ),
          trailing: [
            // tap search: its icon swaps (swap animation); tap compose: a third action appears / leaves
            GlassToolbarCapsule(
              items: [
                GlassToolbarItem(
                  id: _swap ? 'tasks' : 'search',
                  onPressed: () => setState(() => _swap = !_swap),
                  child: RavelIcon(
                    _swap ? RavelIconKind.tasks : RavelIconKind.search,
                    size: 26,
                    strokeWidth: 2.1,
                  ),
                ),
                GlassToolbarItem(
                  id: 'compose',
                  onPressed: () => setState(() => _third = !_third),
                  child: const RavelIcon(
                    RavelIconKind.compose,
                    size: 26,
                    strokeWidth: 2.1,
                  ),
                ),
                if (_third)
                  const GlassToolbarItem(
                    id: 'pencil',
                    child: RavelIcon(
                      RavelIconKind.pencil,
                      size: 26,
                      strokeWidth: 2.1,
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: CustomScrollView(
          slivers: [
            const SliverChromeInset.top(),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < (_navEmpty ? 0 : 60); i++)
                        SizedBox(
                          height: 52,
                          child: Row(
                            children: [
                              const SizedBox(width: 18),
                              RavelIcon(
                                RavelIconKind.chat,
                                size: 22,
                                color: t.colors.foreground,
                              ),
                              const SizedBox(width: 14),
                              Text(
                                'Row $i — The quick brown fox',
                                style: t.typography.body,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}
