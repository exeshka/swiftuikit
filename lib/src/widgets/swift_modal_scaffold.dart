import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:swiftuikit/src/routing/scroll_sheet_route.dart';
import 'package:swiftuikit/src/services/screen_radius_service.dart';

/// A custom Scaffold container designed specifically for modal scroll sheets.
///
/// It listens to the current sheet extent. When the extent expands past `0.45` (moving
/// towards `1.0`), it smoothly decreases the horizontal/bottom margins to `0.0`,
/// fades out the card drop shadows, and morphs the corner radii (top corners match the
/// device's hardware corner radius, and bottom corners flatten out to `0.0`).
class SwiftModalScaffold extends StatelessWidget {
  const SwiftModalScaffold({
    super.key,
    required this.body,
    this.header,
    this.backgroundColor,

    this.baseMargin = 6.0,
    this.boxShadow,
  });

  /// The main scrollable list or content layout inside the modal.
  final Widget body;

  /// An optional header widget (e.g. containing drag handles and titles).
  /// Automatically wrapped in [SwiftScrollSheetDragTarget] to support gestures.
  final Widget? header;

  /// Background color of the sheet scaffold.
  final Color? backgroundColor;

  /// The base margin on the left, right, and bottom edges when floating (extent <= 0.45).
  final double baseMargin;

  /// Custom shadows for the floating card container.
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    // Retrieve current sheet extent and register context for tick rebuilds
    final double extent = SwiftScrollSheetRoute.extentOf(context);

    // Map the extent range [0.45, 1.0] to interpolation progress t [0.0, 1.0]
    double t = 0.0;
    if (extent > 0.45) {
      t = ((extent - 0.45) / (1.0 - 0.45)).clamp(0.0, 1.0);
    }

    // Interpolate margin down to 0
    final double margin = lerpDouble(baseMargin, 0.0, t)!;

    // Fetch device screen corner radius
    final double screenRadius = ScreenRadiusService.instance.radius.topLeft.x;

    // Calculate top corner radius: concentric with the screen's hardware curve

    // From 34 to 38 on full opened
    final double topRadius = lerpDouble(34, 38, t)!;

    // Calculate bottom corner radius: concentric when floating, flattening to 0 on full-screen
    final double bottomRadius = (screenRadius - margin).clamp(0, screenRadius);

    final Color bgColor =
        backgroundColor ?? Theme.of(context).colorScheme.surface;

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.only(left: margin, right: margin, bottom: margin),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(topRadius),
              topRight: Radius.circular(topRadius),
              bottomLeft: Radius.circular(bottomRadius),
              bottomRight: Radius.circular(bottomRadius),
            ),
            boxShadow:
                boxShadow ??
                [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.12 * (1.0 - t),
                    ), // Fade out shadow on full-screen
                    blurRadius: 40,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double minHeight = 250.0;
              final double height = math.max(constraints.maxHeight, minHeight);
              return ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(topRadius),
                  topRight: Radius.circular(topRadius),
                  bottomLeft: Radius.circular(bottomRadius),
                  bottomRight: Radius.circular(bottomRadius),
                ),
                child: OverflowBox(
                  minWidth: constraints.maxWidth,
                  maxWidth: constraints.maxWidth,
                  minHeight: 0,
                  maxHeight: height,
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: height,
                    child: Column(
                      children: [
                        if (header != null) SwiftScrollSheetDragTarget(child: header!),
                        Expanded(child: body),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
