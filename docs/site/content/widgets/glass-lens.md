---
title: GlassLens и ContentLens
group: Стекло и кнопки
order: 6
summary: Линза «пузыря» под пальцем и краевая линза поверх собственного контента.
api: GlassLens,ContentLens
images: switch|Линза у переключателя
---
## Что это

- `GlassLens` — стеклянный «пузырь», в который превращается ползунок при нажатии (switch, segmented, slider). Обычно используется самими контролами.
- `ContentLens` — искажение края **собственного** контента: то, что у ободка, подтягивается из глубины по нормали. Нужен для эффекта линзы поверх картинки/виджета без фонового размытия.

```dart
ContentLens(
  radii: BorderRadius.circular(28),
  bezel: 18,
  strength: 1,
  child: Image.asset('assets/photo.jpg', width: 200, height: 120, fit: BoxFit.cover),
)
```
