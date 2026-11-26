import 'dart:async';

import 'package:flutter/widgets.dart';

import '../theme/swift_ui_theme.dart';
import '../theme/swift_ui_typography.dart' show iosTracking;
import 'liquid_glass.dart';
import 'pressable.dart';

/// The looks of a [GlassButton], named like SwiftUI's button styles (measured on iOS 26.5, see `tools/native_buttons_ref`).
enum GlassButtonStyle {
  /// `.glass`: a liquid glass capsule, the label in the primary colour (the tint colours the label when one is given).
  glass,

  /// `.glassProminent`: a liquid glass capsule tinted with the accent, a white label. The primary action. It presses like
  /// glass (spring grow, highlight) and keeps the shader look, a flat fill would not.
  glassProminent,

  /// `.bordered`: a flat capsule filled with a light wash of the tint, the label in the tint.
  bordered,

  /// `.borderedProminent`: a flat capsule filled with the tint, a white label.
  borderedProminent,

  /// `.borderless`: no plate, the label in the tint.
  borderless,

  /// `.plain`: no plate, the label in the primary colour.
  plain,
}

/// `controlSize` of SwiftUI. On iOS 26.5 [mini] measures the same as [small] and [extraLarge] the same as [large] (only the label of
/// a button with a title differs a little), the kit keeps all five so code ports one to one.
/// [toolbar] is the size native gives a button in a navigation bar or toolbar (42 pt, bigger than [regular]).
enum GlassButtonSize { mini, small, regular, toolbar, large, extraLarge }

/// An iOS 26 button: `Button` with `.buttonStyle(.glass / .glassProminent / .bordered / .borderedProminent / .borderless / .plain)`,
/// `.controlSize(...)` and `.buttonBorderShape(.capsule / .circle)`.
///
/// ```dart
/// GlassButton(label: 'OPEN', style: GlassButtonStyle.glassProminent, size: GlassButtonSize.small, onPressed: open)
/// GlassButton.circle(icon: RavelIcon(RavelIconKind.search), onPressed: search)
/// ```
///
/// The glass styles are the kit's liquid glass plates with the native press response; with `liquid: false` (or where shaders are not
/// available) they fall back to a flat plate that keeps the same press response. A null [onPressed] disables the button.
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    this.label,
    this.icon,
    this.child,
    this.onPressed,
    this.style = GlassButtonStyle.glass,
    this.size = GlassButtonSize.regular,
    this.tint,
    this.destructive = false,
    this.expand = false,
    this.liquid,
    this.glassOnPress = true,
    this.semanticLabel,
  }) : circle = false,
       assert(label != null || icon != null || child != null);

  /// `.buttonBorderShape(.circle)`: an icon in a round plate.
  const GlassButton.circle({
    super.key,
    required Widget this.icon,
    this.onPressed,
    this.style = GlassButtonStyle.glass,
    this.size = GlassButtonSize.regular,
    this.tint,
    this.destructive = false,
    this.liquid,
    this.glassOnPress = true,
    this.semanticLabel,
  }) : label = null,
       child = null,
       expand = false,
       circle = true;

  /// The title. [icon] and [label] together make `Label(title, systemImage:)`.
  final String? label;

  /// Any widget (a `RavelIcon`, an SVG, an `Icon`): it gets the button's foreground colour and size through an [IconTheme].
  final Widget? icon;

  /// A fully custom label (it replaces [label] and [icon]); wrap its text in the foreground colour yourself.
  final Widget? child;

  /// Null: disabled.
  final VoidCallback? onPressed;
  final GlassButtonStyle style;
  final GlassButtonSize size;

  /// `.tint(color)`: the accent of the style. Null: the theme accent.
  final Color? tint;

  /// `role: .destructive`: the tint is the system red.
  final bool destructive;

  /// The button takes the whole width (`.frame(maxWidth: .infinity)`).
  final bool expand;

  /// Liquid glass shader on/off for the glass styles; null follows the theme.
  final bool? liquid;

  /// [GlassButtonStyle.glassProminent] only. true (default): the button rests as a flat tinted fill and turns into liquid glass while
  /// it is pressed, melting smoothly back into the fill on release (no flash). false: it is glass at rest too, as the native one.
  final bool glassOnPress;
  final String? semanticLabel;
  final bool circle;

  static const _destructiveDark = Color(0xFFFF453A);
  static const _destructiveLight = Color(0xFFFF3B30);

  bool get _glass =>
      style == GlassButtonStyle.glass ||
      style == GlassButtonStyle.glassProminent;
  bool get _hasPlate =>
      style != GlassButtonStyle.borderless && style != GlassButtonStyle.plain;

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final m = _Metrics.of(size);
    final tintColor = destructive
        ? (t.isDark ? _destructiveDark : _destructiveLight)
        : (tint ?? t.colors.accent);
    // the colour of the label, the way each style paints it
    final foreground = switch (style) {
      GlassButtonStyle.glass =>
        (tint != null || destructive) ? tintColor : t.colors.foreground,
      GlassButtonStyle.glassProminent ||
      GlassButtonStyle.borderedProminent => t.colors.onAccent,
      GlassButtonStyle.bordered || GlassButtonStyle.borderless => tintColor,
      GlassButtonStyle.plain => t.colors.foreground,
    };
    final enabled = onPressed != null;
    // a disabled glass button keeps its plate (a dimming Opacity would put the glass into an offscreen layer and it would lose its
    // backdrop) and fades only its label, as the native one does
    final shown = enabled || !_glass
        ? foreground
        : foreground.withValues(alpha: foreground.a * 0.4);
    final content = _content(context, t, m, shown);

    Widget plate;
    if (_glass) {
      plate = _GlassPlate(
        prominent: style == GlassButtonStyle.glassProminent,
        glassOnPress: glassOnPress,
        useGlass: liquid ?? t.glass.useLiquidGlass,
        tint: style == GlassButtonStyle.glassProminent ? tintColor : null,
        circle: circle,
        height: circle ? m.circle : m.height,
        padX: m.padX,
        enabled: enabled,
        onPressed: onPressed,
        semanticLabel: semanticLabel ?? label,
        child: content,
      );
    } else {
      plate = _FlatButton(
        style: style,
        tint: tintColor,
        height: circle ? m.circle : m.height,
        width: circle ? m.circle : null,
        padX: m.padX,
        onPressed: onPressed,
        semanticLabel: semanticLabel ?? label,
        hasPlate: _hasPlate,
        child: content,
      );
    }
    if (expand && !circle)
      plate = SizedBox(width: double.infinity, child: plate);
    return enabled || _glass ? plate : Opacity(opacity: 0.4, child: plate);
  }

  Widget _content(
    BuildContext context,
    SwiftUiThemeData t,
    _Metrics m,
    Color foreground,
  ) {
    if (child != null) return child!;
    final text = label == null
        ? null
        : Text(
            label!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.typography.body.copyWith(
              fontSize: m.font,
              fontWeight: FontWeight.w400,
              letterSpacing: iosTracking(m.font),
              color: foreground,
              height: 1,
            ),
          );
    final glyph = icon == null
        ? null
        : IconTheme(
            data: IconThemeData(
              color: foreground,
              size: circle ? m.circle * 0.55 : m.font * 1.1,
            ),
            child: icon!,
          );
    if (text != null && glyph != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          glyph,
          SizedBox(width: m.font * 0.45),
          Flexible(child: text),
        ],
      );
    }
    return glyph ?? text!;
  }
}

/// Native sizes measured on iOS 26.5 (a button with "Open" and an icon circle, pt).
class _Metrics {
  const _Metrics(this.height, this.circle, this.padX, this.font);
  final double height;
  final double circle;
  final double padX;
  final double font;

  static _Metrics of(GlassButtonSize s) => switch (s) {
    GlassButtonSize.mini => const _Metrics(26, 24, 10, 13),
    GlassButtonSize.small => const _Metrics(28, 24, 12, 15),
    GlassButtonSize.regular => const _Metrics(34, 30, 14, 17),
    GlassButtonSize.toolbar => const _Metrics(42, 42, 15, 17),
    GlassButtonSize.large => const _Metrics(50, 46, 18, 17),
    GlassButtonSize.extraLarge => const _Metrics(50, 46, 18, 20),
  };
}

/// The flat styles: bordered / borderedProminent / borderless / plain. The fill follows the press like the native one does.
class _FlatButton extends StatefulWidget {
  const _FlatButton({
    required this.style,
    required this.tint,
    required this.height,
    required this.width,
    required this.padX,
    required this.onPressed,
    required this.semanticLabel,
    required this.hasPlate,
    required this.child,
  });

  final GlassButtonStyle style;
  final Color tint;
  final double height;
  final double? width;
  final double padX;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final bool hasPlate;
  final Widget child;

  @override
  State<_FlatButton> createState() => _FlatButtonState();
}

class _FlatButtonState extends State<_FlatButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final Color fill;
    final double dim;
    switch (widget.style) {
      case GlassButtonStyle.bordered:
        fill = widget.tint.withValues(alpha: _down ? 0.30 : 0.16);
        dim = 1;
      case GlassButtonStyle.borderedProminent:
        fill = widget.tint;
        dim = _down ? 0.82 : 1;
      case GlassButtonStyle.borderless || GlassButtonStyle.plain || _:
        fill = const Color(0x00000000);
        // a label without a plate dims while it is pressed
        dim = _down ? 0.45 : 1;
    }
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onPressed == null ? null : (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onPressed,
        child: AnimatedOpacity(
          opacity: dim,
          duration: const Duration(milliseconds: 90),
          child: Container(
            height: widget.height,
            width: widget.width,
            padding: widget.width != null
                ? null
                : EdgeInsets.symmetric(
                    horizontal: widget.hasPlate ? widget.padX : 4,
                  ),
            decoration: ShapeDecoration(
              color: fill,
              shape: widget.width != null
                  ? const CircleBorder()
                  : const StadiumBorder(),
            ),
            // widthFactor: the label sizes the button, a plain Center would take the whole width
            child: Center(widthFactor: 1, child: widget.child),
          ),
        ),
      ),
    );
  }
}

/// The liquid glass plate of the glass styles. A prominent one rests flat and is glass only while pressed; both ways cross-fade.
class _GlassPlate extends StatefulWidget {
  const _GlassPlate({
    required this.prominent,
    required this.glassOnPress,
    required this.useGlass,
    required this.tint,
    required this.circle,
    required this.height,
    required this.padX,
    required this.enabled,
    required this.onPressed,
    required this.semanticLabel,
    required this.child,
  });

  final bool prominent;
  final bool glassOnPress;
  final bool useGlass;
  final Color? tint;
  final bool circle;
  final double height;
  final double padX;
  final bool enabled;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final Widget child;

  @override
  State<_GlassPlate> createState() => _GlassPlateState();
}

class _GlassPlateState extends State<_GlassPlate> {
  // a quick tap still shows the glass for a moment: it is held this long from the touch-down
  static const _minGlass = Duration(milliseconds: 220);
  bool _glass = false;
  DateTime _downAt = DateTime.now();
  Timer? _release;

  void _down() {
    _release?.cancel();
    _downAt = DateTime.now();
    if (!_glass) setState(() => _glass = true);
  }

  void _up() {
    final wait = _minGlass - DateTime.now().difference(_downAt);
    _release?.cancel();
    if (wait <= Duration.zero) {
      if (_glass && mounted) setState(() => _glass = false);
    } else {
      _release = Timer(wait, () {
        if (mounted) setState(() => _glass = false);
      });
    }
  }

  @override
  void dispose() {
    _release?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final restFlat = w.prominent && w.glassOnPress;
    // flat: the plate is the flat fill. Without the shader it always is; a prominent one is flat until it is pressed.
    final flat = !w.useGlass || (restFlat && !_glass);
    final plate = LiquidGlass(
      width: w.circle ? w.height : null,
      height: w.height,
      interactive: w.enabled,
      tint: w.tint,
      flat: flat,
      // glass -> fill melts over 320 ms, fill -> glass takes 140 ms: no flash either way
      flatFade: w.useGlass ? const Duration(milliseconds: 320) : null,
      glassFade: const Duration(milliseconds: 140),
      child: w.circle
          ? Center(child: w.child)
          : Padding(
              padding: EdgeInsets.symmetric(horizontal: w.padX),
              child: Center(widthFactor: 1, child: w.child),
            ),
    );
    return Pressable(
      onPressed: w.onPressed,
      semanticLabel: w.semanticLabel,
      squish: false,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: w.enabled ? (_) => _down() : null,
        onPointerUp: (_) => _up(),
        onPointerCancel: (_) => _up(),
        child: plate,
      ),
    );
  }
}
