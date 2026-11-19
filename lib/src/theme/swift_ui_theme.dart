import 'package:flutter/material.dart';

import 'swift_ui_theme_data.dart';

export 'swift_ui_adaptive_theme.dart';
export 'swift_ui_chrome_theme.dart';
export 'swift_ui_colors.dart';
export 'swift_ui_glass_theme.dart';
export 'swift_ui_metrics.dart';
export 'swift_ui_theme_data.dart';
export 'swift_ui_typography.dart';

/// Reads the theme of the kit and builds the Material [ThemeData] that carries it.
class SwiftUiTheme {
  const SwiftUiTheme._();

  static ThemeData dark({SwiftUiThemeData? data}) =>
      materialOf(data ?? SwiftUiThemeData.dark());
  static ThemeData light({SwiftUiThemeData? data}) =>
      materialOf(data ?? SwiftUiThemeData.light());

  /// A Material [ThemeData] in the colours and text styles of [t], with [t] itself as an extension.
  static ThemeData materialOf(SwiftUiThemeData t) {
    return ThemeData(
      useMaterial3: true,
      brightness: t.brightness,
      scaffoldBackgroundColor: t.colors.background,
      canvasColor: t.colors.background,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: t.colors.accent,
        brightness: t.brightness,
        surface: t.colors.background,
      ),
      textTheme: TextTheme(
        bodyMedium: t.typography.body,
        bodyLarge: t.typography.body,
        titleLarge: t.typography.title,
      ),
      extensions: [t],
    );
  }

  static SwiftUiThemeData of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<SwiftUiThemeData>() ??
        (theme.brightness == Brightness.dark
            ? SwiftUiThemeData.dark()
            : SwiftUiThemeData.light());
  }
}
