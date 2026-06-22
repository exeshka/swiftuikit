// ignore_for_file: prefer_initializing_formals
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A sliver widget that applies a filter (like blur) to the existing painted
/// content behind it, and then paints its child sliver.
class SliverBackdropFilter extends SingleChildRenderObjectWidget {
  /// Creates a sliver that applies a backdrop filter.
  const SliverBackdropFilter({
    super.key,
    required this.filter,
    super.child,
  });

  /// The image filter to apply to the background.
  final ui.ImageFilter filter;

  @override
  RenderSliverBackdropFilter createRenderObject(BuildContext context) {
    return RenderSliverBackdropFilter(filter: filter);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderSliverBackdropFilter renderObject,
  ) {
    renderObject.filter = filter;
  }
}

/// The [RenderSliver] corresponding to [SliverBackdropFilter].
class RenderSliverBackdropFilter extends RenderProxySliver {
  /// Creates a render object that applies a backdrop filter to a sliver.
  RenderSliverBackdropFilter({
    required ui.ImageFilter filter,
    RenderSliver? child,
  }) : _filter = filter, super(child);

  /// The image filter to apply to the background.
  ui.ImageFilter get filter => _filter;
  ui.ImageFilter _filter;
  set filter(ui.ImageFilter value) {
    if (_filter == value) {
      return;
    }
    _filter = value;
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null && child!.geometry != null) {
      final SliverGeometry geometry = child!.geometry!;
      if (geometry.visible) {
        final double paintExtent = geometry.paintExtent;
        final Size size = switch (constraints.axis) {
          Axis.horizontal => Size(paintExtent, constraints.crossAxisExtent),
          Axis.vertical => Size(constraints.crossAxisExtent, paintExtent),
        };

        // Clip the backdrop filter to the sliver's active paint region.
        context.pushClipRect(
          needsCompositing,
          offset,
          offset & size,
          (PaintingContext context, Offset offset) {
            final BackdropFilterLayer backdropLayer = BackdropFilterLayer(
              filter: filter,
            );
            context.pushLayer(
              backdropLayer,
              (PaintingContext context, Offset offset) {
                context.paintChild(child!, offset);
              },
              offset,
            );
          },
        );
        return;
      }
    }
    super.paint(context, offset);
  }
}
