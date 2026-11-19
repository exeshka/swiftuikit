import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

/// The new API in one page: three pages, each a [SwiftUiScaffold] with its own header (by parameters), its own scroll and the
/// switched by a [SwiftUiPageSwitcher] that moves the whole page, under a [SwiftUiShell] that holds the tab bar (built once); [SwiftUiWindowInfo] (the window a page
/// is laid out in) and the theme (colors, typography, metrics). The Settings tab switches the edge effect and the transition live.
@RoutePage()
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  int _tab = 0;
  var _transition = SwiftUiSwitchTransition.fadeThrough;
  var _edge = 'soft';

  static const _edges = <String, ChromeStyle>{
    'soft': ChromeStyle.soft(),
    'fade': ChromeStyle.fade(),
    'hard': ChromeStyle.hard(),
    'solid': ChromeStyle.solid(divider: true),
    'none': ChromeStyle.none(),
  };

  /// One page of the app: its own header, its own scroll, its own edge effect. It knows nothing about the tab bar (the shell
  /// holds it); the switcher moves the whole page.
  Widget _page({
    required String title,
    NavTitleStyle titleStyle = NavTitleStyle.large,
    List<Widget> actions = const [],
    required Widget body,
  }) => SwiftUiScaffold(
    title: title,
    titleStyle: titleStyle,
    actions: actions,
    topChrome: _edges[_edge],
    bottomChrome: _edges[_edge],
    body: body,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SwiftUiShell(
        // the part that stays: the tab bar floats over the pages, built once whatever page is shown
        bottomBar: GlassTabBar(
          tabs: const [
            GlassTab(icon: RavelIcon(RavelIconKind.chat), label: 'Inbox'),
            GlassTab(icon: RavelIcon(RavelIconKind.tasks), label: 'Tasks'),
            GlassTab(icon: RavelIcon(RavelIconKind.menu), label: 'Settings'),
          ],
          selectedIndex: _tab,
          onSelected: (i) => setState(() => _tab = i),
        ),
        body: SwiftUiPageSwitcher(
          index: _tab,
          transition: _transition,
          children: [
            _page(
              title: 'Inbox',
              actions: [
                GlassToolbarCapsule(
                  items: [
                    GlassToolbarItem(
                      id: 'search',
                      onPressed: () {},
                      child: const RavelIcon(RavelIconKind.search, size: 26),
                    ),
                    GlassToolbarItem(
                      id: 'compose',
                      onPressed: () {},
                      child: const RavelIcon(RavelIconKind.compose, size: 26),
                    ),
                  ],
                ),
              ],
              body: const _InboxPage(),
            ),
            _page(
              title: 'Tasks',
              actions: [
                GlassCircleButton(
                  icon: const RavelIcon(RavelIconKind.plus),
                  onPressed: () {},
                ),
              ],
              body: const _TasksPage(),
            ),
            _page(
              title: 'Settings',
              titleStyle: NavTitleStyle.inline,
              body: _SettingsPage(
                edge: _edge,
                edges: _edges.keys.toList(),
                onEdge: (e) => setState(() => _edge = e),
                transition: _transition,
                onTransition: (t) => setState(() => _transition = t),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InboxPage extends StatelessWidget {
  const _InboxPage();

  static const _mail = [
    ('Ava Martin', 'Design review moved to 15:00', '09:41'),
    ('Build bot', 'ravel_ui_kit #482 passed', '09:12'),
    ('Noah Kim', 'Re: glass buttons on the light theme', 'Yesterday'),
    ('App Store', 'Your build is ready for testing', 'Yesterday'),
    ('Mia Rossi', 'Photos from the offsite', 'Tuesday'),
    ('Liam Chen', 'Can you look at the tab bar spacing?', 'Tuesday'),
    ('Calendar', 'Reminder: sprint planning', 'Monday'),
    ('Emma Wolf', 'Lunch on Friday?', 'Monday'),
    ('Oliver Smith', 'Invoice #1042', 'Sunday'),
    ('Sofia Rey', 'New icons are in the Figma file', 'Sunday'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final window = SwiftUiWindowInfo.of(context);
    return ListView(
      children: [
        ListSection(
          header:
              'WINDOW: ${window.size.width.round()}×${window.size.height.round()}  '
              '${window.horizontal.name} / ${window.vertical.name}',
          children: [
            for (final (from, subject, time) in _mail)
              GroupedRow(
                title: from,
                subtitle: subject,
                value: time,
                chevron: true,
                onTap: () {},
              ),
          ],
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: t.metrics.pageInset),
          child: Text(
            '${_mail.length} messages',
            textAlign: TextAlign.center,
            style: t.typography.caption,
          ),
        ),
      ],
    );
  }
}

class _TasksPage extends StatefulWidget {
  const _TasksPage();
  @override
  State<_TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<_TasksPage> {
  // a page keeps its state while it is not shown: tick something, switch tabs, come back
  final _done = <int>{1};
  static const _tasks = [
    'Write the page switcher',
    'Fix the back button',
    'Move the header to SwiftUiScaffold',
    'Check the blur under the bars',
    'Try it unfolded',
    'Update the README',
  ];

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    return ListView(
      children: [
        ListSection(
          header: 'THE STATE OF THIS PAGE SURVIVES A TAB SWITCH',
          children: [
            for (var i = 0; i < _tasks.length; i++)
              GroupedRow(
                title: _tasks[i],
                trailing: GlassSwitch(
                  value: _done.contains(i),
                  onChanged: (v) =>
                      setState(() => v ? _done.add(i) : _done.remove(i)),
                ),
              ),
          ],
        ),
        Center(
          child: Text(
            '${_done.length} of ${_tasks.length} done',
            style: t.typography.caption,
          ),
        ),
      ],
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({
    required this.edge,
    required this.edges,
    required this.onEdge,
    required this.transition,
    required this.onTransition,
  });

  final String edge;
  final List<String> edges;
  final ValueChanged<String> onEdge;
  final SwiftUiSwitchTransition transition;
  final ValueChanged<SwiftUiSwitchTransition> onTransition;

  Widget _check(bool on, BuildContext context) => on
      ? Icon(
          Icons.check_rounded,
          size: 22,
          color: SwiftUiTheme.of(context).colors.accent,
        )
      : const SizedBox.shrink();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListSection(
          header: 'EDGE EFFECT UNDER THE BARS (ChromeStyle)',
          footer: 'The same slot the theme fills: chrome.top / chrome.bottom.',
          children: [
            for (final e in edges)
              GroupedRow(
                title: e,
                trailing: _check(e == edge, context),
                onTap: () => onEdge(e),
              ),
          ],
        ),
        ListSection(
          header: 'TAB TRANSITION (SwiftUiSwitchTransition)',
          footer: 'None of them draws a page into an offscreen layer.',
          children: [
            for (final tr in SwiftUiSwitchTransition.values)
              GroupedRow(
                title: tr.name,
                trailing: _check(tr == transition, context),
                onTap: () => onTransition(tr),
              ),
          ],
        ),
      ],
    );
  }
}
