import 'package:auto_route/auto_route.dart';


import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

import 'profile_screen.dart';

/// A messenger chat list built from the kit (reference: a Telegram-like client):
///  * a bar with glass buttons, a search field that hides above the list and is revealed by pulling down,
///  * a scrollable strip of folders that sticks under the bar (the search scrolls away, the strip stays),
///  * a floating tab bar,
///  * tapping the search opens the kit's [GlassSearchLauncher] layer: the field slides up, recents, results and a filter
///    segmented control above the keyboard. What the layer shows is the app's own (the kit gives the layer and the field).
@RoutePage()
class TelegramScreen extends StatefulWidget {
  const TelegramScreen({super.key});
  @override
  State<TelegramScreen> createState() => _TelegramScreenState();
}

class _Chat {
  const _Chat(
    this.name,
    this.text,
    this.time,
    this.color, {
    this.pinned = false,
    this.unread = 0,
    this.check = false,
  });
  final String name;
  final String text;
  final String time;
  final Color color;
  final bool pinned;
  final int unread;
  final bool check;
}

const _chats = <_Chat>[
  _Chat(
    'Alex Morgan',
    'Just shipped it',
    '10/30',
    Color(0xFF5B7DB1),
    pinned: true,
  ),
  _Chat(
    'Jamie 👑',
    'ok, sounds good',
    '09/02',
    Color(0xFFB07A55),
    pinned: true,
    check: true,
  ),
  _Chat(
    'Sam 🤡',
    'honestly, true',
    'Mon',
    Color(0xFF6BBF59),
    pinned: true,
    check: true,
  ),
  _Chat(
    'Taylor 🛰',
    'Video',
    'Thu',
    Color(0xFF444444),
    pinned: true,
    check: true,
  ),
  _Chat('Robin', 'And you are the best', 'Thu', Color(0xFFB68FCB), check: true),
  _Chat(
    'Product team',
    'Moving the release to Friday',
    'Tue',
    Color(0xFFD1695F),
    unread: 3,
  ),
  _Chat(
    'Mom',
    'Call me when you are free',
    'Sun',
    Color(0xFF58A6A6),
    unread: 1,
  ),
  _Chat(
    'Design review',
    'Updated the mockups, take a look',
    'Sat',
    Color(0xFF8E6BD1),
  ),
  _Chat('Casey', 'ok, talk tomorrow', 'Fri', Color(0xFFC9A04A), check: true),
  _Chat('Weather bot', 'Sunny, 24°, no rain', 'Thu', Color(0xFF4A90C9)),
  _Chat('Ravel', 'A new build is ready', 'Wed', Color(0xFF9B59D0), unread: 12),
  _Chat('Riley', 'movie tonight?', 'Tue', Color(0xFFCB6F8F)),
  _Chat('Family', 'Photos from the trip', 'Mon', Color(0xFF6D8B4E)),
  _Chat('Work', 'Approved', '10/28', Color(0xFF5E6C84), check: true),
  _Chat('Jordan', 'thanks!', '10/27', Color(0xFF9A7B5C)),
  _Chat('Quinn', 'Where should we meet?', '10/26', Color(0xFFD08A9B)),
];

const _recents = <(String, Color)>[
  ('Robin', Color(0xFFB68FCB)),
  ('Taylor', Color(0xFF444444)),
  ('Sam', Color(0xFF6BBF59)),
  ('Morgan', Color(0xFFD0A57A)),
  ('Pat', Color(0xFF3F3F46)),
  ('Alex', Color(0xFF5B7DB1)),
];

const _results = <(String, String, Color, bool)>[
  ('daily.dev', '19,256 users', Color(0xFFEFEFEF), true),
  ('Pocket Wallet', 'bot', Color(0xFF2F6FDB), true),
  ('Skate Weekly', '12,037 subscribers', Color(0xFFB0553C), false),
  ('Skate Weekly News', '6,726 subscribers', Color(0xFFB0553C), false),
  ('Flow Notes', '7,377 subscribers', Color(0xFF4B4B55), false),
  ('Saved Messages', 'saved messages', Color(0xFF3B82F6), false),
];

class _TelegramScreenState extends State<TelegramScreen>
    with SingleTickerProviderStateMixin {
  static const _searchH = 52.0;
  static const _blue = Color(0xFF4C9BF5);

  static const _folders = <GlassSegment<String>>[
    GlassSegment(value: 'chats', label: '😋 Chats'),
    GlassSegment(value: 'work', label: 'Work', badge: '2'),
    GlassSegment(value: 'all', label: 'All'),
    GlassSegment(value: 'nn', label: '💀 Unnamed'),
    GlassSegment(value: 'family', label: 'Family'),
    GlassSegment(value: 'bots', label: 'Bots', badge: '5'),
  ];

  // One vertical list per folder in a horizontal pager; the strip in the top bar follows the pager while it is swiped.
  final _page = PageController();
  final _pos = ValueNotifier<double>(0);
  late final List<ScrollController> _lists = List.generate(
    _folders.length,
    (_) => ScrollController(keepScrollOffset: false),
  );
  int _active = 0;
  // owned here so that the bars can be told which list is in view when the page changes
  final _chrome = ChromeController();
  final _search = GlobalKey<GlassSearchLauncherState>();
  int _tab = 1;
  String _filter = 'chats';

  @override
  void initState() {
    super.initState();
    _page.addListener(_onPage);
    // --dart-define=TG_SEARCH=true opens the search layer right away (handy for checking it)
    if (const bool.fromEnvironment('TG_SEARCH')) {
      Future.delayed(
        const Duration(milliseconds: 1500),
        () => mounted ? _search.currentState?.open() : null,
      );
    }
  }

  @override
  void dispose() {
    _page.dispose();
    _chrome.dispose();
    _pos.dispose();
    for (final c in _lists) {
      c.dispose();
    }
    super.dispose();
  }

  void _onPage() {
    final p = _page.hasClients ? (_page.page ?? 0) : 0.0;
    _pos.value = p;
    // the lists on both sides get built while swiping: they must show the same collapse state as the one in view
    _alignLists();
  }

  /// The search collapses with the list in view; the other folders' lists follow so a swipe never shows a different state.
  void _alignLists() {
    final cur = _lists[_active];
    if (!cur.hasClients) return;
    final o = cur.offset;
    final want = o < _searchH ? o : _searchH;
    for (var i = 0; i < _lists.length; i++) {
      if (i == _active) continue;
      final c = _lists[i];
      if (!c.hasClients) continue;
      final mine = c.offset;
      final target = o < _searchH ? o : (mine < _searchH ? _searchH : mine);
      if ((mine - target).abs() > 0.5 && want >= 0)
        c.jumpTo(target.clamp(0.0, c.position.maxScrollExtent));
    }
  }

  // The lists of the other folders follow the collapse state of the one in view. (The snap of the half-open search to open or
  // closed is done by the scaffold, like the one of a large title.)
  bool _onScroll(ScrollNotification n) {
    if (n.depth == 1 &&
        n.metrics.axis == Axis.vertical &&
        n is ScrollUpdateNotification) {
      _alignLists();
    }
    return false;
  }

  // The tab bar is shared by the chats page and the profile page (each page registers its own copy as its bottom bar).
  Widget _dock() => BottomDock(
    navBar: GlassTabBar(
      tabs: const [
        GlassTab(icon: RavelIcon(RavelIconKind.tasks), label: 'Contacts'),
        GlassTab(icon: RavelIcon(RavelIconKind.chat), label: 'Chats'),
        GlassTab(icon: RavelIcon(RavelIconKind.menu), label: 'Settings'),
        // any widget is an icon now
        GlassTab(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
      selectedIndex: _tab,
      onSelected: (i) => setState(() => _tab = i),
    ),
  );

  // Both pages stay built, so the chats keep their scroll position, folder and search state while the profile is open.
  @override
  Widget build(BuildContext context) => IndexedStack(
    index: _tab == 3 ? 1 : 0,
    children: [
      _chatsPage(context),
      ProfileScreen(bottomBar: _dock(), showBack: false),
    ],
  );

  Widget _chatsPage(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Listener(
        child: Stack(
          children: [
            ChromeScaffold(
              controller: _chrome,
              blockZoneTouches: true,
              scrollDepth: 1,
              // the kit's default edge effect (no hand-set tint / sigma)
              // the search is the collapsible part of the top bar: it scrolls away with the list and is cut off at the bar's
              // edge (nothing is painted under the bar once it is gone)
              topBar: CollapsibleBar(
                bar: _bar(t),
                sectionHeight: _searchH,
                // hidden at the start, revealed by pulling the list down (the kit places the lists and leaves the scroll room)
                initiallyCollapsed: true,
                // the folder strip is part of the bar: always under it, above the blur, nothing to hand over while scrolling
                footerHeight: 56,
                footer: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  // a liquid glass track with a dark thumb, like the messenger's folder strip
                  child: GlassScrollSegments<String>(
                    glass: true,
                    thumbColor: const Color(0xCC000000),
                    height: 40,
                    segments: _folders,
                    value: _folders[_active].value,
                    position: _pos,
                    onChanged: (v) => _page.animateToPage(
                      _folders.indexWhere((f) => f.value == v),
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                ),
                section: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: GlassSearchLauncher(
                    key: _search,
                    liquid: false,
                    resultsBuilder: (context, query) => _results_(context, t),
                    bottomBuilder: (context) => StatefulBuilder(
                      builder: (context, setLayer) => GlassSegmentedControl<String>(
                        segments: const [
                          GlassSegment(value: 'chats', label: 'Chats'),
                          GlassSegment(value: 'channels', label: 'Channels'),
                          GlassSegment(value: 'apps', label: 'Apps'),
                          GlassSegment(value: 'posts', label: 'Posts'),
                        ],
                        value: _filter,
                        height: 40,
                        onChanged: (v) => setLayer(() => _filter = v),
                      ),
                    ),
                  ),
                ),
              ),
              bottomBar: _dock(),
              body: NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: PageView.builder(
                  controller: _page,
                  itemCount: _folders.length,
                  onPageChanged: (i) {
                    setState(() => _active = i);
                    // the bars follow the list in view, not the one that scrolled last
                    final c = _lists[i];
                    if (c.hasClients) _chrome.scrollOffset.value = c.offset;
                    _alignLists();
                  },
                  itemBuilder: (context, page) {
                    // a list that has just been built starts at 0: bring it to the collapse state of the one in view
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => mounted ? _alignLists() : null,
                    );
                    return _KeepAlive(
                      child: CustomScrollView(
                        controller: _lists[page],
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        slivers: [
                          const SliverChromeInset.top(),
                          SliverList(
                            delegate: SliverChildBuilderDelegate((context, i) {
                              final chats = _chatsOf(page);
                              return _ChatRow(
                                chat: chats[i],
                                last: i == chats.length - 1,
                              );
                            }, childCount: _chatsOf(page).length),
                          ),
                          const SliverChromeInset.bottom(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// What a folder shows (mock data): a different subset of the chats for every folder.
  List<_Chat> _chatsOf(int folder) {
    bool keep(int i) => switch (folder) {
      1 => i % 3 == 0,
      3 => i % 2 == 1,
      4 => i % 4 == 0,
      5 => i % 5 == 0,
      _ => true,
    };
    return [
      for (var i = 0; i < _chats.length; i++)
        if (keep(i)) _chats[i],
    ];
  }

  Widget _bar(SwiftUiThemeData t) {
    return SizedBox(
      height: t.metrics.barHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        // the title is centred on the SCREEN (a Stack), not in what is left between the buttons of different widths
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              'Chats',
              style: t.typography.title.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            Row(
              children: [
                LiquidGlass(
                  height: t.metrics.circleButtonSize,
                  interactive: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: Text(
                        'Edit',
                        style: t.typography.body.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                GlassCircleButton(
                  icon: RavelIcon(RavelIconKind.plus),
                  onPressed: () {},
                ),
                const SizedBox(width: 10),
                GlassCircleButton(
                  icon: RavelIcon(RavelIconKind.compose),
                  tint: _blue,
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _openButton(SwiftUiThemeData t, {required bool glass}) {
    final label = Text(
      'OPEN',
      style: t.typography.body.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
    if (glass) {
      return LiquidGlass(
        height: 30,
        interactive: true,
        tint: _blue,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Center(child: label),
        ),
      );
    }
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: const ShapeDecoration(shape: StadiumBorder(), color: _blue),
      child: label,
    );
  }

  Widget _results_(BuildContext context, SwiftUiThemeData t) {
    final insetBottom = MediaQuery.paddingOf(context).bottom;
    return ListView(
      padding: EdgeInsets.only(bottom: insetBottom + 70),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _recents.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (_, i) => Column(
              children: [
                _Avatar(name: _recents[i].$1, color: _recents[i].$2, size: 58),
                const SizedBox(height: 6),
                SizedBox(
                  width: 62,
                  child: Text(
                    _recents[i].$1,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: t.typography.caption.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            children: [
              Text(
                'RECENT',
                style: t.typography.caption.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text('Clear', style: t.typography.caption.copyWith(fontSize: 13)),
            ],
          ),
        ),
        for (final r in _results)
          SizedBox(
            height: 64,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _Avatar(name: r.$1, color: r.$3, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.typography.body.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          r.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.typography.caption.copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  if (r.$4)
                    // Liquid glass at rest. While the page fades in (an Opacity layer has no backdrop to refract) the same pill is
                    // flat, so it never shows without a background.
                    _openButton(t, glass: ModalRoute.of(context)?.animation?.isCompleted ?? false),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.color, this.size = 54});
  final String name;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final initial = name.characters.isEmpty ? '?' : name.characters.first;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Text(
        initial,
        style: t.typography.title.copyWith(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({required this.chat, required this.last});
  final _Chat chat;
  final bool last;
  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    return SizedBox(
      height: 72,
      child: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Row(
          children: [
            _Avatar(name: chat.name, color: chat.color),
            const SizedBox(width: 12),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: last
                      ? null
                      : Border(
                          bottom: BorderSide(
                            color: t.colors.foreground.withValues(alpha: 0.08),
                            width: 0.5,
                          ),
                        ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chat.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.typography.body.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              chat.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.typography.caption.copyWith(
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            chat.time,
                            style: t.typography.caption.copyWith(
                              fontSize: 13,
                              color: const Color(0xFF8E8E93),
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (chat.unread > 0)
                            Container(
                              constraints: const BoxConstraints(minWidth: 20),
                              height: 20,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              alignment: Alignment.center,
                              decoration: const ShapeDecoration(
                                shape: StadiumBorder(),
                                color: Color(0xFF4C9BF5),
                              ),
                              child: Text(
                                '${chat.unread}',
                                style: t.typography.caption.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          else if (chat.pinned)
                            const Icon(
                              Icons.push_pin,
                              size: 16,
                              color: Color(0xFF8E8E93),
                            )
                          else
                            const SizedBox(height: 20),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Keeps a pager page alive while it is out of view (its scroll position and state stay).
class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});
  final Widget child;
  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
