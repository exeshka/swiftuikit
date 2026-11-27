---
title: Утилиты
group: Темы и утилиты
order: 3
summary: Прогрев шейдеров, заморозка страницы под переходом, радиус экрана, анимация числа, адаптивное окно.
api: RavelWarmUp,FreezeUnderRoute,ScreenRadiusService,SwiftText,SwiftUiWindowInfo,SwiftUiWindowScope,SnappingScrollPhysics
images: components|Компоненты
---
## Что это

- `preloadRavelUiKit()` — загрузить все шейдеры до `runApp`.
- `RavelWarmUp` — компилирует GPU-пайплайны под первыми кадрами (включено в `SwiftUiApp`).
- `FreezeUnderRoute` — заменяет страницу её снимком, пока над ней идёт переход: каждый `BackdropFilter` стоит ~1 мс на кадре.
- `ScreenRadiusService` — физический радиус скругления экрана (для листов).
- `SwiftText` — посимвольная анимация цифр, как `.contentTransition(.numericText())`.
- `SwiftUiWindowInfo` / `SwiftUiWindowScope` — размер окна, size classes (compact/regular), зарезервированные области (сгиб складного).
- `SnappingScrollPhysics` — физика с пружинным доводом к позициям.

```dart
SwiftText('${count}', style: const TextStyle(fontSize: 48), duration: const Duration(milliseconds: 400))
```
