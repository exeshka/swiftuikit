// Endless scroll for Instruments Power Profiler (profile):
//   flutter run --profile -t lib/bench_loop.dart --dart-define=VARIANT=full|plain|idle
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:swiftuikit/swiftuikit.dart';

import 'data.dart';
import 'screens/chatgpt_screen.dart';
import 'screens/telegram_screen.dart';

const _variant = String.fromEnvironment('VARIANT', defaultValue: 'full');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await preloadRavelUiKit();
  final scroll = ScrollController();
  Widget home = _variant == 'telegram'
      ? const TelegramScreen()
      : const ChatGptScreen(); // full: chrome with blur zones and glass
  if (_variant == 'plain') {
    // same list, no chrome (no backdrop filters)
    home = Scaffold(
      body: Builder(
        builder: (context) => ListView.builder(
          controller: scroll,
          padding: const EdgeInsets.only(top: 120, bottom: 100),
          itemCount: chatGptTitles.length,
          itemBuilder: (context, i) => ListRow(
            title: chatGptTitles[i],
            height: 49,
            horizontalPadding: 33,
            onTap: () {},
          ),
        ),
      ),
    );
  }
  if (_variant == 'vanilla') {
    home = Scaffold(
      body: ListView.builder(
        controller: scroll,
        itemCount: chatGptTitles.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.all(14),
          child: Text(chatGptTitles[i], style: const TextStyle(fontSize: 19)),
        ),
      ),
    );
  }
  if (_variant == 'blur') {
    // chrome with blur zones only: empty bars, no glass
    home = Scaffold(
      body: ChromeScaffold(
        topBar: const ChromeBar(child: SizedBox(height: 44)),
        bottomBar: const ChromeBar(
          edge: ChromeEdge.bottom,
          child: SizedBox(height: 44),
        ),
        body: ListView.builder(
          controller: scroll,
          itemCount: chatGptTitles.length,
          itemBuilder: (context, i) => ListRow(
            title: chatGptTitles[i],
            height: 49,
            horizontalPadding: 33,
            onTap: () {},
          ),
        ),
      ),
    );
  }
  if (_variant == 'glass') {
    // glass groups only: no blur zones
    home = Scaffold(
      body: Stack(
        children: [
          ListView.builder(
            controller: scroll,
            padding: const EdgeInsets.only(top: 120, bottom: 100),
            itemCount: chatGptTitles.length,
            itemBuilder: (context, i) => ListRow(
              title: chatGptTitles[i],
              height: 49,
              horizontalPadding: 33,
              onTap: () {},
            ),
          ),
          Positioned(
            top: 60,
            right: 20,
            child: LiquidGlassGroup(
              child: GlassCircleButton(
                icon: RavelIcon(RavelIconKind.search),
                onPressed: () {},
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 34,
            right: 20,
            child: LiquidGlassGroup(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FloatingPillButton(
                    label: 'Chat',
                    icon: RavelIcon(RavelIconKind.compose),
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
        ],
      ),
    );
  }
  runApp(
    SwiftUiApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: SwiftUiThemeData.dark().withGlass(
        liquidPrefilter:
            const int.fromEnvironment('PREF', defaultValue: 85) / 100,
      ),
      home: home,
    ),
  );
  if (_variant == 'idle') return;
  ScrollPosition? pos;
  ScrollPosition? find() {
    if (_variant != 'full' && _variant != 'telegram')
      return scroll.hasClients ? scroll.position : null;
    ScrollPosition? r;
    void v(Element e) {
      if (r != null) return;
      if (e is StatefulElement && e.state is ScrollableState) {
        final st = e.state as ScrollableState;
        if (st.position.axis == Axis.vertical) {
          r = st.position;
          return;
        }
      }
      e.visitChildren(v);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(v);
    return r;
  }

  Ticker((d) {
    pos ??= find();
    final p = pos;
    if (p == null || !p.hasContentDimensions) return;
    final span = p.maxScrollExtent - 100;
    final x = (d.inMicroseconds / 1e6 * 600) % (span * 2);
    p.jumpTo(x < span ? x : span * 2 - x);
  }).start();
}
