---
title: ListRow и ListSectionTitle
group: Списки и заголовки
order: 3
summary: Простая строка меню и небольшой заголовок секции.
api: ListRow,ListSectionTitle
images: chatgpt|Меню ChatGPT,claude|Меню Claude
---
## Что это

`ListRow` — строка с иконкой, одной строкой заголовка и trailing; `ListSectionTitle` — вторичная подпись секции («Recents»). Для меню-боковых панелей и простых списков.

```dart
ListView(children: [
  const ListSectionTitle('Recents'),
  ListRow(title: 'New chat', leading: RavelIcon(RavelIconKind.compose), onTap: () {}),
])
```
