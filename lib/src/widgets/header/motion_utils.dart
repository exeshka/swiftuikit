import 'package:flutter/material.dart';
import 'package:swiftuikit/src/composables/motion_blur_row.dart';
import 'package:swiftuikit/src/widgets/header/swift_header.dart';
import 'package:swiftuikit/src/widgets/toolbar/toolbar_button.dart';
import 'package:swiftuikit/src/widgets/toolbar/toolbar_item_group.dart';

Widget motionChild(Widget child) {
  if (child is Row) {
    return MotionBlurRow(
      mainAxisAlignment: child.mainAxisAlignment,
      mainAxisSize: child.mainAxisSize,
      crossAxisAlignment: child.crossAxisAlignment,
      textDirection: child.textDirection,
      verticalDirection: child.verticalDirection,
      textBaseline: child.textBaseline,
      spacing: child.spacing,
      clipMotion: false,
      signatureFn: motionSignature,
      children: child.children,
    );
  }

  return child;
}

String motionSignature(Widget widget) {
  final key = widget.key;
  final keyPart = key == null ? '' : '#$key';

  if (widget is ToolbarItemGroup) {
    return '${widget.runtimeType}$keyPart';
  }

  if (widget is MotionBlurRow) {
    return '${widget.runtimeType}$keyPart';
  }

  if (widget is ToolbarButton) {
    return '${widget.runtimeType}$keyPart(${motionSignature(widget.child)})';
  }

  if (widget is SwiftHeaderContent) {
    return '${widget.runtimeType}$keyPart(${widget.left == null ? '' : motionSignature(widget.left!)},${motionSignature(widget.middle)},${motionSignature(widget.right)})';
  }

  return defaultMotionSignature(widget);
}
