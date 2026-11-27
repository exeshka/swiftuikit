---
title: GlassSlider и GlassStepper
group: Формы и контролы
order: 2
summary: Слайдер с тонкой дорожкой и «набухающим» ползунком и степпер − / +.
api: GlassSlider,GlassStepper
images: controls|Слайдер и степпер
---
## Что это

- `GlassSlider` — тонкая дорожка и белая капсула-ползунок на пружине; `divisions` даёт шаги.
- `GlassStepper` — пилюля с «−» и «+», каждая половина подсвечивается и повторяет нажатие при удержании.

```dart
GlassSlider(value: v, min: 0, max: 100, divisions: 20, onChanged: (x) => setState(() => v = x))
GlassStepper(onIncrement: () => setState(() => n++), onDecrement: () => setState(() => n--), canDecrement: n > 0)
```
