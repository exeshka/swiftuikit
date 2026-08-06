import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

part 'swift_text/swift_text_motion.dart';
part 'swift_text/swift_text_controller.dart';
part 'swift_text/swift_text_atlas.dart';
part 'swift_text/swift_text_render_widget.dart';
part 'swift_text/swift_text_rendering.dart';
part 'swift_text/swift_text_scene.dart';
part 'swift_text/text_layout.dart';

const _defaultTransitionDuration = Duration(milliseconds: 450);

/// A glyph-level Flutter counterpart of SwiftUI's
/// `.contentTransition(.numericText())`.
///
/// Matching numeric slots remain sharp. A stable single-line non-numeric
/// template is also preserved when only its digits change; other text is
/// replaced. Changed glyphs transition from leading to trailing edge using
/// vertical motion, opacity and blur. Updating [data] (or [text] in the rich
/// constructor) starts the transition automatically. Style-only changes are
/// applied without starting a glyph transition.
class SwiftText extends StatefulWidget {
  const SwiftText(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.locale,
    this.softWrap = true,
    this.overflow = TextOverflow.visible,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.countsDown,
    this.duration = _defaultTransitionDuration,
    this.curve = const SwiftTextSmoothCurve(),
    this.onEnd,
  }) : text = null;

  const SwiftText.rich(
    TextSpan this.text, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.locale,
    this.softWrap = true,
    this.overflow = TextOverflow.visible,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.countsDown,
    this.duration = _defaultTransitionDuration,
    this.curve = const SwiftTextSmoothCurve(),
    this.onEnd,
  }) : data = null;

  final String? data;

  /// Rich content. [WidgetSpan] is not supported because inline render objects
  /// cannot be moved as independent glyphs.
  final TextSpan? text;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool softWrap;
  final TextOverflow overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;

  /// Controls the roll direction of the transition.
  ///
  /// * `null` (default) — the direction is detected automatically by comparing
  ///   the numeric values in the old and new content: a decrease rolls down,
  ///   an increase rolls up. Content without a meaningful number change keeps
  ///   the previous direction.
  /// * `true` — force the count-down direction: the outgoing glyph exits below
  ///   and the incoming glyph enters from above.
  /// * `false` — force the count-up direction: the outgoing glyph exits above
  ///   and the incoming glyph enters from below.
  final bool? countsDown;
  final Duration duration;
  final Curve curve;
  final VoidCallback? onEnd;

  @override
  State<SwiftText> createState() => _SwiftTextState();
}
