---
title: Pressable и RavelIcon
group: Стекло и кнопки
order: 7
summary: Нажимаемая область с «squish»-откликом и набор тонких иконок, нарисованных путями.
api: Pressable,RavelIcon
images: components|Иконки и кнопки
---
## Что это

- `Pressable` — цель нажатия с небольшим iOS-сжатием (`scale`); `squish: false` отключает, если ребёнок сам показывает отклик.
- `RavelIcon(RavelIconKind.x)` — линейные иконки без шрифта: строка толщины подстроена под SF Symbols. Цвет и размер берутся из `IconTheme`.

```dart
Pressable(
  onPressed: () {},
  child: Row(children: [RavelIcon(RavelIconKind.compose, size: 22), const SizedBox(width: 8), const Text('New')]),
)
```
