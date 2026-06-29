import 'package:flutter/material.dart';
import 'swift_header_chrome.dart';

class SwiftScaffold extends StatefulWidget {
  const SwiftScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.backgroundColor,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Color? backgroundColor;

  @override
  State<SwiftScaffold> createState() => _SwiftScaffoldState();
}

class _SwiftScaffoldState extends State<SwiftScaffold> {
  double _lastRegisteredAppBarHeight = 0;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return ColoredBox(
      color: widget.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      child: SwiftPinnedHeaderChrome(
        child: Builder(
          builder: (context) {
            final chromeController =
                SwiftPinnedHeaderChromeScope.maybeOf(context);

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _registerAppBar(chromeController, topPadding);
            });

            return Column(
              children: [
                if (widget.appBar != null) widget.appBar!,
                Expanded(child: widget.body),
              ],
            );
          },
        ),
      ),
    );
  }

  void _registerAppBar(
    SwiftPinnedHeaderChromeController? controller,
    double topPadding,
  ) {
    if (controller == null || widget.appBar == null) return;
    final appBarHeight = topPadding + widget.appBar!.preferredSize.height;
    if (appBarHeight == _lastRegisteredAppBarHeight) return;
    _lastRegisteredAppBarHeight = appBarHeight;

    controller.update(
      id: #swift_scaffold_appbar,
      height: appBarHeight,
      visibleHeight: appBarHeight,
      child: const SizedBox.shrink(),
      link: LayerLink(),
      signature: 'swift_scaffold_appbar_$appBarHeight',
    );
  }
}
