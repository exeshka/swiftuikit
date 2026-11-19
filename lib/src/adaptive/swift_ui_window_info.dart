import 'dart:ui' show DisplayFeature, DisplayFeatureType;

import 'package:flutter/widgets.dart';

import '../theme/swift_ui_theme.dart';

/// Compact or regular, as in iOS (`UIUserInterfaceSizeClass`), but of the window the app is given right now.
enum SwiftUiSizeClass { compact, regular }

/// What a [SwiftUiReservedRegion] is.
enum SwiftUiReservedRegionKind {
  /// The fold of a foldable display: it divides the screen in two.
  fold,

  /// An area the hardware takes (the camera cut-out).
  cutout,
}

/// A rectangle (in window coordinates) the content should not rely on: the fold of a foldable, a cut-out. The counterpart of
/// `reservedRegions(kind:)` of SwiftUI / UIKit.
@immutable
class SwiftUiReservedRegion {
  const SwiftUiReservedRegion(this.kind, this.bounds);
  final SwiftUiReservedRegionKind kind;
  final Rect bounds;

  @override
  bool operator ==(Object other) =>
      other is SwiftUiReservedRegion &&
      other.kind == kind &&
      other.bounds == bounds;

  @override
  int get hashCode => Object.hash(kind, bounds);
}

/// The window the app is laid out in, right now: its size, its size classes and its reserved regions. It changes as the window
/// does (the device folds or unfolds, a split view is dragged, the phone is turned): read it in `build`, never once at launch,
/// and never decide a layout from the device idiom or orientation.
///
/// The size comes from `MediaQuery`, the size classes from the thresholds of [SwiftUiAdaptiveTheme]. Reserved regions come from
/// Flutter's display features (Android foldables); iOS does not report the fold to Flutter yet, so an app (or a plugin) that
/// knows it can say so with a [SwiftUiWindowScope].
@immutable
class SwiftUiWindowInfo {
  const SwiftUiWindowInfo({
    required this.size,
    required this.horizontal,
    required this.vertical,
    this.reservedRegions = const [],
  });

  final Size size;
  final SwiftUiSizeClass horizontal;
  final SwiftUiSizeClass vertical;
  final List<SwiftUiReservedRegion> reservedRegions;

  bool get isCompactWidth => horizontal == SwiftUiSizeClass.compact;
  bool get isRegularWidth => horizontal == SwiftUiSizeClass.regular;
  bool get isCompactHeight => vertical == SwiftUiSizeClass.compact;
  bool get isRegularHeight => vertical == SwiftUiSizeClass.regular;

  /// The fold, when the display has one the app knows of.
  SwiftUiReservedRegion? get fold {
    for (final r in reservedRegions) {
      if (r.kind == SwiftUiReservedRegionKind.fold) return r;
    }
    return null;
  }

  /// Computes the info of a window of [size].
  static SwiftUiWindowInfo resolve(
    Size size,
    SwiftUiAdaptiveTheme adaptive, {
    List<SwiftUiReservedRegion> reservedRegions = const [],
  }) => SwiftUiWindowInfo(
    size: size,
    horizontal: size.width >= adaptive.regularWidth
        ? SwiftUiSizeClass.regular
        : SwiftUiSizeClass.compact,
    vertical: size.height >= adaptive.regularHeight
        ? SwiftUiSizeClass.regular
        : SwiftUiSizeClass.compact,
    reservedRegions: reservedRegions,
  );

  /// The window of [context]; rebuilds the caller when the size (or the display features) change.
  static SwiftUiWindowInfo of(BuildContext context) {
    final mq = MediaQuery.of(context);
    final scope = context
        .dependOnInheritedWidgetOfExactType<SwiftUiWindowScope>();
    return resolve(
      mq.size,
      SwiftUiTheme.of(context).adaptive,
      reservedRegions:
          scope?.reservedRegions ?? _fromFeatures(mq.displayFeatures),
    );
  }

  static List<SwiftUiReservedRegion> _fromFeatures(
    List<DisplayFeature> features,
  ) => [
    for (final f in features)
      SwiftUiReservedRegion(
        f.type == DisplayFeatureType.cutout
            ? SwiftUiReservedRegionKind.cutout
            : SwiftUiReservedRegionKind.fold,
        f.bounds,
      ),
  ];

  @override
  bool operator ==(Object other) =>
      other is SwiftUiWindowInfo &&
      other.size == size &&
      other.horizontal == horizontal &&
      other.vertical == vertical &&
      _listEq(other.reservedRegions, reservedRegions);

  @override
  int get hashCode => Object.hash(size, horizontal, vertical);

  static bool _listEq(List<Object> a, List<Object> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Tells the widgets below where the reserved regions of the window are, when Flutter does not (the fold of an iPhone Duo comes
/// from the native `reservedRegions` API through a plugin of the app's own). Without it [SwiftUiWindowInfo.of] uses Flutter's
/// display features.
class SwiftUiWindowScope extends InheritedWidget {
  const SwiftUiWindowScope({
    super.key,
    required this.reservedRegions,
    required super.child,
  });

  final List<SwiftUiReservedRegion> reservedRegions;

  @override
  bool updateShouldNotify(SwiftUiWindowScope old) =>
      !SwiftUiWindowInfo._listEq(old.reservedRegions, reservedRegions);
}
