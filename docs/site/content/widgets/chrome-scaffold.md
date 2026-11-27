---
title: ChromeScaffold
group: Бары и навигация
order: 1
summary: Скаффолд, у которого верх и низ — зоны блюра, подогнанные под высоту баров и липких заголовков.
api: ChromeScaffold,ChromeBar,SliverChromeInset
images: nav-bars|Контент уходит под бар,sticky|Зона блюра растёт под липкие заголовки
keywords: scaffold blur edge effect
---
## Что это

Основа всех экранов: слои снизу вверх — `body` (скроллится под зонами) → прогрессивный блюр сверху/снизу → `topBar`/`bottomBar`. Высоты баров регистрируются автоматически (`ChromeBar` или самообслуживаемые `LargeTitleHeader`, `CollapsibleBar`).

## Когда использовать

Когда нужен нативный «scroll edge effect» iOS 26. Если хватает готового — берите `SwiftUiScaffold`, он сделан поверх этого.

## Пример

```dart
ChromeScaffold(
  topBar: const LargeTitleHeader(title: 'Library'),
  body: ListView.builder(
    itemCount: 50,
    itemBuilder: (_, i) => ListRow(title: 'Item $i'),
  ),
  bottomBar: ChromeBar(
    edge: ChromeEdge.bottom,
    child: GlassTabBar(selectedIndex: 0, onSelected: (_) {}, tabs: [GlassTab(icon: RavelIcon(RavelIconKind.chat), label: 'Chats')]),
  ),
)
```

Если тело — `CustomScrollView`, первым слайвером поставьте `SliverChromeInset.top()`. Для горизонтального пейджера списков: `scrollDepth: 1`.

> Эффект под барами задаётся `topChrome`/`bottomChrome` (`ChromeStyle.soft/fade/solid/none…`) или для поддерева через `ChromeStyleScope`.
