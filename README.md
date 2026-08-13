<div align="center">

# SwiftUIKit

**A growing collection of Flutter widgets, routes, and interaction primitives inspired by iOS 26–27.**

[![pub.dev](https://img.shields.io/pub/v/swiftuikit?logo=dart&label=pub.dev&color=0175C2)](https://pub.dev/packages/swiftuikit)
[![Flutter](https://img.shields.io/badge/Flutter-3.22%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Inspired by](https://img.shields.io/badge/inspired_by-iOS_26%E2%80%9327-111111?logo=apple&logoColor=white)](#why-swiftuikit)
[![License](https://img.shields.io/badge/license-MIT-6E56CF)](LICENSE)

Motion, depth, interactive gestures, adaptive corners, and presentation
patterns that feel at home on Apple platforms while remaining Flutter-native.

</div>

<p align="center">
  <img src="https://raw.githubusercontent.com/exeshka/swiftuikit/main/assets/image.png" alt="SwiftUIKit page transition" width="29%" />
  <img src="https://raw.githubusercontent.com/exeshka/swiftuikit/main/assets/image%20copy.png" alt="SwiftUIKit sheet transition" width="29%" />
  <img src="https://raw.githubusercontent.com/exeshka/swiftuikit/main/assets/image%20copy%202.png" alt="SwiftUIKit stacked presentation" width="29%" />
</p>

> SwiftUIKit is an independent project inspired by Apple interface patterns.
> It is not affiliated with or endorsed by Apple Inc.

## Why SwiftUIKit

Flutter has excellent primitives, but reproducing the interaction details of
modern iOS interfaces often requires coordinating routes, gestures, clipping,
scroll positions, spring motion, and physical screen corners. SwiftUIKit
packages those details into composable building blocks.

| Motion-first | Router-ready | Composable | Adaptive |
|---|---|---|---|
| Spring-like transitions and interruption-safe retargeting | Direct `Navigator`, Navigator 2.0 / `go_router`, and `auto_route` APIs | Use complete routes or lower-level widgets independently | Physical screen corner radius and safe-area aware presentation |

## Component catalog

### Text and page motion

| Component | What it does | Status |
|---|---|---|
| [`SwiftText`](#swifttext) | Animates changed glyphs with vertical motion, blur, opacity, and automatic numeric direction | Stable |
| [`SwiftPageViewAnimation`](#swiftpageviewanimation) | Adds overlap, parallax, scale, and rounded overscroll to a horizontal `PageView` | Experimental |

### Navigation and presentations

| Component | What it does | Status |
|---|---|---|
| [`SwiftPageRoute`](#swiftpage) | Full-screen page transition with interactive swipe-back, scale, and parallax | Stable |
| [`SwiftZoomHero` + `SwiftZoomRoute`](#swiftzoom) | Element-to-element zoom with a draggable whole-page dismissal and dynamic destinations | Stable |
| [`SwiftSheetRoute`](#swiftsheet) | Stack-aware iOS sheet with drag-to-dismiss and scroll handoff | Stable |
| [`SwiftScrollSheetRoute`](#swiftscrollsheet) | Draggable sheet with fractional or fixed-height detents and programmatic control | Experimental |
| [`SwiftModalRoute`](#swiftmodal) | Content-sized modal with dimming, rounded corners, and drag-to-dismiss | Experimental |

### Composition and scroll utilities

| Component | What it does | Status |
|---|---|---|
| [`SwiftStepSheet`](#swiftstepsheet) | Multi-step content container with animated height changes | Experimental |
| [`SwiftModalScaffold`](#swiftmodalscaffold) | Morphs a floating scroll sheet into a full-screen surface as it expands | Experimental |
| [`SwiftScrollSheetDragTarget`](#swiftscrollsheetdragtarget) | Turns a custom header or handle into a drag surface for a scroll sheet | Experimental |
| [`SwiftSheetScrollProvider`](#scroll-coordination) | Exposes a sheet's effective `ScrollController` to descendants | Stable |
| [`SwiftSheetScrollBinding`](#scroll-coordination) | Binds the primary scroll controller, with a safe fallback | Stable |
| [`ScrollOverlapListener`](#scroll-coordination) | Rebuilds from the current leading overscroll amount | Stable |
| [`ScrollValueListener`](#scroll-coordination) | Rebuilds from the current scroll offset | Stable |
| [`SnappingScrollPhysics`](#snappingscrollphysics) | Snaps a scroll position to configurable points using spring physics | Stable |
| [`ScreenRadiusService`](#screenradiusservice) | Reads and caches the device's physical corner radius | Stable |

## Installation

Install the current pub.dev release:

```bash
flutter pub add swiftuikit
```

Or add it manually:

```yaml
dependencies:
  swiftuikit: ^0.2.1
```

To follow the latest GitHub revision:

```yaml
dependencies:
  swiftuikit:
    git:
      url: https://github.com/exeshka/swiftuikit
```

Import the public library:

```dart
import 'package:swiftuikit/swiftuikit.dart';
```

## Setup

Initialize `ScreenRadiusService` before `runApp` when using routes or widgets
that follow the physical corners of the device:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ScreenRadiusService.instance.initialize();
  runApp(const App());
}
```

Without initialization, corner-aware components safely fall back to
`BorderRadius.zero`.

## Widget guide

### SwiftText

`SwiftText` is a glyph-level counterpart to SwiftUI's numeric text content
transition. Unchanged glyphs stay sharp while changed glyphs move vertically,
fade, and blur. Numeric direction is detected automatically, rapid updates
retarget from the current visual state, and style-only changes do not restart
the animation.

> **99% native feel.** The timing, roll direction, blur, opacity, and
> interruption behavior are tuned so the text transition feels almost
> indistinguishable from its native iOS counterpart.

<p align="center">
  <img src="https://raw.githubusercontent.com/exeshka/swiftuikit/main/assets/swift_text_demo.gif" alt="SwiftText music player demo" width="320" />
</p>

```dart
SwiftText(
  'Balance: $balance',
  duration: const Duration(milliseconds: 450),
  style: const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
  ),
)
```

Use `countsDown` to override the detected roll direction, `SwiftText.rich` for
styled `TextSpan` content, and `onEnd` to observe completion. `WidgetSpan` is
not supported because inline render objects cannot move as individual glyphs.

```dart
SwiftText.rich(
  TextSpan(
    children: [
      const TextSpan(text: 'Score  '),
      TextSpan(
        text: '$score',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ],
  ),
)
```

### SwiftPage

`SwiftPageRoute` provides a full-screen push transition with an interactive
swipe-back gesture. The incoming page overlaps the previous page while the
background scales and moves with the gesture.

```dart
Navigator.of(context).push(
  SwiftPageRoute<void>(
    settings: const RouteSettings(name: '/details'),
    child: const DetailsScreen(),
    canSwipe: true,
    canOnlySwipeFromEdge: false,
    minScale: 0.95,
  ),
);
```

Key controls include `pageOverlapFraction`, `backGestureWidth`,
`clipWithScreenRadius`, `radius`, `borderRadius`, and a custom transition
duration. Use `SwiftPage` with Navigator 2.0 / `go_router`, or
`SwiftPageAutoRoute` with `auto_route`.

`canOnlySwipeFromEdge` defaults to `false`. The full-screen gesture follows the
iOS 26 interaction model: it can start in any unclaimed area, while horizontal
`PageView`, scroll, slider, and custom drag controls keep their own gestures.
The leading-edge gesture remains available even when horizontal content fills
the page. Set `canOnlySwipeFromEdge` to `true` for classic edge-only navigation.

For a shared `Hero` to follow the interactive back gesture, set
`transitionOnUserGestures: true` on both matching `Hero` widgets.

### SwiftZoom

`SwiftZoomHero` connects a source element to a complete destination page.
`SwiftZoomRoute` manages background dimming, fallback scale, and interactive
whole-page dismissal. The destination ID may change while the route is open,
so a `PageView` can dismiss into the source for its currently selected item.

Source:

```dart
SwiftZoomHero(
  id: product.id,
  borderRadius: BorderRadius.circular(24),
  child: ProductCard(product: product),
)
```

Destination:

```dart
SwiftZoomHero(
  id: products[currentIndex].id,
  borderRadius: ScreenRadiusService.instance.radius,
  child: ProductGallery(
    products: products,
    initialIndex: currentIndex,
  ),
)
```

Route:

```dart
Navigator.of(context).push(
  SwiftZoomRoute<void>(
    dismissDirection: SwiftZoomDismissDirection.horizontal,
    builder: (_) => const ProductGalleryScreen(),
  ),
);
```

Choose `SwiftZoomDismissDirection.any`, `.horizontal`, or `.downward` to
coordinate dismissal with the destination's own scroll gestures. If the source
is no longer mounted, the route falls back to a complete-page scale and fade.

### SwiftSheet

`SwiftSheetRoute` presents an iOS-style sheet that stacks correctly above
pages and other sheets. It coordinates drag-to-dismiss with the sheet's scroll
position and can animate the previous route into the background.

For direct Navigator usage, `showSwiftSheet` is the shortest entry point:

```dart
showSwiftSheet<void>(
  context: context,
  showDragHandle: true,
  scrollableBuilder: (context, controller) {
    return ListView(
      controller: controller,
      children: const [
        ListTile(title: Text('Account')),
        ListTile(title: Text('Notifications')),
      ],
    );
  },
);
```

Regular `Hero` transitions work when opening and closing a sheet. To keep the
Hero attached to a drag-to-dismiss gesture, set
`transitionOnUserGestures: true` on both matching `Hero` widgets. After a
committed dismiss, the revealed route remains interactive while the sheet and
Hero finish settling. Automatic `CupertinoNavigationBar` and
`CupertinoSliverNavigationBar` Heroes do not cross the modal sheet boundary.

The sheet supports custom radii, nested navigation, background animation,
top-safe-area preservation, drag thresholds, and fling thresholds. Use
`SwiftSheetRoute.popSheet(context)` to close the complete sheet from nested
content.

### SwiftScrollSheet

`SwiftScrollSheetRoute` combines draggable sheet behavior with snap detents.
Detents may be fractions of the available height, fixed logical-pixel heights,
or the built-in `medium` and `large` values.

```dart
final sheetController = SwiftScrollSheetController(initialValue: 0.5);

Navigator.of(context).push(
  SwiftScrollSheetRoute<void>(
    settings: const RouteSettings(name: '/library'),
    child: const LibrarySheet(),
    detents: const [
      SwiftSheetDetent.medium,
      SwiftSheetDetent.large,
    ],
    initialDetent: SwiftSheetDetent.medium,
    sheetController: sheetController,
  ),
);
```

`SwiftScrollSheetController` exposes `animateTo`, `jumpTo`, `expand`,
`collapse`, `snapToNearest`, the current `extent`, and the resolved snap stops.
Inside the route, use `SwiftScrollSheetRoute.controllerOf(context)` or
`SwiftScrollSheetRoute.extentOf(context)` when direct access is more convenient.

#### SwiftScrollSheetDragTarget

Wrap a custom header or drag handle to forward vertical gestures to the
nearest `SwiftScrollSheetRoute`:

```dart
SwiftScrollSheetDragTarget(
  child: const SheetHeader(title: 'Library'),
)
```

### SwiftModal

`SwiftModalRoute` sizes itself to its child up to the available screen height.
It slides from the bottom, dims the background, supports a configurable
barrier, and hands drag gestures off from scrollable content before dismissing.

```dart
Navigator.of(context).push(
  SwiftModalRoute<void>(
    settings: const RouteSettings(name: '/filters'),
    child: const FiltersPanel(),
    barrierDismissible: true,
    barrierOpacity: 0.3,
    dismissThreshold: 0.3,
  ),
);
```

Use `SwiftModalPage` for Navigator 2.0 / `go_router`, or
`SwiftModalAutoRoute` for `auto_route`.

### SwiftPageViewAnimation

`SwiftPageViewAnimation` adds iOS-inspired depth to horizontal paging: the
previous page can remain partially covered, pages scale with progress, and
edge overscroll reveals adaptive rounded corners.

```dart
SwiftPageViewAnimation.pageView(
  controller: pageController,
  itemCount: pages.length,
  itemBuilder: (context, index) => pages[index],
  minScale: 0.95,
  pageOverlapFraction: 0.20,
  onPageChanged: onPageChanged,
)
```

Use `parallaxIndexes` to restrict the effect to selected pages,
`coverPreviousPage` to disable overlap, and `radius` or `borderRadius` to
override the physical screen radius.

### SwiftStepSheet

`SwiftStepSheet` switches between a list of steps and animates height changes
with `AnimatedSize`. Its state exposes navigation commands and the enclosing
modal route's open progress.

```dart
final stepKey = GlobalKey<SwiftStepSheetState>();

SwiftStepSheet(
  key: stepKey,
  steps: const [
    ContactStep(),
    AddressStep(),
    ConfirmationStep(),
  ],
)
```

Call `nextStep`, `previousStep`, or `goToStep` through the state key or
`SwiftStepSheet.of(context)`. Descendants can read the route transition with
`SwiftStepSheet.openProgressOf(context)`.

### SwiftModalScaffold

`SwiftModalScaffold` is designed for content inside a
`SwiftScrollSheetRoute`. As the sheet expands, it removes its floating margin
and shadow, flattens the lower corners, and aligns the upper corners with the
physical screen.

```dart
SwiftModalScaffold(
  header: const SheetHeader(title: 'Collection'),
  body: ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) => ItemTile(items[index]),
  ),
)
```

The optional `header` is automatically wrapped in
`SwiftScrollSheetDragTarget`.

### Scroll coordination

These smaller widgets make scroll-driven effects reusable without moving
controller logic into page state:

| Widget | Use it for |
|---|---|
| `SwiftSheetScrollProvider` | Providing a known `ScrollController` to a sheet subtree |
| `SwiftSheetScrollBinding` | Exposing the nearest `PrimaryScrollController`, with an owned fallback when none exists |
| `ScrollOverlapListener` | Building from leading overscroll, clamped by `maxOverlap` |
| `ScrollValueListener` | Building from the current offset of a single attached scroll position |

```dart
ScrollValueListener(
  controller: controller,
  builder: (context, offset) {
    return Header(elevation: (offset / 24).clamp(0.0, 1.0));
  },
)
```

### SnappingScrollPhysics

`SnappingScrollPhysics` snaps a scroll position to a list of logical-pixel
points. Low-velocity movement uses `snapThreshold`; a fling chooses the next
point in its direction.

```dart
ListView(
  controller: controller,
  physics: const SnappingScrollPhysics(
    snapPoints: [0, 240, 480],
    springConfig: SnapSpringConfig.snappy,
  ),
  children: children,
)
```

Choose `SnapSpringConfig.smooth`, `.snappy`, or `.bouncy`, or provide custom
mass, stiffness, and damping.

### ScreenRadiusService

`ScreenRadiusService` is a `ChangeNotifier` singleton that reads and caches the
physical corner radius reported by the platform. Components use its
`BorderRadius` to keep page and sheet clipping concentric with the screen.

```dart
final borderRadius = ScreenRadiusService.instance.radius;
final radius = ScreenRadiusService.instance.radiusValue;
```

Call `refresh()` if the host window changes and the radius must be queried
again.

## Routing adapters

The same transition core is exposed for three navigation styles:

| Experience | Direct Navigator | Navigator 2.0 / `go_router` | `auto_route` |
|---|---|---|---|
| Page | `SwiftPageRoute` | `SwiftPage` | `SwiftPageAutoRoute` |
| Zoom | `SwiftZoomRoute` | `SwiftZoomPage` | `SwiftZoomAutoRoute` |
| Sheet | `SwiftSheetRoute` / `showSwiftSheet` | `SwiftSheetPage` | `SwiftSheetAutoRoute` |
| Scroll sheet | `SwiftScrollSheetRoute` | `SwiftScrollSheetPage` | `SwiftScrollSheetAutoRoute` |
| Content modal | `SwiftModalRoute` | `SwiftModalPage` | `SwiftModalAutoRoute` |

### Navigator 2.0 / go_router

Use the `Page` adapters from a `pageBuilder`:

```dart
GoRoute(
  path: '/details',
  pageBuilder: (context, state) {
    return SwiftPage<void>(
      key: state.pageKey,
      name: state.name,
      child: const DetailsScreen(),
    );
  },
)
```

### auto_route

Use the matching route definitions in `RootStackRouter`:

```dart
@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    SwiftPageAutoRoute(page: HomeRoute.page, initial: true),
    SwiftPageAutoRoute(page: DetailsRoute.page),
    SwiftZoomAutoRoute(page: GalleryRoute.page),
    SwiftSheetAutoRoute(
      page: SettingsRoute.page,
      showDragHandle: true,
    ),
  ];
}
```

Regenerate routes from the application package after changing route
definitions:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Low-level building blocks

Most applications should use the routes and adapters above. The package also
exports these lower-level pieces for custom integrations:

| API | Purpose |
|---|---|
| `SwiftSheetTransition` | Builds the primary and delegated animations used by stacked sheets |
| `SwiftSheetScope` | Propagates the resolved sheet radius to nested page routes |
| `SwiftPageTransitions` | Central configuration and route builder for page and sheet motion |
| `SwiftTextSmoothCurve` | Critically damped curve used by the default `SwiftText` transition |

## Example app

The [`example`](example/) application contains the auto_route catalog,
interactive page and zoom flows, stacked sheets, and the responsive
[`SwiftText` music player](example/lib/src/screens/swift_text_player_screen.dart).

```bash
cd example
flutter run
```

## Stability

APIs annotated with `@experimental` are usable but may change before the next
stable release. At the moment this includes scroll sheets, content-sized
modals, `SwiftPageViewAnimation`, `SwiftStepSheet`, and
`SwiftModalScaffold`.

Bug reports, focused examples, and pull requests are welcome.

## Support SwiftUIKit

If SwiftUIKit saves you time or helps your Flutter app feel closer to native
iOS, consider supporting its continued development.

<p align="center">
  <a href="https://ko-fi.com/exeshka">
    <img src="https://img.shields.io/badge/Support_SwiftUIKit_on-Ko--fi-FF5E5B?style=for-the-badge&logo=ko-fi&logoColor=white" alt="Support SwiftUIKit on Ko-fi" />
  </a>
</p>

## License

SwiftUIKit is available under the [MIT License](LICENSE).
