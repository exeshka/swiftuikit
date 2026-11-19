import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

import '../data.dart';
import 'drawer_shell.dart';

/// Copy of the ChatGPT iOS 26 side menu (reference 5).
@RoutePage()
class ChatGptScreen extends StatefulWidget {
  const ChatGptScreen({super.key});
  @override
  State<ChatGptScreen> createState() => _ChatGptScreenState();
}

class _ChatGptScreenState extends State<ChatGptScreen> {
  // starts scrolled so the first row is already under the title, like in the reference
  final _scroll = ScrollController(initialScrollOffset: 36);

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    return Scaffold(
      body: DrawerShell(
        page: (context, fill) => DrawerMainPage(
          title: 'ChatGPT',
          fill: fill,
          titleStyle: t.typography.title.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        menuFraction: 0.79,
        menu: ChromeScaffold(
          topBar: ChromeBar(
            child: TitleBar(
              // the page is a side menu: no back button
              automaticallyImplyLeading: false,
              title: 'ChatGPT',
              titleStyle: t.typography.title.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w600,
              ),
              trailing: [
                GlassCircleButton(
                  icon: RavelIcon(RavelIconKind.search),
                  semanticLabel: 'Search',
                  onPressed: () => Navigator.maybePop(context),
                ),
              ],
            ),
          ),
          bottomBar: ChromeBar(
            edge: ChromeEdge.bottom,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(34, 0, 20, 8),
              child: SizedBox(
                height: t.metrics.avatarSize,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FloatingPillButton(
                      label: 'Chat',
                      icon: RavelIcon(RavelIconKind.compose),
                      onPressed: () {},
                    ),
                    GlassAvatarButton(
                      initials: 'JD',
                      accented: true,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: ListView.builder(
            controller: _scroll,
            itemCount: chatGptTitles.length,
            itemBuilder: (context, i) => ListRow(
              title: chatGptTitles[i],
              height: 49,
              horizontalPadding: 33,
              style: t.typography.body.copyWith(fontSize: 19),
              trailing: i == 13
                  ? RavelIcon(
                      RavelIconKind.pencil,
                      size: 20,
                      color: t.colors.foregroundSecondary,
                    )
                  : null,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
  }
}
