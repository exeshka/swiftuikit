# AGENTS.md — swiftuikit

## What this is

Flutter package (not an app) providing iOS-style page transitions, sheet routes, scroll sheets, and modal routes. Version 0.1.1, `publish_to: none`. Two routing adapters: auto_route and go_router/Navigator 2.0.

## Commands

```bash
# Analyze (only 2 known warnings: prefer_initializing_formals, unused_element)
flutter analyze

# Run example app
cd example && flutter run

# Codegen for example app (auto_route)
cd example && dart run build_runner build --delete-conflicting-outputs
```

No tests, no CI, no Makefile. `flutter analyze` is the only verification step.

## Architecture

```
lib/
  swiftuikit.dart              # barrel export (also re-exports inspire_blur)
  src/
    routing/
      page_transitions.dart    # Core: SwiftPageRoute, SwiftPageTransitions, swipe-back gesture
      sheet_route.dart         # SwiftSheetRoute — drag-to-dismiss bottom sheet
      scroll_sheet_route.dart  # SwiftScrollSheetRoute — scroll-driven sheet with snap detents
      modal_route.dart         # SwiftModalRoute — dynamic-height modal
      page_view_animation.dart # SwiftPageViewAnimation — parallax/scale PageView
    routing_adapters/
      go_router_adapter.dart   # SwiftPage, SwiftSheetPage, SwiftScrollSheetPage, SwiftModalPage
      auto_route_adapter.dart  # SwiftPageAutoRoute, SwiftSheetAutoRoute, etc.
    services/
      screen_radius_service.dart # ScreenRadiusService singleton — device corner radius
    widgets/
      swift_step_sheet.dart    # Multi-step sheet container
      swift_modal_scaffold.dart # Scaffold for modal scroll sheets
    core/                      # empty
```

## Critical setup requirement

`ScreenRadiusService.instance.initialize()` must be called in `main()` before `runApp()`. It fetches physical device corner radius via platform channel. Without it, screen-radius clipping defaults to `BorderRadius.zero`.

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ScreenRadiusService.instance.initialize();
  runApp(App());
}
```

## Key dependencies

- `auto_route` — routing framework, requires `build_runner` + `auto_route_generator` for codegen
- `inspire_blur` — re-exported from barrel, part of public API
- `screen_corner_radius` — **git dependency** (custom fork at `github.com/exeshka/screen_corner_radius`), reads physical device screen corners
- `flutter_shaders` — shader support (currently commented out in pubspec)
- `equatable`, `meta` — utilities

## Codegen

Example app uses `auto_route` with `@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')`. Generated file: `example/lib/src/core/router/router.gr.dart`. Run codegen from the `example/` directory, not root.

## Routing convention

Routes use two naming patterns:
- **auto_route**: `SwiftPageAutoRoute`, `SwiftSheetAutoRoute`, `SwiftScrollSheetAutoRoute`, `SwiftModalAutoRoute`
- **go_router**: `SwiftPage`, `SwiftSheetPage`, `SwiftScrollSheetPage`, `SwiftModalPage`

Both wrap the same core route classes from `lib/src/routing/`. `SwiftPage` and `SwiftPageAutoRoute` accept `canOnlySwipeFromEdge` (default `false`) to restrict swipe detection to the screen edge.

## Known issues

- `_SwiftBackGestureController` uses `Curves.fastEaseInToSlowEaseOut` with dynamic timing: forward animation `lerpDouble(800, 0, controller.value)` capped at 300ms, back animation `lerpDouble(0, 800, controller.value)`
- Gesture detector uses `RawGestureDetector` with direction-aware `_DirectionDependentDragGestureRecognizer` — checks direction on every `handleEvent`, stops tracking pointer if drag is in wrong direction
- `checkStartedCallback: () => _backGestureController != null` — once gesture is captured, all subsequent events pass through even if `popGestureEnabled` changes
- `Positioned.fill` gesture detector over full page — allows interrupting in-flight animation by starting a new swipe

## Style notes

- No comments in code (unless documenting public API with `///`)
- Private classes prefixed with `_` (e.g., `_SwiftPageRouteTransition`, `_SwiftBackGestureController`)
- Sheet-related routes implement `SwiftSheetStackRoute` interface for route stacking
- `SwiftPageTransitions` is a static utility class with configurable constants (all `static` fields, mutable)
