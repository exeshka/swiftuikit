import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

import '../data.dart';

/// Contacts-like list: every letter has a sticky header. As you scroll the
/// headers pin one under another and the blur zone grows to cover them.
@RoutePage()
class StickyScreen extends StatelessWidget {
  const StickyScreen({super.key, this.replacing = false});

  /// false: headers stack under each other and the blur zone grows with them.
  /// true: each header is pushed out by the next one (iOS grouped list).
  final bool replacing;

  static const _letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'];

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    return Scaffold(
      body: ChromeScaffold(
        topBar: LargeTitleHeader(
          title: replacing ? 'Contacts' : 'Stacked headers',
          trailing: [
            GlassCircleButton(
              icon: RavelIcon(RavelIconKind.search),
              onPressed: () {},
            ),
          ],
        ),
        bottomBar: ChromeBar(
          edge: ChromeEdge.bottom,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: SizedBox(
              height: t.metrics.avatarSize,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FloatingPillButton(
                    label: 'New',
                    icon: RavelIcon(RavelIconKind.plus),
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
        body: CustomScrollView(
          slivers: [
            const SliverChromeInset.top(),
            for (var s = 0; s < _letters.length; s++)
              if (replacing)
                PinnedSection(
                  headerHeight: 36,
                  headerBuilder: (context, stuck) =>
                      _header(t, _letters[s], stuck),
                  slivers: [_rows(s)],
                )
              else ...[
                PinnedHeader(
                  height: 36,
                  builder: (context, stuck) => _header(t, _letters[s], stuck),
                ),
                _rows(s),
              ],
            const SliverChromeInset.bottom(),
          ],
        ),
      ),
    );
  }

  Widget _header(SwiftUiThemeData t, String letter, bool stuck) => Padding(
    padding: EdgeInsets.symmetric(horizontal: t.metrics.pageInset),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        letter,
        style: t.typography.caption.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: stuck ? t.colors.foreground : t.colors.foregroundSecondary,
        ),
      ),
    ),
  );

  Widget _rows(int s) => SliverList(
    delegate: SliverChildBuilderDelegate(
      (context, i) => ListRow(
        title: contactNames[(s * 4 + i) % contactNames.length],
        onTap: () {},
      ),
      childCount: 6,
    ),
  );
}

/// The same page with replacing headers (its own route: the generated one takes no path argument).
@RoutePage()
class StickyReplacingScreen extends StatelessWidget {
  const StickyReplacingScreen({super.key});

  @override
  Widget build(BuildContext context) => const StickyScreen(replacing: true);
}
