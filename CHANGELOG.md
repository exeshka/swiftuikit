## 0.1.3

- Re-publish with hosted `screen_corner_radius` dependency (pub.dev compatible)
### Fixes
- Fixed `SwiftSheetRoute` stacking animation in go_router: previous sheet now correctly animates UP (not DOWN) when a new sheet is pushed on top
- `delegateTransition` now checks both `SwiftSheetScope` and `CupertinoSheetScope` for parent sheet detection

### Example
- Added full go_router example (`example_go_router/`) mirroring the auto_route demo: SwiftPage, SwiftSheet variants, and Hero Flow with nested sheet stacking

## 0.1.2

### Fixes
- `animateBackground: false` now correctly disables background animation when pushing a `SwiftSheetRoute`
- Custom `sheetRadius` / `sheetBorderRadius` now applies to the background page's corner radius during sheet transitions

### API
- Marked experimental route types with `@experimental`: `SwiftScrollSheetRoute`, `SwiftScrollSheetController`, `SwiftSheetDetent`, `SwiftScrollSheetDragTarget`, `SwiftModalRoute`, `SwiftPageViewAnimation`, `SwiftStepSheet`, `SwiftModalScaffold`, and their go_router / auto_route adapters

### Documentation
- Added README with quick start, setup guide, route type reference, and property tables for `SwiftPage` and `SwiftSheet`
- Added roadmap section

### Example
- Added demo screens: `SwiftPage`, `SwiftPage` (no swipe), `SwiftSheet`, `SwiftSheet` (no background animation), `SwiftSheet` (no drag), `SwiftSheet` (custom radius 16)

## 0.1.1

### Fixes
- `SwiftSheetRoute` pop no longer causes background page to animate/jerk
- `SwiftPageRoute` background stays stationary during both modal and sheet transitions

### Example
- Added nested routes demo inside `SwiftSheetRoute` (sheet with internal page navigation)

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
