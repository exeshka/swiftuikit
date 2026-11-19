import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

import '../app_state.dart';
import '../router/app_router.dart';

/// The index of the example, grouped like the router: applications first, then the technical pages.
@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    Widget item(String title, PageRouteInfo route, RavelIconKind icon) =>
        ListRow(
          title: title,
          leading: RavelIcon(icon, color: t.colors.foregroundSecondary),
          trailing: RavelIcon(
            RavelIconKind.chevronRight,
            size: 18,
            color: t.colors.foregroundTertiary,
          ),
          onTap: () => context.router.push(route),
        );
    // Material: the list rows use Text, which needs a Material ancestor (otherwise: yellow double underline)
    return Material(
      color: Colors.transparent,
      child: ChromeScaffold(
        topBar: LargeTitleHeader(
          title: 'Ravel UI Kit',
          trailing: [
            GlassCircleButton(
              icon: RavelIcon(
                ThemeMode.dark == themeMode.value
                    ? RavelIconKind.plus
                    : RavelIconKind.menu,
              ),
              semanticLabel: 'Toggle theme',
              onPressed: () =>
                  themeMode.value = themeMode.value == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark,
            ),
          ],
        ),
        body: ListView(
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: progressiveBlur,
              builder: (context, on, _) => ListRow(
                title: 'Blur under the bars (off: fade)',
                trailing: GlassSwitch(
                  value: on,
                  onChanged: (v) => progressiveBlur.value = v,
                ),
              ),
            ),
            const ListSectionTitle('Applications'),
            item(
              'Chat list: search, folders, profile tab',
              const TelegramRoute(),
              RavelIconKind.chat,
            ),
            item('ChatGPT menu', const ChatGptRoute(), RavelIconKind.chat),
            item('Claude menu', const ClaudeRoute(), RavelIconKind.chat),
            item(
              'Coffee menu: strip, grid, tab bar',
              const CoffeeRoute(),
              RavelIconKind.chat,
            ),
            item(
              'Drinks: hero, two tab levels, carousels',
              const DrinkitRoute(),
              RavelIconKind.chat,
            ),
            item(
              'Profile: stretch header (pull down)',
              ProfileRoute(),
              RavelIconKind.pencil,
            ),
            const ListSectionTitle('Technical: headers, lists, inputs'),
            item(
              'Sticky: stacking headers',
              StickyRoute(),
              RavelIconKind.tasks,
            ),
            item(
              'Sticky: replacing headers',
              const StickyReplacingRoute(),
              RavelIconKind.tasks,
            ),
            item(
              'Nav bars (large/inline)',
              const NavBarsRoute(),
              RavelIconKind.compose,
            ),
            item(
              'Page: back, bubble, blue button, bottom buttons',
              const PageDemoRoute(),
              RavelIconKind.compose,
            ),
            item(
              'Input: composer dock, text field, tab bar',
              const InputRoute(),
              RavelIconKind.pencil,
            ),
            item('Switches', const SwitchRoute(), RavelIconKind.tasks),
            item(
              'Controls: menu, segmented, search, slider, list',
              const ControlsRoute(),
              RavelIconKind.tasks,
            ),
            item(
              'Controls over a photo (vs native)',
              const ControlsPhotoRoute(),
              RavelIconKind.tasks,
            ),
            item(
              'Controls on white (vs native)',
              const ControlsWhiteRoute(),
              RavelIconKind.tasks,
            ),
            item(
              'Components',
              const ComponentsRoute(),
              RavelIconKind.artifacts,
            ),
            item(
              'Inbox: the new API in one page',
              const InboxRoute(),
              RavelIconKind.chat,
            ),
            item(
              'Page switcher (tabs)',
              const SwitcherRoute(),
              RavelIconKind.chat,
            ),
            const ListSectionTitle('Technical: liquid glass'),
            item(
              'Liquid glass (draggable, full-screen picture)',
              const LiquidPlaygroundRoute(),
              RavelIconKind.artifacts,
            ),
            item(
              'Liquid glass (list)',
              const LiquidRoute(),
              RavelIconKind.artifacts,
            ),
            item(
              'Liquid glass morph',
              const LiquidMorphRoute(),
              RavelIconKind.artifacts,
            ),
            item(
              'Liquid glass presence',
              const LiquidPresenceRoute(),
              RavelIconKind.artifacts,
            ),
            item(
              'Liquid glass interactive',
              const LiquidInteractiveRoute(),
              RavelIconKind.artifacts,
            ),
            item(
              'Liquid glass grid',
              const LiquidGridRoute(),
              RavelIconKind.artifacts,
            ),
            item(
              'Liquid glass center',
              const LiquidCenterRoute(),
              RavelIconKind.artifacts,
            ),
            item(
              'EDR / HDR test',
              const EdrTestRoute(),
              RavelIconKind.artifacts,
            ),
          ],
        ),
      ),
    );
  }
}
