---
title: GlassTabBar
group: Бары и навигация
order: 4
summary: Плавающий таб-бар iOS 26: компактная стеклянная капсула с иконкой над подписью.
api: GlassTabBar,GlassTab
images: coffee|Таб-бар в приложении,inbox|Таб-бар и страницы
---
## Что это

Измерен на нативном `TabView`: капсула 58 pt высотой, 90 pt на вкладку, по центру. Выбранная вкладка окрашена акцентом и лежит на собственной капсуле; при нажатии — стеклянная линза, перетаскиваемая между вкладками.

```dart
GlassTabBar(
  selectedIndex: index,
  onSelected: (i) => setState(() => index = i),
  tabs: [
    GlassTab(icon: RavelIcon(RavelIconKind.chat), label: 'Chats'),
    GlassTab(icon: RavelIcon(RavelIconKind.search), label: 'Search'),
    GlassTab(icon: RavelIcon(RavelIconKind.tasks), label: 'Tasks'),
  ],
)
```

Кладите в `SwiftUiShell.bottomBar` или `ChromeScaffold.bottomBar`.
