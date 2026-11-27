---
title: GlassSelectionToolbar
group: Оверлеи: листы, диалоги, меню
order: 4
summary: Меню cut/copy/paste над выделением текста на стеклянной капсуле.
api: GlassSelectionToolbar
images: input|Поле ввода
---
## Что это

Замена системного меню выделения. Используется как `contextMenuBuilder` текстового поля:

```dart
TextField(
  contextMenuBuilder: (context, state) => GlassSelectionToolbar.editableText(state),
)
```
