import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:swiftuikit/src/composables/morph_transition_slots.dart';
import 'package:swiftuikit/src/primitives/morph_surface.dart';
import 'package:swiftuikit/src/primitives/motion_blur.dart';
import 'package:swiftuikit/src/widgets/toolbar/toolbar_button.dart';
import 'package:swiftuikit/src/widgets/toolbar/toolbar_item_group.dart';
import 'package:swiftuikit/src/widgets/header/motion_utils.dart';
import 'swift_pinned_sliver.dart';

class SwiftHeader extends StatelessWidget {
  const SwiftHeader({
    super.key,
    this.left,
    required this.right,
    required this.middle,
    this.pinned = true,
    this.floating = false,
    this.trackAtRest = true,
    this.automaticallyImplyLeading = true,
    this.automaticallyImpliedLeadingStyle,
    this.heroTag = 'swift_header',
  });

  final Widget? left;
  final Widget right;
  final Widget middle;
  final bool pinned;
  final bool floating;
  final bool trackAtRest;
  final bool automaticallyImplyLeading;
  final MorphSurfaceStyle? automaticallyImpliedLeadingStyle;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final effectiveLeft = left ?? _automaticLeading(context);
    final content = SwiftHeaderContent(
      left: effectiveLeft,
      right: right,
      middle: middle,
    );

    return SwiftSliverHeader(
      pinned: pinned,
      floating: floating,
      trackAtRest: trackAtRest,
      foregroundInChrome: false,
      heroTag: heroTag,
      child: content,
    );
  }

  Widget? _automaticLeading(BuildContext context) {
    if (!automaticallyImplyLeading) {
      return null;
    }

    final route = ModalRoute.of(context);
    final canPop =
        route?.impliesAppBarDismissal ?? Navigator.of(context).canPop();
    if (!canPop) {
      return null;
    }

    final theme = Theme.of(context).colorScheme;
    return ToolbarItemGroup(
      style:
          automaticallyImpliedLeadingStyle ??
          MorphSurfaceStyle(
            color: theme.surface.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(296),
            blurSigma: 20,
          ),
      children: [
        ToolbarButton(
          child: Icon(Icons.arrow_back_ios_new_rounded, color: theme.onSurface),
          onTap: () {
            Navigator.of(context).maybePop();
          },
        ),
      ],
    );
  }
}

class SwiftHeaderContent extends StatelessWidget {
  static const _slotSwitchDuration = Duration(milliseconds: 260);

  final Widget? left;
  final Widget right;
  final Widget middle;

  const SwiftHeaderContent({
    super.key,
    this.left,
    required this.right,
    required this.middle,
  });

  @override
  Widget build(BuildContext context) {
    final content = _SwiftHeaderTransitionSlots(
      left: left,
      middle: middle,
      right: right,
    );

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Material(
          color: Colors.transparent,
          child: SizedBox(height: 44, child: content),
        ),
      ),
    );
  }
}

class _SwiftHeaderTransitionSlots extends MorphTransitionSlots {
  _SwiftHeaderTransitionSlots({
    required Widget? left,
    required Widget middle,
    required Widget right,
  }) : super.sections(
         left: _sectionFromWidget('left', left),
         middle: _sectionFromWidget('middle', middle),
         right: _sectionFromWidget('right', right),
         itemSpacing: _itemSpacingFrom(right),
       );

  static double _itemSpacingFrom(Widget child) {
    if (child is Row) {
      return child.spacing;
    }

    return 12;
  }

  static MorphTransitionSection _sectionFromWidget(String name, Widget? child) {
    if (child == null) {
      return MorphTransitionSection.empty;
    }

    if (child is Row) {
      return MorphTransitionSection([
        for (var index = 0; index < child.children.length; index++)
          MorphTransitionSlot(
            contentKey:
                child.children[index].key ??
                ValueKey('swift_header_${name}_$index'),
            child: child.children[index],
          ),
      ]);
    }

    return MorphTransitionSection([
      MorphTransitionSlot(
        contentKey:
            child.key ??
            ValueKey('swift_header_$name:${motionSignature(child)}'),
        child: child,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 0,
          right: 0,
          child: _HeaderMotionBlurSwitcher(
            duration: SwiftHeaderContent._slotSwitchDuration,
            smearOffset: const Offset(10, 0),
            sizeAlignment: Alignment.centerRight,
            child: _SwiftHeaderSectionRow(section: right, spacing: itemSpacing),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: _HeaderMotionBlurSwitcher(
            duration: SwiftHeaderContent._slotSwitchDuration,
            smearOffset: const Offset(-10, 0),
            sizeAlignment: Alignment.centerLeft,
            child: _SwiftHeaderSectionRow(section: left, spacing: itemSpacing),
          ),
        ),
        Positioned.fill(
          child: _HeaderMotionBlurSwitcher(
            duration: SwiftHeaderContent._slotSwitchDuration,
            smearOffset: const Offset(0, -6),
            sizeAlignment: Alignment.center,
            child: _SwiftHeaderSectionRow(
              section: middle,
              spacing: itemSpacing,
            ),
          ),
        ),
      ],
    );
  }
}

class _SwiftHeaderSectionRow extends StatelessWidget {
  const _SwiftHeaderSectionRow({required this.section, required this.spacing});

  final MorphTransitionSection section;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (section.slots.isEmpty) {
      return const SizedBox.shrink();
    }

    if (section.slots.length == 1) {
      return section.slots.first.child;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: spacing,
      children: [for (final slot in section.slots) slot.child],
    );
  }
}

class _HeaderMotionBlurSwitcher extends StatefulWidget {
  const _HeaderMotionBlurSwitcher({
    required this.child,
    required this.smearOffset,
    required this.duration,
    required this.sizeAlignment,
  });

  static const double _maxBlurSigma = 8;

  final Widget child;
  final Offset smearOffset;
  final Duration duration;
  final AlignmentGeometry sizeAlignment;

  @override
  State<_HeaderMotionBlurSwitcher> createState() =>
      _HeaderMotionBlurSwitcherState();
}

class _HeaderMotionBlurSwitcherState extends State<_HeaderMotionBlurSwitcher>
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
  void didUpdateWidget(covariant _HeaderMotionBlurSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (motionSignature(oldWidget.child) != motionSignature(widget.child)) {
      _triggerScaleImpulse(oldWidget);
    }
  }

  void _triggerScaleImpulse(_HeaderMotionBlurSwitcher oldWidget) {
    int oldLength = 0;
    int newLength = 0;

    final oldChild = oldWidget.child;
    final newChild = widget.child;

    if (oldChild is _SwiftHeaderSectionRow) {
      oldLength = oldChild.section.slots.length;
    }
    if (newChild is _SwiftHeaderSectionRow) {
      newLength = newChild.section.slots.length;
    }

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
    final animatedChild = motionChild(widget.child);

    return ScaleTransition(
      scale: _scaleController,
      child: AnimatedSize(
        clipBehavior: Clip.none,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        alignment: widget.sizeAlignment,
        child: AnimatedSwitcher(
          duration: widget.duration,
          reverseDuration: widget.duration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              alignment: widget.sizeAlignment,
              clipBehavior: Clip.none,
              children: [
                for (final previousChild in previousChildren)
                  Positioned.fill(
                    child: OverflowBox(
                      alignment: widget.sizeAlignment,
                      minWidth: 0,
                      minHeight: 0,
                      maxWidth: double.infinity,
                      maxHeight: double.infinity,
                      child: previousChild,
                    ),
                  ),
                ?currentChild,
              ],
            );
          },
          transitionBuilder: (child, animation) {
            return AnimatedBuilder(
              animation: animation,
              child: child,
              builder: (context, child) {
                final progress = animation.value.clamp(0.0, 1.0);
                final blurProgress = 1 - progress;

                return MotionBlur(
                  opacity: progress,
                  blurSigma:
                      _HeaderMotionBlurSwitcher._maxBlurSigma * blurProgress,
                  smearOffset: widget.smearOffset * blurProgress,
                  smearIntensity: blurProgress,
                  child: Center(child: child),
                );
              },
            );
          },
          child: KeyedSubtree(
            key: ValueKey(motionSignature(animatedChild)),
            child: animatedChild,
          ),
        ),
      ),
    );
  }
}
