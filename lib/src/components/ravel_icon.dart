import 'dart:math' as math;

import 'package:flutter/widgets.dart';

enum RavelIconKind {
  search,
  menu,
  plus,
  compose,
  chat,
  tasks,
  chevronRight,
  chevronLeft,
  check,
  pencil,
  artifacts,
  close,
}

/// Thin-stroke line icons drawn with paths, so the kit has no icon font
/// dependency and strokes match the iOS look.
class RavelIcon extends StatelessWidget {
  const RavelIcon(
    this.kind, {
    super.key,
    this.size,
    this.color,
    this.strokeWidth = 1.8,
  });

  final RavelIconKind kind;

  /// Null: the size of the surrounding [IconTheme], else 24.
  final double? size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    // an icon placed in a button / tab takes its color and size from the IconTheme the component sets
    final theme = context.dependOnInheritedWidgetOfExactType<IconTheme>()?.data;
    final c =
        color ??
        theme?.color ??
        DefaultTextStyle.of(context).style.color ??
        const Color(0xFFFFFFFF);
    return SizedBox.square(
      dimension: size ?? theme?.size ?? 24,
      child: CustomPaint(painter: _IconPainter(kind, c, strokeWidth)),
    );
  }
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.kind, this.color, this.stroke);
  final RavelIconKind kind;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.scale(s);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void line(double x1, double y1, double x2, double y2) =>
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), p);
    switch (kind) {
      case RavelIconKind.search:
        canvas.drawCircle(const Offset(10.5, 10.5), 6.8, p);
        line(15.6, 15.6, 20.4, 20.4);
      case RavelIconKind.menu:
        line(4, 7, 20, 7);
        line(4, 12, 13, 12);
        line(4, 17, 20, 17);
      case RavelIconKind.plus:
        line(12, 4.5, 12, 19.5);
        line(4.5, 12, 19.5, 12);
      case RavelIconKind.compose:
        final path = Path()
          ..moveTo(11, 4.5)
          ..lineTo(7.5, 4.5)
          ..arcToPoint(
            const Offset(3.5, 8.5),
            radius: const Radius.circular(4),
            clockwise: false,
          )
          ..lineTo(3.5, 16.5)
          ..arcToPoint(
            const Offset(7.5, 20.5),
            radius: const Radius.circular(4),
            clockwise: false,
          )
          ..lineTo(15.5, 20.5)
          ..arcToPoint(
            const Offset(19.5, 16.5),
            radius: const Radius.circular(4),
            clockwise: false,
          )
          ..lineTo(19.5, 13);
        canvas.drawPath(path, p);
        final pen = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 1.9
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(const Offset(10.5, 13.5), const Offset(19.2, 4.8), pen);
      case RavelIconKind.chat:
        final path = Path()
          ..moveTo(12, 3.8)
          ..cubicTo(7.2, 3.8, 3.5, 7.2, 3.5, 11.6)
          ..cubicTo(3.5, 13.6, 4.3, 15.4, 5.6, 16.8)
          ..cubicTo(5.4, 18.2, 4.8, 19.4, 3.8, 20.2)
          ..cubicTo(5.9, 20.2, 7.4, 19.6, 8.5, 18.8)
          ..cubicTo(9.5, 19.2, 10.7, 19.4, 12, 19.4)
          ..cubicTo(16.8, 19.4, 20.5, 16, 20.5, 11.6)
          ..cubicTo(20.5, 7.2, 16.8, 3.8, 12, 3.8)
          ..close();
        canvas.drawPath(path, p);
      case RavelIconKind.tasks:
        line(4.5, 5.5, 6.5, 7.5);
        line(6.5, 7.5, 9.5, 3.8);
        canvas.drawCircle(const Offset(6.5, 16.5), 2.2, p);
        line(12.5, 6, 20, 6);
        line(12.5, 16.5, 20, 16.5);
      case RavelIconKind.chevronRight:
        canvas.drawPath(
          Path()
            ..moveTo(9, 5)
            ..lineTo(16, 12)
            ..lineTo(9, 19),
          p,
        );
      case RavelIconKind.check:
        canvas.drawPath(
          Path()
            ..moveTo(4.5, 12.5)
            ..lineTo(9.5, 17.5)
            ..lineTo(19.5, 6.5),
          p,
        );
      case RavelIconKind.chevronLeft:
        canvas.drawPath(
          Path()
            ..moveTo(15, 5)
            ..lineTo(8, 12)
            ..lineTo(15, 19),
          p,
        );
      case RavelIconKind.pencil:
        canvas.save();
        canvas.translate(12, 12);
        canvas.rotate(math.pi / 4);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-3, -10, 6, 17),
            const Radius.circular(1.5),
          ),
          p,
        );
        canvas.drawPath(
          Path()
            ..moveTo(-3, 7)
            ..lineTo(0, 11.5)
            ..lineTo(3, 7),
          p,
        );
        canvas.restore();
      case RavelIconKind.close:
        line(6, 6, 18, 18);
        line(18, 6, 6, 18);
      case RavelIconKind.artifacts:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3.5, 7.5, 12, 12),
            const Radius.circular(2.5),
          ),
          p,
        );
        canvas.drawPath(
          Path()
            ..moveTo(8, 7.5)
            ..lineTo(8, 5.5)
            ..arcToPoint(
              const Offset(10, 3.5),
              radius: const Radius.circular(2),
              clockwise: true,
            )
            ..lineTo(18.5, 3.5)
            ..arcToPoint(
              const Offset(20.5, 5.5),
              radius: const Radius.circular(2),
              clockwise: true,
            )
            ..lineTo(20.5, 14)
            ..arcToPoint(
              const Offset(18.5, 16),
              radius: const Radius.circular(2),
              clockwise: true,
            )
            ..lineTo(15.5, 16),
          p,
        );
    }
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.kind != kind || old.color != color || old.stroke != stroke;
}
