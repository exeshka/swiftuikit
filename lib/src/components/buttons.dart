import 'package:flutter/widgets.dart';

import '../theme/swift_ui_theme.dart';
import 'glass_surface.dart';
import 'pressable.dart';
import 'ravel_icon.dart';

/// Round glass button (search, menu, plus...).
class GlassCircleButton extends StatelessWidget {
  const GlassCircleButton({
    super.key,
    this.icon,
    this.child,
    this.onPressed,
    this.size,
    this.semanticLabel,
    this.blur = false,
    this.liquid,
    this.interactive = true,
    this.tint,
    this.iconColor,
  }) : assert(icon != null || child != null);

  /// Any widget (a [RavelIcon], an SVG, an `Icon`...): it gets the button's icon color and size through an [IconTheme].
  final Widget? icon;
  final Widget? child;
  final VoidCallback? onPressed;
  final double? size;
  final String? semanticLabel;

  /// Blur the backdrop behind the button (costly, see [GlassSurface.backdropBlur]).
  final bool blur;

  /// Liquid glass shader on/off; null follows [SwiftUiThemeData.useLiquidGlass].
  /// Turn it off for buttons repeated in lists (≈0.2 ms per plate).
  final bool? liquid;

  /// Native press response of liquid glass (spring scale, highlight, rubber band). The flat fallback keeps the small squish.
  final bool interactive;

  /// Tinted glass (native `.glassEffect(.regular.tint(color))`), e.g. a blue primary action. Null: plain glass.
  final Color? tint;

  /// Icon color; default is the theme's glass icon color (white on a dark tint).
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final d = size ?? t.metrics.circleButtonSize;
    // The press response (grow, highlight, stretch) belongs to the plate in both looks, glass and flat. Only a plate with a
    // backdrop blur has none and keeps the small squish.
    final native = interactive && !blur;
    return Pressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      squish: !native,
      child: GlassSurface.circle(
        size: d,
        backdropBlur: blur,
        liquid: liquid,
        interactive: native,
        fill: tint,
        child:
            child ??
            Center(
              child: IconTheme(
                data: IconThemeData(
                  color: iconColor ?? t.glass.glassIcon,
                  size: d * 0.5,
                ),
                child: icon!,
              ),
            ),
      ),
    );
  }
}

/// The back button of a navigation bar: a glass circle with the native chevron (SF `chevron.left` weight). Without [onPressed] it
/// pops the current route. [TitleBar] and [LargeTitleHeader] show it by themselves when the route can be popped.
class GlassBackButton extends StatelessWidget {
  const GlassBackButton({
    super.key,
    this.onPressed,
    this.size,
    this.liquid,
    this.semanticLabel = 'Back',
  });

  final VoidCallback? onPressed;
  final double? size;
  final bool? liquid;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return GlassCircleButton(
      size: size,
      liquid: liquid,
      semanticLabel: semanticLabel,
      // the native chevron: taller and heavier than the thin list chevron
      icon: const RavelIcon(
        RavelIconKind.chevronLeft,
        size: 26,
        strokeWidth: 2.5,
      ),
      onPressed: onPressed ?? () => Navigator.maybePop(context),
    );
  }
}

/// Glass circle with initials (or any child) used as account button.
class GlassAvatarButton extends StatelessWidget {
  const GlassAvatarButton({
    super.key,
    required this.initials,
    this.onPressed,
    this.accented = false,
    this.size,
    this.liquid,
    this.interactive = true,
  });

  final String initials;
  final VoidCallback? onPressed;

  /// Paint initials on an accent colored disc (ChatGPT style) instead of
  /// plain text on glass (Claude style).
  final bool accented;
  final double? size;
  final bool? liquid;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final d = size ?? t.metrics.avatarSize;
    final native = interactive;
    final text = Text(
      initials,
      style: t.typography.body.copyWith(
        fontSize: accented ? 17 : 22,
        fontWeight: accented ? FontWeight.w500 : FontWeight.w600,
        color: accented ? t.colors.onAccent : t.colors.foreground,
      ),
    );
    return Pressable(
      onPressed: onPressed,
      semanticLabel: 'Account',
      squish: !native,
      child: GlassSurface.circle(
        size: d,
        liquid: liquid,
        interactive: native,
        child: accented
            ? Center(
                child: Container(
                  width: d * 0.72,
                  height: d * 0.72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: t.colors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: text,
                ),
              )
            : Center(child: text),
      ),
    );
  }
}

/// White floating pill with icon and label ("Chat", "New chat").
class FloatingPillButton extends StatelessWidget {
  const FloatingPillButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
  });

  final String label;

  /// Any widget; it gets the pill's foreground color and size 24 through an [IconTheme].
  final Widget? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    return Pressable(
      onPressed: onPressed,
      semanticLabel: label,
      scale: 0.96,
      child: Container(
        height: t.metrics.pillHeight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: ShapeDecoration(
          color: t.colors.pillFill,
          shape: const StadiumBorder(),
          shadows: [
            BoxShadow(
              color: t.colors.pillShadow,
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              IconTheme(
                data: IconThemeData(color: t.colors.pillForeground, size: 24),
                child: icon!,
              ),
              const SizedBox(width: 12),
            ],
            Text(
              label,
              style: t.typography.title.copyWith(
                color: t.colors.pillForeground,
                fontSize: 19,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
