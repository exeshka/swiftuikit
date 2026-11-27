---
title: showGlassMenu и GlassMenuButton
group: Оверлеи: листы, диалоги, меню
order: 3
summary: Нативное меню (UIMenu): стеклянная панель, вырастающая из кнопки.
api: showGlassMenu,GlassMenuButton,GlassMenuItem,GlassMenuDivider,GlassMenuEntry
images: menu-open|Открытое меню, controls|Страница контролов
videos: morph-demo|Лист и меню вырастают из кнопок
---
## Что это

Панель растёт из якоря с пружиной и закрывается тапом вне или выбором пункта. С `origin` меню вырастает из стекла самой кнопки (кнопка скрыта, пока меню открыто), как на нативных glass-кнопках.

## Пример

```dart
GlassMenuButton(
  entries: [
    GlassMenuItem(label: 'Копировать', leading: RavelIcon(RavelIconKind.pencil), onSelected: copy),
    GlassMenuItem(label: 'Выбрано', checked: true, onSelected: () {}),
    const GlassMenuDivider(),
    GlassMenuItem(label: 'Удалить', destructive: true, onSelected: remove),
  ],
  builder: (context, open) => GlassCircleButton(icon: RavelIcon(RavelIconKind.menu), onPressed: open),
)
```

### Морф из кнопки

```dart
final origin = GlassSheetOriginController();
GlassSheetOrigin(
  controller: origin,
  child: GlassCircleButton(
    icon: RavelIcon(RavelIconKind.menu),
    onPressed: () => showGlassMenu(context, origin: origin, entries: entries),
  ),
)
```

С `GlassMenuButton` как `onLongPress` получается контекстное меню.
