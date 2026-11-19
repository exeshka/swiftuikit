import 'package:flutter/widgets.dart';

import '../theme/swift_ui_theme.dart';
import 'pressable.dart';

/// Menu row: optional leading icon, single-line ellipsized title, trailing.
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.onTap,
    this.style,
    this.height,
    this.horizontalPadding,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final TextStyle? style;
  final double? height;
  final double? horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final row = SizedBox(
      height: height ?? t.metrics.rowHeight,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding ?? t.metrics.pageInset,
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 16)],
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style ?? t.typography.body.copyWith(fontSize: 20),
              ),
            ),
            ...?(trailing == null
                ? null
                : [const SizedBox(width: 12), trailing!]),
          ],
        ),
      ),
    );
    if (onTap == null) return row;
    return Pressable(onPressed: onTap, scale: 0.985, child: row);
  }
}

/// Small secondary section label ("Recents").
class ListSectionTitle extends StatelessWidget {
  const ListSectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        t.metrics.pageInset,
        18,
        t.metrics.pageInset,
        6,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: t.typography.caption.copyWith(fontSize: 17),
            ),
          ),
          // ignore: use_null_aware_elements
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
