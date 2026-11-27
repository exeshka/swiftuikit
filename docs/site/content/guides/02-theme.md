---
title: Тема и цвета
order: 2
summary: SwiftUiThemeData, семантические цвета в духе iOS, параметры шейдера стекла, переключение светлой и тёмной темы.
keywords: theme dark light цвета typography metrics
images: components|Компоненты в тёмной/светлой теме
---
## Что в теме

`SwiftUiThemeData` собирается из шести групп:

| Группа | Класс | Что там |
|---|---|---|
| `colors` | `SwiftUiColors` | `background`, `foreground`, `foregroundSecondary/Tertiary`, `separator`, `accent`, `onAccent`, `pillFill` … как в iOS |
| `typography` | `SwiftUiTypography` | стили текста (`body`, заголовки) |
| `metrics` | `SwiftUiMetrics` | размеры, радиусы, высота бара |
| `glass` | `SwiftUiGlassTheme` | заливка плоского стекла и параметры шейдера: `liquidBezel`, `liquidRefraction`, `liquidBlur`, `liquidSpecular`… |
| `chrome` | `SwiftUiChromeTheme` | какой эффект рисуется под барами |
| `adaptive` | `SwiftUiAdaptiveTheme` | границы compact/regular классов окна |

## Светлая и тёмная

```dart
SwiftUiApp(
  themeMode: ThemeMode.system,                 // ThemeMode реэкспортирован китом
  theme: SwiftUiThemeData.light(),
  darkTheme: SwiftUiThemeData.dark(),
  home: const Home(),
);
```

## Настройка стекла

`withGlass` меняет часть параметров шейдера без `copyWith` вложенных групп:

```dart
final base = SwiftUiThemeData.dark();
final theme = base.withGlass(liquidBlur: 14, liquidRefraction: 1.1, useLiquidGlass: true);
```

`useLiquidGlass: false` выключает шейдер везде: все `LiquidGlass`/`GlassSurface` становятся плоскими подложками — удобно для старых устройств и тестов.

## Эффект под барами

```dart
final theme = base.copyWith(chrome: base.chrome.copyWith(top: const ChromeStyle.solid()));
```

Варианты `ChromeStyle`: `soft()` (по умолчанию, прогрессивный блюр), `variableBlur()`, `fade()`, `blur()`, `hard()`, `solid()`, `none()`, `custom()`. Для одного поддерева — `ChromeStyleScope`.

## Чтение темы

```dart
final t = SwiftUiTheme.of(context);
t.isDark; t.colors.accent; t.typography.body; t.metrics;
```
