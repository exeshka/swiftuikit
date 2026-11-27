---
title: GlassScrollSegments
group: Формы и контролы
order: 4
summary: Горизонтально прокручиваемая полоса сегментов (папки/фильтры) с тем же стеклянным ползунком.
api: GlassScrollSegments,GlassScrollSegmentsController
images: telegram|Папки чатов
---
## Что это

Как `GlassSegmentedControl`, но сегменты по ширине содержимого и лента прокручивается к выбранному (`scrollAlign`). `position` — `ValueListenable<double>` (дробный индекс): подключите `PageController.page`, и ползунок следует за свайпом пейджера. `badge` у сегмента — счётчик.

```dart
GlassScrollSegments<int>(
  value: folder,
  onChanged: (v) => setState(() => folder = v),
  glass: true,
  segments: const [
    GlassSegment(value: 0, label: 'All', badge: '12'),
    GlassSegment(value: 1, label: 'Work'),
    GlassSegment(value: 2, label: 'Personal'),
  ],
)
```
