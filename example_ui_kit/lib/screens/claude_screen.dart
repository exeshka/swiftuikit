import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

import '../data.dart';
import 'drawer_shell.dart';

/// Copy of the Claude iOS 26 side menu (reference 6).
@RoutePage()
class ClaudeScreen extends StatefulWidget {
  const ClaudeScreen({super.key});
  @override
  State<ClaudeScreen> createState() => _ClaudeScreenState();
}

class _ClaudeScreenState extends State<ClaudeScreen> {
  final _scroll = ScrollController(initialScrollOffset: 92);

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Claude brand preset: warmer near-black background, same tokens otherwise.
    final base = SwiftUiTheme.of(context);
    final tokens = base.isDark
        ? base.copyWith(
            colors: base.colors.copyWith(background: const Color(0xFF0F0F0F)),
            chrome: base.chrome.copyWith(blurTint: const Color(0xFF0F0F0F)),
          )
        : base;
    return Theme(
      data: base.isDark ? SwiftUiTheme.dark(data: tokens) : Theme.of(context),
      child: Builder(
        builder: (context) {
          final t = SwiftUiTheme.of(context);
          final icon = t.colors.foregroundSecondary;
          Widget row(String title, RavelIconKind kind) => ListRow(
            title: title,
            height: 51,
            horizontalPadding: 27,
            style: t.typography.body.copyWith(fontSize: 19),
            leading: RavelIcon(kind, size: 28, color: icon, strokeWidth: 1.5),
            onTap: () {},
          );
          return Scaffold(
            backgroundColor: t.colors.background,
            body: DrawerShell(
              page: (context, fill) => DrawerMainPage(
                title: 'Claude',
                fill: fill,
                titleStyle: t.typography.serifTitle.copyWith(fontSize: 24),
              ),
              menuFraction: 0.82,
              peekColor: t.isDark ? const Color(0xFF151515) : null,
              menu: ChromeScaffold(
                topBar: ChromeBar(
                  child: TitleBar(
                    // the page is a side menu: no back button
                    automaticallyImplyLeading: false,
                    title: 'Claude',
                    titleStyle: t.typography.serifTitle.copyWith(fontSize: 27),
                    trailing: [
                      GlassCircleButton(
                        icon: RavelIcon(RavelIconKind.menu),
                        semanticLabel: 'Menu',
                        onPressed: () => Navigator.maybePop(context),
                      ),
                    ],
                  ),
                ),
                bottomBar: ChromeBar(
                  edge: ChromeEdge.bottom,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 40, 8),
                    child: SizedBox(
                      height: t.metrics.avatarSize,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GlassAvatarButton(initials: 'J', onPressed: () {}),
                          FloatingPillButton(
                            label: 'New chat',
                            icon: RavelIcon(RavelIconKind.plus),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                body: ListView(
                  controller: _scroll,
                  children: [
                    row('Chats', RavelIconKind.chat),
                    row('Projects', RavelIconKind.artifacts),
                    row('Artifacts', RavelIconKind.artifacts),
                    row('Cowork', RavelIconKind.tasks),
                    const ListSectionTitle('Recents'),
                    for (final r in claudeRecents) row(r, RavelIconKind.chat),
                    ListRow(
                      title: 'All chats',
                      height: 51,
                      horizontalPadding: 27,
                      style: t.typography.caption.copyWith(fontSize: 19),
                      trailing: RavelIcon(
                        RavelIconKind.chevronRight,
                        size: 20,
                        color: t.colors.foregroundSecondary,
                      ),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
