import 'package:flutter/services.dart' show TextCapitalization, TextInputAction;
import 'package:flutter/widgets.dart';

import '../theme/swift_ui_theme.dart';
import 'buttons.dart';
import 'glass_text_field.dart';
import 'headers.dart' show SectionProgress;
import 'ravel_icon.dart';

/// iOS 26 search field: a glass capsule with a magnifier, a clear button while there is text, and a "Cancel" that slides in
/// next to it while the field has focus.
class GlassSearchBar extends StatefulWidget {
  const GlassSearchBar({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'Search',
    this.cancelLabel = 'Cancel',
    this.onChanged,
    this.onSubmitted,
    this.onCancel,
    this.height = 44,
    this.cancelAsButton = false,
    this.alwaysShowCancel = false,
    this.liquid = true,
    this.fill,
    this.cancelLiquid = true,
    this.fadeWithSection = true,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final String cancelLabel;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Called after Cancel cleared the text and dropped the focus.
  final VoidCallback? onCancel;
  final double height;

  /// true: the cancel control is a liquid glass round button with a cross (the messenger look) instead of the text
  /// [cancelLabel].
  final bool cancelAsButton;

  /// true: the cancel control stays while the field is not focused too (a search page that is open whatever the focus is).
  final bool alwaysShowCancel;

  /// true (default): the field is a glass plate. false: a plain container of one colour ([fill], default: the glass tint
  /// flattened onto the page background), like the search field of the native large-title apps. No backdrop pass.
  final bool liquid;
  final Color? fill;

  /// With [cancelAsButton]: true (default) a liquid glass circle, false a plain circle of the field's colour (a flat field
  /// with a flat button, or any mix: plain field + glass button is `liquid: false, cancelLiquid: true`).
  final bool cancelLiquid;

  /// Inside a collapsing [CollapsibleBar] section: the icon and the hint shrink and fade out as it closes while the field's
  /// container stays solid.
  final bool fadeWithSection;

  @override
  State<GlassSearchBar> createState() => _GlassSearchBarState();
}

class _GlassSearchBarState extends State<GlassSearchBar> {
  TextEditingController? _ownController;
  FocusNode? _ownFocus;
  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_rebuild);
    _focus.addListener(_rebuild);
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

  void _cancel() {
    _controller.clear();
    widget.onChanged?.call('');
    _focus.unfocus();
    widget.onCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final focused = _focus.hasFocus;
    final showCancel = focused || widget.alwaysShowCancel;
    final hasText = _controller.text.isNotEmpty;
    return Row(
      children: [
        Expanded(
          child: GlassTextField(
            controller: _controller,
            focusNode: _focus,
            hintText: widget.hintText,
            maxLines: 1,
            minHeight: widget.height,
            textCapitalization: TextCapitalization.none,
            textInputAction: TextInputAction.search,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            interactive: false,
            contentOpacity: widget.fadeWithSection
                ? SectionProgress.fade(SectionProgress.of(context))
                : 1,
            plainFill: widget.liquid
                ? null
                : (widget.fill ??
                      Color.alphaBlend(t.glass.glassFill, t.colors.background)),
            leading: RavelIcon(
              RavelIconKind.search,
              size: 20,
              color: t.glass.glassIcon.withValues(alpha: 0.7),
            ),
            trailing: hasText
                ? GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      _controller.clear();
                      widget.onChanged?.call('');
                    },
                    child: CustomPaint(
                      size: const Size.square(18),
                      painter: _ClearPainter(
                        t.glass.glassIcon.withValues(alpha: 0.6),
                      ),
                    ),
                  )
                : null,
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.centerRight,
          child: showCancel && widget.cancelAsButton
              ? Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: widget.cancelLiquid
                      ? GlassCircleButton(
                          icon: RavelIcon(RavelIconKind.close),
                          size: widget.height,
                          semanticLabel: widget.cancelLabel,
                          onPressed: _cancel,
                        )
                      : GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _cancel,
                          child: Container(
                            width: widget.height,
                            height: widget.height,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  widget.fill ??
                                  Color.alphaBlend(
                                    t.glass.glassFill,
                                    t.colors.background,
                                  ),
                            ),
                            alignment: Alignment.center,
                            child: RavelIcon(
                              RavelIconKind.close,
                              size: 20,
                              color: t.glass.glassIcon,
                            ),
                          ),
                        ),
                )
              : showCancel
              ? GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _cancel,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      widget.cancelLabel,
                      style: t.typography.body.copyWith(
                        fontSize: 17,
                        color: t.colors.accent,
                      ),
                    ),
                  ),
                )
              : const SizedBox(width: 0, height: 0),
        ),
      ],
    );
  }
}

class _ClearPainter extends CustomPainter {
  _ClearPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawCircle(
      s.center(Offset.zero),
      s.width / 2,
      Paint()..color = color,
    );
    final p = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.75)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final c = s.center(Offset.zero);
    final d = s.width * 0.18;
    canvas.drawLine(c + Offset(-d, -d), c + Offset(d, d), p);
    canvas.drawLine(c + Offset(-d, d), c + Offset(d, -d), p);
  }

  @override
  bool shouldRepaint(_ClearPainter old) => old.color != color;
}
