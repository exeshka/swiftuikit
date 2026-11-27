---
title: Стекло и производительность
order: 3
summary: Как устроен LiquidGlass, почему одна плита — это один проход по фону, и как держать 60/120 fps с LiquidGlassGroup.
keywords: liquid glass performance shader группа fps
images: liquid|Стекло над насыщенным фоном, liquid-morph|Слияние пластин в группе
---
## Цена

Каждая `LiquidGlass` плита — один офскрин-проход: размытие фона движком + шейдер (преломление на ободке, дисперсия, блик, тень). Это ~0.2 мс на плиту, поэтому стекло — для нескольких заметных элементов (кнопки бара, пилюля, плавающий тулбар), а не для строк списка.

## Правила

1. **Группируйте.** Плиты в `LiquidGlassGroup` делят один проход (до 8). `ChromeBar`, `LargeTitleHeader`, `CollapsibleBar` уже оборачивают бар в группу — кнопки бара стоят как одна.
2. **Повторяющееся — плоским.** У кнопок в списке ставьте `liquid: false`: плоская плита рисуется одним примитивом и сохраняет отклик на нажатие.
3. **Не оборачивайте в `Opacity`.** Плита не должна быть внутри собственного офскрин-слоя; для прозрачности есть `LiquidGlass.opacity`, для появления — `LiquidGlassPresence`.
4. **Тяжёлое поддерево** под непрозрачным слоем можно «усыпить» через `LiquidGlassSuspend(suspended: true)`.
5. **`highQuality`** добавляет префильтр размытия для тонких деталей под стеклом — только где это видно.

## Слияние плит

`LiquidGlassGroup(spacing: 40)`: плиты ближе 40 pt сливаются в одну форму, пока одна из них нажата, появляется или исчезает — как `GlassEffectContainer(spacing:)` в SwiftUI.

```dart
LiquidGlassGroup(
  spacing: 40,
  child: Row(children: [
    LiquidGlass(width: 60, height: 60, interactive: true, child: Icon(Icons.add)),
    LiquidGlass(width: 60, height: 60, interactive: true, child: Icon(Icons.edit)),
  ]),
)
```

## Появление и исчезновение

```dart
LiquidGlassPresence(
  show: visible,
  builder: (context, presence) => LiquidGlass(presence: presence, width: 80, height: 80, child: const SizedBox()),
)
```

## Если шейдеров нет

Web, `flutter test` и устройства без Impeller получают плоскую `GlassSurface` — внешний вид деградирует, а поведение остаётся прежним.
