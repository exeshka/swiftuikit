---
title: SwiftUiPageSwitcher
group: Каркас приложения и роутинг
order: 3
summary: Переключение страниц с анимацией (без офскрин-слоя): сдвиг, затухание, ничего.
api: SwiftUiPageSwitcher
images: switcher|Переключатель страниц
---
## Что это

Показывает одну из `children` и анимирует смену: `SwiftUiSwitchTransition` (в т.ч. `fadeThrough`). Ни одна из них не использует `Opacity`-слой — блюр и стекло продолжают работать во время перехода. Страницы сохраняют позицию скролла, `lazy` строит страницу при первом показе.

```dart
SwiftUiPageSwitcher(index: tab, transition: SwiftUiSwitchTransition.fadeThrough, children: pages)
```
