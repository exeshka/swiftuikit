import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:swiftuikit/swiftuikit.dart';

/// A drink-ordering home page built only from the kit (reference: a delivery app): a full-screen "hero" behind the list that
/// changes with the category, a top bar with a logo, the pickup point and an avatar over it, two levels of text tabs that stick
/// under the bar (categories; sections of the page) and follow the scroll, carousels of cards.
///
/// Everything the kit did not have is marked `GAP:`.
@RoutePage()
class DrinkitScreen extends StatefulWidget {
  const DrinkitScreen({super.key});
  @override
  State<DrinkitScreen> createState() => _DrinkitScreenState();
}

class _Hero {
  const _Hero(this.title, this.note, this.a, this.b);
  final String title;
  final String note;
  final Color a;
  final Color b;
}

const _categories = ['for you', 'winter', 'coffee', 'not coffee', 'food'];
const _heroes = <_Hero>[
  _Hero('Make a Wish', 'tap for more', Color(0xFF1B2B6B), Color(0xFFC9A36B)),
  _Hero('Winter menu', 'warm up', Color(0xFF2B3A55), Color(0xFFB9C6D6)),
  _Hero('Iced Caramel Latte', '2 350 ₸', Color(0xFFB7BCC4), Color(0xFFD9C3A5)),
  _Hero('Fresh teas', 'from 1 200 ₸', Color(0xFF3F5A3A), Color(0xFFD4B24C)),
  _Hero('Bakery', 'baked today', Color(0xFF6B4A32), Color(0xFFE6CFA8)),
];

const _sections = ['popular drinks', 'rewards', 'new for you'];

class _Drink {
  const _Drink(this.name, this.price, this.color);
  final String name;
  final String price;
  final Color color;
}

const _drinks = <_Drink>[
  _Drink('Cappuccino', '1 450 ₸', Color(0xFFC59A74)),
  _Drink('Gingerbread Latte with...', '1 750 ₸', Color(0xFFD9B58C)),
  _Drink('Mandarin Osmanthus...', '1 850 ₸', Color(0xFFE0A35A)),
  _Drink('Mandarin Osmanthus', '2 200 ₸', Color(0xFFD6935A)),
];

class _DrinkitScreenState extends State<DrinkitScreen> {
  static const _heroH = 620.0;
  static const _tabsH = 56.0;
  static const _subH = 44.0;

  final _scroll = ScrollController();
  // owned here: the top fade is driven by the scroll (nothing over the hero at rest, a smooth fade-in as the list moves up)
  final _chrome = ChromeController();
  final _cat = ValueNotifier<int>(0);
  final _sec = ValueNotifier<int>(0);
  final _keys = [for (final _ in _sections) GlobalKey()];
  double _inset = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_spy);
    _chrome.topEdgeFade.value = 0; // nothing over the hero at rest
  }

  @override
  void dispose() {
    _scroll.dispose();
    _chrome.dispose();
    _cat.dispose();
    _sec.dispose();
    super.dispose();
  }

  void _spy() {
    if (!_scroll.hasClients) return;
    _chrome.topEdgeFade.value = (_scroll.offset / 160).clamp(0.0, 1.0);
    var cur = 0;
    for (var i = 0; i < _keys.length; i++) {
      final box = _keys[i].currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached) continue;
      final y = RenderAbstractViewport.of(box).getOffsetToReveal(box, 0).offset;
      if (y <= _scroll.offset + _inset + _tabsH + _subH + 8) cur = i;
    }
    if (cur != _sec.value) _sec.value = cur;
  }

  void _goTo(int i) {
    final box = _keys[i].currentContext?.findRenderObject();
    if (box is! RenderBox) return;
    final y =
        RenderAbstractViewport.of(box).getOffsetToReveal(box, 0).offset -
        _inset -
        _tabsH -
        _subH;
    _sec.value = i;
    _scroll.animateTo(
      y.clamp(0.0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    return Scaffold(
      backgroundColor: t.colors.background,
      body: Material(
        color: Colors.transparent,
        child: ChromeScaffold(
          controller: _chrome,
          bottomBlur: false, // the hero page has no darkening at the bottom
          // the hero runs under the status bar: the bars are over a photo, not over a plain background
          topBar: ChromeBar(
            child: SizedBox(
              height: t.metrics.barHeight + 8,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // GAP: no logo / image widget
                    Container(
                      width: t.metrics.circleButtonSize,
                      height: t.metrics.circleButtonSize,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2F3CFF),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Europe city',
                            style: t.typography.body.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'until 9:00 PM',
                            style: t.typography.caption.copyWith(
                              color: t.colors.foregroundSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GlassCircleButton(
                      icon: const RavelIcon(RavelIconKind.plus),
                      semanticLabel: 'Profile',
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: Builder(
            builder: (context) {
              _inset = MediaQuery.paddingOf(context).top;
              final list = CustomScrollView(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  const SliverChromeInset.top(),
                  // the hero is behind the list: room for it, tapping it is not possible
                  const SliverToBoxAdapter(
                    child: SizedBox(height: _heroH - _tabsH - 150),
                  ),
                  PinnedHeader(
                    height: _tabsH,
                    child: _TextTabs(
                      labels: _categories,
                      active: _cat,
                      size: 24,
                      onTap: (i) => _cat.value = i,
                    ),
                  ),
                  // the second level shows up once the first one sticks
                  PinnedHeader(
                    height: _subH,
                    builder: (context, stuck) => Opacity(
                      opacity: stuck ? 1 : 0,
                      child: _TextTabs(
                        labels: _sections,
                        active: _sec,
                        size: 16,
                        onTap: _goTo,
                      ),
                    ),
                  ),
                  _title(t, 0),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 214,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _drinks.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (_, i) => _DrinkCard(_drinks[i]),
                      ),
                    ),
                  ),
                  _title(t, 1),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        height: 110,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: t.glass.glassFill,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Order for 20 000 ₸ and\nget the Kitbox',
                          style: t.typography.body.copyWith(fontSize: 19),
                        ),
                      ),
                    ),
                  ),
                  _title(t, 2),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 400,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 4,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (_, i) => _BigCard(
                          name: const [
                            'Chicken Crepes',
                            'Syrniki',
                            'Croissant',
                            'Cheesecake',
                          ][i],
                          price: '1 750 ₸',
                          color: const [
                            Color(0xFFE3A15C),
                            Color(0xFFD9B58C),
                            Color(0xFFD99A52),
                            Color(0xFFEBD9B4),
                          ][i],
                        ),
                      ),
                    ),
                  ),
                  const SliverChromeInset.bottom(),
                ],
              );
              // GAP: no image widget: the hero is a gradient and a circle. It is BEHIND the list and moves with the scroll, a
              // fade at its bottom melts it into the page; it follows the category
              return Stack(
                children: [
                  ListenableBuilder(
                    listenable: Listenable.merge([_scroll, _cat]),
                    builder: (context, _) {
                      final o = _scroll.hasClients ? _scroll.offset : 0.0;
                      // pulled down: the hero stays at the top and grows by the pull (its bottom edge follows the list), the
                      // picture inside grows with it
                      final pull = o < 0 ? -o : 0.0;
                      return Positioned(
                        left: 0,
                        right: 0,
                        top: o < 0 ? 0.0 : -o,
                        height: _heroH + pull,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: _HeroView(
                            key: ValueKey(_cat.value),
                            hero: _heroes[_cat.value],
                            bottom: t.colors.background,
                            pull: pull,
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned.fill(child: list),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _title(SwiftUiThemeData t, int i) => SliverToBoxAdapter(
    child: Padding(
      key: _keys[i],
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 14),
      child: Text(
        _sections[i],
        style: t.typography.title.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}

/// GAP: the kit has no plain text tabs (no glass, no thumb): a row of labels, the active one bright.
class _TextTabs extends StatelessWidget {
  const _TextTabs({
    required this.labels,
    required this.active,
    required this.size,
    required this.onTap,
  });
  final List<String> labels;
  final ValueNotifier<int> active;
  final double size;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    return ValueListenableBuilder<int>(
      valueListenable: active,
      builder: (context, a, _) => ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: labels.length,
        separatorBuilder: (_, _) => SizedBox(width: size * 1.1),
        itemBuilder: (_, i) => Pressable(
          onPressed: () => onTap(i),
          scale: 0.96,
          child: Center(
            child: Text(
              labels[i],
              style: t.typography.title.copyWith(
                fontSize: size,
                fontWeight: FontWeight.w400,
                color: i == a
                    ? t.colors.foreground
                    : t.colors.foregroundTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroView extends StatelessWidget {
  const _HeroView({
    super.key,
    required this.hero,
    required this.bottom,
    this.pull = 0,
  });
  final _Hero hero;
  final Color bottom;

  /// How far the list is pulled down (pt): the picture scales up with it.
  final double pull;

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [hero.a, hero.b],
            ),
          ),
        ),
        Center(
          child: Transform.scale(
            scale: 1 + pull / 500,
            child: FractionallySizedBox(
              widthFactor: 0.8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: const AspectRatio(aspectRatio: 1),
              ),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, bottom],
              stops: const [0.5, 0.97],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 190,
          child: Column(
            children: [
              Text(
                hero.title,
                textAlign: TextAlign.center,
                style: t.typography.title.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hero.note,
                style: t.typography.caption.copyWith(
                  color: t.colors.foregroundSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DrinkCard extends StatelessWidget {
  const _DrinkCard(this.d);
  final _Drink d;

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    return Pressable(
      onPressed: () {},
      child: Container(
        width: 166,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          color: t.glass.glassFill,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: d.color,
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
            const Spacer(),
            Text(
              d.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.typography.body.copyWith(fontSize: 15),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(d.price, style: t.typography.body.copyWith(fontSize: 15)),
                const Spacer(),
                RavelIcon(
                  RavelIconKind.chevronRight,
                  size: 16,
                  color: t.colors.foregroundTertiary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BigCard extends StatelessWidget {
  const _BigCard({
    required this.name,
    required this.price,
    required this.color,
  });
  final String name;
  final String price;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    return Pressable(
      onPressed: () {},
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: const Color(0xFFE6E9EE),
          borderRadius: BorderRadius.circular(32),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Text(
              name,
              style: t.typography.title.copyWith(
                fontSize: 21,
                color: const Color(0xFF15181D),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  price,
                  style: t.typography.body.copyWith(
                    fontSize: 18,
                    color: const Color(0xFF15181D),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFF15181D),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: RavelIcon(
                      RavelIconKind.plus,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
