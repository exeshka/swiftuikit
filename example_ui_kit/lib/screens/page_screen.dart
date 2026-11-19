import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

/// A page assembled from the kit: a back button, a centered title, a bubble of two actions and a separate blue button on
/// top; a button at each end of the bottom edge.
// named explicitly: `PageRoute` would clash with Flutter's own PageRoute
@RoutePage(name: 'PageDemoRoute')
class PageScreen extends StatefulWidget {
  const PageScreen({super.key});
  @override
  State<PageScreen> createState() => _PageScreenState();
}

class _PageScreenState extends State<PageScreen> {
  bool _bubble = true;
  bool _blue = true;
  bool _bottom = true;

  static const _blueColor = Color(0xFF0A84FF);

  /// Presence animation of a plate: it scales and fades in and out and the layout space follows.
  Widget _appear(
    bool show,
    Widget Function(double p) build, {
    Alignment alignment = Alignment.centerRight,
  }) {
    return LiquidGlassPresence(
      show: show,
      duration: const Duration(milliseconds: 450),
      builder: (context, p) =>
          Align(alignment: alignment, widthFactor: p, child: build(p)),
    );
  }

  Widget _toggle(SwiftUiThemeData t, int n) {
    final labels = [
      'Bubble (search / compose)',
      'Blue button',
      'Bottom buttons',
    ];
    final values = [_bubble, _blue, _bottom];
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          const SizedBox(width: 18),
          Expanded(child: Text(labels[n], style: t.typography.body)),
          GlassSwitch(
            value: values[n],
            onChanged: (v) => setState(() {
              if (n == 0) _bubble = v;
              if (n == 1) _blue = v;
              if (n == 2) _bottom = v;
            }),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: ChromeScaffold(
        // the kit's default edge effect (no hand-set tint / sigma)
        topBar: LargeTitleHeader(
          title: 'Title',
          style: NavTitleStyle.inline,
          trailing: [
            _appear(
              _bubble,
              (p) => GlassToolbarCapsule(
                presence: p,
                items: [
                  GlassToolbarItem(
                    id: 'search',
                    onPressed: () {},
                    child: const RavelIcon(
                      RavelIconKind.search,
                      size: 26,
                      strokeWidth: 2.1,
                    ),
                  ),
                  GlassToolbarItem(
                    id: 'compose',
                    onPressed: () {},
                    child: const RavelIcon(
                      RavelIconKind.compose,
                      size: 26,
                      strokeWidth: 2.1,
                    ),
                  ),
                ],
              ),
            ),
            _appear(
              _blue,
              (p) => IgnorePointer(
                ignoring: !_blue,
                child: LiquidGlass.circle(
                  size: 44,
                  presence: p,
                  interactive: true,
                  tint: _blueColor,
                  // Center: LiquidGlass gives its child tight constraints, the icon would stretch to the whole plate
                  child: Opacity(
                    opacity: p,
                    child: const Center(
                      child: RavelIcon(
                        RavelIconKind.plus,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomBar: BottomDock(
          composer: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _appear(
                  _bottom,
                  alignment: Alignment.centerLeft,
                  (p) => LiquidGlass.circle(
                    size: 56,
                    presence: p,
                    interactive: true,
                    child: Opacity(
                      opacity: p,
                      child: Center(
                        child: RavelIcon(
                          RavelIconKind.menu,
                          size: 28,
                          color: t.glass.glassIcon,
                        ),
                      ),
                    ),
                  ),
                ),
                _appear(
                  _bottom,
                  (p) => LiquidGlass.circle(
                    size: 56,
                    presence: p,
                    interactive: true,
                    child: Opacity(
                      opacity: p,
                      child: Center(
                        child: RavelIcon(
                          RavelIconKind.pencil,
                          size: 28,
                          color: t.glass.glassIcon,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: ListView.builder(
          itemCount: 43,
          itemBuilder: (_, n) {
            if (n < 3) return _toggle(t, n);
            final i = n - 3;
            return SizedBox(
              height: 52,
              child: Row(
                children: [
                  const SizedBox(width: 18),
                  RavelIcon(
                    RavelIconKind.chat,
                    size: 22,
                    color: t.colors.foreground,
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Row $i — The quick brown fox',
                    style: t.typography.body,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
