---
title: GlassTextField
group: Формы и контролы
order: 5
summary: Поле ввода на стеклянной плите, как композер iOS 26: растёт вместе с текстом.
api: GlassTextField
images: input|Композер на стекле
---
## Что это

Одна строка — капсула 44 pt; при росте текста плита растягивается до `maxLines`. `leading`/`trailing` — кнопки внутри плиты (плюс, микрофон, отправка); `plainFill` — без стекла, плоский контейнер.

```dart
GlassTextField(
  hintText: 'Message',
  maxLines: 6,
  leading: GlassCircleButton(icon: RavelIcon(RavelIconKind.plus), onPressed: () {}),
  trailing: GlassCircleButton(icon: RavelIcon(RavelIconKind.check), tint: Colors.blue, onPressed: send),
  onSubmitted: (_) => send(),
)
```
