---
title: TitleBar, LargeTitleHeader
group: Бары и навигация
order: 2
summary: Заголовки баров: простой TitleBar и крупный iOS-26 LargeTitleHeader (большой/малый/с подзаголовком).
api: TitleBar,LargeTitleHeader,SwiftUiBackButton
images: nav-bars|Варианты заголовка
---
## Что это

- `LargeTitleHeader` — 44 pt бар с кнопками и крупным заголовком 34 pt (опционально с подзаголовком); сворачивается при скролле. `style: NavTitleStyle` выбирает large/inline.
- `TitleBar` — простой бар: заголовок слева и действия справа, для `ChromeBar`.
- `SwiftUiBackButton` — кнопка «назад» для кастомного бара: показывается, когда у маршрута есть куда вернуться.

```dart
LargeTitleHeader(
  title: 'Photos',
  subtitle: '1 248 items',
  trailing: [GlassCircleButton(icon: RavelIcon(RavelIconKind.plus), onPressed: () {})],
)
```

Кнопка назад подставляется сама (`automaticallyImplyLeading`).
