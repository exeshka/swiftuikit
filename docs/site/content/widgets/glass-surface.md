---
title: GlassSurface
group: Стекло и кнопки
order: 3
summary: Плита-подложка: настоящее стекло с шейдером или намеренно плоская заливка без шейдера.
api: GlassSurface
images: components|Компоненты поверх яркого фона
---
## Что это

Низкоуровневая плита для своих контролов. С шейдером — настоящее стекло; с `liquid: false` (и там, где шейдеров нет) — одна полупрозрачная заливка без ободка и теней: самая дешёвая отрисовка, ~0.45 мс экономии на кнопку.

## Пример

```dart
GlassSurface(
  shape: const StadiumBorder(),
  width: 200,
  height: 48,
  liquid: false,                // плоская, для повторяющихся элементов
  alignment: Alignment.center,
  child: const Text('Flat plate'),
)
```

`backdropBlur: true` добавит размытие фона (отдельный проход — не злоупотребляйте).
