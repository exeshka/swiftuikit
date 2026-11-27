---
title: GlassSheet и showGlassSheet
group: Оверлеи: листы, диалоги, меню
order: 1
summary: Лист iOS 26 с детентами: стекло на частичных высотах, непрозрачный на large; морф из кнопки.
api: GlassSheet,showGlassSheet,GlassSheetPresenter,GlassSheetOriginController,GlassSheetDetent,GlassSheetController
images: sheet-open|Лист на детенте medium, sheets|Страница листов примера
videos: morph-demo|Лист и меню вырастают из кнопок
keywords: sheet bottom sheet detent morph origin
---
## Что это

`.sheet` из SwiftUI с `presentationDetents`. Тащится вниз для закрытия, содержимое скроллится после достижения полной высоты.

Три способа показать:

- `showGlassSheet(context, child: ...)` — из любого колбэка;
- `GlassSheetPresenter(isPresented:, sheetChild:, child: page)` — как `.sheet(isPresented:)`;
- роутер: `GlassSheetAutoRoute` (auto_route) / `GlassSheetPage` (go_router).

## Пример

```dart
final ctrl = GlassSheetController();

await showGlassSheet<void>(
  context,
  controller: ctrl,
  detents: const [GlassSheetDetent.fraction(0.4), GlassSheetDetent.medium, GlassSheetDetent.large],
  initialDetent: GlassSheetDetent.medium,
  builder: (context, scroll) => ListView(controller: scroll, children: const [ListRow(title: 'One'), ListRow(title: 'Two')]),
);
```

Детенты: `medium`, `large`, `fraction(f)`, `height(h)`. `dismissible: false` — нельзя закрыть; `modal: false` — страница под листом остаётся доступной.

## Морф из кнопки

```dart
final origin = GlassSheetOriginController();

GlassSheetOrigin(
  controller: origin,
  child: GlassButton(
    label: 'Открыть',
    onPressed: () => showGlassSheet<void>(context, origin: origin, child: const MyContent()),
  ),
)
```

Кнопка скрывается, лист начинается её формой (капсула/круг стекла), вырастает в карточку и при закрытии сжимается обратно. Подробнее — в гайде «Навигация и листы».
