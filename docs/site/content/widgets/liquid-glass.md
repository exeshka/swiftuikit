---
title: LiquidGlass
group: Стекло и кнопки
order: 1
summary: Плита «жидкого стекла» iOS 26: преломление на ободке, размытие, дисперсия, блик — одним шейдером.
api: LiquidGlass
images: liquid|Стекло над фоном, liquid-grid|Плиты на сетке
keywords: shader refraction стекло шейдер
---
## Что это

Базовый строительный блок кита. Фон под плитой преломляется на ободке выпуклой «подушки» (в середине спокойно), слегка размывается, раскладывается по каналам, подкрашивается и подсвечивается бликом. Всё — один фрагментный шейдер и один проход по фону.

## Когда использовать

Для нескольких заметных элементов: кнопки баров, пилюля, плавающий тулбар, лист. Для строк списка — `GlassSurface(liquid: false)` или `flat: true`. Группы плит — в `LiquidGlassGroup` (см. гайд «Стекло и производительность»).

## Минимальный пример

```dart
LiquidGlass(
  width: 160,
  height: 56,
  interactive: true,                 // пружина, подсветка под пальцем, «резинка»
  child: const Center(child: Text('Glass')),
)
```

## Варианты

```dart
LiquidGlass(clear: true, width: 120, height: 120, cornerRadius: 36, child: const SizedBox()); // Glass.clear
LiquidGlass(tint: const Color(0x660A84FF), width: 140, height: 52, child: const SizedBox()); // тонированное
LiquidGlass(flat: true, interactive: true, width: 140, height: 52, child: const SizedBox()); // без шейдера, тот же отклик
```

`opacity` — прозрачность всей плиты вместо `Opacity` (который сломал бы шейдер); `presence` (0..1) — рост из точки / схлопывание, см. `LiquidGlassPresence`.
