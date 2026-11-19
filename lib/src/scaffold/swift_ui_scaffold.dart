import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';

import '../adaptive/swift_ui_window_info.dart';
import '../chrome/chrome_controller.dart';
import '../chrome/chrome_scaffold.dart';
import '../chrome/chrome_style.dart';
import '../components/headers.dart';
import '../theme/swift_ui_theme.dart';

/// A page of an app in the kit's look, with the native layout by default: it puts the header, the body and the bottom bar
/// where iOS 26 does and hands the edge effect to the theme. Under it is a [ChromeScaffold] (the zones, the insets, the blur),
/// which stays available for anything this does not cover.
///
/// The header comes in two ways:
///  * **by parameters**: [title], [subtitle], [titleStyle], [leading], [actions]: a [LargeTitleHeader] (large or inline title,
///    glass buttons, the back button when the route has somewhere to return to);
///  * **your own**: [topBar] or [topBarBuilder] (which also gets the [SwiftUiWindowInfo], so the bar can change with the
///    window). A custom bar is wrapped in a [ChromeBar] so the scaffold learns its height; with [wrapTopBar] false the widget is
///    placed as it is, for one that registers itself ([LargeTitleHeader], `StretchHeader`). For the back button of a custom
///    bar use [SwiftUiBackButton.maybeOf].
///
/// The window is read from [SwiftUiWindowInfo.of] (it follows the device folding, a split view...), and [bodyBuilder] and
/// [topBarBuilder] get it. The adaptive layouts (the sidebar and the detail of a wide window) live one level up, in the
/// navigation shell; a page lays itself out in the window it is given.
class SwiftUiScaffold extends StatelessWidget {
  const SwiftUiScaffold({
    super.key,
    this.title,
    this.subtitle,
    this.titleStyle = NavTitleStyle.large,
    this.leading,
    this.actions = const [],
    this.automaticallyImplyLeading = true,
    this.onBack,
    this.topBar,
    this.topBarBuilder,
    this.wrapTopBar = true,
    this.body,
    this.bodyBuilder,
    this.bottomBar,
    this.overlay,
    this.controller,
    this.backgroundColor,
    this.topChrome,
    this.bottomChrome,
    this.bottomBlur = true,
    this.bottomBarSafeAreaShare,
    this.snapLargeTitle = true,
    this.blockZoneTouches = false,
    this.freezeUnderRoute = false,
    this.scrollDepth = 0,
  }) : assert(
         body != null || bodyBuilder != null,
         'Give a body or a bodyBuilder',
       ),
       assert(
         title == null || (topBar == null && topBarBuilder == null),
         'Give a title (the default header) or a topBar / topBarBuilder (your own), not both',
       ),
       assert(
         topBar == null || topBarBuilder == null,
         'Give a topBar or a topBarBuilder, not both',
       );

  /// The title of the default header.
  final String? title;
  final String? subtitle;
  final NavTitleStyle titleStyle;

  /// The leading widget of the default header (the back button is implied when null).
  final Widget? leading;

  /// The trailing widgets of the default header.
  final List<Widget> actions;
  final bool automaticallyImplyLeading;
  final VoidCallback? onBack;

  /// A header of your own.
  final Widget? topBar;
  final Widget Function(BuildContext context, SwiftUiWindowInfo window)?
  topBarBuilder;

  /// Wrap a custom bar in a [ChromeBar] (false for a bar that registers itself).
  final bool wrapTopBar;

  final Widget? body;
  final Widget Function(BuildContext context, SwiftUiWindowInfo window)?
  bodyBuilder;

  /// Placed as it is (a [ChromeBar] on the bottom edge, or a [BottomDock]).
  final Widget? bottomBar;
  final Widget? overlay;
  final ChromeController? controller;
  final Color? backgroundColor;

  /// See [ChromeScaffold.topChrome] / [ChromeScaffold.bottomChrome].
  final ChromeStyle? topChrome;
  final ChromeStyle? bottomChrome;
  final bool bottomBlur;
  final double? bottomBarSafeAreaShare;
  final bool snapLargeTitle;
  final bool blockZoneTouches;
  final bool freezeUnderRoute;
  final int scrollDepth;

  @override
  Widget build(BuildContext context) {
    final window = SwiftUiWindowInfo.of(context);
    Widget? header;
    if (title != null) {
      header = LargeTitleHeader(
        title: title!,
        subtitle: subtitle,
        style: titleStyle,
        leading: leading,
        trailing: actions,
        automaticallyImplyLeading: automaticallyImplyLeading,
        onBack: onBack,
      );
    } else {
      final custom = topBarBuilder?.call(context, window) ?? topBar;
      if (custom != null) {
        header = wrapTopBar ? ChromeBar(child: custom) : custom;
      }
    }
    // Material (transparent) gives the text of the page its style from the theme and lets ink effects work, so the page needs
    // no `Scaffold` around it
    return Material(
      type: MaterialType.transparency,
      textStyle: SwiftUiTheme.of(context).typography.body,
      child: ChromeScaffold(
        topBar: header,
        bottomBar: bottomBar,
        overlay: overlay,
        controller: controller,
        backgroundColor: backgroundColor,
        topChrome: topChrome,
        bottomChrome: bottomChrome,
        bottomBlur: bottomBlur,
        bottomBarSafeAreaShare: bottomBarSafeAreaShare,
        snapLargeTitle: snapLargeTitle,
        blockZoneTouches: blockZoneTouches,
        freezeUnderRoute: freezeUnderRoute,
        scrollDepth: scrollDepth,
        body: bodyBuilder?.call(context, window) ?? body!,
      ),
    );
  }
}
