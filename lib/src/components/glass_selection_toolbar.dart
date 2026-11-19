// ignore: deprecated_member_use
import 'package:flutter/cupertino.dart'
    show CupertinoLocalizations, DefaultCupertinoLocalizations;
import 'package:flutter/widgets.dart';

import '../theme/swift_ui_theme.dart';
import 'ravel_icon.dart';
import 'glass_surface.dart';

const double _screenPadding = 8;
const double _gapToSelection = 8;
const double _height = 44;

/// The cut / copy / paste menu over a text selection, on a liquid glass capsule instead of the system menu.
///
/// Use it as `contextMenuBuilder` of an [EditableText]:
/// `contextMenuBuilder: (context, state) => GlassSelectionToolbar.editableText(state)`.
///
/// Placement follows the system toolbar: above the selection, below it when there is no room above, kept clear of the
/// screen edges and the status bar. Labels come from [CupertinoLocalizations] (English without them); a Live Text
/// button is left out, the field has no Live Text input.
class GlassSelectionToolbar extends StatelessWidget {
  const GlassSelectionToolbar({
    super.key,
    required this.anchors,
    required this.items,
  });

  /// The toolbar for the selection of [state]: its anchors and the buttons that fit the current state (a collapsed
  /// caret in an empty field offers only Paste, a selection offers Cut / Copy ...).
  GlassSelectionToolbar.editableText(EditableTextState state, {Key? key})
    : this(
        key: key,
        anchors: state.contextMenuAnchors,
        items: state.contextMenuButtonItems,
      );

  /// Where the selection is: the toolbar goes above [TextSelectionToolbarAnchors.primaryAnchor] or, when it does not
  /// fit there, below [TextSelectionToolbarAnchors.secondaryAnchor].
  final TextSelectionToolbarAnchors anchors;
  final List<ContextMenuButtonItem> items;

  static String _label(BuildContext context, ContextMenuButtonItem item) {
    if (item.label != null) return item.label!;
    CupertinoLocalizations l;
    try {
      l = CupertinoLocalizations.of(context);
    } catch (_) {
      l = const DefaultCupertinoLocalizations();
    }
    return switch (item.type) {
      ContextMenuButtonType.cut => l.cutButtonLabel,
      ContextMenuButtonType.copy => l.copyButtonLabel,
      ContextMenuButtonType.paste => l.pasteButtonLabel,
      ContextMenuButtonType.selectAll => l.selectAllButtonLabel,
      ContextMenuButtonType.lookUp => l.lookUpButtonLabel,
      ContextMenuButtonType.searchWeb => l.searchWebButtonLabel,
      ContextMenuButtonType.share => l.shareButtonLabel,
      ContextMenuButtonType.delete => 'Delete',
      ContextMenuButtonType.liveTextInput || ContextMenuButtonType.custom => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final shown = [
      for (final i in items)
        if (i.type != ContextMenuButtonType.liveTextInput &&
            _label(context, i).isNotEmpty)
          i,
    ];
    if (shown.isEmpty) return const SizedBox.shrink();

    final top = MediaQuery.paddingOf(context).top + _screenPadding;
    final adjust = Offset(_screenPadding, top);
    final above = anchors.primaryAnchor - const Offset(0, _gapToSelection);
    final below =
        (anchors.secondaryAnchor ?? anchors.primaryAnchor) +
        const Offset(0, _gapToSelection);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        _screenPadding,
        top,
        _screenPadding,
        _screenPadding,
      ),
      child: CustomSingleChildLayout(
        delegate: TextSelectionToolbarLayoutDelegate(
          anchorAbove: above - adjust,
          anchorBelow: below - adjust,
        ),
        child: _Capsule(items: shown),
      ),
    );
  }
}

const double _buttonPadding = 16;
const double _navWidth = 40;

TextStyle _buttonStyle(SwiftUiThemeData t) => t.typography.body.copyWith(
  fontSize: 16,
  fontWeight: FontWeight.w500,
  color: t.colors.foreground,
  decoration: TextDecoration.none,
);

/// Splits the buttons into pages that fit [maxWidth]: a page that has neighbours reserves room for the arrow(s).
/// Every page holds at least one button, so nothing is ever unreachable. [widths] are the widths of the buttons.
@visibleForTesting
List<List<int>> paginateToolbar(List<double> widths, double maxWidth) {
  final pages = <List<int>>[];
  var i = 0;
  while (i < widths.length) {
    final first = pages.isEmpty;
    final page = <int>[];
    var used = first ? 0.0 : _navWidth; // the back arrow
    while (i < widths.length) {
      final isLast = i == widths.length - 1;
      // room for the forward arrow unless this would be the last button of the last page
      final reserve = isLast ? 0.0 : _navWidth;
      if (page.isNotEmpty && used + widths[i] + 1 + reserve > maxWidth) break;
      page.add(i);
      used += widths[i] + 1;
      i++;
    }
    pages.add(page);
  }
  return pages;
}

class _Capsule extends StatefulWidget {
  const _Capsule({required this.items});

  final List<ContextMenuButtonItem> items;

  @override
  State<_Capsule> createState() => _CapsuleState();
}

class _CapsuleState extends State<_Capsule> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final divider = t.colors.foreground.withValues(alpha: 0.14);
    final style = _buttonStyle(t);
    final scaler = MediaQuery.textScalerOf(context);
    final labels = [
      for (final i in widget.items) GlassSelectionToolbar._label(context, i),
    ];

    return LayoutBuilder(
      builder: (context, box) {
        final widths = [
          for (final label in labels)
            () {
              final tp = TextPainter(
                text: TextSpan(text: label, style: style),
                textDirection: TextDirection.ltr,
                textScaler: scaler,
                maxLines: 1,
              )..layout();
              final w = tp.width + _buttonPadding * 2;
              tp.dispose();
              return w;
            }(),
        ];
        final maxWidth = box.maxWidth.isFinite ? box.maxWidth : 10000.0;
        final pages = paginateToolbar(widths, maxWidth);
        final page = _page.clamp(0, pages.length - 1);
        final shown = pages[page];

        Widget sep() => Container(width: 1, height: 20, color: divider);
        return GlassSurface(
          height: _height,
          child: IntrinsicWidth(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (page > 0) ...[
                  _Button.arrow(
                    icon: RavelIconKind.chevronLeft,
                    semanticLabel: 'Previous',
                    onPressed: () => setState(() => _page = page - 1),
                  ),
                  sep(),
                ],
                for (var k = 0; k < shown.length; k++) ...[
                  if (k > 0) sep(),
                  _Button(
                    label: labels[shown[k]],
                    onPressed: widget.items[shown[k]].onPressed,
                  ),
                ],
                if (page < pages.length - 1) ...[
                  sep(),
                  _Button.arrow(
                    icon: RavelIconKind.chevronRight,
                    semanticLabel: 'Next',
                    onPressed: () => setState(() => _page = page + 1),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Button extends StatefulWidget {
  const _Button({required this.label, required this.onPressed}) : icon = null;

  /// A page arrow instead of a label.
  const _Button.arrow({
    required RavelIconKind this.icon,
    required String semanticLabel,
    required this.onPressed,
  }) : label = semanticLabel;

  final String label;
  final RavelIconKind? icon;
  final VoidCallback? onPressed;

  @override
  State<_Button> createState() => _ButtonState();
}

class _ButtonState extends State<_Button> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onPressed,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 90),
          opacity: _down ? 0.45 : 1,
          child: Container(
            height: _height,
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(
              horizontal: widget.icon == null ? _buttonPadding : 0,
            ),
            width: widget.icon == null ? null : _navWidth,
            child: widget.icon != null
                ? RavelIcon(
                    widget.icon!,
                    size: 18,
                    color: t.colors.foreground,
                    strokeWidth: 2,
                  )
                : Text(widget.label, maxLines: 1, style: _buttonStyle(t)),
          ),
        ),
      ),
    );
  }
}
