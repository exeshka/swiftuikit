import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

/// A multi-step sheet container widget that automatically manages dynamic height transitions
/// between steps, and exposes step state and the modal route's open progress directly to
/// child contexts via `SwiftStepSheet.of(context)`.
///
/// **Not stable** — API may change.
@experimental
class SwiftStepSheet extends StatefulWidget {
  const SwiftStepSheet({
    super.key,
    required this.steps,
    this.initialStep = 0,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
  });

  /// The list of steps (widgets) to display sequentially.
  final List<Widget> steps;

  /// The index of the step to display initially.
  final int initialStep;

  /// Height transition animation duration.
  final Duration animationDuration;

  /// Height transition curve.
  final Curve animationCurve;

  @override
  State<SwiftStepSheet> createState() => SwiftStepSheetState();

  /// Retrieves the closest [SwiftStepSheetState] from the context to access current step index
  /// and trigger page transition commands.
  static SwiftStepSheetState of(BuildContext context) {
    final _SwiftStepSheetScope? scope =
        context.dependOnInheritedWidgetOfExactType<_SwiftStepSheetScope>();
    if (scope == null) {
      throw FlutterError(
        'SwiftStepSheet.of() called with a context that does not contain a SwiftStepSheet.',
      );
    }
    return scope.state;
  }

  /// Helper to fetch the current sheet's open progress (0.0 to 1.0) directly from context.
  static double openProgressOf(BuildContext context) {
    final _SwiftStepSheetScope? scope =
        context.dependOnInheritedWidgetOfExactType<_SwiftStepSheetScope>();
    return scope?.openProgress ?? 1.0;
  }
}

class SwiftStepSheetState extends State<SwiftStepSheet> {
  late int _currentStep;
  Animation<double>? _routeAnimation;

  /// Returns the index of the currently active step.
  int get currentStep => _currentStep;

  /// Returns the overall open progress of the modal sheet route (from 0.0 to 1.0).
  /// Rebuilds depending widgets on every tick of the transition animation.
  double get openProgress {
    return _routeAnimation?.value ?? 1.0;
  }

  /// Returns the ModalRoute's open animation controller.
  Animation<double>? get openAnimation => _routeAnimation;

  /// Transitions the sheet to the step at [index], animating its height changes dynamically.
  void goToStep(int index) {
    if (index >= 0 && index < widget.steps.length) {
      setState(() {
        _currentStep = index;
      });
    }
  }

  /// Transitions to the next step index.
  void nextStep() => goToStep(_currentStep + 1);

  /// Transitions to the previous step index.
  void previousStep() => goToStep(_currentStep - 1);

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newAnimation = ModalRoute.of(context)?.animation;
    if (_routeAnimation != newAnimation) {
      _routeAnimation?.removeListener(_onAnimationTick);
      _routeAnimation = newAnimation;
      _routeAnimation?.addListener(_onAnimationTick);
    }
  }

  void _onAnimationTick() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _routeAnimation?.removeListener(_onAnimationTick);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SwiftStepSheetScope(
      state: this,
      currentStep: _currentStep,
      openProgress: openProgress,
      child: AnimatedSize(
        duration: widget.animationDuration,
        curve: widget.animationCurve,
        alignment: Alignment.bottomCenter,
        child: widget.steps[_currentStep],
      ),
    );
  }
}

class _SwiftStepSheetScope extends InheritedWidget {
  const _SwiftStepSheetScope({
    required this.state,
    required this.currentStep,
    required this.openProgress,
    required super.child,
  });

  final SwiftStepSheetState state;
  final int currentStep;
  final double openProgress;

  @override
  bool updateShouldNotify(_SwiftStepSheetScope oldWidget) {
    return currentStep != oldWidget.currentStep ||
        openProgress != oldWidget.openProgress;
  }
}
