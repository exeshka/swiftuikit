---
title: SwiftUiApp
group: Каркас приложения и роутинг
order: 1
summary: Корень приложения в стиле кита: тема, навигатор или router, прогрев GPU.
api: SwiftUiApp
images: buttons|Приложение-пример
---
## Что это

Аналог `MaterialApp` с `SwiftUiThemeData` вместо `ThemeData`. Поддерживает `home`/`routes` и `SwiftUiApp.router(routerConfig:)`. `themeMode` — Flutter-ный `ThemeMode`, реэкспортируется китом.

```dart
SwiftUiApp.router(
  themeMode: ThemeMode.system,
  theme: SwiftUiThemeData.light(),
  darkTheme: SwiftUiThemeData.dark(),
  routerConfig: router,
)
```
