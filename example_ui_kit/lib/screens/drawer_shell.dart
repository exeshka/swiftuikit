import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';
import 'package:swiftuikit/swiftuikit.dart' show ScreenRadiusService;

import '../data.dart';

/// Side menu under a page that slides to the right (ChatGPT / Claude iOS): the kit's [SwiftUiDrawer] with this example's
/// colours and the corner radius of the device's screen (44 pt when the platform cannot tell it).
///
/// [page] gets the colour that is painted under the page (its own scrim / fade should match it); the page opens the menu with
/// `SwiftUiDrawer.of(context).toggle()`.
class DrawerShell extends StatelessWidget {
  const DrawerShell({
    super.key,
    required this.menu,
    required this.page,
    this.menuFraction = 0.8,
    this.peekColor,
    this.initiallyOpen = false,
  });

  final Widget menu;
  final Widget Function(BuildContext context, Color fill) page;
  final double menuFraction;
  final Color? peekColor;
  final bool initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final theme = SwiftUiTheme.of(context);
    final fill =
        peekColor ??
        (theme.isDark ? const Color(0xFF111112) : const Color(0xFFFFFFFF));
    final deviceRadius = ScreenRadiusService.instance.radiusValue;
    return SwiftUiDrawer(
      menu: menu,
      menuFraction: menuFraction,
      initiallyOpen: initiallyOpen,
      pageColor: fill,
      cornerRadius: deviceRadius > 0 ? deviceRadius : 44,
      body: Builder(builder: (context) => page(context, fill)),
    );
  }
}

/// The main page of the drawer examples, made of kit components: a title bar with a menu button, a list that scrolls under
/// the bars (a vertical scroll must not fight the drawer's horizontal drag), and at the bottom a text field with a liquid
/// glass button on each side. The bars share one glass pass each ([ChromeBar] groups its plates).
class DrawerMainPage extends StatelessWidget {
  const DrawerMainPage({
    super.key,
    required this.title,
    required this.fill,
    this.titleStyle,
  });

  final String title;
  final Color fill;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    return ChromeScaffold(
      backgroundColor: fill,
      topBar: ChromeBar(
        child: TitleBar(
          automaticallyImplyLeading: false,
          leading: GlassCircleButton(
            icon: RavelIcon(RavelIconKind.menu),
            semanticLabel: 'Menu',
            onPressed: () => SwiftUiDrawer.of(context).toggle(),
          ),
          title: title,
          titleStyle: titleStyle,
          trailing: [
            GlassCircleButton(
              icon: RavelIcon(RavelIconKind.compose),
              semanticLabel: 'New',
              onPressed: () {},
            ),
          ],
        ),
      ),
      bottomBar: ChromeBar(
        edge: ChromeEdge.bottom,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            t.metrics.pageInset,
            0,
            t.metrics.pageInset,
            8,
          ),
          child: Row(
            // the buttons stay at the bottom while the field grows with its lines
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GlassCircleButton(
                icon: RavelIcon(RavelIconKind.plus),
                semanticLabel: 'Add',
                onPressed: () {},
              ),
              const SizedBox(width: 10),
              const Expanded(child: GlassTextField(hintText: 'Ask anything')),
              const SizedBox(width: 10),
              GlassCircleButton(
                icon: RavelIcon(RavelIconKind.chat),
                semanticLabel: 'Chats',
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: chatGptTitles.length,
        itemBuilder: (context, i) =>
            ListRow(title: chatGptTitles[i], onTap: () {}),
      ),
    );
  }
}
