import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/swift_ui_theme.dart';
import 'glass_surface.dart';

/// An entry of a [showGlassMenu] / [GlassMenuButton] menu.
sealed class GlassMenuEntry {
  const GlassMenuEntry();
}

/// A tappable row: optional [leading] widget (icon), label, optional check mark.
class GlassMenuItem extends GlassMenuEntry {
  const GlassMenuItem({
    required this.label,
    this.leading,
    this.destructive = false,
    this.checked = false,
    this.onSelected,
  });

  final String label;
  final Widget? leading;

  /// Red label and icon (delete, sign out...).
  final bool destructive;
  final bool checked;
  final VoidCallback? onSelected;
}

/// Thick separator between groups of items (native menus group with an 8 pt gap).
class GlassMenuDivider extends GlassMenuEntry {
  const GlassMenuDivider();
}

const _kItemHeight = 44.0;
const _kDividerHeight = 8.0;
const _kPad = 6.0;

/// Native-style menu (UIMenu / SwiftUI Menu): a glass panel that pops out of the widget [context] belongs to, scaling
/// from the anchor corner with a spring, and dismisses on a tap outside or on an item.
Future<void> showGlassMenu(
  BuildContext context, {
  required List<GlassMenuEntry> entries,
  double width = 254,
}) {
  final box = context.findRenderObject() as RenderBox;
  final anchor = box.localToGlobal(Offset.zero) & box.size;
  return Navigator.of(
    context,
    rootNavigator: true,
  ).push(_GlassMenuRoute(anchor: anchor, entries: entries, width: width));
}

/// Gives [builder] an `open` callback that shows the menu anchored to the widget it returns. Hand `open` to your button:
///
/// ```dart
/// GlassMenuButton(
///   entries: [...],
///   builder: (context, open) => GlassCircleButton(icon: RavelIcon(RavelIconKind.menu), onPressed: open),
/// )
/// ```
/// (use it as `onLongPress` of anything for a context menu).
class GlassMenuButton extends StatelessWidget {
  const GlassMenuButton({
    super.key,
    required this.builder,
    required this.entries,
    this.width = 254,
  });

  final Widget Function(BuildContext context, VoidCallback open) builder;
  final List<GlassMenuEntry> entries;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (c) =>
          builder(c, () => showGlassMenu(c, entries: entries, width: width)),
    );
  }
}

class _GlassMenuRoute extends PopupRoute<void> {
  _GlassMenuRoute({
    required this.anchor,
    required this.entries,
    required this.width,
  });

  final Rect anchor;
  final List<GlassMenuEntry> entries;
  final double width;

  @override
  Color? get barrierColor => null;
  @override
  bool get barrierDismissible => true;
  @override
  String? get barrierLabel => 'Dismiss';
  @override
  Duration get transitionDuration => const Duration(milliseconds: 380);
  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 180);

  double get _height =>
      _kPad * 2 +
      entries.fold<double>(
        0,
        (h, e) => h + (e is GlassMenuDivider ? _kDividerHeight : _kItemHeight),
      );

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
  ) {
    final size = MediaQuery.sizeOf(context);
    final safe = MediaQuery.paddingOf(context);
    final h = _height;
    const margin = 12.0;
    // under the anchor when it fits, above it otherwise; aligned to the anchor's near screen edge
    final below = anchor.bottom + 8 + h <= size.height - safe.bottom - margin;
    final top = below
        ? anchor.bottom + 8
        : math.max(safe.top + margin, anchor.top - 8 - h);
    final alignRight = anchor.center.dx > size.width / 2;
    var left = alignRight ? anchor.right - width : anchor.left;
    left = left.clamp(margin, size.width - width - margin);
    final origin = Alignment(
      ((anchor.center.dx - left) / width * 2 - 1).clamp(-1.0, 1.0),
      below ? -1 : 1,
    );
    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          width: width,
          height: h,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final scale =
                  0.55 +
                  0.45 *
                      Curves.easeOutBack.transform(
                        animation.value.clamp(0.0, 1.0),
                      );
              return Opacity(
                opacity: Curves.easeOut.transform(
                  (animation.value * 1.6).clamp(0.0, 1.0),
                ),
                child: Transform.scale(
                  scale: scale,
                  alignment: origin,
                  child: child,
                ),
              );
            },
            child: _MenuPanel(entries: entries),
          ),
        ),
      ],
    );
  }
}

class _MenuPanel extends StatelessWidget {
  const _MenuPanel({required this.entries});
  final List<GlassMenuEntry> entries;

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    // the route sits above the app's Material: without this default, Text gets the yellow double underline
    return DefaultTextStyle(
      style: t.typography.body.copyWith(decoration: TextDecoration.none),
      child: GlassSurface(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        backdropBlur: true,
        sigma: 28,
        fill: t.isDark ? const Color(0xE62C2C2E) : const Color(0xE6F2F2F7),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: _kPad),
          child: Column(
            children: [
              for (final e in entries)
                switch (e) {
                  GlassMenuDivider() => Container(
                    height: _kDividerHeight,
                    margin: const EdgeInsets.symmetric(vertical: 0),
                    color: t.colors.foreground.withValues(alpha: 0.08),
                  ),
                  final GlassMenuItem item => _MenuRow(item: item),
                },
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatefulWidget {
  const _MenuRow({required this.item});
  final GlassMenuItem item;
  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final item = widget.item;
    final color = item.destructive
        ? const Color(0xFFFF453A)
        : t.colors.foreground;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        Navigator.of(context).pop();
        item.onSelected?.call();
      },
      child: Container(
        height: _kItemHeight,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _down
              ? t.colors.foreground.withValues(alpha: 0.12)
              : const Color(0x00000000),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            if (item.checked)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: CustomPaint(
                  size: const Size(16, 16),
                  painter: _CheckPainter(color),
                ),
              ),
            Expanded(
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.typography.body.copyWith(fontSize: 17, color: color),
              ),
            ),
            if (item.leading != null)
              IconTheme(
                data: IconThemeData(color: color, size: 22),
                child: DefaultTextStyle(
                  style: TextStyle(color: color),
                  child: item.leading!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(s.width * 0.12, s.height * 0.55)
        ..lineTo(s.width * 0.4, s.height * 0.82)
        ..lineTo(s.width * 0.9, s.height * 0.2),
      p,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.color != color;
}
