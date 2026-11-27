---
title: CollapsibleBar
group: Бары и навигация
order: 3
summary: Бар со сворачиваемой секцией (поиск, баннер) и постоянным футером (полоса вкладок).
api: CollapsibleBar,SectionCollapse
images: telegram|Поиск, папки, пейджер
---
## Что это

`bar` всегда виден, `section` сворачивается при скролле, `footer` остаётся прикреплённым под баром. С `initiallyCollapsed: true` секция скрыта и появляется при протягивании списка вниз (как поиск в мессенджерах). `SectionProgress` отдаёт степень раскрытия вложенным виджетам.

```dart
CollapsibleBar(
  bar: TitleBar(title: 'Chats'),
  section: const GlassSearchBar(fadeWithSection: true),
  sectionHeight: 52,
  initiallyCollapsed: true,
  footer: GlassScrollSegments<int>(value: 0, onChanged: (_) {}, segments: const [GlassSegment(value: 0, label: 'All')]),
  footerHeight: 44,
)
```
