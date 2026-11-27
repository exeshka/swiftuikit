---
title: SwiftUiTheme и тема
group: Темы и утилиты
order: 1
summary: Чтение темы, цвета, типографика, метрики и параметры стекла.
api: SwiftUiThemeData,SwiftUiTheme,SwiftUiColors,SwiftUiTypography,SwiftUiMetrics,SwiftUiGlassTheme,SwiftUiChromeTheme,SwiftUiAdaptiveTheme
images: components|Светлая и тёмная
---
## Что это

`SwiftUiTheme.of(context)` отдаёт `SwiftUiThemeData`. Подробно — в гайде «Тема и цвета».

```dart
final t = SwiftUiTheme.of(context);
Text('Hi', style: t.typography.body.copyWith(color: t.colors.foregroundSecondary));
```
