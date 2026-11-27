---
title: GlassSwitch
group: Формы и контролы
order: 1
summary: Переключатель iOS 26: при нажатии ползунок превращается в стеклянную пилюлю.
api: GlassSwitch
images: switch|Три переключателя,controls|На странице контролов
---
## Что это

Измерен на нативном `Toggle`: 63×28 pt дорожка, 37×24 pt ползунок. Тащится пальцем, при удержании — чистое стекло; зелёный как в системе (#30D158 в тёмной теме).

```dart
GlassSwitch(value: on, onChanged: (v) => setState(() => on = v))

// c запросом: пока Future выполняется, в ползунке спиннер, переключатель заблокирован
GlassSwitch(value: on, onChangedAsync: (next) async { await api.save(next); setState(() => on = next); })
```
