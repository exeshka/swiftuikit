## Unreleased

### UI kit

- `GlassSheet` with `origin`: it opens with the same droplet morph as the glass menu (the control collapses into a droplet that grows into the sheet with a spring, its
  content squeezed and blurred, sharpening as it grows). Opening takes 460 ms. Closing plays the same path back (440 ms): the sheet collapses into a droplet, the droplet flows into the control. The droplet is about 3x the control and the control rides inside it (seen through the glass), as on a native toolbar button -> sheet (measured frame by frame).
- `LiquidGlass.cornerScaleTR` / `cornerScaleBR` (and `uMelt.zw` in the shader): the top-right / bottom-right corner radius relative to the left ones, for plates that are not symmetric. The menu morph uses them (the native blob's top-right corner is tighter than the top-left one).
- Menu morph (`showGlassMenu(origin:)`) now follows the measured native timeline (tools/native_morph_ref/MORPH_SPEC.md): one glass plate whose four edges have their own damped springs (the menu overshoots, its top dips and comes back), the control's picture fades in 55 ms, the rows are enlarged and blurred and sharpen from 100 ms, closing has its own springs and timings (opening 700 ms, closing 450 ms).
- Menus and sheets with `origin`: the control no longer vanishes. A picture of it (`GlassSheetOriginController.capture`) rides inside the droplet, clipped to its shape and blurring out as the menu / sheet grows, and comes back with it, as the whole toolbar group does on native. The control's plate and the menu's are two plates of one `LiquidGlassGroup`, so the shader draws their smooth union (the droplet comes out of the button that was touched, `GlassSheetOriginController.lastTouch`) (the way `GlassEffectContainer` does) and the droplet pulls out of the control instead of a rectangle morphing. A menu closes as its opening played back (the same blob and motion curve, 380 ms), as measured on the native one.
- Menus (`showGlassMenu`) answer a touch like dialogs: the panel is a glass plate that grows, stretches under the finger and lights up locally; the row under the finger is
  highlighted and follows it, the one the finger is lifted over is chosen.
- `showGlassMenu` / `GlassMenuButton` take `origin` (a `GlassSheetOriginController` on the control or on the whole group of buttons): the menu grows out of the
  control's glass as a native one does (fitted frame by frame to a slowed simulator recording): the glass collapses into a droplet, the droplet moves and grows into the
  menu with a spring and a little overshoot, its rows are in it from the start, shrunk and blurred, and sharpen as it grows. Icons are now leading, as in iOS 26.
  `GlassSheetOriginController.hideForPresentation()` / `showAfterPresentation()` are public for such presenters.
- Dialogs: the preferred action (`GlassAlertRole.preferred`) is a capsule filled with the tint and white text, as in a native alert; the whole card has the glass touch
  response (grows on a press, stretches under a drag, lights up locally: `LiquidGlass.glowSigma`/`glowStrength`); the button under the finger is highlighted and follows it
  (press one, drag to another, lift to activate that one); closing takes 240 ms like native; a title without a message is centred.
- `LiquidGlass.opacity`: fades the whole plate (glass, shadow, flat fill, child) inside the glass pass. An `Opacity` widget around glass renders it
  offscreen without a backdrop, so the plate vanished; this keeps the backdrop live. Dialog cards (`showGlassAlert`/`showGlassActionDialog`) use it.
  Under a plain `Opacity`/`FadeTransition` ancestor a plate no longer vanishes: it draws the flat plate while the fade runs and cross-fades back to glass
  in 160 ms once it is over.
- `GlassSheet`: the iOS 26 resizable `.sheet`. At a partial detent (`GlassSheetDetent.medium`, `.fraction`, `.height`) it is a floating card of liquid
  glass inset from the screen edges, with the drag indicator; dragged up it becomes an opaque full-width page at `.large`. The page behind
  is not scaled, only dimmed in proportion to the height of the sheet. Content scroll hands off to the sheet. Three ways to use it:
  `showGlassSheet(context, ...)`, `GlassSheetRoute` (router adapters `GlassSheetAutoRoute` for auto_route and `GlassSheetPage` for
  go_router: the page widget is the content) and `GlassSheetPresenter` (inside a page, `isPresented` driven, with `modal: false` the page
  stays usable). `GlassSheetController` moves it between detents. Native reference app in `tools/native_sheet_detents_ref`.
  The sheet can grow out of a glass control (`GlassSheetOrigin` around the control, `origin:` on `showGlassSheet` / `GlassSheetRoute` /
  `GlassSheetPresenter`): the card starts as the control's capsule or circle of liquid glass, grows into the sheet with its content scaled
  in, and shrinks back on close, no `Hero`: the sheet's own geometry is animated. Release after a drag settles with a spring that keeps
  the velocity of the finger. Text tracking of iOS (`iosTracking`) is applied to the kit's text styles; `GlassButtonSize.toolbar` added.
- `showGlassAlert` / `showGlassActionDialog` (`GlassDialogRoute`): the iOS 26 `.alert` and `.confirmationDialog`. A card of liquid glass (320 pt, or
  240 pt for the action dialog, radius 42) with a left-aligned title and message and glass capsule buttons: two share a row (cancel first),
  more stack (cancel last), `GlassAlertRole.destructive` is red, `.preferred` semibold, `GlassAlertField` adds a text field. The alert
  opens from 1.12x while it fades in and fades out, the page is dimmed by 20 %. The action dialog opens next to a `GlassSheetOrigin` control
  or at the bottom, hides its cancel button and closes with a tap outside. Metrics measured on the native reference in
  `tools/native_dialogs_ref`.

- Merged the `ravel_ui_kit` package into swiftuikit: the iOS 26 style UI kit (progressive-blur `ChromeScaffold`, liquid glass
  shader plates, glass buttons / tab bar / segmented / slider / menu / text field, themed through `SwiftUiThemeData`) is now exported
  from `package:swiftuikit/swiftuikit.dart`. Call `preloadRavelUiKit()` once before `runApp`.
- Shaders live in `shaders/` and are bundled with the package.
- Liquid glass inside a page that SwiftSheet scales (an offscreen `ImageFilterLayer`) now stays in place instead of drifting down
  by the slide.
- Liquid glass groups melt only the plates that really interact (the pressed one and its neighbours within the spacing); the other
  plates of a bar keep their own shape.
- The kit example app moved to `example_ui_kit/`, its tests to `test/ui_kit/`, native reference tools to `tools/`.

### Fixes

- Kept interactive page pops input-locked and linear until their settle animation completes
- Restored native interactive `Hero` flights through `transitionOnUserGestures`
- Prevented rapid follow-up swipes from interrupting a page that is still settling
- Made post-gesture settling proportional to the remaining distance so input
  unlocks as soon as the native-speed transition finishes
- Added iOS 26-style full-screen gesture arbitration: unclaimed content swipes
  navigate back while horizontal scrollables and drag controls keep their gestures
- Kept a prioritized leading-edge swipe available over horizontal page content
- Matched the previous page's animated corner shape to the foreground page
  throughout interactive push, pop, and settle transitions
- Enabled regular and `transitionOnUserGestures` Hero flights for SwiftSheet
  routes, aligned their overlay coordinates with the sheet's top gap, and kept
  the revealed route interactive while dismissal finishes
- Made rapid SwiftSheet Hero reversals safe when a dismiss gesture interrupts
  an active push or immediately re-grabs a canceled settle animation
- Coordinated overlapping route-drag and scroll-handoff gesture sessions so
  they cannot restart the same in-flight SwiftSheet Hero transition
- Delayed SwiftSheet's interactive Hero flight until a scroll gesture actually
  hands off to sheet dismissal, so normal list scrolling cannot pin the Hero in
  the overlay
- Restored native Cupertino sheet ancestry so automatic
  CupertinoNavigationBar Heroes do not animate across the modal boundary

## 0.2.1

### Documentation

- Fixed screenshots and the animated `SwiftText` preview not rendering on pub.dev by using absolute asset URLs

## 0.2.0

### New features

- Added `SwiftText`, a glyph-level text transition with automatic numeric direction, rich text support, blur, and rapid retargeting

### Breaking changes

- Raised the minimum supported Flutter version to 3.22.0

### Documentation

- Rebuilt the README as a complete component catalog with setup and usage examples
- Added an optimized animated `SwiftText` preview

### Example

- Added a responsive English music player showcasing `SwiftText` across track metadata, counters, and navigation labels

## 0.1.5

### New features
- Added `SwiftZoomHero`, `SwiftZoomRoute`, `SwiftZoomPage`, and `SwiftZoomAutoRoute` with dynamic destination IDs and interactive drag-to-dismiss

### Breaking changes
- Removed the legacy `SwiftInteractiveZoomRoute`, `SwiftInteractiveZoomSource`, `SwiftInteractiveZoomBackground`, `SwiftInteractiveZoomPage`, and `SwiftInteractiveZoomAutoRoute` APIs

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
