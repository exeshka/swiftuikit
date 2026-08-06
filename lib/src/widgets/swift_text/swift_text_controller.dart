part of '../swift_text.dart';

class _SwiftTextState extends State<SwiftText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late SwiftText _from;
  late SwiftText _target;
  bool _hasPendingCompletion = false;
  bool _disableAnimations = false;
  late bool _countsDown;
  int _transitionId = 0;
  double _retargetProgress = 1;
  bool _retargetImmediately = true;

  @override
  void initState() {
    super.initState();
    _from = widget;
    _target = widget;
    _countsDown = widget.countsDown ?? false;
    _controller = AnimationController(
      vsync: this,
      duration: _controllerDuration(widget),
      value: 1,
    )..addStatusListener(_handleStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final value = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (value != _disableAnimations) {
      _disableAnimations = value;
      if (value) {
        _from = widget;
        _target = widget;
        _retargetProgress = _controller.value;
        _retargetImmediately = true;
        _transitionId++;
        _controller.value = 1;
        _completeIfNeeded();
      }
    }
  }

  @override
  void didUpdateWidget(SwiftText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_contentChanged(oldWidget, widget)) {
      _hasPendingCompletion = true;
      if (_disableAnimations || widget.duration == Duration.zero) {
        _from = widget;
        _target = widget;
        _retargetProgress = _controller.value;
        _retargetImmediately = true;
        _transitionId++;
        _controller.duration = _controllerDuration(widget);
        _controller.value = 1;
        _completeIfNeeded();
      } else {
        _startTransition(widget);
      }
    } else if (_controller.isAnimating) {
      _target = widget;
    } else {
      _from = widget;
      _target = widget;
    }
  }

  void _startTransition(SwiftText next) {
    _retargetProgress = _controller.value;
    _retargetImmediately = false;
    _transitionId++;
    _countsDown = _resolveCountsDown(_target, next);
    _from = _target;
    _target = next;
    _controller.duration = _controllerDuration(next);
    _controller.forward(from: 0);
  }

  bool _resolveCountsDown(SwiftText from, SwiftText to) {
    final override = to.countsDown;
    if (override != null) return override;
    return _detectCountsDown(_plainText(from), _plainText(to)) ?? _countsDown;
  }

  static String _plainText(SwiftText configuration) {
    return configuration.data ?? configuration.text?.toPlainText() ?? '';
  }

  Duration _controllerDuration(SwiftText configuration) {
    final curve = configuration.curve;
    if (curve is! SwiftTextSmoothCurve ||
        configuration.duration == Duration.zero) {
      return configuration.duration;
    }
    return Duration(
      microseconds: math.max(
        1,
        (configuration.duration.inMicroseconds * curve.settlingRatio).round(),
      ),
    );
  }

  bool _contentChanged(SwiftText oldWidget, SwiftText newWidget) {
    return _plainText(oldWidget) != _plainText(newWidget);
  }

  void _handleStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _from = _target;
    _completeIfNeeded();
  }

  void _completeIfNeeded() {
    if (!_hasPendingCompletion) return;
    _hasPendingCompletion = false;
    widget.onEnd?.call();
  }

  TextSpan _resolvedSpan(BuildContext context, SwiftText configuration) {
    var base = DefaultTextStyle.of(context).style.merge(configuration.style);
    if (MediaQuery.boldTextOf(context)) {
      base = base.merge(const TextStyle(fontWeight: FontWeight.bold));
    }
    final rich = configuration.text;
    if (rich != null) {
      return TextSpan(style: base, children: <InlineSpan>[rich]);
    }
    return TextSpan(style: base, text: configuration.data ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _resolvedSpan(context, _target);
    final latest = _resolvedSpan(context, widget);
    return _SwiftTextRenderWidget(
      fromText: _resolvedSpan(context, _from),
      toText: resolved,
      animation: _controller,
      curve: _target.curve,
      countsDown: _countsDown,
      textAlign: _target.textAlign,
      textDirection: _target.textDirection ?? Directionality.of(context),
      locale: _target.locale ?? Localizations.maybeLocaleOf(context),
      textScaler: _target.textScaler ?? MediaQuery.textScalerOf(context),
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      strutStyle: _target.strutStyle,
      softWrap: _target.softWrap,
      overflow: _target.overflow,
      maxLines: _target.maxLines,
      semanticsLabel: widget.semanticsLabel ?? latest.toPlainText(),
      transitionId: _transitionId,
      retargetProgress: _retargetProgress,
      retargetImmediately: _retargetImmediately,
    );
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_handleStatus)
      ..dispose();
    super.dispose();
  }
}
