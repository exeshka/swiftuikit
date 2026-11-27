import 'dart:io' show Directory, File, Platform;

import 'package:flutter/material.dart';

const _themeDefine = String.fromEnvironment('THEME');
final _theme = _themeDefine.isNotEmpty
    ? _themeDefine
    : (launchOption('THEME') ?? 'dark');

/// A launch option for a build without dart-defines (the docs screenshots): the environment of the process
/// (`SIMCTL_CHILD_<NAME>=... xcrun simctl launch`) or a line `NAME=value` of `launch.txt` in the temp dir in the app container.
String? launchOption(String name) {
  final env = Platform.environment[name];
  if (env != null && env.isNotEmpty) return env;
  try {
    for (final l in File('${Directory.systemTemp.path}/launch.txt').readAsLinesSync()) {
      if (l.startsWith('$name=')) return l.substring(name.length + 1).trim();
    }
  } catch (_) {}
  return null;
}

/// Blur under the bars (the kit's default) instead of the cheap fade (the switch on the home page).
final progressiveBlur = ValueNotifier<bool>(true);

final themeMode = ValueNotifier<ThemeMode>(
  _theme == 'light' ? ThemeMode.light : ThemeMode.dark,
);
