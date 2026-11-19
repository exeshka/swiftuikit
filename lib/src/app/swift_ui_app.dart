import 'package:flutter/material.dart';

import '../theme/swift_ui_theme.dart';
import '../util/warm_up.dart';

/// The root of an app in the kit's look: what `MaterialApp` is for Material. It takes the kit's theme data instead of
/// `ThemeData`, picks the light or the dark one by [themeMode] (and the platform brightness for [ThemeMode.system]) and puts
/// it where every widget of the kit finds it ([SwiftUiTheme.of]). Everything else is passed to a `MaterialApp`, so
/// navigation, localization and the rest work as usual.
///
/// ```dart
/// runApp(SwiftUiApp(
///   theme: SwiftUiThemeData.light(),
///   darkTheme: SwiftUiThemeData.dark(),
///   home: const HomePage(),
/// ));
/// ```
///
/// With [warmUp] (default) the GPU pipelines of the kit are compiled under the first frames (see [RavelWarmUp]); call
/// `preloadRavelUiKit()` before `runApp`.
class SwiftUiApp extends StatelessWidget {
  const SwiftUiApp({
    super.key,
    this.theme,
    this.darkTheme,
    this.themeMode = ThemeMode.system,
    this.warmUp = true,
    this.navigatorKey,
    this.scaffoldMessengerKey,
    this.home,
    this.routes = const <String, WidgetBuilder>{},
    this.initialRoute,
    this.onGenerateRoute,
    this.onGenerateInitialRoutes,
    this.onUnknownRoute,
    this.navigatorObservers = const <NavigatorObserver>[],
    this.builder,
    this.title = '',
    this.onGenerateTitle,
    this.color,
    this.locale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales = const <Locale>[Locale('en', 'US')],
    this.showPerformanceOverlay = false,
    this.showSemanticsDebugger = false,
    this.debugShowCheckedModeBanner = true,
    this.shortcuts,
    this.actions,
    this.restorationScopeId,
    this.scrollBehavior,
  }) : routeInformationProvider = null,
       routeInformationParser = null,
       routerDelegate = null,
       backButtonDispatcher = null,
       routerConfig = null;

  /// Like the default constructor, but with a `Router` instead of a `Navigator` (go_router, auto_route...). Give either
  /// [routerConfig] or [routerDelegate] (with [routeInformationParser], [routeInformationProvider]).
  const SwiftUiApp.router({
    super.key,
    this.theme,
    this.darkTheme,
    this.themeMode = ThemeMode.system,
    this.warmUp = true,
    this.scaffoldMessengerKey,
    this.routeInformationProvider,
    this.routeInformationParser,
    this.routerDelegate,
    this.backButtonDispatcher,
    this.routerConfig,
    this.builder,
    this.title = '',
    this.onGenerateTitle,
    this.color,
    this.locale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales = const <Locale>[Locale('en', 'US')],
    this.showPerformanceOverlay = false,
    this.showSemanticsDebugger = false,
    this.debugShowCheckedModeBanner = true,
    this.shortcuts,
    this.actions,
    this.restorationScopeId,
    this.scrollBehavior,
  }) : navigatorKey = null,
       home = null,
       routes = const <String, WidgetBuilder>{},
       initialRoute = null,
       onGenerateRoute = null,
       onGenerateInitialRoutes = null,
       onUnknownRoute = null,
       navigatorObservers = const <NavigatorObserver>[];

  /// The theme in light mode (null: [SwiftUiThemeData.light]).
  final SwiftUiThemeData? theme;

  /// The theme in dark mode (null: [SwiftUiThemeData.dark]).
  final SwiftUiThemeData? darkTheme;

  /// Which of the two is used; [ThemeMode.system] follows the platform brightness.
  final ThemeMode themeMode;

  /// Compile the kit's GPU pipelines under the first frames (see [RavelWarmUp]).
  final bool warmUp;

  final GlobalKey<NavigatorState>? navigatorKey;
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;
  final Widget? home;
  final Map<String, WidgetBuilder> routes;
  final String? initialRoute;
  final RouteFactory? onGenerateRoute;
  final InitialRouteListFactory? onGenerateInitialRoutes;
  final RouteFactory? onUnknownRoute;
  final List<NavigatorObserver> navigatorObservers;
  final RouteInformationProvider? routeInformationProvider;
  final RouteInformationParser<Object>? routeInformationParser;
  final RouterDelegate<Object>? routerDelegate;
  final BackButtonDispatcher? backButtonDispatcher;
  final RouterConfig<Object>? routerConfig;

  /// Wraps the navigator (or the router's content). The kit's own wrapper (the warm-up) sits above it.
  final TransitionBuilder? builder;
  final String title;
  final GenerateAppTitle? onGenerateTitle;
  final Color? color;
  final Locale? locale;
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;
  final LocaleListResolutionCallback? localeListResolutionCallback;
  final LocaleResolutionCallback? localeResolutionCallback;
  final Iterable<Locale> supportedLocales;
  final bool showPerformanceOverlay;
  final bool showSemanticsDebugger;
  final bool debugShowCheckedModeBanner;
  final Map<ShortcutActivator, Intent>? shortcuts;
  final Map<Type, Action<Intent>>? actions;
  final String? restorationScopeId;
  final ScrollBehavior? scrollBehavior;

  bool get _isRouter => routerDelegate != null || routerConfig != null;

  Widget _wrap(BuildContext context, Widget? child) {
    final inner = builder == null ? child : builder!(context, child);
    if (inner == null) return const SizedBox.shrink();
    // a transparent Material gives every Text below (a drawer menu, a bar over the pages) the text style of the theme, and
    // lets ink effects work, so nothing in an app needs a `Scaffold` around it
    final themed = Material(
      type: MaterialType.transparency,
      textStyle: SwiftUiTheme.of(context).typography.body,
      child: inner,
    );
    return warmUp ? RavelWarmUp(child: themed) : themed;
  }

  @override
  Widget build(BuildContext context) {
    final light = SwiftUiTheme.light(data: theme);
    final dark = SwiftUiTheme.dark(data: darkTheme);
    if (_isRouter) {
      return MaterialApp.router(
        scaffoldMessengerKey: scaffoldMessengerKey,
        routeInformationProvider: routeInformationProvider,
        routeInformationParser: routeInformationParser,
        routerDelegate: routerDelegate,
        backButtonDispatcher: backButtonDispatcher,
        routerConfig: routerConfig,
        builder: _wrap,
        title: title,
        onGenerateTitle: onGenerateTitle,
        color: color,
        theme: light,
        darkTheme: dark,
        themeMode: themeMode,
        locale: locale,
        localizationsDelegates: localizationsDelegates,
        localeListResolutionCallback: localeListResolutionCallback,
        localeResolutionCallback: localeResolutionCallback,
        supportedLocales: supportedLocales,
        showPerformanceOverlay: showPerformanceOverlay,
        showSemanticsDebugger: showSemanticsDebugger,
        debugShowCheckedModeBanner: debugShowCheckedModeBanner,
        shortcuts: shortcuts,
        actions: actions,
        restorationScopeId: restorationScopeId,
        scrollBehavior: scrollBehavior,
      );
    }
    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      home: home,
      routes: routes,
      initialRoute: initialRoute,
      onGenerateRoute: onGenerateRoute,
      onGenerateInitialRoutes: onGenerateInitialRoutes,
      onUnknownRoute: onUnknownRoute,
      navigatorObservers: navigatorObservers,
      builder: _wrap,
      title: title,
      onGenerateTitle: onGenerateTitle,
      color: color,
      theme: light,
      darkTheme: dark,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: localizationsDelegates,
      localeListResolutionCallback: localeListResolutionCallback,
      localeResolutionCallback: localeResolutionCallback,
      supportedLocales: supportedLocales,
      showPerformanceOverlay: showPerformanceOverlay,
      showSemanticsDebugger: showSemanticsDebugger,
      debugShowCheckedModeBanner: debugShowCheckedModeBanner,
      shortcuts: shortcuts,
      actions: actions,
      restorationScopeId: restorationScopeId,
      scrollBehavior: scrollBehavior,
    );
  }
}
