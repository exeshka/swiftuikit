part of '../swift_text.dart';

class _PendingRetarget {
  const _PendingRetarget({
    required this.snapshot,
    required this.previousTarget,
    required this.immediately,
  });

  final _SceneSnapshot? snapshot;
  final _TextLayout? previousTarget;
  final bool immediately;
}

class _SceneSnapshot {
  const _SceneSnapshot({
    required this.glyphs,
    required this.size,
    required this.baseline,
    required this.targetLayout,
    this.sizeVelocity = Offset.zero,
    this.baselineVelocity = 0,
  });

  final List<_PresentedGlyph> glyphs;
  final Size size;
  final double? baseline;
  final _TextLayout targetLayout;
  final Offset sizeVelocity;
  final double baselineVelocity;
}

class _PresentedGlyph {
  const _PresentedGlyph({
    required this.layout,
    required this.glyph,
    required this.rect,
    required this.opacity,
    required this.sigma,
    required this.scale,
    required this.lineage,
    required this.remnantDepth,
    this.positionVelocity = Offset.zero,
    this.opacityVelocity = 0,
    this.sigmaVelocity = 0,
    this.scaleVelocity = 0,
  });

  final _TextLayout layout;
  final _Glyph glyph;
  final Rect rect;
  final double opacity;
  final double sigma;
  final double scale;

  final _Glyph? lineage;

  final int remnantDepth;
  final Offset positionVelocity;
  final double opacityVelocity;
  final double sigmaVelocity;
  final double scaleVelocity;
}

class _GlyphTransition {
  const _GlyphTransition({
    required this.source,
    required this.targetLayout,
    required this.target,
    required this.unchanged,
    required this.waveIndex,
    required this.waveCount,
    this.remnant = false,
  });

  final _PresentedGlyph? source;
  final _TextLayout? targetLayout;
  final _Glyph? target;
  final bool unchanged;
  final int waveIndex;
  final int waveCount;
  final bool remnant;
}

class _TransitionScene {
  const _TransitionScene({
    required this.sourceSize,
    required this.targetSize,
    required this.sourceBaseline,
    required this.sourceSizeVelocity,
    required this.sourceBaselineVelocity,
    required this.targetBaseline,
    required this.targetLayout,
    required this.sourceGlyphs,
    required this.transitions,
    required this.curve,
    required this.countsDown,
    required this.startRaw,
    this.isStable = false,
  });

  factory _TransitionScene.stable({
    required _TextLayout layout,
    required Size size,
  }) {
    final painterBaseline = layout.painter.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    final baseline =
        painterBaseline + (size.height - layout.painter.height) * 0.5;
    return _TransitionScene(
      sourceSize: size,
      targetSize: size,
      sourceBaseline: baseline,
      sourceSizeVelocity: Offset.zero,
      sourceBaselineVelocity: 0,
      targetBaseline: baseline,
      targetLayout: layout,
      sourceGlyphs: const <_PresentedGlyph>[],
      transitions: const <_GlyphTransition>[],
      curve: Curves.linear,
      countsDown: false,
      startRaw: 0,
      isStable: true,
    );
  }

  final Size sourceSize;
  final Size targetSize;
  final double? sourceBaseline;
  final Offset sourceSizeVelocity;
  final double sourceBaselineVelocity;
  final double? targetBaseline;
  final _TextLayout targetLayout;
  final List<_PresentedGlyph> sourceGlyphs;
  final List<_GlyphTransition> transitions;
  final Curve curve;
  final bool countsDown;
  final double startRaw;
  final bool isStable;

  double normalizedRaw(double raw) {
    if (isStable) return 1;
    if (startRaw >= 1) return 1;
    return ((raw - startRaw) / (1 - startRaw)).clamp(0.0, 1.0);
  }

  double layoutProgress(double raw) {
    if (isStable) return 1;
    return curve.transform(normalizedRaw(raw)).clamp(0.0, 1.0);
  }

  Size sizeAt(double raw) {
    if (isStable) return targetSize;
    final base = Size.lerp(sourceSize, targetSize, layoutProgress(raw))!;
    final momentum = _momentumDisplacement(raw);
    return Size(
      math.max(0, base.width + sourceSizeVelocity.dx * momentum),
      math.max(0, base.height + sourceSizeVelocity.dy * momentum),
    );
  }

  double? baselineAt(double raw) {
    if (sourceBaseline == null || targetBaseline == null) return targetBaseline;
    final base = ui.lerpDouble(
      sourceBaseline,
      targetBaseline,
      layoutProgress(raw),
    )!;
    return base + sourceBaselineVelocity * _momentumDisplacement(raw);
  }

  double _momentumDisplacement(double raw) {
    if (isStable) return 0;
    return (1 - startRaw) * _retargetMomentum(normalizedRaw(raw));
  }

  List<_PresentedGlyph> presentedAt(double raw, _RenderSwiftText render) {
    final localRaw = normalizedRaw(raw);
    if (isStable || localRaw >= 1) {
      return render._stableSnapshot(targetLayout, targetSize).glyphs;
    }

    final currentSize = sizeAt(raw);
    final layoutPhase = layoutProgress(raw);
    final momentum = _momentumDisplacement(raw);
    final direction = countsDown ? -1.0 : 1.0;
    final result = <_PresentedGlyph>[];

    for (final transition in transitions) {
      final source = transition.source;
      final target = transition.target;
      final targetLayout = transition.targetLayout;
      final phase = transition.remnant
          ? (localRaw / 0.45).clamp(0.0, 1.0)
          : render._glyphPhase(
              localRaw,
              transition.waveIndex,
              transition.waveCount,
            );
      final motion = curve.transform(phase).clamp(0.0, 1.0);
      final fontSize = math.max(
        source?.glyph.style.fontSize ?? 14,
        target?.style.fontSize ?? 14,
      );
      final travel = fontSize * _glyphTravelFactor;
      final maximumSigma = math.max(0.75, fontSize * _glyphBlurFactor);

      Rect? sourceRect;
      if (source != null) {
        sourceRect = render._rectInCurrentBox(
          source.rect,
          sourceSize,
          currentSize,
        );
      }
      final targetRect = targetLayout == null || target == null
          ? null
          : render._anchoredRect(
              target.bounds,
              targetLayout.painter.size,
              currentSize,
            );

      if (transition.unchanged &&
          source != null &&
          sourceRect != null &&
          target != null &&
          targetLayout != null &&
          targetRect != null) {
        final opacityProgress = _incomingOpacity(layoutPhase);
        result.add(
          _PresentedGlyph(
            layout: targetLayout,
            glyph: target,
            rect: Rect.lerp(
              sourceRect,
              targetRect,
              layoutPhase,
            )!.shift(source.positionVelocity * momentum),
            opacity:
                (ui.lerpDouble(source.opacity, 1, opacityProgress)! +
                        source.opacityVelocity * momentum)
                    .clamp(0.0, 1.0)
                    .toDouble(),
            sigma: math.max(
              0,
              ui.lerpDouble(source.sigma, 0, opacityProgress)! +
                  source.sigmaVelocity * momentum,
            ),
            scale:
                (ui.lerpDouble(source.scale, 1, layoutPhase)! +
                        source.scaleVelocity * momentum)
                    .clamp(_minimumGlyphScale, 1.0)
                    .toDouble(),
            lineage: target,
            remnantDepth: 0,
          ),
        );
        continue;
      }

      if (source != null && sourceRect != null && motion < 1) {
        final baseOpacity = source.opacity * _outgoingOpacity(motion);
        final baseSigma = ui.lerpDouble(source.sigma, maximumSigma, motion)!;
        final baseScale = ui.lerpDouble(
          source.scale,
          _minimumGlyphScale,
          motion,
        )!;
        result.add(
          _PresentedGlyph(
            layout: source.layout,
            glyph: source.glyph,
            rect: sourceRect.shift(
              Offset(0, -direction * travel * motion) +
                  source.positionVelocity * momentum,
            ),
            opacity: (baseOpacity + source.opacityVelocity * momentum)
                .clamp(0.0, 1.0)
                .toDouble(),
            sigma: math.max(0, baseSigma + source.sigmaVelocity * momentum),
            scale: (baseScale + source.scaleVelocity * momentum)
                .clamp(_minimumGlyphScale, 1.0)
                .toDouble(),
            lineage: null,
            remnantDepth: source.remnantDepth + 1,
          ),
        );
      }

      if (target != null && targetLayout != null && targetRect != null) {
        result.add(
          _PresentedGlyph(
            layout: targetLayout,
            glyph: target,
            rect: targetRect.shift(
              Offset(0, direction * travel * (1 - motion)),
            ),
            opacity: _incomingOpacity(motion),
            sigma: maximumSigma * (1 - _incomingOpacity(motion)),
            scale: ui.lerpDouble(_minimumGlyphScale, 1, motion)!,
            lineage: target,
            remnantDepth: 0,
          ),
        );
      }
    }
    return result;
  }
}
