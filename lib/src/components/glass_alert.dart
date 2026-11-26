import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/swift_ui_theme.dart';
import '../theme/swift_ui_typography.dart' show iosTracking;
import 'glass_sheet.dart' show GlassSheetOriginController;
import 'liquid_glass.dart';
import 'press_tracker.dart';

/// What a button of an alert / action dialog means, as SwiftUI's `ButtonRole`.
enum GlassAlertRole {
  /// A plain button.
  normal,

  /// `.cancel`: goes first in a row of two, last in a stack; an action dialog hides it (a tap outside is the cancel).
  cancel,

  /// `.destructive`: red.
  destructive,

  /// The default action, `keyboardShortcut(.defaultAction)`: semibold.
  preferred,
}

/// A button of [showGlassAlert] / [showGlassActionDialog]. Tapping it closes the dialog; [value] is what the dialog returns.
class GlassAlertAction<T> {
  const GlassAlertAction({
    required this.label,
    this.role = GlassAlertRole.normal,
    this.value,
    this.onPressed,
  });

  final String label;
  final GlassAlertRole role;

  /// Returned by [showGlassAlert].
  final T? value;

  /// Called after the dialog started closing.
  final VoidCallback? onPressed;
}

/// A text field in an alert (`TextField` inside `.alert`). Read the text from [controller].
class GlassAlertField {
  const GlassAlertField({
    required this.controller,
    this.placeholder,
    this.obscureText = false,
    this.keyboardType,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String? placeholder;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool autofocus;
}

/// An iOS 26 alert, `.alert(title, isPresented:)`: a card of liquid glass in the middle of the screen with a left-aligned title and
/// message and glass buttons (two side by side, more stacked). Completes with the [GlassAlertAction.value] of the tapped button.
///
/// ```dart
/// final ok = await showGlassAlert<bool>(
///   context,
///   title: 'Delete the file?',
///   message: 'This cannot be undone.',
///   actions: const [
///     GlassAlertAction(label: 'Delete', role: GlassAlertRole.destructive, value: true),
///     GlassAlertAction(label: 'Cancel', role: GlassAlertRole.cancel, value: false),
///   ],
/// );
/// ```
Future<T?> showGlassAlert<T>(
  BuildContext context, {
  String? title,
  String? message,
  required List<GlassAlertAction<T>> actions,
  List<GlassAlertField> fields = const [],
  bool barrierDismissible = false,
  bool? liquid,
  bool useRootNavigator = true,
}) {
  return Navigator.of(context, rootNavigator: useRootNavigator).push(
    GlassDialogRoute<T>(
      title: title,
      message: message,
      actions: actions,
      fields: fields,
      barrierDismissible: barrierDismissible,
      liquid: liquid,
    ),
  );
}

/// An iOS 26 `.confirmationDialog`: a narrower glass card with a stack of full-width glass buttons. With [origin] the card opens next
/// to the control (below it, or above when there is no room) and grows out of it; without, it sits at the bottom of the screen. A
/// `cancel` action is not drawn: a tap outside the card closes it and returns that action's value.
Future<T?> showGlassActionDialog<T>(
  BuildContext context, {
  String? title,
  String? message,
  required List<GlassAlertAction<T>> actions,
  GlassSheetOriginController? origin,
  bool? liquid,
  bool useRootNavigator = true,
}) {
  return Navigator.of(context, rootNavigator: useRootNavigator).push(
    GlassDialogRoute<T>(
      title: title,
      message: message,
      actions: actions,
      actionDialog: true,
      origin: origin,
      barrierDismissible: true,
      liquid: liquid,
    ),
  );
}

/// The route behind [showGlassAlert] and [showGlassActionDialog]. Transparent: the dialog draws its own dim.
class GlassDialogRoute<T> extends PopupRoute<T> {
  GlassDialogRoute({
    super.settings,
    this.title,
    this.message,
    required this.actions,
    this.fields = const [],
    this.actionDialog = false,
    this.origin,
    this.barrierDismissible = false,
    this.liquid,
  });

  final String? title;
  final String? message;
  final List<GlassAlertAction<T>> actions;
  final List<GlassAlertField> fields;
  final bool actionDialog;
  final GlassSheetOriginController? origin;
  final bool? liquid;

  @override
  final bool barrierDismissible;

  // measured on the native alert: it settles in a blink and fades out faster still
  @override
  Duration get transitionDuration => const Duration(milliseconds: 240);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 240);

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _GlassDialog<T>(route: this, animation: animation);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

class _GlassDialog<T> extends StatelessWidget {
  const _GlassDialog({required this.route, required this.animation});

  final GlassDialogRoute<T> route;
  final Animation<double> animation;

  void _close(GlassAlertAction<T>? a) {
    Navigator.of(route.navigator!.context).pop(a?.value);
    a?.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final action = route.actionDialog;
    final width = action ? 240.0 : math.min(320.0, mq.size.width - 48);
    final cancel = route.actions
        .where((a) => a.role == GlassAlertRole.cancel)
        .firstOrNull;
    final card = _Card<T>(
      width: width,
      title: route.title,
      message: route.message,
      actions: route.actions,
      fields: route.fields,
      stacked: action,
      hideCancel: action,
      onTap: _close,
      liquid: route.liquid,
    );
    return AnimatedBuilder(
      animation: animation,
      child: card,
      builder: (context, child) {
        final v = animation.value.clamp(0.0, 1.0);
        final closing = animation.status == AnimationStatus.reverse;
        // native alert: opens from 1.12x, easing down onto its size while it fades in; closes with a plain fade
        final grow = closing ? 1.0 : Curves.easeOutCubic.transform(v);
        final scale = 1 + 0.12 * (1 - grow);
        final fade = closing
            ? v
            : Curves.easeOut.transform((v * 2).clamp(0, 1));
        Widget placed;
        if (action) {
          placed = _anchored(context, mq, child!, width, grow, fade);
        } else {
          placed = Center(
            child: Padding(
              // native centres the alert in the safe area (the keyboard shrinks it from below)
              padding: EdgeInsets.only(
                top: mq.padding.top,
                bottom: math.max(mq.padding.bottom, mq.viewInsets.bottom),
              ),
              child: Transform.scale(
                scale: scale,
                child: _Fade(opacity: fade, child: child!),
              ),
            ),
          );
        }
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: route.barrierDismissible ? () => _close(cancel) : null,
                // native dim: black at about 20 %
                child: ColoredBox(
                  color: const Color(0xFF000000).withValues(alpha: 0.2 * fade),
                ),
              ),
            ),
            placed,
          ],
        );
      },
    );
  }

  Widget _anchored(
    BuildContext context,
    MediaQueryData mq,
    Widget child,
    double width,
    double grow,
    double fade,
  ) {
    final o = route.origin?.rect;
    if (o == null) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(bottom: mq.padding.bottom + 8),
          child: Transform.scale(
            scale: 0.9 + 0.1 * grow,
            child: _Fade(opacity: fade, child: child),
          ),
        ),
      );
    }
    final left = (o.center.dx - width / 2).clamp(
      16.0,
      mq.size.width - width - 16,
    );
    final below = o.bottom + 8;
    // the card is as tall as it is: place it under the control while that leaves room, above otherwise
    final fitsBelow = below < mq.size.height * 0.45;
    return Positioned(
      left: left,
      top: fitsBelow ? below : null,
      bottom: fitsBelow ? null : mq.size.height - o.top + 8,
      child: Transform.scale(
        scale: 0.85 + 0.15 * grow,
        alignment: Alignment(
          (o.center.dx - left) / width * 2 - 1,
          fitsBelow ? -1 : 1,
        ),
        child: _Fade(opacity: fade, child: child),
      ),
    );
  }
}

class _Card<T> extends StatelessWidget {
  const _Card({
    required this.width,
    required this.title,
    required this.message,
    required this.actions,
    required this.fields,
    required this.stacked,
    required this.hideCancel,
    required this.onTap,
    required this.liquid,
  });

  final double width;
  final String? title;
  final String? message;
  final List<GlassAlertAction<T>> actions;
  final List<GlassAlertField> fields;
  final bool stacked;
  final bool hideCancel;
  final void Function(GlassAlertAction<T>) onTap;
  final bool? liquid;

  static const _side = 16.0; // the buttons' and field's inset from the card
  static const _textSide = 32.0; // the title's and message's
  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final titleStyle = t.typography.body.copyWith(
      fontSize: 17.5,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: iosTracking(18),
      color: t.colors.foreground,
    );
    final messageStyle = t.typography.body.copyWith(
      fontSize: 15.5,
      height: 20 / 15.5,
      letterSpacing: iosTracking(15),
      color: t.colors.foregroundSecondary,
    );
    final cancel = actions
        .where((a) => a.role == GlassAlertRole.cancel)
        .toList();
    final others = actions
        .where((a) => a.role != GlassAlertRole.cancel)
        .toList();
    final shown = hideCancel ? others : [...others, ...cancel];
    // two buttons share a row (the cancel one first); more, or long labels, stack
    final row =
        !stacked &&
        shown.length == 2 &&
        shown.every((a) => a.label.length <= 14);
    final ordered = row ? [...cancel, ...others] : shown;
    return SizedBox(
      width: width,
      child: _Plate(
        liquid: liquid,
        child: PressTracker<GlassAlertAction<T>>(
          onActivate: onTap,
          builder: (context, hot, keyOf) {
            Widget button(GlassAlertAction<T> a) => _AlertButton(
              key: keyOf(a),
              label: a.label,
              role: a.role,
              pressed: identical(hot, a),
            );
            return Padding(
              padding: const EdgeInsets.fromLTRB(_side, 23.3, _side, 15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (title != null && title!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: _textSide - _side,
                      ),
                      child: Text(
                        title!,
                        style: titleStyle,
                        // a title without a message is centred, as in a native alert
                        textAlign: message == null || message!.isEmpty
                            ? TextAlign.center
                            : TextAlign.start,
                      ),
                    ),
                  if (message != null && message!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        _textSide - _side,
                        title == null ? 0 : 4,
                        _textSide - _side,
                        0,
                      ),
                      child: Text(message!, style: messageStyle),
                    ),
                  if (title != null || message != null)
                    const SizedBox(height: 20),
                  for (var i = 0; i < fields.length; i++) ...[
                    if (i > 0) const SizedBox(height: _gap),
                    _AlertField(field: fields[i]),
                  ],
                  if (fields.isNotEmpty) const SizedBox(height: 20),
                  if (row)
                    Row(
                      children: [
                        for (var i = 0; i < ordered.length; i++) ...[
                          if (i > 0) const SizedBox(width: _gap),
                          Expanded(child: button(ordered[i])),
                        ],
                      ],
                    )
                  else
                    for (var i = 0; i < ordered.length; i++) ...[
                      if (i > 0) const SizedBox(height: _gap),
                      button(ordered[i]),
                    ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AlertButton extends StatelessWidget {
  const _AlertButton({
    super.key,
    required this.label,
    required this.role,
    required this.pressed,
  });

  final String label;
  final GlassAlertRole role;

  /// The finger is on this button (it follows the finger, see [PressTracker]).
  final bool pressed;

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final destructive = role == GlassAlertRole.destructive;
    // the preferred (default) action is a filled capsule in the tint, as in a native alert
    final preferred = role == GlassAlertRole.preferred;
    final color = destructive
        ? (t.isDark ? const Color(0xFFFF453A) : const Color(0xFFFF3B30))
        : preferred
        ? t.colors.onAccent
        : t.colors.foreground;
    final fill = preferred
        ? Color.alphaBlend(
            pressed ? const Color(0x33000000) : const Color(0x00000000),
            t.colors.accent,
          )
        : t.colors.foreground.withValues(alpha: pressed ? 0.26 : 0.12);
    return Container(
      height: 48,
      alignment: Alignment.center,
      decoration: ShapeDecoration(shape: const StadiumBorder(), color: fill),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: t.typography.body.copyWith(
          fontSize: 18,
          height: 1,
          letterSpacing: iosTracking(18),
          fontWeight: preferred ? FontWeight.w600 : FontWeight.w400,
          color: color,
        ),
      ),
    );
  }
}

class _AlertField extends StatefulWidget {
  const _AlertField({required this.field});

  final GlassAlertField field;

  @override
  State<_AlertField> createState() => _AlertFieldState();
}

class _AlertFieldState extends State<_AlertField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.field.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final style = t.typography.body.copyWith(
      fontSize: 18,
      height: 1.2,
      letterSpacing: iosTracking(18),
      color: t.colors.foreground,
    );
    final f = widget.field;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        color: t.colors.foreground.withValues(alpha: 0.12),
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          if (f.placeholder != null)
            ListenableBuilder(
              listenable: f.controller,
              builder: (context, _) => f.controller.text.isEmpty
                  ? Text(
                      f.placeholder!,
                      style: style.copyWith(color: t.colors.foregroundTertiary),
                    )
                  : const SizedBox.shrink(),
            ),
          EditableText(
            controller: f.controller,
            focusNode: _focus,
            style: style,
            cursorColor: t.colors.accent,
            backgroundCursorColor: t.colors.foregroundTertiary,
            obscureText: f.obscureText,
            keyboardType: f.keyboardType,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

/// The glass card; a flat opaque one without shaders or with `liquid: false`.
class _Plate extends StatelessWidget {
  const _Plate({required this.liquid, required this.child});

  final bool? liquid;
  final Widget child;

  static const radius = 42.0;

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final glass = (liquid ?? t.glass.useLiquidGlass) && LiquidGlass.supported;
    final opacity = _Fade.of(context);
    // the whole card answers a touch like glass does: it grows, stretches under the finger and lights up
    return LiquidGlass(
      cornerRadius: radius,
      opacity: opacity,
      interactive: true,
      // the glow stays around the finger instead of turning the whole card grey
      glowSigma: 70,
      glowStrength: 0.7,
      stretch: 3,
      flat: !glass,
      tint: glass
          ? null
          : (t.isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7)),
      child: child,
    );
  }
}

/// The fade of a dialog card. An [Opacity] around a glass plate would put it in an offscreen layer without a backdrop, so the
/// plate reads the value from here and fades inside its own pass ([LiquidGlass.opacity]).
class _Fade extends InheritedWidget {
  const _Fade({required this.opacity, required super.child});

  final double opacity;

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Fade>()?.opacity ?? 1;

  @override
  bool updateShouldNotify(_Fade old) => old.opacity != opacity;
}
