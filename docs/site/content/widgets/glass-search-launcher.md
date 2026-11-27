---
title: GlassSearchLauncher
group: Бары и навигация
order: 8
summary: Поле, которое не редактируется на месте, а открывает слой поиска над всей страницей.
api: GlassSearchLauncher
images: telegram|Лаунчер поиска
---
## Что это

Выглядит как `GlassSearchBar`; по нажатию поле уезжает наверх, страница гаснет, под полем показываются результаты `resultsBuilder`. `bottomBuilder` — что докнуть над клавиатурой (фильтр сегментами).

```dart
GlassSearchLauncher(
  hintText: 'Search chats',
  resultsBuilder: (context, query) => ListView(children: [
    for (final c in chats.where((c) => c.contains(query))) ListRow(title: c),
  ]),
  onClosed: () => setState(() => filter = ''),
)
```
