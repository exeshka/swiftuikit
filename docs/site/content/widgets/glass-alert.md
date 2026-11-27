---
title: showGlassAlert и диалоги
group: Оверлеи: листы, диалоги, меню
order: 2
summary: Алерт и confirmationDialog iOS 26 на жидком стекле; возвращают value нажатой кнопки.
api: showGlassAlert,showGlassActionDialog,GlassAlertAction,GlassAlertField,GlassAlertRole,GlassDialogRoute
images: alert-open|Алерт,sheets|Страница примера
---
## Что это

- `showGlassAlert<T>` — карточка по центру: заголовок и сообщение слева, кнопки (две рядом, больше — столбиком). Опционально текстовые поля `GlassAlertField`.
- `showGlassActionDialog<T>` — `confirmationDialog`: узкая карточка со столбцом кнопок; с `origin` вырастает рядом с кнопкой, иначе внизу экрана. Кнопка с ролью `cancel` не рисуется — закрытие тапом вне карточки возвращает её value.

## Пример

```dart
final ok = await showGlassAlert<bool>(
  context,
  title: 'Удалить файл?',
  message: 'Это нельзя отменить.',
  actions: const [
    GlassAlertAction(label: 'Удалить', role: GlassAlertRole.destructive, value: true),
    GlassAlertAction(label: 'Отмена', role: GlassAlertRole.cancel, value: false),
  ],
);

final name = TextEditingController();
await showGlassAlert<void>(context, title: 'Имя', fields: [GlassAlertField(controller: name, placeholder: 'Name')],
  actions: const [GlassAlertAction(label: 'OK', value: null)]);
```
