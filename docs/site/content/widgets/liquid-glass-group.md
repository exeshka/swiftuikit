---
title: LiquidGlassGroup и Presence
group: Стекло и кнопки
order: 2
summary: Общий проход по фону для нескольких плит, слияние плит в одну форму и анимированное появление.
api: LiquidGlassGroup,LiquidGlassPresence,LiquidGlassSuspend
images: liquid-morph|Слияние пластин,liquid-grid|Плиты в одной группе
---
## Что это

- `LiquidGlassGroup` — одна пара «размытие + шейдер» на все плиты внутри (до 8). С `spacing` плиты, оказавшиеся ближе, плавно сливаются в одну форму (аналог `GlassEffectContainer(spacing:)`).
- `LiquidGlassPresence` — анимирует появление/исчезновение плиты (`presence` 0→1).
- `LiquidGlassSuspend` — рисует стекло плоским, пока `suspended: true` (поддерево живо, но GPU на него не тратим).

## Пример

```dart
LiquidGlassGroup(
  spacing: 40,
  child: Row(mainAxisSize: MainAxisSize.min, children: [
    LiquidGlassPresence(
      show: showSecond,
      builder: (context, p) => LiquidGlass(presence: p, interactive: true, width: 64, height: 64, child: const Icon(Icons.edit)),
    ),
    LiquidGlass(interactive: true, width: 64, height: 64, child: const Icon(Icons.add)),
  ]),
)
```
