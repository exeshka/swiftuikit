part of '../swift_text.dart';

const _layoutEpsilon = 0.001;
const _minimumGlyphScale = 0.62;
const _maximumGlyphStagger = 0.35;
const _perGlyphStagger = 0.06;
const _glyphTravelFactor = 0.50;
const _glyphBlurFactor = 0.12;
const _glyphBlurBucketSize = 1.0;
const _outgoingOpacityLanding = 0.90;
const _incomingOpacityLanding = 0.94;
const _velocitySampleRawDelta = 1 / 240;
const _swiftUISmoothSettlingRatio = 0.9 / 0.55;

double _retargetMomentum(double t) {
  if (t <= 0 || t >= 1) return 0;
  return t * math.pow(1 - t, 8).toDouble();
}

double _smootherStep(double value) {
  final t = value.clamp(0.0, 1.0).toDouble();
  return t * t * t * (t * (t * 6 - 15) + 10);
}

double _outgoingOpacity(double motion) {
  return 1 - _smootherStep(motion / _outgoingOpacityLanding);
}

double _incomingOpacity(double motion) {
  return _smootherStep(motion / _incomingOpacityLanding);
}

/// The critically damped response used by SwiftUI's non-bouncing `smooth`
/// spring.
///
/// [settlingRatio] converts SwiftUI's perceptual duration into the longer
/// physical timeline needed by the spring to become visually stationary. The
/// default is measured from `Spring.smooth(duration: 0.55)`, whose perceptual
/// duration is 0.55 seconds and settling duration is 0.9 seconds.
class SwiftTextSmoothCurve extends Curve {
  const SwiftTextSmoothCurve({this.settlingRatio = _swiftUISmoothSettlingRatio})
    : assert(settlingRatio > 1);

  final double settlingRatio;

  @override
  double transformInternal(double t) {
    if (t == 0 || t == 1) return t;
    final response = 2 * math.pi * settlingRatio;
    final x = response * t;
    return 1 - (1 + x) * math.exp(-x);
  }
}
