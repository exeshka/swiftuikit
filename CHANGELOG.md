## 0.1.0

### New features
- **SwiftModalRoute** — modal page route with dynamic height (sizes to content), drag-to-dismiss with scroll handoff, background dimming, rounded top corners
- **SwiftPageRoute** — full-screen page route with iOS-style swipe-back gesture, parallax/scale transitions
- **SwiftSheetRoute** — modal bottom sheet route with drag-to-dismiss and scroll handoff
- **SwiftScrollSheetRoute** — scroll-driven sheet with snap stops, `SwiftScrollSheetController` for programmatic control
- **SwiftPageViewAnimation** — `PageView` with parallax/scale effects, overscroll bounce with rounded corners
- Auto route adapters: `SwiftPageAutoRoute`, `SwiftSheetAutoRoute`, `SwiftScrollSheetAutoRoute`, `SwiftModalAutoRoute`
- GoRouter/Navigator 2.0 adapters: `SwiftPage`, `SwiftSheetPage`, `SwiftScrollSheetPage`, `SwiftModalPage`
- **ScreenRadiusService** — reads physical device screen corner radius for authentic iOS clipping
- Header widgets: `SwiftHeader`, `SwiftSliverHeader`, `SwiftScaffold`, `SwiftPinnedHeaderChrome`
- Toolbar widgets: `ToolbarButton`, `ToolbarItemGroup`
- Composables: `MorphTransitionSlots`, `MotionBlurRow`
- Primitives: `MorphSurface`, `MorphGlow`, `MorphStretch`, `MotionBlur`

### Fixes
- `SwiftPageRoute` no longer animates background (scale/translate) when `SwiftModalRoute` is pushed on top
- `SwiftModalRoute` pop no longer causes background page to jerk
- `PageView` overscroll bounce now shows rounded corners on edge pages
- `PageView` uses `BouncingScrollPhysics` by default for consistent bounce on all platforms

### Breaking changes
- Migrated routing from `lib/src/widgets/page_view/` to `lib/src/routing/`
- Migrated composables from `lib/src/core/widgets/` to `lib/src/composables/` and `lib/src/primitives/`
- Removed legacy widget files: `material_glow`, `material_stretch`, `morph_id`, `swift_material`, `swift_auto_routes`, `swift_page_transitions`, `swift_page_view_animation`, `swift_scroll_sheet_route`, `swift_sheet_route` (old paths)
