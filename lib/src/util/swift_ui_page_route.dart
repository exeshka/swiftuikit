import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/widgets.dart';

/// The route of a pushed page on iOS: it slides in from the right, the page under it moves a little, and a swipe from the left
/// edge takes it back with the finger. With [fullscreenDialog] it rises from the bottom like a modal.
///
/// ```dart
/// Navigator.of(context).push(SwiftUiPageRoute(builder: (_) => const DetailPage()));
/// ```
class SwiftUiPageRoute<T> extends CupertinoPageRoute<T> {
  SwiftUiPageRoute({
    required super.builder,
    super.settings,
    super.fullscreenDialog,
    super.maintainState,
  });
}
