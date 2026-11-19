// ignore: deprecated_member_use
import 'package:flutter/cupertino.dart'
    show cupertinoTextSelectionHandleControls;
import 'package:flutter/gestures.dart' show TapDragUpDetails;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../theme/swift_ui_theme.dart';
import 'glass_selection_toolbar.dart';
import 'glass_surface.dart';

/// Text field on a liquid glass plate, like the native iOS 26 composer (`TextField` + `.glassEffect(.regular.interactive())`).
///
/// A single line is a 44 pt capsule; the field grows with its text up to [maxLines] lines (the plate becomes a rounded
/// rectangle with the same corner radius, it grows upward when the field sits at the bottom of a column). [leading] and
/// [trailing] sit inside the plate (a mic, a send button...); the trailing slot is bottom-aligned, so it stays next to the
/// last line of a tall field. The plate answers touches like native interactive glass.
class GlassTextField extends StatefulWidget {
  const GlassTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.minLines = 1,
    this.maxLines = 5,
    this.leading,
    this.trailing,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.sentences,
    this.enabled = true,
    this.autofocus = false,
    this.minHeight = 44,
    this.cornerRadius,
    this.interactive = true,
    this.liquid,
    this.plainFill,
    this.contentOpacity = 1,
    this.style,
    this.slotInset = 6,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final int minLines;
  final int maxLines;
  final Widget? leading;
  final Widget? trailing;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool enabled;
  final bool autofocus;

  /// Height of one line plate (native: 44 pt).
  final double minHeight;

  /// Corner radius; default is half of [minHeight] (a capsule that keeps its radius when the field grows).
  final double? cornerRadius;

  /// Native press response of the glass (grow, highlight, rubber band).
  final bool interactive;

  /// Non-null: no glass at all, the plate is a plain container of this one colour (no rim, no highlight, no backdrop pass).
  final Color? plainFill;

  /// Opacity of what is inside the plate (leading, text, trailing); the plate itself is not affected.
  final double contentOpacity;

  /// Liquid glass shader on/off; null follows [SwiftUiThemeData.useLiquidGlass].
  final bool? liquid;

  /// Text style; default is [SwiftUiThemeData.body].
  final TextStyle? style;

  /// Space (pt) between the plate's edge and [leading] / [trailing]. For a round button of the same height as the plate's
  /// minimum minus twice this value, the gap is the same on all sides (the plate's radius is concentric with the button's).
  final double slotInset;

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField>
    implements TextSelectionGestureDetectorBuilderDelegate {
  TextEditingController? _ownController;
  FocusNode? _ownFocus;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  // Selection gestures (long press, double tap, drag handles) and the copy / paste
  // menu: a bare EditableText has none of them, TextField / CupertinoTextField add
  // them through this builder.
  @override
  final GlobalKey<EditableTextState> editableTextKey =
      GlobalKey<EditableTextState>();
  @override
  bool get forcePressEnabled => true;
  @override
  bool get selectionEnabled => true;
  late final _SelectionGestures _gestures = _SelectionGestures(this);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_rebuild);
    _focus.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(GlassTextField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      (old.controller ?? _ownController)?.removeListener(_rebuild);
      _controller.addListener(_rebuild);
    }
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownFocus)?.removeListener(_rebuild);
      _focus.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_rebuild);
    _focus.removeListener(_rebuild);
    _ownController?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final style = (widget.style ?? t.typography.body).copyWith(
      color: t.colors.foreground,
    );
    final hintStyle = style.copyWith(
      color: t.glass.glassIcon.withValues(alpha: 0.5),
    );
    final radius = widget.cornerRadius ?? widget.minHeight / 2;
    final multiline = widget.maxLines > 1;

    final field = Stack(
      alignment: Alignment.centerLeft,
      children: [
        if (widget.hintText != null && _controller.text.isEmpty)
          IgnorePointer(
            child: Text(
              widget.hintText!,
              style: hintStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        _gestures.buildGestureDetector(
          behavior: HitTestBehavior.translucent,
          child: EditableText(
            key: editableTextKey,
            controller: _controller,
            focusNode: _focus,
            style: style,
            cursorColor: t.colors.accent,
            backgroundCursorColor: t.glass.glassIcon,
            selectionColor: t.colors.accent.withValues(alpha: 0.35),
            minLines: widget.minLines,
            maxLines: widget.maxLines,
            keyboardType:
                widget.keyboardType ??
                (multiline ? TextInputType.multiline : TextInputType.text),
            textInputAction: widget.textInputAction,
            textCapitalization: widget.textCapitalization,
            readOnly: !widget.enabled,
            autofocus: widget.autofocus,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            keyboardAppearance: t.brightness,
            cursorWidth: 2,
            cursorRadius: const Radius.circular(1),
            rendererIgnoresPointer: true,
            enableInteractiveSelection: true,
            selectionControls: cupertinoTextSelectionHandleControls,
            // The menu is our own liquid glass capsule, not the system / Cupertino one.
            contextMenuBuilder: (context, editableTextState) =>
                GlassSelectionToolbar.editableText(editableTextState),
          ),
        ),
      ],
    );

    final content = Padding(
      padding: EdgeInsets.fromLTRB(
        widget.leading != null ? widget.slotInset : 18,
        0,
        widget.trailing != null ? widget.slotInset : 18,
        0,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: widget.minHeight),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (widget.leading != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _slot(widget.leading!),
              ),
            Expanded(
              child: Padding(
                // vertical padding so one line is centered in the minimum height (44 - 17 pt text line ~ 12.5 each)
                padding: EdgeInsets.symmetric(
                  vertical:
                      (widget.minHeight -
                          (style.fontSize ?? 17) * (style.height ?? 1.25)) /
                      2,
                ),
                child: field,
              ),
            ),
            if (widget.trailing != null)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: _slot(widget.trailing!),
              ),
          ],
        ),
      ),
    );

    // tapping anywhere on the plate focuses the field
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.enabled ? () => _focus.requestFocus() : null,
      child: _plate(
        radius,
        // the plate grows and shrinks with the lines, animated (native: ~0.25 s, no jump)
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: widget.contentOpacity < 1
              ? Opacity(opacity: widget.contentOpacity, child: content)
              : content,
        ),
      ),
    );
  }

  Widget _plate(double radius, Widget child) {
    final fill = widget.plainFill;
    if (fill != null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: child,
      );
    }
    return GlassSurface(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      liquid: widget.liquid,
      interactive: widget.interactive,
      child: child,
    );
  }

  Widget _slot(Widget child) => SizedBox(
    height: widget.minHeight,
    child: Center(child: child),
  );
}

/// Same wiring as CupertinoTextField: a tap focuses the field and shows the keyboard,
/// the rest (selection, handles, menu) comes from the framework builder.
class _SelectionGestures extends TextSelectionGestureDetectorBuilder {
  _SelectionGestures(this._state) : super(delegate: _state);

  final _GlassTextFieldState _state;

  @override
  void onSingleTapUp(TapDragUpDetails details) {
    super.onSingleTapUp(details);
    _state.editableTextKey.currentState?.requestKeyboard();
  }
}
