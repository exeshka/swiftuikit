import 'package:flutter/widgets.dart';
import 'package:screen_corner_radius/screen_corner_radius.dart';

/// A singleton service that retrieves and caches the physical corner radius of the screen.
///
/// This service extends [ChangeNotifier] to notify UI components when the radius is
/// resolved or updated (specifically needed on Android, where window insets might
/// not be immediately available before the widget tree is first laid out).
class ScreenRadiusService extends ChangeNotifier {
  ScreenRadiusService._();

  /// The singleton instance of [ScreenRadiusService].
  static final ScreenRadiusService instance = ScreenRadiusService._();

  BorderRadius _radius = BorderRadius.zero;
  bool _isInitialized = false;

  /// The physical screen corner radius represented as [BorderRadius].
  BorderRadius get radius => _radius;

  /// A proxy helper returning the top-left x corner radius.
  /// Useful if a single double value is needed.
  double get radiusValue => _radius.topLeft.x;

  /// Whether the initial attempt to retrieve the corner radius has run.
  bool get isInitialized => _isInitialized;

  /// Initializes the service.
  ///
  /// This should be called in `main()` before calling `runApp()`.
  /// Since some platforms (e.g. Android) might not have window insets ready
  /// before the layout phase starts, this automatically schedules a post-frame
  /// callback to fetch the radius again once the window is attached.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // First attempt before runApp
    await _fetchRadius();
    _isInitialized = true;

    // Schedule second attempt after the first frame is laid out
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchRadius();
    });
  }

  /// Manually force-refresh the screen corner radius value.
  Future<void> refresh() async {
    await _fetchRadius();
  }

  Future<void> _fetchRadius() async {
    try {
      final fetched = await ScreenCornerRadius.get();
      final radius = fetched == null
          ? BorderRadius.zero
          : BorderRadius.only(
              topLeft: Radius.circular(fetched.topLeft),
              topRight: Radius.circular(fetched.topRight),
              bottomLeft: Radius.circular(fetched.bottomLeft),
              bottomRight: Radius.circular(fetched.bottomRight),
            );

      if (radius != _radius) {
        _radius = radius;
        notifyListeners();
      }
    } catch (e) {
      debugPrint(
        'ScreenRadiusService: failed to fetch screen corner radius: $e',
      );
    }
  }
}
