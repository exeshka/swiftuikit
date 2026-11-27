---
title: ListSection и GroupedRow
group: Списки и заголовки
order: 1
summary: Inset-grouped список как в Настройках iOS: карточка со скруглением, иконки-плитки, шевроны.
api: ListSection,GroupedRow
images: controls|Группированный список
---
## Что это

`ListSection` — секция с заголовком, скруглённой карточкой и тонкими разделителями. Строки — `GroupedRow` (цветная иконка 30 pt, заголовок, значение справа, шеврон, или любой `trailing` — переключатель, степпер).

```dart
ListSection(
  header: 'Account',
  separatorInset: 62,
  children: [
    GroupedRow(title: 'Notifications', icon: RavelIcon(RavelIconKind.chat), iconColor: Colors.red, chevron: true, onTap: () {}),
    GroupedRow(title: 'Dark mode', icon: RavelIcon(RavelIconKind.menu), iconColor: Colors.indigo, trailing: GlassSwitch(value: true, onChanged: (_) {})),
  ],
)
```
