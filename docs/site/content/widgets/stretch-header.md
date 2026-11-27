---
title: StretchHeader
group: Списки и заголовки
order: 5
summary: Шапка профиля, растущая при протягивании списка вниз: аватар → фото во весь экран.
api: StretchHeader,MorphBox
images: profile|Профиль
---
## Что это

`builder` получает `StretchInfo` (степень раскрытия), `MorphBox` двигает прямоугольник и радиус между двумя состояниями. Есть двухступенчатый pull (`onOverpull`) и хаптика.

```dart
StretchHeader(
  collapsedHeight: 220,
  expandedHeight: 640,
  builder: (context, info) => Stack(children: [
    MorphBox(from: avatarRect, to: fullRect, t: info.t, child: Image.asset('assets/me.jpg', fit: BoxFit.cover)),
  ]),
)
```
