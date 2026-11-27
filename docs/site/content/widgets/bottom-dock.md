---
title: BottomDock
group: Бары и навигация
order: 5
summary: Низ страницы в раскладке iOS 26: плавающие пузыри, композер и таб-бар, сложенные в стопку.
api: BottomDock
images: input|Композер и кнопки над ним
---
## Что это

Для `ChromeScaffold.bottomBar`: три слота — `floating` (подсказки, «к концу чата»), `composer` (поле ввода), `navBar` (таб-бар). `hideNavBarWithKeyboard` уводит таб-бар при клавиатуре.

```dart
bottomBar: BottomDock(
  floating: GlassCircleButton(icon: RavelIcon(RavelIconKind.chevronRight), onPressed: () {}),
  composer: const GlassTextField(hintText: 'Message'),
  navBar: GlassTabBar(selectedIndex: 0, onSelected: (_) {}, tabs: tabs),
)
```
