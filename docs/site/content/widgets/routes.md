---
title: Маршруты и переходы
group: Каркас приложения и роутинг
order: 5
summary: Переходы страниц iOS, листы и zoom-hero, адаптеры auto_route и go_router.
api: SwiftUiPageRoute,SwiftZoomRoute,SwiftZoomHero,SwiftModalRoute,SwiftScrollSheetRoute,SwiftScrollSheetController,SwiftScrollSheetDragTarget,SwiftModalScaffold,SwiftStepSheet,SwiftSheetRoute,GlassSheetAutoRoute,GlassSheetPage,SwiftPageAutoRoute,SwiftSheetAutoRoute,SwiftZoomAutoRoute,SwiftModalAutoRoute,SwiftScrollSheetAutoRoute,SwiftPage,SwiftSheetPage,SwiftZoomPage,SwiftScrollSheetPage,SwiftModalPage
images: sheets|Листы
---
## Что это

- `SwiftUiPageRoute` — push iOS: сдвиг справа, параллакс страницы под ней, свайп назад.
- `SwiftZoomRoute` + `SwiftZoomHero` — zoom-переход «элемент → страница» по совпадающим `id`.
- `SwiftSheetRoute`, `SwiftModalRoute`, `SwiftScrollSheetRoute` — листы-страницы со своей анимацией (последний — **нестабильный API**).
- Адаптеры: `GlassSheetAutoRoute`, `SwiftPageAutoRoute`, `SwiftSheetAutoRoute`, `SwiftZoomAutoRoute` для auto_route и `GlassSheetPage`, `SwiftPage`, `SwiftSheetPage`, `SwiftZoomPage` для go_router.

```dart
// auto_route
GlassSheetAutoRoute(page: SheetContentRoute.page, path: '/sheet-content', scrollable: false)

// zoom
SwiftZoomHero(id: item.id, child: Thumbnail(item))   // на списке
SwiftZoomHero(id: item.id, child: DetailPage(item))  // на странице-назначении
```
