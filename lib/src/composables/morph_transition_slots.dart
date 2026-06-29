import 'package:flutter/material.dart';

@immutable
final class MorphTransitionSlot {
  const MorphTransitionSlot({required this.contentKey, required this.child});

  final Object contentKey;
  final Widget child;
}

@immutable
final class MorphTransitionSection {
  const MorphTransitionSection(this.slots);

  final List<MorphTransitionSlot> slots;

  static const empty = MorphTransitionSection([]);
}

class MorphTransitionSlots extends StatelessWidget {
  MorphTransitionSlots({
    super.key,
    Widget? left,
    Widget? middle,
    Widget? right,
    Object leftKey = const ValueKey('morph_transition_left'),
    Object middleKey = const ValueKey('morph_transition_middle'),
    this.itemSpacing = 12,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  }) : left = _singleSection(leftKey, left),
       middle = _singleSection(middleKey, middle),
       right = _sectionFromWidget(right);

  const MorphTransitionSlots.sections({
    super.key,
    this.left = MorphTransitionSection.empty,
    this.middle = MorphTransitionSection.empty,
    this.right = MorphTransitionSection.empty,
    this.itemSpacing = 12,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final MorphTransitionSection left;
  final MorphTransitionSection middle;
  final MorphTransitionSection right;
  final double itemSpacing;
  final CrossAxisAlignment crossAxisAlignment;

  static MorphTransitionSection _singleSection(Object key, Widget? child) {
    if (child == null) {
      return MorphTransitionSection.empty;
    }

    return MorphTransitionSection([
      MorphTransitionSlot(contentKey: key, child: child),
    ]);
  }

  static MorphTransitionSection _sectionFromWidget(Widget? child) {
    if (child == null) {
      return MorphTransitionSection.empty;
    }

    if (child is Row) {
      return MorphTransitionSection([
        for (var index = 0; index < child.children.length; index++)
          MorphTransitionSlot(
            contentKey: child.children[index].key ?? ValueKey('right_$index'),
            child: child.children[index],
          ),
      ]);
    }

    return MorphTransitionSection([
      MorphTransitionSlot(
        contentKey: child.key ?? const ValueKey('morph_transition_right'),
        child: child,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: _SectionRow(
              section: left,
              spacing: itemSpacing,
              crossAxisAlignment: crossAxisAlignment,
            ),
          ),
        ),
        _SectionRow(
          section: middle,
          spacing: itemSpacing,
          crossAxisAlignment: crossAxisAlignment,
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: _SectionRow(
              section: right,
              spacing: itemSpacing,
              crossAxisAlignment: crossAxisAlignment,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({
    required this.section,
    required this.spacing,
    required this.crossAxisAlignment,
  });

  final MorphTransitionSection section;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final children = section.slots
        .map((slot) => slot.child)
        .where((child) => !_isEmptySlot(child))
        .toList();

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      spacing: spacing,
      children: children,
    );
  }

  static bool _isEmptySlot(Widget child) {
    return child is SizedBox &&
        child.width == null &&
        child.height == null &&
        child.child == null;
  }
}
