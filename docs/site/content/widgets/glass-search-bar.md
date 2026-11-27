---
title: GlassSearchBar
group: Бары и навигация
order: 7
summary: Поле поиска iOS 26: стеклянная капсула с лупой, очисткой и выезжающей «Cancel».
api: GlassSearchBar
images: controls|Поле поиска,telegram|Поиск в мессенджере
---
## Что это

Редактируемое поле. `cancelAsButton: true` — стеклянная круглая кнопка с крестиком (как в мессенджерах), `liquid: false` — плоское поле одной краской (дешевле), `fadeWithSection` — для использования внутри `CollapsibleBar`.

```dart
GlassSearchBar(
  hintText: 'Search',
  onChanged: (q) => setState(() => query = q),
  onCancel: () => setState(() => query = ''),
)
```
