---
title: PinnedHeader и PinnedSection
group: Списки и заголовки
order: 4
summary: Липкие заголовки секций: прилипают к верху, вытесняются следующим; зона блюра растёт под ними.
api: PinnedHeader,PinnedSection
images: sticky|Контакты с липкими буквами
---
## Что это

`PinnedSection` склеивает заголовок и слайверы секции: прилипший заголовок вытесняется следующим (как в iOS). `PinnedHeader` — отдельный липкий слайвер; `builder(context, stuck)` знает, прилип ли он.

```dart
CustomScrollView(slivers: [
  const SliverChromeInset.top(),
  for (final letter in letters)
    PinnedSection(
      headerHeight: 28,
      header: ListSectionTitle(letter),
      slivers: [SliverList.list(children: [for (final n in names[letter]!) ListRow(title: n)])],
    ),
])
```
