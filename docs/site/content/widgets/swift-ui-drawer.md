---
title: SwiftUiDrawer
group: Каркас приложения и роутинг
order: 4
summary: Боковое меню под приложением, страница сдвигается вправо (как в ChatGPT и Claude).
api: SwiftUiDrawer
images: chatgpt|ChatGPT,claude|Claude
---
## Что это

Свайп от левого края двигает страницу вместе с пальцем, страница скругляется и затемняется. `menuFraction` — ширина меню (доля экрана), `cornerRadius` — радиус страницы (лучше радиус экрана).

```dart
SwiftUiDrawer(
  menu: const MenuPanel(),
  body: const ChatPage(),
  menuFraction: 0.8,
)
```
