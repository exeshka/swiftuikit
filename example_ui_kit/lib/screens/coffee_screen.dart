import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:swiftuikit/swiftuikit.dart';

/// A coffee-shop menu built only from the kit, like a delivery app: a top bar (back, the address, two round buttons), a banner
/// that scrolls away, a category strip that sticks under the bar and follows the scroll (and scrolls the list when tapped), a
/// two-column grid of products, a floating tab bar.
///
/// Everything that was missing to build this from the kit alone is marked `GAP:` below.
@RoutePage()
class CoffeeScreen extends StatefulWidget {
  const CoffeeScreen({super.key});
  @override
  State<CoffeeScreen> createState() => _CoffeeScreenState();
}

class _Item {
  const _Item(this.name, this.price, this.color);
  final String name;
  final int price;
  final Color color;
}

const _menu = <String, List<_Item>>{
  'Classic': [
    _Item('Espresso', 300, Color(0xFFB9825B)),
    _Item('Americano', 360, Color(0xFF8D5E3C)),
    _Item('Latte', 480, Color(0xFFD9B99B)),
    _Item('Iced latte', 480, Color(0xFFC8A98C)),
    _Item('Cappuccino', 420, Color(0xFFCBA37E)),
    _Item('Cappuccino large', 490, Color(0xFFC09470)),
  ],
  'Signature': [
    _Item('Raf', 520, Color(0xFFE2C9A8)),
    _Item('Flat white', 450, Color(0xFFD5B48F)),
    _Item('Orange coffee', 470, Color(0xFFE0A15A)),
    _Item('Coconut latte', 500, Color(0xFFD8CBB8)),
  ],
  'Tea': [
    _Item('Berry tea', 380, Color(0xFFB04A6A)),
    _Item('Sea buckthorn', 380, Color(0xFFE0903A)),
    _Item('Green tea', 320, Color(0xFF8DAA6B)),
    _Item('Black tea', 320, Color(0xFF7A4B34)),
  ],
  'Desserts': [
    _Item('Cheesecake', 390, Color(0xFFEBD9B4)),
    _Item('Croissant', 260, Color(0xFFD99A52)),
    _Item('Brownie', 290, Color(0xFF6B4332)),
    _Item('Muffin', 240, Color(0xFFB98A5E)),
  ],
};

const _stories = <Color>[
  Color(0xFFE0A15A),
  Color(0xFFB04A6A),
  Color(0xFF8DAA6B),
  Color(0xFF5B7DB1),
  Color(0xFFB68FCB),
];

class _Story extends StatelessWidget {
  const _Story({required this.color, required this.seen, this.onPressed});
  final Color color;
  final bool seen;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    return Pressable(
      onPressed: onPressed,
      child: Container(
        width: 76,
        height: 76,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: seen ? t.colors.separator : t.colors.accent,
            width: 2.5,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _CoffeeScreenState extends State<CoffeeScreen> {
  static const _stripH = 56.0;
  static const _bannerH = 260.0;
  static const _sheetR = 28.0;
  static const _storiesH = 92.0;

  final _scroll = ScrollController();
  late final _names = _menu.keys.toList();
  late final _keys = [for (final _ in _names) GlobalKey()];
  late final _segments = [
    for (final n in _names) GlassSegment<String>(value: n, label: n),
  ];
  final _active = ValueNotifier<String>('Classic');
  int _tab = 0;
  double _inset = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_spy);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _active.dispose();
    super.dispose();
  }

  /// The section whose title has passed under the bar and the strip is the current one.
  void _spy() {
    if (!_scroll.hasClients) return;
    var cur = _names.first;
    for (var i = 0; i < _names.length; i++) {
      final ctx = _keys[i].currentContext;
      final box = ctx?.findRenderObject();
      if (box is! RenderBox || !box.attached) continue;
      final y = RenderAbstractViewport.of(box).getOffsetToReveal(box, 0).offset;
      if (y <= _scroll.offset + _inset + _stripH + 8) cur = _names[i];
    }
    if (cur != _active.value) _active.value = cur;
  }

  void _goTo(String name) {
    final box = _keys[_names.indexOf(name)].currentContext?.findRenderObject();
    if (box is! RenderBox) return;
    final y =
        RenderAbstractViewport.of(box).getOffsetToReveal(box, 0).offset -
        _inset -
        _stripH;
    _active.value = name;
    _scroll.animateTo(
      y.clamp(0.0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final w = MediaQuery.sizeOf(context).width;
    const gap = 12.0;
    final cardW = (w - 32 - gap) / 2;
    return Scaffold(
      backgroundColor: t.colors.background,
      body: Material(
        color: Colors.transparent,
        child: ChromeScaffold(
          topBar: ChromeBar(
            child: SizedBox(
              height: t.metrics.barHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (Navigator.canPop(context)) ...[
                      const GlassBackButton(),
                      const SizedBox(width: 10),
                    ],
                    // the address: one glass pill, grows with its text
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: LiquidGlass(
                          height: t.metrics.circleButtonSize,
                          interactive: true,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // GAP: no map-pin icon in RavelIconKind
                                RavelIcon(
                                  RavelIconKind.artifacts,
                                  size: 18,
                                  color: t.colors.accent,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Tverskoy Boulevard',
                                  style: t.typography.body.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // GAP: no qr-code icon
                    GlassCircleButton(
                      icon: RavelIcon(RavelIconKind.tasks),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 10),
                    const GlassAvatarButton(initials: 'JD', accented: true),
                  ],
                ),
              ),
            ),
          ),
          bottomBar: BottomDock(
            navBar: GlassTabBar(
              // GAP: the tabs take only RavelIconKind: no cup / bag / heart
              tabs: const [
                GlassTab(
                  icon: RavelIcon(RavelIconKind.artifacts),
                  label: 'Menu',
                ),
                GlassTab(icon: RavelIcon(RavelIconKind.tasks), label: 'Orders'),
                GlassTab(
                  icon: RavelIcon(RavelIconKind.plus),
                  label: 'Favorites',
                ),
                GlassTab(icon: RavelIcon(RavelIconKind.chat), label: 'Cart'),
              ],
              selectedIndex: _tab,
              onSelected: (i) => setState(() => _tab = i),
            ),
          ),
          body: Builder(
            builder: (context) {
              // the inset of the bars: what a scroll to a section has to leave free
              _inset = MediaQuery.paddingOf(context).top;
              final list = CustomScrollView(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  const SliverChromeInset.top(),
                  // GAP: no stories widget (a horizontal strip of ringed circles with a seen/unseen state)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: _storiesH,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        itemCount: _stories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, i) => _Story(
                          color: _stories[i],
                          seen: i >= 3,
                          onPressed: () {},
                        ),
                      ),
                    ),
                  ),
                  // room for the banner: it is drawn BEHIND the list (see below), so the sheet (the strip and the products)
                  // slides over its bottom edge
                  const SliverToBoxAdapter(
                    child: SizedBox(height: _bannerH - _sheetR),
                  ),
                  // the top of the sheet: rounded while it lies over the banner, flat once it sticks under the bar
                  PinnedHeader(
                    height: _stripH,
                    animateZone: false,
                    builder: (context, stuck) => DecoratedBox(
                      decoration: BoxDecoration(
                        color: t.colors.background,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(stuck ? 0 : _sheetR),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        // GAP: the strip does not follow a ScrollController: `value` is fed by hand (see _spy)
                        child: ValueListenableBuilder<String>(
                          valueListenable: _active,
                          builder: (context, v, _) =>
                              GlassScrollSegments<String>(
                                glass: true,
                                height: 40,
                                segments: _segments,
                                value: v,
                                onChanged: _goTo,
                              ),
                        ),
                      ),
                    ),
                  ),
                  for (var s = 0; s < _names.length; s++) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        key: _keys[s],
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                        child: Text(
                          _names[s],
                          style: t.typography.title.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: gap,
                          mainAxisSpacing: 16,
                          mainAxisExtent: cardW + 64,
                        ),
                        itemCount: _menu[_names[s]]!.length,
                        itemBuilder: (context, i) =>
                            _Card(item: _menu[_names[s]]![i], size: cardW),
                      ),
                    ),
                  ],
                  const SliverChromeInset.bottom(),
                ],
              );
              // GAP: no image / banner widget, a plain gradient stands in. Full width, behind the list: it moves with the scroll
              // (parallax-free) and the sheet's rounded corners show it through
              return Stack(
                children: [
                  ListenableBuilder(
                    listenable: _scroll,
                    builder: (context, _) => Positioned(
                      left: 0,
                      right: 0,
                      top:
                          _inset +
                          _storiesH -
                          (_scroll.hasClients ? _scroll.offset : 0),
                      height: _bannerH,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF3D5A9A), Color(0xFF8A4FB0)],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            20,
                            20,
                            20,
                            20 + _sheetR,
                          ),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              'Autumn drinks',
                              style: t.typography.title.copyWith(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
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
}

class _Card extends StatelessWidget {
  const _Card({required this.item, required this.size});
  final _Item item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    return Pressable(
      onPressed: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: t.glass.glassFill,
                borderRadius: BorderRadius.circular(t.metrics.cardRadius),
              ),
              // GAP: no network image / placeholder widget: a cup drawn from a circle stands in
              child: Center(
                child: Container(
                  width: size * 0.5,
                  height: size * 0.5,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.typography.body.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${item.price} ₽',
            style: t.typography.body.copyWith(
              fontSize: 15,
              color: t.colors.foregroundSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
