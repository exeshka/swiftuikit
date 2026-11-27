---
title: ProgressiveBlur и ChromeStyle
group: Темы и утилиты
order: 2
summary: Прогрессивный блюр (сильнее у края) и стили краевого эффекта под барами.
api: ProgressiveBlur,ChromeStyle,ChromeStyleScope,ChromeController
images: nav-bars|Эффект под баром
---
## Что это

- `ProgressiveBlur` — размывает всё нарисованное **позади** себя, сильнее у `edge`, до нуля на противоположной стороне; поверх мягкая тонировка.
- `ChromeStyle` — как контент уходит под бары: `soft`, `variableBlur`, `fade`, `blur`, `hard`, `solid`, `none`, `custom`.
- `ChromeStyleScope.both(style:, child:)` — меняет стиль всех скаффолдов ниже (переключатель в настройках, A/B).

```dart
ChromeStyleScope.both(style: const ChromeStyle.fade(), child: const MyApp())
```
