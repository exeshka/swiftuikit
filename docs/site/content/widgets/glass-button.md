---
title: GlassButton
group: Стекло и кнопки
order: 4
summary: Кнопка iOS 26: стили glass, glassProminent, bordered, borderedProminent, borderless, plain и 5 размеров.
api: GlassButton,GlassButtonStyle,GlassButtonSize
images: buttons|Все стили и размеры
---
## Что это

Аналог SwiftUI `Button` с `.buttonStyle(...)`, `.controlSize(...)` и `.buttonBorderShape(...)`; размеры и цвета измерены на iOS 26.5. Стеклянные стили — это `LiquidGlass` с нативным откликом на нажатие.

## Когда использовать

Любые текстовые/иконочные действия: основная кнопка, вторичная, на всю ширину, деструктивная.

## Пример

```dart
GlassButton(
  label: 'Продолжить',
  style: GlassButtonStyle.glassProminent,
  size: GlassButtonSize.large,
  expand: true,
  onPressed: () {},
)

GlassButton.circle(icon: RavelIcon(RavelIconKind.search), onPressed: () {})
GlassButton(label: 'Удалить', destructive: true, style: GlassButtonStyle.bordered, onPressed: () {})
```

`onPressed: null` — выключенная кнопка. `glassProminent` в покое — плоская тонированная заливка, под пальцем превращается в стекло и плавно возвращается.
