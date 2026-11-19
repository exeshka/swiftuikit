import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swiftuikit/swiftuikit.dart' show ScreenRadiusService;
import 'package:swiftuikit/swiftuikit.dart';

import 'app_state.dart';
import 'router/app_router.dart';

// Launch options: --dart-define=SCREEN=<a path of the router without the slash>, e.g. telegram | coffee | drinkit | profile |
//                 chatgpt | claude | sticky | sticky-replace | components | liquid-playground | nav-bars | ... (see lib/router/app_router.dart)
//                 --dart-define=THEME=dark|light
//                 --dart-define=PERF=true (performance overlay)
const _screen = String.fromEnvironment('SCREEN');
const _perf = bool.fromEnvironment('PERF');
// Engine blur prefilter of the glass, percent of the blur sigma (kit default 85). Lower = cheaper GPU, less anti-aliasing of thin features.
const _pref = int.fromEnvironment('PREF', defaultValue: 85) / 100;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await preloadRavelUiKit();
  await ScreenRadiusService.instance.initialize();
  runApp(ShowcaseApp());
}

class ShowcaseApp extends StatelessWidget {
  ShowcaseApp({super.key});

  final _router = AppRouter();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeMode,
      builder: (context, mode, _) => ValueListenableBuilder<bool>(
        valueListenable: progressiveBlur,
        builder: (context, blur, _) => SwiftUiApp.router(
          debugShowCheckedModeBanner: false,
          showPerformanceOverlay: _perf,
          title: 'Ravel UI Kit',
          themeMode: mode,
          theme: SwiftUiThemeData.light().withGlass(liquidPrefilter: _pref),
          darkTheme: SwiftUiThemeData.dark().withGlass(liquidPrefilter: _pref),
          // SCREEN opens that page alone (no home under it), like the old initialRoute did
          routerConfig: _router.config(
            deepLinkBuilder: _screen.isEmpty
                ? null
                : (_) => DeepLink.path('/$_screen'),
          ),
          builder: (context, child) => ChromeStyleScope.both(
            style: blur ? const ChromeStyle.soft() : const ChromeStyle.fade(),
            child: PhoneFrame(
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.escape): () =>
                      Navigator.maybeOf(context)?.maybePop(),
                },
                child: Focus(autofocus: true, child: child!),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// On wide windows (desktop) shows the app in an iPhone-sized column with the
/// iPhone 17 safe area, so screens match the reference screenshots.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});
  final Widget child;

  static const size = Size(402, 874);

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (mq.size.width < 700) return child;
    final t = SwiftUiTheme.of(context);
    final h = (mq.size.height - 24).clamp(400.0, size.height);
    final scale = h / size.height;
    return ColoredBox(
      color: t.isDark ? const Color(0xFF1C1C1E) : const Color(0xFFD1D1D6),
      child: Center(
        child: SizedBox(
          width: size.width * scale,
          height: h,
          child: FittedBox(
            child: SizedBox.fromSize(
              size: size,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(52),
                child: MediaQuery(
                  data: mq.copyWith(
                    size: size,
                    padding: const EdgeInsets.only(top: 59, bottom: 34),
                    viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
