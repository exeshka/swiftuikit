---
title: GlassSegmentedControl
group: Формы и контролы
order: 3
summary: Сегментированный контрол: капсульная дорожка, ползунок на пружине, перетаскивается.
api: GlassSegmentedControl,GlassSegment
images: controls|Сегменты,controls-white|Светлый фон
---
## Что это

Ползунок скользит к выбранному сегменту, тащится пальцем и набухает при нажатии. Сегменты — текст и/или иконка.

```dart
GlassSegmentedControl<int>(
  value: tab,
  onChanged: (v) => setState(() => tab = v),
  segments: const [
    GlassSegment(value: 0, label: 'Day'),
    GlassSegment(value: 1, label: 'Week'),
    GlassSegment(value: 2, label: 'Month'),
  ],
)
```
