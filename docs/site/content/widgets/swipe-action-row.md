---
title: SwipeActionRow и RavelRefreshControl
group: Списки и заголовки
order: 2
summary: Строка со свайп-действиями как в нативном swipeActions и pull-to-refresh в стиле iOS.
api: SwipeActionRow,SwipeAction,RavelRefreshControl
images: controls|Свайп и обновление
---
## Что это

- `SwipeActionRow` — свайп влево открывает кнопки; строка уезжает, подсвечивается, а край скругляется в полукруг; `dismisses: true` удаляет строку со схлопыванием.
- `RavelRefreshControl` — первый слайвер `CustomScrollView`: контент остаётся оттянутым со спиннером, пока `onRefresh` выполняется (нужен `BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())`).

```dart
SwipeActionRow(
  actions: [SwipeAction(label: 'Delete', color: Colors.red, dismisses: true, onPressed: () => remove(i))],
  child: ListRow(title: 'Message $i'),
)

CustomScrollView(
  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
  slivers: [RavelRefreshControl(onRefresh: reload), SliverList.list(children: rows)],
)
```
