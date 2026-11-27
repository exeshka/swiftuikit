---
title: SwiftUiScaffold, SwiftUiShell
group: Каркас приложения и роутинг
order: 2
summary: Страница с нативной раскладкой iOS 26 и оболочка с таб-баром, который не перерисовывается при смене страниц.
api: SwiftUiScaffold,SwiftUiShell,SwiftUiShellScope
images: inbox|Три страницы, общий таб-бар
---
## Что это

- `SwiftUiScaffold` — страница: `title`, `actions`, `body`, `bottomBar`. Внутри `ChromeScaffold`, эффект краёв берётся из темы.
- `SwiftUiShell` — часть приложения, которая остаётся при смене страниц: бар (таб-бар) поверх `body`; страницы — независимые экраны со своим скроллом.

```dart
SwiftUiShell(
  bottomBar: GlassTabBar(selectedIndex: i, onSelected: setTab, tabs: tabs),
  body: SwiftUiPageSwitcher(index: i, children: [for (final p in pages) p]),
)
```
