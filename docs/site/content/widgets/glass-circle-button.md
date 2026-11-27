---
title: GlassCircleButton и кнопки баров
group: Стекло и кнопки
order: 5
summary: Круглая стеклянная кнопка для баров, а также назад, аватар и плавающая пилюля.
api: GlassCircleButton,GlassBackButton,GlassAvatarButton,FloatingPillButton
images: page|Кнопки в баре,nav-bars|Назад и действия
---
## Что это

- `GlassCircleButton` — круглая кнопка (поиск, меню, плюс). `tint` — акцентная, `liquid: false` — плоская для списков.
- `GlassBackButton` — шеврон «назад»; без `onPressed` делает pop.
- `GlassAvatarButton` — круг с инициалами (аккаунт).
- `FloatingPillButton` — белая плавающая пилюля с иконкой и подписью («New chat»).

## Пример

```dart
Row(children: [
  const GlassBackButton(),
  const Spacer(),
  GlassCircleButton(icon: RavelIcon(RavelIconKind.menu), semanticLabel: 'Menu', onPressed: () {}),
  GlassCircleButton(icon: RavelIcon(RavelIconKind.plus), tint: Colors.blue, onPressed: () {}),
  GlassAvatarButton(initials: 'AB', onPressed: () {}),
])
```
