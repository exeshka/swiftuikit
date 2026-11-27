---
title: Навигация и листы
order: 4
summary: Переходы страниц, листы с детентами, морф меню и листа из кнопки, диалоги, интеграция с auto_route и go_router.
keywords: navigation router sheet morph origin auto_route go_router
images: sheets|Страница «Sheets» примера
videos: morph-demo|Лист и меню вырастают из кнопок
---
## Листы

`showGlassSheet` открывает лист поверх приложения, как `showModalBottomSheet`; он стеклянный на частичных детентах и непрозрачный на `large`.

```dart
await showGlassSheet<void>(
  context,
  detents: const [GlassSheetDetent.medium, GlassSheetDetent.large],
  child: const MyContent(),
);
```

Три способа:

- `showGlassSheet(context, ...)` — из любого колбэка;
- `GlassSheetPresenter(isPresented: ..., ...)` — внутри страницы, как `.sheet(isPresented:)`;
- `GlassSheetAutoRoute` / `GlassSheetPage` — лист как страница роутера (auto_route / go_router).

## Морф из кнопки

Оберните кнопку в `GlassSheetOrigin` и передайте тот же `GlassSheetOriginController` в `showGlassSheet` или `showGlassMenu`. Кнопка прячется, лист (или меню) стартует её формой и растёт до своего размера; при закрытии сжимается обратно.

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

## Диалоги

`showGlassAlert` — алерт по центру; `showGlassActionDialog` — `confirmationDialog`, с `origin` вырастает рядом с кнопкой.

## Переходы страниц

`SwiftUiPageRoute` — переход iOS (сдвиг справа, страница под ней чуть уходит, свайп назад). Для замороженных снимков страницы под переходом — `FreezeUnderRoute` (включён в `ChromeScaffold`). Дополнительно в ядре есть `SwiftZoomRoute` (zoom-hero), `SwiftSheetRoute`, `SwiftModalRoute`; адаптеры: `SwiftPageAutoRoute`, `SwiftSheetAutoRoute`, `SwiftZoomAutoRoute`, `SwiftPage`, `SwiftSheetPage`, `SwiftZoomPage`.
