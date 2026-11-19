import 'package:flutter/material.dart';

const _theme = String.fromEnvironment('THEME', defaultValue: 'dark');

/// Blur under the bars (the kit's default) instead of the cheap fade (the switch on the home page).
final progressiveBlur = ValueNotifier<bool>(true);

final themeMode = ValueNotifier<ThemeMode>(
  _theme == 'light' ? ThemeMode.light : ThemeMode.dark,
);
