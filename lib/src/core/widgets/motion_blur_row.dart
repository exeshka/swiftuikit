import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:swiftuikit/src/core/widgets/motion_blur.dart';
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
      children: child.children,
    );
  }

  return child;
}

String motionSignature(Widget widget) {
  final key = widget.key;
  final keyPart = key == null ? '' : '#$key';

  if (widget is _MotionBlurSpacer) {
    return widget.signature;
  }

  if (widget is ToolbarItemGroup) {
    return '${widget.runtimeType}$keyPart';
  }

  if (widget is MotionBlurRow) {
    return '${widget.runtimeType}$keyPart';
  }

  if (widget is ToolbarButton) {
    return '${widget.runtimeType}$keyPart(${motionSignature(widget.child)})';
  }

  if (widget is Flex) {
    return '${widget.runtimeType}$keyPart(${widget.children.map(motionSignature).join(',')})';
  }

  if (widget is Center) {
    final child = widget.child;
    return '${widget.runtimeType}$keyPart(${child == null ? '' : motionSignature(child)})';
  }

  if (widget is Padding) {
    final child = widget.child;
    return '${widget.runtimeType}$keyPart(${child == null ? '' : motionSignature(child)})';
  }

  if (widget is DefaultTextStyle) {
    return '${widget.runtimeType}$keyPart(${motionSignature(widget.child)})';
  }

  if (widget is Text) {
    return '${widget.runtimeType}$keyPart(${widget.data ?? widget.textSpan})';
  }

  if (widget is Icon) {
    return '${widget.runtimeType}$keyPart(${widget.icon?.codePoint})';
  }

  return '${widget.runtimeType}$keyPart';
}

class MotionBlurRow extends StatefulWidget {
  const MotionBlurRow({
    super.key,
    required this.children,
    required this.mainAxisAlignment,
    required this.mainAxisSize,
    required this.crossAxisAlignment,
    required this.verticalDirection,
    required this.spacing,
    required this.clipMotion,
    this.textDirection,
    this.textBaseline,
  });

  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;
  final TextBaseline? textBaseline;
  final double spacing;
  final bool clipMotion;

  @override
  State<MotionBlurRow> createState() => _MotionBlurRowState();
}

class _MotionBlurRowState extends State<MotionBlurRow> {
  static const _duration = Duration(milliseconds: 500);
  final List<_MotionBlurRowSlot> _slots = [];
  var _nextSlotId = 0;

  List<Widget> _buildLogicalChildren(List<Widget> children, double spacing) {
    if (children.isEmpty) return const [];
    final List<Widget> result = [];
    for (var i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        final leftSig = motionSignature(children[i]);
        final rightSig = motionSignature(children[i + 1]);
        result.add(
          _MotionBlurSpacer(
            width: spacing,
            signature: '__spacer__${leftSig}__${rightSig}__',
          ),
        );
      }
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    final logicalChildren = _buildLogicalChildren(
      widget.children,
      widget.spacing,
    );
    for (final child in logicalChildren) {
      _slots.add(
        _MotionBlurRowSlot(
          id: _nextSlotId++,
          signature: motionSignature(child),
          child: child,
          visible: true,
        ),
      );
    }
  }

  @override
  void didUpdateWidget(covariant MotionBlurRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSlots();
  }

  void _syncSlots() {
    final logicalChildren = _buildLogicalChildren(
      widget.children,
      widget.spacing,
    );
    final current = logicalChildren
        .map(
          (child) => _MotionBlurRowSlot(
            id: -1,
            signature: motionSignature(child),
            child: child,
            visible: true,
          ),
        )
        .toList();
    final matchedCurrentIndexes = <int>{};
    final nextSlots = <_MotionBlurRowSlot>[];

    for (final slot in _slots) {
      final currentIndex = _firstUnmatchedIndex(
        current,
        matchedCurrentIndexes,
        slot.signature,
      );

      if (currentIndex == -1) {
        if (slot.visible) {
          slot.visible = false;
          Future<void>.delayed(_duration, () {
            if (!mounted) return;
            setState(() {
              _slots.removeWhere(
                (candidate) => candidate.id == slot.id && !candidate.visible,
              );
            });
          });
        }
        nextSlots.add(slot);
        continue;
      }

      for (var i = 0; i < currentIndex; i++) {
        if (matchedCurrentIndexes.contains(i)) continue;
        nextSlots.add(_newHiddenSlot(current[i]));
        matchedCurrentIndexes.add(i);
      }

      slot
        ..child = current[currentIndex].child
        ..visible = true;
      matchedCurrentIndexes.add(currentIndex);
      nextSlots.add(slot);
    }

    for (var i = 0; i < current.length; i++) {
      if (matchedCurrentIndexes.contains(i)) continue;
      nextSlots.add(_newHiddenSlot(current[i]));
    }

    setState(() {
      _slots
        ..clear()
        ..addAll(nextSlots);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        for (final slot in _slots) {
          if (!slot.visible) continue;
          slot.ready = true;
        }
      });
    });
  }

  int _firstUnmatchedIndex(
    List<_MotionBlurRowSlot> current,
    Set<int> matchedIndexes,
    String signature,
  ) {
    for (var i = 0; i < current.length; i++) {
      if (matchedIndexes.contains(i)) continue;
      if (current[i].signature == signature) return i;
    }

    return -1;
  }

  _MotionBlurRowSlot _newHiddenSlot(_MotionBlurRowSlot source) {
    return _MotionBlurRowSlot(
      id: _nextSlotId++,
      signature: source.signature,
      child: source.child,
      visible: true,
      ready: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: widget.mainAxisAlignment,
      mainAxisSize: widget.mainAxisSize,
      crossAxisAlignment: widget.crossAxisAlignment,
      textDirection: widget.textDirection,
      verticalDirection: widget.verticalDirection,
      textBaseline: widget.textBaseline,
      spacing: 0,
      children: [
        for (var i = 0; i < _slots.length; i++)
          _MotionBlurPresence(
            key: ValueKey(_slots[i].id),
            visible: _slots[i].visible && _slots[i].ready,
            smearOffset: const Offset(8, 0),
            clip: widget.clipMotion,
            child: _slots[i].child,
          ),
      ],
    );
  }
}

class _MotionBlurRowSlot {
  _MotionBlurRowSlot({
    required this.id,
    required this.signature,
    required this.child,
    required this.visible,
    this.ready = true,
  });

  final int id;
  String signature;
  Widget child;
  bool visible;
  bool ready;
}

class _MotionBlurSpacer extends StatelessWidget {
  const _MotionBlurSpacer({required this.width, required this.signature});

  final double width;
  final String signature;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width);
  }
}

class _MotionBlurPresence extends StatefulWidget {
  const _MotionBlurPresence({
    super.key,
    required this.visible,
    required this.smearOffset,
    required this.clip,
    required this.child,
  });

  static const double _maxBlurSigma = 8;

  final bool visible;
  final Offset smearOffset;
  final bool clip;
  final Widget child;

  @override
  State<_MotionBlurPresence> createState() => _MotionBlurPresenceState();
}

class _MotionBlurPresenceState extends State<_MotionBlurPresence>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      value: widget.visible ? 1.0 : 0.0,
      lowerBound: -0.2,
      upperBound: 1.2,
    );
  }

  @override
  void didUpdateWidget(covariant _MotionBlurPresence oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible) {
      _runSpringAnimation();
    }
  }

  void _runSpringAnimation() {
    final target = widget.visible ? 1.0 : 0.0;
    final spring = SpringDescription(
      mass: 1.0,
      stiffness: 140.0,
      damping: 15.0,
    );
    final simulation = SpringSimulation(
      spring,
      _controller.value,
      target,
      _controller.velocity,
    );
    _controller.animateWith(simulation);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value.clamp(0.0, 1.0);
        final blurProgress = (1.0 - progress).clamp(0.0, 1.0);

        final content = Align(
          widthFactor: progress,
          child: MotionBlur(
            opacity: progress,
            blurSigma: _MotionBlurPresence._maxBlurSigma * blurProgress,
            smearOffset: widget.smearOffset * blurProgress,
            smearIntensity: blurProgress,
            child: widget.child,
          ),
        );

        if (!widget.clip) {
          return content;
        }

        return ClipRect(child: content);
      },
    );
  }
}
