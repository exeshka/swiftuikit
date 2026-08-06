part of '../swift_text.dart';

class _TextOverflowState {
  const _TextOverflowState({required this.width, required this.height});

  final bool width;
  final bool height;

  bool get hasOverflow => width || height;
}

class _RenderSwiftText extends RenderBox
    with RelayoutWhenSystemFontsChangeMixin {
  _RenderSwiftText({
    required this._fromText,
    required this._toText,
    required this._animation,
    required this._curve,
    required this._countsDown,
    required this._textAlign,
    required this._textDirection,
    required this._locale,
    required this._textScaler,
    required this._devicePixelRatio,
    required this._strutStyle,
    required this._softWrap,
    required this._overflow,
    required this._maxLines,
    required this._semanticsLabel,
    required this._transitionId,
  });

  TextSpan _fromText;
  TextSpan _toText;
  Animation<double> _animation;
  set animation(Animation<double> value) {
    if (identical(_animation, value)) return;
    _animation.removeListener(_handleTick);
    _animation = value;
    _animation.addListener(_handleTick);
    markNeedsLayout();
  }

  Curve _curve;
  bool _countsDown;

  @visibleForTesting
  bool get countsDown => _countsDown;

  @visibleForTesting
  List<int> get debugWaveIndices => <int>[
    for (final transition in _scene?.transitions ?? const <_GlyphTransition>[])
      if (!transition.unchanged && !transition.remnant) transition.waveIndex,
  ];

  @visibleForTesting
  List<int> get debugWaveCounts => <int>[
    for (final transition in _scene?.transitions ?? const <_GlyphTransition>[])
      if (!transition.unchanged && !transition.remnant) transition.waveCount,
  ];

  @visibleForTesting
  List<Rect> get debugUnchangedGlyphRects {
    final scene = _scene;
    if (scene == null) return const <Rect>[];
    final targets = Set<_Glyph>.identity();
    for (final transition in scene.transitions) {
      if (transition.unchanged && transition.target != null) {
        targets.add(transition.target!);
      }
    }
    return <Rect>[
      for (final glyph in scene.presentedAt(_rawProgress, this))
        if (glyph.lineage != null && targets.contains(glyph.lineage))
          glyph.rect,
    ];
  }

  @visibleForTesting
  List<double> get debugPresentedScales => <double>[
    for (final glyph
        in _scene?.presentedAt(_rawProgress, this) ?? const <_PresentedGlyph>[])
      glyph.scale,
  ];

  @visibleForTesting
  List<double> get debugPresentedOpacities => <double>[
    for (final glyph
        in _scene?.presentedAt(_rawProgress, this) ?? const <_PresentedGlyph>[])
      glyph.opacity,
  ];

  @visibleForTesting
  List<Rect> get debugPresentedGlyphRects => <Rect>[
    for (final glyph
        in _scene?.presentedAt(_rawProgress, this) ?? const <_PresentedGlyph>[])
      glyph.rect,
  ];

  @visibleForTesting
  List<String> get debugPresentedGlyphTexts => <String>[
    for (final glyph
        in _scene?.presentedAt(_rawProgress, this) ?? const <_PresentedGlyph>[])
      glyph.glyph.text,
  ];

  @visibleForTesting
  int get debugEffectGlyphCount =>
      (_scene?.presentedAt(_rawProgress, this) ?? const <_PresentedGlyph>[])
          .where(_needsEffectPass)
          .length;

  @visibleForTesting
  int get debugBlurPassCount {
    final passes = <(bool, int)>{};
    for (final glyph
        in _scene?.presentedAt(_rawProgress, this) ??
            const <_PresentedGlyph>[]) {
      if (glyph.opacity <= 0.002) continue;
      final mix = _blurMix(glyph);
      final outgoing = glyph.lineage == null;
      if (mix.lower > 0 && mix.lowerWeight > 0.002) {
        passes.add((outgoing, mix.lower));
      }
      if (mix.upper > 0 && mix.upperWeight > 0.002) {
        passes.add((outgoing, mix.upper));
      }
    }
    return passes.length;
  }

  @visibleForTesting
  double? get debugAlphabeticBaseline =>
      computeDistanceToActualBaseline(TextBaseline.alphabetic);

  @visibleForTesting
  Locale? get debugLocale => _locale;

  @visibleForTesting
  int get debugLayoutGeneration => _debugLayoutGeneration;

  @visibleForTesting
  int get debugOwnedLayoutCount => _ownedLayouts.length;

  @visibleForTesting
  bool get debugHasOverflowFade =>
      _overflow == TextOverflow.fade && _overflowState.hasOverflow;

  @visibleForTesting
  bool get debugHasVerticalOverflowFade =>
      _overflow == TextOverflow.fade &&
      !_overflowState.width &&
      _overflowState.height;

  TextAlign _textAlign;
  set textAlign(TextAlign value) {
    if (_textAlign == value) return;
    _textAlign = value;
    _layoutConfigurationDirty = true;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    _layoutConfigurationDirty = true;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  Locale? _locale;
  set locale(Locale? value) {
    if (_locale == value) return;
    _locale = value;
    _layoutConfigurationDirty = true;
    markNeedsLayout();
  }

  TextScaler _textScaler;
  set textScaler(TextScaler value) {
    if (_textScaler == value) return;
    _textScaler = value;
    _layoutConfigurationDirty = true;
    markNeedsLayout();
  }

  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (_devicePixelRatio == value) return;
    _devicePixelRatio = value;
    _disposeGlyphAtlases();
    markNeedsPaint();
  }

  StrutStyle? _strutStyle;
  set strutStyle(StrutStyle? value) {
    if (_strutStyle == value) return;
    _strutStyle = value;
    _layoutConfigurationDirty = true;
    markNeedsLayout();
  }

  bool _softWrap;
  set softWrap(bool value) {
    if (_softWrap == value) return;
    _softWrap = value;
    _layoutConfigurationDirty = true;
    markNeedsLayout();
  }

  TextOverflow _overflow;
  set overflow(TextOverflow value) {
    if (_overflow == value) return;
    _overflow = value;
    _layoutConfigurationDirty = true;
    markNeedsLayout();
  }

  int? _maxLines;
  set maxLines(int? value) {
    if (_maxLines == value) return;
    _maxLines = value;
    _layoutConfigurationDirty = true;
    markNeedsLayout();
  }

  String _semanticsLabel;
  set semanticsLabel(String value) {
    if (_semanticsLabel == value) return;
    _semanticsLabel = value;
    markNeedsSemanticsUpdate();
  }

  int _transitionId;
  _TextLayout? _targetLayout;
  _TransitionScene? _scene;
  _PendingRetarget? _pendingRetarget;
  BoxConstraints? _layoutConstraints;
  bool _layoutConfigurationDirty = true;
  final Map<_TextLayout, _GlyphAtlas> _glyphAtlases =
      Map<_TextLayout, _GlyphAtlas>.identity();
  final Set<_TextLayout> _ownedLayouts = Set<_TextLayout>.identity();
  int _debugLayoutGeneration = 0;
  _TextLayout? _fadeSizeLayout;
  Size _fadeSize = Size.zero;

  double get _rawProgress => _animation.value.clamp(0.0, 1.0);
  double get _layoutProgress => _scene?.layoutProgress(_rawProgress) ?? 1;

  void retarget({
    required int transitionId,
    required double previousProgress,
    required bool immediately,
    required TextSpan fromText,
    required TextSpan toText,
    required Curve curve,
    required bool countsDown,
  }) {
    if (transitionId == _transitionId) {
      final textChanged =
          _fromText.compareTo(fromText) != RenderComparison.identical ||
          _toText.compareTo(toText) != RenderComparison.identical;
      _fromText = fromText;
      _toText = toText;
      _curve = curve;
      _countsDown = countsDown;
      if (textChanged) {
        _layoutConfigurationDirty = true;
        _disposeGlyphAtlases();
        markNeedsLayout();
      }
      return;
    }

    final existingPending = _pendingRetarget;
    final snapshot =
        existingPending?.snapshot ??
        (immediately ? null : _snapshotScene(previousProgress));
    final previousTarget = existingPending?.previousTarget ?? _targetLayout;
    _transitionId = transitionId;
    _fromText = fromText;
    _toText = toText;
    _curve = curve;
    _countsDown = countsDown;
    _pendingRetarget = _PendingRetarget(
      snapshot: snapshot,
      previousTarget: previousTarget,
      immediately: immediately,
    );
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  void _handleTick() => markNeedsLayout();

  TextPainter _makePainter(TextSpan text) {
    return TextPainter(
      text: text,
      textAlign: _textAlign,
      textDirection: _textDirection,
      textScaler: _textScaler,
      maxLines: _maxLines,
      ellipsis: _overflow == TextOverflow.ellipsis ? '\u2026' : null,
      locale: _locale,
      strutStyle: _strutStyle,
      textWidthBasis: TextWidthBasis.parent,
    );
  }

  double _adjustMaxWidth(double width) {
    return _softWrap || _overflow == TextOverflow.ellipsis
        ? width
        : double.infinity;
  }

  _TextLayout _layout(TextSpan text, BoxConstraints constraints) {
    final painter = _makePainter(text)
      ..layout(
        minWidth: constraints.minWidth,
        maxWidth: _adjustMaxWidth(constraints.maxWidth),
      );
    final layout = _TextLayout.fromPainter(painter, text);
    _ownedLayouts.add(layout);
    _debugLayoutGeneration++;
    return layout;
  }

  @override
  void systemFontsDidChange() {
    _layoutConfigurationDirty = true;
    _disposeGlyphAtlases();
    super.systemFontsDidChange();
  }

  _SceneSnapshot? _snapshotScene(double rawProgress) {
    final scene = _scene;
    final target = _targetLayout;
    if (scene == null || target == null) return null;
    final glyphs = scene.presentedAt(rawProgress, this);
    final currentSize = scene.sizeAt(rawProgress);
    final currentBaseline = scene.baselineAt(rawProgress);
    if (scene.isStable || rawProgress <= scene.startRaw) {
      return _SceneSnapshot(
        glyphs: glyphs,
        size: currentSize,
        baseline: currentBaseline,
        targetLayout: target,
      );
    }

    final previousRaw = math.max(
      scene.startRaw,
      rawProgress - _velocitySampleRawDelta,
    );
    final delta = rawProgress - previousRaw;
    if (delta <= 0) {
      return _SceneSnapshot(
        glyphs: glyphs,
        size: currentSize,
        baseline: currentBaseline,
        targetLayout: target,
      );
    }

    final previousGlyphs = scene.presentedAt(previousRaw, this);
    final previousSize = scene.sizeAt(previousRaw);
    final previousBaseline = scene.baselineAt(previousRaw);
    final sizeVelocity = Offset(
      (currentSize.width - previousSize.width) / delta,
      (currentSize.height - previousSize.height) / delta,
    );
    final boxPositionVelocity = Offset(
      sizeVelocity.dx * _horizontalAnchor,
      sizeVelocity.dy * 0.5,
    );
    final previousByGlyph = Map<_Glyph, _PresentedGlyph>.identity();
    for (final glyph in previousGlyphs) {
      previousByGlyph[glyph.glyph] = glyph;
    }
    final velocityGlyphs = <_PresentedGlyph>[
      for (final glyph in glyphs)
        if (previousByGlyph[glyph.glyph] case final previous?)
          _PresentedGlyph(
            layout: glyph.layout,
            glyph: glyph.glyph,
            rect: glyph.rect,
            opacity: glyph.opacity,
            sigma: glyph.sigma,
            scale: glyph.scale,
            lineage: glyph.lineage,
            remnantDepth: glyph.remnantDepth,
            positionVelocity:
                (glyph.rect.topLeft - previous.rect.topLeft) / delta -
                boxPositionVelocity,
            opacityVelocity: (glyph.opacity - previous.opacity) / delta,
            sigmaVelocity: (glyph.sigma - previous.sigma) / delta,
            scaleVelocity: (glyph.scale - previous.scale) / delta,
          )
        else
          glyph,
    ];
    return _SceneSnapshot(
      glyphs: velocityGlyphs,
      size: currentSize,
      baseline: currentBaseline,
      targetLayout: target,
      sizeVelocity: sizeVelocity,
      baselineVelocity: currentBaseline == null || previousBaseline == null
          ? 0
          : (currentBaseline - previousBaseline) / delta,
    );
  }

  _SceneSnapshot _stableSnapshot(_TextLayout layout, Size boxSize) {
    final glyphs = <_PresentedGlyph>[];
    for (final glyph in layout.glyphs) {
      final rect = _anchoredRect(glyph.bounds, layout.painter.size, boxSize);
      if (rect == null) continue;
      glyphs.add(
        _PresentedGlyph(
          layout: layout,
          glyph: glyph,
          rect: rect,
          opacity: 1,
          sigma: 0,
          scale: 1,
          lineage: glyph,
          remnantDepth: 0,
        ),
      );
    }
    final painterBaseline = layout.painter.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    return _SceneSnapshot(
      glyphs: glyphs,
      size: boxSize,
      baseline:
          painterBaseline + (boxSize.height - layout.painter.height) * 0.5,
      targetLayout: layout,
    );
  }

  _TransitionScene _buildScene({
    required _SceneSnapshot source,
    required _TextLayout previousTarget,
    required _TextLayout target,
    required Size targetSize,
    required Curve curve,
    required bool countsDown,
    double startRaw = 0,
  }) {
    final numericOnly =
        _isNumericGlyphSequence(previousTarget.glyphs) &&
        _isNumericGlyphSequence(target.glyphs);
    final pairs = _pairGlyphs(
      previousTarget.glyphs,
      target.glyphs,
      numericOnly: numericOnly,
    );
    final byLineage = Map<_Glyph, _PresentedGlyph>.identity();
    for (final glyph in source.glyphs) {
      final lineage = glyph.lineage;
      if (lineage != null) byLineage[lineage] = glyph;
    }
    final consumed = Set<_PresentedGlyph>.identity();
    final transitions = <_GlyphTransition>[];
    for (final pair in pairs) {
      final sourceGlyph = pair.oldGlyph == null
          ? null
          : byLineage[pair.oldGlyph!];
      if (sourceGlyph != null) consumed.add(sourceGlyph);
      transitions.add(
        _GlyphTransition(
          source: sourceGlyph,
          targetLayout: pair.newGlyph == null ? null : target,
          target: pair.newGlyph,
          unchanged: pair.unchanged && sourceGlyph != null,
          waveIndex: pair.waveIndex,
          waveCount: pair.waveCount,
        ),
      );
    }

    for (final glyph in source.glyphs) {
      if (consumed.contains(glyph) ||
          glyph.opacity <= 0.002 ||
          glyph.remnantDepth >= 2) {
        continue;
      }
      transitions.insert(
        0,
        _GlyphTransition(
          source: glyph,
          targetLayout: null,
          target: null,
          unchanged: false,
          waveIndex: 0,
          waveCount: 1,
          remnant: true,
        ),
      );
    }

    final targetPainterBaseline = target.painter
        .computeDistanceToActualBaseline(TextBaseline.alphabetic);
    return _TransitionScene(
      sourceSize: source.size,
      targetSize: targetSize,
      sourceBaseline: source.baseline,
      sourceSizeVelocity: source.sizeVelocity,
      sourceBaselineVelocity: source.baselineVelocity,
      targetBaseline:
          targetPainterBaseline +
          (targetSize.height - target.painter.height) * 0.5,
      targetLayout: target,
      sourceGlyphs: source.glyphs,
      transitions: transitions,
      curve: curve,
      countsDown: countsDown,
      startRaw: startRaw,
    );
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final oldPainter = _makePainter(_fromText)
      ..layout(
        minWidth: constraints.minWidth,
        maxWidth: _adjustMaxWidth(constraints.maxWidth),
      );
    TextPainter? newPainter;
    try {
      newPainter = _makePainter(_toText)
        ..layout(
          minWidth: constraints.minWidth,
          maxWidth: _adjustMaxWidth(constraints.maxWidth),
        );
      return constraints.constrain(
        Size.lerp(oldPainter.size, newPainter.size, _layoutProgress)!,
      );
    } finally {
      oldPainter.dispose();
      newPainter?.dispose();
    }
  }

  @override
  void performLayout() {
    final constraintsChanged = _layoutConstraints != constraints;
    final pending = _pendingRetarget;

    if (_targetLayout == null) {
      _targetLayout = _layout(_toText, constraints);
      _scene = _TransitionScene.stable(
        layout: _targetLayout!,
        size: constraints.constrain(_targetLayout!.painter.size),
      );
    } else if (pending != null) {
      final target = _layout(_toText, constraints);
      if (pending.immediately) {
        _scene = _TransitionScene.stable(
          layout: target,
          size: constraints.constrain(target.painter.size),
        );
      } else {
        final previousTarget =
            pending.previousTarget ??
            _layout(_fromText, _layoutConstraints ?? constraints);
        final source =
            pending.snapshot ??
            _stableSnapshot(
              previousTarget,
              (_layoutConstraints ?? constraints).constrain(
                previousTarget.painter.size,
              ),
            );
        _scene = _buildScene(
          source: source,
          previousTarget: previousTarget,
          target: target,
          targetSize: constraints.constrain(target.painter.size),
          curve: _curve,
          countsDown: _countsDown,
        );
      }
      _targetLayout = target;
      _pendingRetarget = null;
    } else if (constraintsChanged || _layoutConfigurationDirty) {
      final source = _snapshotScene(_rawProgress);
      final previousTarget = _targetLayout!;
      final target = _layout(_toText, constraints);
      if (source == null || _rawProgress >= 1) {
        _scene = _TransitionScene.stable(
          layout: target,
          size: constraints.constrain(target.painter.size),
        );
      } else {
        _scene = _buildScene(
          source: source,
          previousTarget: previousTarget,
          target: target,
          targetSize: constraints.constrain(target.painter.size),
          curve: _curve,
          countsDown: _countsDown,
          startRaw: _rawProgress,
        );
      }
      _targetLayout = target;
    }

    _layoutConstraints = constraints;
    _layoutConfigurationDirty = false;
    var scene = _scene!;
    if (_rawProgress >= 1 && !scene.isStable) {
      final target = _targetLayout!;
      scene = _TransitionScene.stable(
        layout: target,
        size: constraints.constrain(target.painter.size),
      );
      _scene = scene;
    }
    _pruneResources(scene);
    size = constraints.constrain(scene.sizeAt(_rawProgress));
  }

  _GlyphAtlas _atlasFor(_TextLayout layout) {
    return _glyphAtlases.putIfAbsent(
      layout,
      () => _GlyphAtlas.build(layout, _devicePixelRatio),
    );
  }

  Set<_TextLayout> _activeLayouts(_TransitionScene scene) {
    final active = Set<_TextLayout>.identity()..add(scene.targetLayout);
    for (final glyph in scene.sourceGlyphs) {
      active.add(glyph.layout);
    }
    for (final transition in scene.transitions) {
      final source = transition.source;
      final target = transition.targetLayout;
      if (source != null) active.add(source.layout);
      if (target != null) active.add(target);
    }
    return active;
  }

  void _pruneResources(_TransitionScene scene) {
    final active = _activeLayouts(scene);
    final obsolete = <_TextLayout>[
      for (final layout in _glyphAtlases.keys)
        if (!active.contains(layout)) layout,
    ];
    for (final layout in obsolete) {
      _glyphAtlases.remove(layout)?.dispose();
    }

    final obsoleteLayouts = <_TextLayout>[
      for (final layout in _ownedLayouts)
        if (!active.contains(layout)) layout,
    ];
    for (final layout in obsoleteLayouts) {
      _ownedLayouts.remove(layout);
      layout.dispose();
    }
  }

  void _disposeGlyphAtlases() {
    for (final atlas in _glyphAtlases.values) {
      atlas.dispose();
    }
    _glyphAtlases.clear();
  }

  void _disposeTextLayouts() {
    for (final layout in _ownedLayouts) {
      layout.dispose();
    }
    _ownedLayouts.clear();
    _fadeSizeLayout = null;
    _fadeSize = Size.zero;
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    final scene = _scene;
    if (scene == null) {
      return super.computeDistanceToActualBaseline(baseline) ?? size.height;
    }
    return scene.baselineAt(_rawProgress) ?? size.height;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final scene = _scene;
    final targetLayout = _targetLayout;
    if (scene == null || targetLayout == null) return;

    final canvas = context.canvas;
    final raw = _rawProgress;
    final overflowState = _overflowState;
    final shouldClip = overflowState.hasOverflow;
    final usesFade = shouldClip && _overflow == TextOverflow.fade;
    final clipMargin = shouldClip ? _maximumGlyphFontSize * 1.40 : 0.0;
    if (shouldClip && _overflow != TextOverflow.visible) {
      final bounds = offset & size;
      if (usesFade) {
        canvas.saveLayer(bounds, Paint());
        canvas.clipRect(bounds);
      } else {
        canvas.save();
        canvas.clipRect(bounds.inflate(clipMargin));
      }
    }

    if (raw <= 0) {
      _paintPresentedGlyphs(canvas, offset, scene.presentedAt(raw, this));
    } else if (raw >= 1) {
      targetLayout.painter.paint(
        canvas,
        offset + _layoutOrigin(targetLayout.painter.size),
      );
    } else {
      _paintPresentedGlyphs(canvas, offset, scene.presentedAt(raw, this));
    }

    if (shouldClip && _overflow != TextOverflow.visible) {
      if (usesFade) {
        canvas.translate(offset.dx, offset.dy);
        canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..blendMode = BlendMode.modulate
            ..shader = _overflowFadeShader(overflowState, targetLayout),
        );
      }
      canvas.restore();
    }
  }

  void _paintPresentedGlyph(
    Canvas canvas,
    Offset offset,
    _PresentedGlyph glyph, [
    double opacityMultiplier = 1,
  ]) {
    _paintGlyph(
      canvas: canvas,
      origin: offset,
      layout: glyph.layout,
      glyph: glyph.glyph,
      targetRect: glyph.rect,
      opacity: glyph.opacity * opacityMultiplier,
      scale: glyph.scale,
    );
  }

  void _paintPresentedGlyphs(
    Canvas canvas,
    Offset offset,
    List<_PresentedGlyph> glyphs,
  ) {
    final groups = <(bool, int), List<(_PresentedGlyph, double)>>{};
    final direct = <(_PresentedGlyph, double)>[];

    void addSample(_PresentedGlyph glyph, int bucket, double weight) {
      if (weight <= 0.002) return;
      final sample = (glyph, weight);
      if (bucket == 0) {
        direct.add(sample);
        return;
      }
      final key = (glyph.lineage == null, bucket);
      groups.putIfAbsent(key, () => <(_PresentedGlyph, double)>[]).add(sample);
    }

    for (final glyph in glyphs) {
      if (glyph.opacity <= 0.002) continue;
      final mix = _blurMix(glyph);
      addSample(glyph, mix.lower, mix.lowerWeight);
      addSample(glyph, mix.upper, mix.upperWeight);
    }

    final keys = groups.keys.toList()
      ..sort((left, right) {
        final direction = left.$1 == right.$1 ? 0 : (left.$1 ? -1 : 1);
        return direction != 0 ? direction : left.$2.compareTo(right.$2);
      });
    for (final key in keys) {
      final group = groups[key]!;
      final sigma = key.$2 * _glyphBlurBucketSize;
      Rect? bounds;
      for (final sample in group) {
        final glyph = sample.$1;
        if (glyph.opacity <= 0.002) continue;
        final rect = Rect.fromCenter(
          center: offset + glyph.rect.center,
          width: glyph.rect.width * glyph.scale,
          height: glyph.rect.height * glyph.scale,
        );
        bounds = bounds == null ? rect : bounds.expandToInclude(rect);
      }
      if (bounds == null) continue;
      final filterPaint = Paint()
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: sigma * 0.72,
          sigmaY: sigma * 1.08,
          tileMode: TileMode.decal,
        );
      canvas.saveLayer(bounds.inflate(sigma * 3 + 2), filterPaint);
      for (final sample in group) {
        _paintPresentedGlyph(canvas, offset, sample.$1, sample.$2);
      }
      canvas.restore();
    }

    for (final sample in direct) {
      _paintPresentedGlyph(canvas, offset, sample.$1, sample.$2);
    }
  }

  ({int lower, double lowerWeight, int upper, double upperWeight}) _blurMix(
    _PresentedGlyph glyph,
  ) {
    final scaledSigma = math.max(0.0, glyph.sigma / _glyphBlurBucketSize);
    final lower = scaledSigma.floor();
    final upper = scaledSigma.ceil();
    if (lower == upper) {
      return (lower: lower, lowerWeight: 1, upper: upper, upperWeight: 0);
    }
    final upperWeight = scaledSigma - lower;
    return (
      lower: lower,
      lowerWeight: 1 - upperWeight,
      upper: upper,
      upperWeight: upperWeight,
    );
  }

  _TextOverflowState get _overflowState {
    final layouts = Set<_TextLayout>.identity();
    final target = _targetLayout;
    final scene = _scene;
    if (target != null) layouts.add(target);
    if (scene != null) {
      layouts.add(scene.targetLayout);
      for (final glyph in scene.sourceGlyphs) {
        layouts.add(glyph.layout);
      }
    }

    var overflowsWidth = false;
    var overflowsHeight = false;
    for (final layout in layouts) {
      final painter = layout.painter;
      overflowsWidth |=
          constraints.hasBoundedWidth &&
          painter.size.width > constraints.maxWidth + _layoutEpsilon;
      overflowsHeight |=
          (constraints.hasBoundedHeight &&
              painter.size.height > constraints.maxHeight + _layoutEpsilon) ||
          painter.didExceedMaxLines;
    }
    return _TextOverflowState(width: overflowsWidth, height: overflowsHeight);
  }

  ui.Shader _overflowFadeShader(
    _TextOverflowState state,
    _TextLayout targetLayout,
  ) {
    final fadeSize = _fadeSizeFor(targetLayout);
    if (state.width) {
      final width = math.min(size.width, fadeSize.width);
      final (start, end) = switch (_textDirection) {
        TextDirection.rtl => (width, 0.0),
        TextDirection.ltr => (size.width - width, size.width),
      };
      return ui.Gradient.linear(Offset(start, 0), Offset(end, 0), const <Color>[
        Color(0xffffffff),
        Color(0x00ffffff),
      ]);
    }

    final height = math.min(size.height, fadeSize.height / 2);
    return ui.Gradient.linear(
      Offset(0, size.height - height),
      Offset(0, size.height),
      const <Color>[Color(0xffffffff), Color(0x00ffffff)],
    );
  }

  Size _fadeSizeFor(_TextLayout layout) {
    if (identical(_fadeSizeLayout, layout)) return _fadeSize;
    final painter = TextPainter(
      text: TextSpan(style: _toText.style, text: '\u2026'),
      textDirection: _textDirection,
      textScaler: _textScaler,
      locale: _locale,
    )..layout();
    try {
      _fadeSizeLayout = layout;
      _fadeSize = painter.size;
      return _fadeSize;
    } finally {
      painter.dispose();
    }
  }

  @override
  Rect get paintBounds {
    final oldSize = _scene?.sourceSize ?? size;
    final newSize = _scene?.targetSize ?? size;
    final oldOrigin = _layoutOrigin(oldSize);
    final newOrigin = _layoutOrigin(newSize);
    final left = math.min(0.0, math.min(oldOrigin.dx, newOrigin.dx));
    final top = math.min(0.0, math.min(oldOrigin.dy, newOrigin.dy));
    final right = math.max(
      size.width,
      math.max(oldOrigin.dx + oldSize.width, newOrigin.dx + newSize.width),
    );
    final bottom = math.max(
      size.height,
      math.max(oldOrigin.dy + oldSize.height, newOrigin.dy + newSize.height),
    );
    final bleed = _maximumGlyphFontSize * 1.40;
    return Rect.fromLTRB(
      left - bleed,
      top - bleed,
      right + bleed,
      bottom + bleed,
    );
  }

  double get _maximumGlyphFontSize {
    var maximum = 14.0;
    for (final glyph in _scene?.sourceGlyphs ?? const <_PresentedGlyph>[]) {
      maximum = math.max(maximum, glyph.glyph.style.fontSize ?? 14);
    }
    for (final glyph in _targetLayout?.glyphs ?? const <_Glyph>[]) {
      maximum = math.max(maximum, glyph.style.fontSize ?? 14);
    }
    return maximum;
  }

  double _glyphPhase(double raw, int index, int count) {
    if (count <= 1) return raw.clamp(0.0, 1.0);
    final totalStagger = math.min(
      _maximumGlyphStagger,
      (count - 1) * _perGlyphStagger,
    );
    final delay = totalStagger * index / (count - 1);
    return ((raw - delay) / (1 - delay)).clamp(0.0, 1.0);
  }

  Rect _rectInCurrentBox(Rect rect, Size sourceBox, Size currentBox) {
    return rect.shift(
      Offset(
        (currentBox.width - sourceBox.width) * _horizontalAnchor,
        (currentBox.height - sourceBox.height) * 0.5,
      ),
    );
  }

  Rect? _anchoredRect(Rect? rect, Size layoutSize, [Size? boxSize]) {
    if (rect == null) return null;
    return rect.shift(_layoutOrigin(layoutSize, boxSize));
  }

  Offset _layoutOrigin(Size layoutSize, [Size? boxSize]) {
    final box = boxSize ?? size;
    return Offset(
      (box.width - layoutSize.width) * _horizontalAnchor,
      (box.height - layoutSize.height) * 0.5,
    );
  }

  double get _horizontalAnchor {
    return switch (_textAlign) {
      TextAlign.left => 0,
      TextAlign.right => 1,
      TextAlign.center => 0.5,
      TextAlign.start ||
      TextAlign.justify => _textDirection == TextDirection.ltr ? 0 : 1,
      TextAlign.end => _textDirection == TextDirection.ltr ? 1 : 0,
    };
  }

  void _paintGlyph({
    required Canvas canvas,
    required Offset origin,
    required _TextLayout layout,
    required _Glyph glyph,
    required Rect targetRect,
    required double opacity,
    required double scale,
  }) {
    final sourceRect = glyph.bounds;
    if (sourceRect == null || opacity <= 0.002) return;
    final atlasEntry = _atlasFor(layout).entries[glyph];
    if (atlasEntry != null) {
      _paintAtlasGlyph(
        canvas: canvas,
        origin: origin,
        sourceRect: sourceRect,
        targetRect: targetRect,
        atlasEntry: atlasEntry,
        opacity: opacity,
        scale: scale,
      );
      return;
    }

    final dx = targetRect.center.dx - sourceRect.center.dx;
    final dy = targetRect.center.dy - sourceRect.center.dy;
    final needsLayer = opacity < 0.999;
    if (needsLayer) {
      final destinationCenter = origin + targetRect.center;
      final transformedBounds = Rect.fromCenter(
        center: destinationCenter,
        width: sourceRect.width * scale,
        height: sourceRect.height * scale,
      );
      final layerMargin = math.max(2.0, sourceRect.longestSide * 0.05);
      final layerBounds = transformedBounds.inflate(layerMargin);

      final layerPaint = Paint()
        ..color = Color.fromRGBO(255, 255, 255, opacity);
      canvas.saveLayer(layerBounds, layerPaint);
    }

    canvas.save();
    canvas.translate(origin.dx + dx, origin.dy + dy);
    canvas.translate(sourceRect.center.dx, sourceRect.center.dy);
    canvas.scale(scale);
    canvas.translate(-sourceRect.center.dx, -sourceRect.center.dy);
    canvas.clipRect(sourceRect.inflate(0.6));
    layout.painter.paint(canvas, Offset.zero);
    canvas.restore();
    if (needsLayer) canvas.restore();
  }

  void _paintAtlasGlyph({
    required Canvas canvas,
    required Offset origin,
    required Rect sourceRect,
    required Rect targetRect,
    required _GlyphAtlasEntry atlasEntry,
    required double opacity,
    required double scale,
  }) {
    final logicalBounds = atlasEntry.logicalBounds;
    final centerDelta = logicalBounds.center - sourceRect.center;
    final destinationCenter =
        origin +
        targetRect.center +
        Offset(centerDelta.dx * scale, centerDelta.dy * scale);
    final destination = Rect.fromCenter(
      center: destinationCenter,
      width: logicalBounds.width * scale,
      height: logicalBounds.height * scale,
    );
    final paint = Paint()
      ..color = Color.fromRGBO(255, 255, 255, opacity)
      ..filterQuality = FilterQuality.medium;
    canvas.drawImageRect(
      atlasEntry.image,
      atlasEntry.sourceRect,
      destination,
      paint,
    );
  }

  bool _needsEffectPass(_PresentedGlyph glyph) {
    return glyph.opacity > 0.002 &&
        (glyph.opacity < 0.999 || glyph.sigma > 0.05);
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..label = _semanticsLabel
      ..textDirection = _textDirection;
  }

  @override
  void detach() {
    _animation.removeListener(_handleTick);
    super.detach();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _animation.addListener(_handleTick);
  }

  @override
  void dispose() {
    _disposeGlyphAtlases();
    _disposeTextLayouts();
    super.dispose();
  }
}
