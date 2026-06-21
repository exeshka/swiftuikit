import 'package:flutter/widgets.dart';
import 'package:flutter/physics.dart';
import 'package:swiftuikit/src/core/widgets/material_glow.dart';
import 'package:swiftuikit/src/core/widgets/material_stretch.dart';
import 'package:swiftuikit/src/core/widgets/swift_material.dart';
import 'package:swiftuikit/src/core/widgets/motion_blur_row.dart';

class ToolbarItemGroup extends StatefulWidget {
  final List<Widget> children;
  final MorphSurfaceStyle style;

  const ToolbarItemGroup({
    super.key,
    required this.children,
    required this.style,
  });

  @override
  State<ToolbarItemGroup> createState() => _ToolbarItemGroupState();
}

class _ToolbarItemGroupState extends State<ToolbarItemGroup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      value: 1.0,
      lowerBound: 0.5,
      upperBound: 1.5,
    );
  }

  @override
  void didUpdateWidget(covariant ToolbarItemGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_childrenChanged(oldWidget.children, widget.children)) {
      _triggerScaleImpulse(oldWidget.children.length, widget.children.length);
    }
  }

  bool _childrenChanged(List<Widget> oldChildren, List<Widget> newChildren) {
    if (oldChildren.length != newChildren.length) return true;
    for (var i = 0; i < oldChildren.length; i++) {
      if (motionSignature(oldChildren[i]) !=
          motionSignature(newChildren[i])) {
        return true;
      }
    }
    return false;
  }

  void _triggerScaleImpulse(int oldLength, int newLength) {
    double velocity = -0.8;
    if (newLength > oldLength) {
      velocity = -1.0;
    } else if (newLength < oldLength) {
      velocity = 1.5;
    }

    final spring = SpringDescription(
      mass: 1.0,
      stiffness: 150.0,
      damping: 14.0,
    );
    final simulation = SpringSimulation(
      spring,
      _scaleController.value,
      1.0,
      velocity,
    );
    _scaleController.animateWith(simulation);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleController,
      child: LiquidStretch(
        child: GlassGlowLayer(
          child: MorphSurface(
            style: widget.style,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
              child: MotionBlurRow(
                mainAxisAlignment: widget.children.length == 1
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                verticalDirection: VerticalDirection.down,
                spacing: 20,
                clipMotion: false,
                children: [...widget.children],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
