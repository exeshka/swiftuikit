import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

/// A profile page like Telegram's settings: pull the list down and the avatar morphs into a full-bleed photo; a long enough
/// pull snaps it open, pushes the list down and keeps it open until the list is scrolled up. Built from the kit's
/// [StretchHeader] and [MorphBox]; the glass buttons stay on top of the photo.
@RoutePage()
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.bottomBar, this.showBack = true});

  /// false: no back button even if the route can be popped (the profile as a tab of another page).
  final bool showBack;

  /// A bar for the bottom edge (the tab bar when the profile is a tab of another page).
  final Widget? bottomBar;

  static const _collapsed = 270.0;
  static const _expanded = 470.0;
  static const _avatar = 104.0;

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Material(
        color: Colors.transparent,
        child: ChromeScaffold(
          bottomBar: bottomBar,
          // the photo runs under the status bar and the buttons: no fade there (the scaffold lowers it while the header opens)
          topBar: ChromeBar(
            child: SizedBox(
              height: t.metrics.barHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // a pushed page has the back button at the start; as a tab of another page it has the menu
                    if (showBack && Navigator.canPop(context))
                      const GlassBackButton()
                    else
                      GlassCircleButton(
                        icon: RavelIcon(RavelIconKind.menu),
                        onPressed: () {},
                      ),
                    const Spacer(),
                    GlassCircleButton(
                      icon: RavelIcon(RavelIconKind.search),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 10),
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
                  ],
                ),
              ),
            ),
          ),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              StretchHeader(
                collapsedHeight: _collapsed,
                expandedHeight: _expanded,
                builder: _header,
                // the second stage: pull the OPEN header again and release (what Telegram does to open the photo viewer)
                onOverpull: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const _FullProfileScreen(),
                  ),
                ),
              ),
              SliverList.builder(
                itemCount: _rows.length,
                itemBuilder: (context, i) => ListRow(
                  title: _rows[i],
                  height: 56,
                  horizontalPadding: 24,
                  style: t.typography.body.copyWith(
                    fontSize: 17,
                    color: i < 3 ? t.colors.accent : t.colors.foreground,
                  ),
                  trailing: i < 3
                      ? null
                      : RavelIcon(
                          RavelIconKind.chevronRight,
                          size: 18,
                          color: t.colors.foregroundTertiary,
                        ),
                  onTap: () {},
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 120 + safeBottom)),
            ],
          ),
        ),
      ),
    );
  }

  static const _rows = [
    'Change emoji status',
    'Change profile colour',
    'Change photo',
    'Maxim',
    'Add account',
    'My profile',
    'Saved messages',
    'Recent calls',
    'Devices',
    'Chat folders',
    'Notifications',
    'Privacy and security',
    'Data and storage',
    'Appearance',
    'Language',
  ];

  static Widget _header(BuildContext context, StretchInfo info) {
    final t = SwiftUiTheme.of(context);
    final w = info.width;
    final c = info.collapse; // 0 at rest .. 1 scrolled: only the name is left, in the bar row
    // the avatar at rest: a circle level with the bar buttons; scrolled it shrinks and fades; open: the photo fills the whole
    // header, under the bars
    // e: the open state (a quick spring that starts once the pull passes the trigger, and back), not the finger. While the
    // finger pulls, the circle just gets bigger (info.stretch) and stays a circle.
    final e = info.t;
    final grown =
        _avatar *
        (1 + 0.5 * info.stretch * (1 - e)); // grows downwards, its top stays
    final d = grown + (36 - grown) * c;
    final cy = (78 + grown / 2) + (88 - (78 + grown / 2)) * c;
    final circle = Rect.fromCenter(
      center: Offset(w / 2, cy),
      width: d,
      height: d,
    );
    final full = Rect.fromLTWH(0, 0, w, info.height);
    // the text sits under the morphing box and slides into its bottom as it fills the header; scrolled (c) it goes to the
    // bar row, small
    final boxBottom = circle.bottom + (full.bottom - circle.bottom) * e;
    final compactY = info.topInset - 26 - 12;
    // the text slides into the box by the time it is 60% open and then keeps its distance from the box's bottom edge
    final et = (e / 0.6).clamp(0.0, 1.0);
    // blend from where the text is NOW (it depends on how open the header is) to the bar row. (It used to add the distance from
    // the closed state's position, which is wrong while the header is still open: a fast scroll up flung the text off the
    // screen until the header had closed.)
    final rest = boxBottom + 16 - 100 * et;
    final y = rest + (compactY - rest) * c;
    final align = Alignment.lerp(Alignment.topCenter, Alignment.topLeft, e)!;
    final nameSize = 30 + (17 - 30) * c;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        MorphBox(
          from: circle,
          to: full,
          t: info.t,
          fromRadius: d / 2,
          toRadius: 0,
          child: Opacity(
            opacity: (1 - 1.6 * c).clamp(0.0, 1.0),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF58585E),
                    Color(0xFF2A2A2E),
                    Color(0xFF1A1A1D),
                  ],
                ),
              ),
              child: Transform.scale(
                scale: 1 + 0.12 * info.overpull,
                child: Center(
                  child: Text(
                    'EX',
                    style: TextStyle(
                      fontSize: (30 + 120 * e) * (1 - 0.6 * c),
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // darkens the bottom of the photo for the text, only while it is open
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55 * e),
                  ],
                  stops: const [0.55, 1],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          top: y,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: align,
                child: Text(
                  'exeshka',
                  style: t.typography.title.copyWith(
                    fontSize: nameSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Opacity(
                opacity: (1 - 2.2 * c).clamp(0.0, 1.0),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Align(
                    alignment: align,
                    child: Text(
                      '+7 *** ** ** ·  @exeshkaa',
                      style: t.typography.body.copyWith(
                        fontSize: 17,
                        color: t.colors.foregroundSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// What the second stage opens: the full profile (a photo viewer in the real app).
class _FullProfileScreen extends StatelessWidget {
  const _FullProfileScreen();

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF58585E), Color(0xFF1A1A1D)],
                ),
              ),
              child: Center(
                child: Text(
                  'EX',
                  style: TextStyle(
                    fontSize: 200,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: const GlassBackButton(),
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 60,
            child: Text(
              'Full profile',
              style: t.typography.title.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
