import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

import 'tech_page.dart';

/// Menu, segmented control, search bar, slider, stepper, grouped list with swipe actions and pull-to-refresh.
@RoutePage()
class ControlsScreen extends StatefulWidget {
  const ControlsScreen({super.key});
  @override
  State<ControlsScreen> createState() => _ControlsScreenState();
}

class _ControlsScreenState extends State<ControlsScreen> {
  String _seg = 'a';
  double _volume = 0.4;
  int _count = 3;
  bool _wifi = true;
  String _query = '';
  final _items = ['Inbox', 'Drafts', 'Sent', 'Archive'];
  int _refreshes = 0;

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final safe = MediaQuery.paddingOf(context);
    final shown = _items
        .where((e) => e.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return TechPage(
      title: 'Controls',
      child: Scaffold(
        backgroundColor: t.isDark ? Colors.black : const Color(0xFFF2F2F7),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            RavelRefreshControl(
              onRefresh: () async {
                await Future<void>.delayed(const Duration(seconds: 1));
                if (mounted) setState(() => _refreshes++);
              },
            ),
            SliverPadding(padding: EdgeInsets.only(top: safe.top + 8)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Controls ($_refreshes)',
                        style: t.typography.largeTitle,
                      ),
                    ),
                    GlassMenuButton(
                      builder: (context, open) => GlassCircleButton(
                        icon: RavelIcon(RavelIconKind.menu),
                        onPressed: open,
                      ),
                      entries: [
                        GlassMenuItem(
                          label: 'Select',
                          leading: const RavelIcon(
                            RavelIconKind.tasks,
                            size: 20,
                          ),
                        ),
                        GlassMenuItem(
                          label: 'Sort by name',
                          checked: true,
                          onSelected: () {},
                        ),
                        GlassMenuItem(label: 'Sort by date', onSelected: () {}),
                        const GlassMenuDivider(),
                        GlassMenuItem(
                          label: 'Delete all',
                          destructive: true,
                          onSelected: () => setState(() => _items.clear()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: GlassSearchBar(
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: GlassSegmentedControl<String>(
                  segments: const [
                    GlassSegment(value: 'a', label: 'All'),
                    GlassSegment(value: 'b', label: 'Unread'),
                    GlassSegment(value: 'c', label: 'Flagged'),
                  ],
                  value: _seg,
                  onChanged: (v) => setState(() => _seg = v),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: ListSection(
                header: 'Settings',
                separatorInset: 62,
                children: [
                  GroupedRow(
                    title: 'Wi-Fi',
                    icon: RavelIcon(RavelIconKind.search),
                    iconColor: const Color(0xFF0A84FF),
                    trailing: GlassSwitch(
                      value: _wifi,
                      onChanged: (v) => setState(() => _wifi = v),
                    ),
                  ),
                  GroupedRow(
                    title: 'Quantity',
                    icon: RavelIcon(RavelIconKind.plus),
                    iconColor: const Color(0xFF30D158),
                    value: '$_count',
                    trailing: GlassStepper(
                      onIncrement: () => setState(() => _count++),
                      onDecrement: () =>
                          setState(() => _count = _count > 0 ? _count - 1 : 0),
                      canDecrement: _count > 0,
                    ),
                  ),
                  GroupedRow(
                    title: 'General',
                    icon: RavelIcon(RavelIconKind.tasks),
                    iconColor: const Color(0xFF8E8E93),
                    chevron: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: ListSection(
                header: 'Volume',
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: GlassSlider(
                      value: _volume,
                      onChanged: (v) => setState(() => _volume = v),
                    ),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: ListSection(
                header: 'Mailboxes (swipe both ways)',
                footer: 'Pull the page down to refresh.',
                children: [
                  for (final e in shown)
                    SwipeActionRow(
                      leadingActions: [
                        SwipeAction(
                          label: 'Pin',
                          color: const Color(0xFF4390F6),
                          onPressed: () {},
                        ),
                        SwipeAction(
                          label: 'Read',
                          color: const Color(0xFF32D74B),
                          onPressed: () {},
                        ),
                      ],
                      actions: [
                        SwipeAction(
                          label: 'Delete',
                          dismisses: true,
                          onPressed: () => setState(() => _items.remove(e)),
                        ),
                        SwipeAction(
                          label: 'Flag',
                          color: const Color(0xFFFE9130),
                          onPressed: () {},
                        ),
                      ],
                      child: GroupedRow(title: e, chevron: true, onTap: () {}),
                    ),
                  if (shown.isEmpty) const GroupedRow(title: 'Nothing found'),
                ],
              ),
            ),
            SliverPadding(padding: EdgeInsets.only(bottom: safe.bottom + 40)),
          ],
        ),
      ),
    );
  }
}
