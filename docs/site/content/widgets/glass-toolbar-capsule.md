---
title: GlassToolbarCapsule
group: Бары и навигация
order: 6
summary: Стеклянная капсула с несколькими действиями справа в баре; при смене действий анимируется как нативная.
api: GlassToolbarCapsule,GlassToolbarItem
images: page|Пузырь из двух действий
---
## Что это

Группа действий в одной интерактивной капсуле. Элементы идентифицируются по `id`: новый — появляется, исчезнувший — схлопывается, другой `id` на том же месте — меняется.

```dart
GlassToolbarCapsule(
  items: [
    GlassToolbarItem(id: 'share', child: RavelIcon(RavelIconKind.compose), onPressed: share),
    GlassToolbarItem(id: 'more', child: RavelIcon(RavelIconKind.menu), onPressed: more),
  ],
)
```

Для показа/скрытия всей капсулы используйте `presence` вместе с `LiquidGlassPresence`.
