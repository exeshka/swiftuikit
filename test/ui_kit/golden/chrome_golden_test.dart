import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftuikit/swiftuikit.dart';

import '../test_app.dart';

// Goldens run on the test renderer, where ImageFilter.shader is unavailable,
// so ProgressiveBlur uses its uniform-blur fallback. They pin down layout,
// zone sizes, tint and component rendering; the shader path is checked on
// device (see README, "Verifying visually").

Widget _screen({
  ScrollController? controller,
  bool large = false,
  bool stickies = false,
  Brightness b = Brightness.dark,
}) {
  final tokens = b == Brightness.dark
      ? SwiftUiThemeData.dark()
      : SwiftUiThemeData.light();
  return testApp(
    ChromeScaffold(
      topChrome: const ChromeStyle.soft(), // the goldens cover the progressive blur option
      bottomChrome: const ChromeStyle.soft(),
      topBar: large
          ? LargeTitleHeader(
              title: 'Contacts',
              leading: GlassCircleButton(
                icon: RavelIcon(RavelIconKind.chevronLeft),
                onPressed: () {},
              ),
              trailing: [
                GlassCircleButton(
                  icon: RavelIcon(RavelIconKind.search),
                  onPressed: () {},
                ),
              ],
            )
          : ChromeBar(
              child: TitleBar(
                title: 'ChatGPT',
                trailing: [
                  GlassCircleButton(
                    icon: RavelIcon(RavelIconKind.search),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
      bottomBar: ChromeBar(
        edge: ChromeEdge.bottom,
        child: SizedBox(
          height: tokens.metrics.avatarSize + 8,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FloatingPillButton(
                  label: 'Chat',
                  icon: RavelIcon(RavelIconKind.compose),
                  onPressed: () {},
                ),
                GlassAvatarButton(
                  initials: 'MS',
                  accented: true,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
      body: stickies
          ? CustomScrollView(
              controller: controller,
              slivers: [
                const SliverChromeInset.top(),
                for (var s = 0; s < 4; s++) ...[
                  PinnedHeader(
                    height: 36,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Section $s',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverList.builder(
                    itemCount: 6,
                    itemBuilder: (_, i) => Container(
                      height: 49,
                      color: i.isEven
                          ? const Color(0xFF3A5BA0)
                          : const Color(0xFFB04A4A),
                    ),
                  ),
                ],
                const SliverChromeInset.bottom(),
              ],
            )
          : ListView.builder(
              controller: controller,
              itemCount: 60,
              itemBuilder: (context, i) => Container(
                height: 49,
                color: i.isEven
                    ? const Color(0xFF3A5BA0)
                    : const Color(0xFFB04A4A),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Row $i',
                  style: const TextStyle(color: Colors.white, fontSize: 17),
                ),
              ),
            ),
    ),
    brightness: b,
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  testWidgets('golden: top position', (tester) async {
    setPhoneSize(tester);
    await tester.pumpWidget(_screen());
    await _settle(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/top_position.png'),
    );
  });

  testWidgets('golden: content under the blur', (tester) async {
    setPhoneSize(tester);
    await tester.pumpWidget(_screen());
    await tester.drag(find.byType(ListView), const Offset(0, -180));
    await _settle(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/content_under_blur.png'),
    );
  });

  testWidgets('golden: large title collapsed', (tester) async {
    setPhoneSize(tester);
    await tester.pumpWidget(_screen(large: true));
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await _settle(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/large_title_collapsed.png'),
    );
  });

  testWidgets('golden: stuck headers grow the blur zone', (tester) async {
    setPhoneSize(tester);
    await tester.pumpWidget(_screen(large: true, stickies: true));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -520));
    await _settle(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/stuck_headers.png'),
    );
  });

  testWidgets('golden: light theme', (tester) async {
    setPhoneSize(tester);
    await tester.pumpWidget(_screen(b: Brightness.light));
    await tester.drag(find.byType(ListView), const Offset(0, -180));
    await _settle(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/light_theme.png'),
    );
  });
}
