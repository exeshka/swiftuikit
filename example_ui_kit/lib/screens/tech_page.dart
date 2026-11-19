import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

/// The frame of every technical page: the kit's standard large-title header (with the automatic back button) over the page's own
/// content. The content gets the header's height as `MediaQuery.padding.top` and scrolls under its blur.
class TechPage extends StatelessWidget {
  const TechPage({
    super.key,
    required this.title,
    required this.child,
    this.trailing = const [],
  });

  final String title;
  final Widget child;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ChromeScaffold(
        topBar: LargeTitleHeader(title: title, trailing: trailing),
        body: child,
      ),
    );
  }
}
