// The silhouette of the menu morph as plain geometry (no shader): rectangle springs and corner radii, the same formulas as
// lib/src/components/glass_menu.dart (`current`), and the corner radii proposed from the native fits (`proposed`).
// All lengths in pt, tau in real ms. The rectangle is the native menu's, in the native screen layout (see MORPH_SPEC.md).
import 'dart:math' as math;
import 'dart:ui';

import 'morph_knots.dart';

/// Native layout of the recording (pt): the capsule at rest and the settled menu.
const Rect kCap = Rect.fromLTRB(282.0, 62.7, 385.3, 105.7);
const Rect kMenu = Rect.fromLTRB(136.7, 62.3, 385.7, 228.0);

double smoothStep(double x) {
  final t = x.clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

class EdgeSpring {
  const EdgeSpring(this.t0, this.v0, this.omega, this.zeta, {this.d = 0, this.ts = 1});

  EdgeSpring withTail(bool on) => on ? this : EdgeSpring(t0, v0, omega, zeta);
  final double t0, v0, omega, zeta;

  /// slow tail added after the spring: d * exp(-(tau - t0) / ts)  (not in glass_menu.dart yet)
  final double d, ts;
  double at(double tau, {required double rest, required double x0, required double xf}) {
    if (tau <= t0) {
      final s = (tau / t0).clamp(0.0, 1.0);
      return rest + (x0 - rest) * s * s * (3 - 2 * s);
    }
    final s = tau - t0;
    final wd = omega * math.sqrt(1 - zeta * zeta);
    final dd = x0 - xf;
    return xf + math.exp(-zeta * omega * s) * (dd * math.cos(wd * s) + (v0 + zeta * omega * dd) / wd * math.sin(wd * s)) + d * math.exp(-s / ts);
  }
}

class Radii {
  const Radii(this.tl, this.tr, this.br, this.bl);
  final double tl, tr, br, bl;
}

/// Everything read from glass_menu.dart, so that the test follows the code (see morph_iou_test.dart).
class MenuSource {
  MenuSource({
    required this.open,
    required this.close,
    required this.openX0,
    required this.closeX0,
    this.openSymmetric = false,
    this.closeKnotsTau = const [],
    this.closeKnotsTR = const [],
    this.closeKnotsBR = const [],
    this.closeRadiusSmooth = false,
    this.clampToHeight = false,
  });

  /// glass_menu.dart no longer leans the opening (trScale = brScale = 1).
  final bool openSymmetric;

  /// glass_menu.dart closing: TR / BR scales from knots, radius 31 + 22 * smoothStep(tau / 45).
  final List<double> closeKnotsTau, closeKnotsTR, closeKnotsBR;
  final bool closeRadiusSmooth;

  /// The shader clamps a corner radius (after the scale) to the plate's height.
  final bool clampToHeight;

  MenuSource withTails(bool on) => MenuSource(
        open: [for (final s in open) s.withTail(on)],
        close: [for (final s in close) s.withTail(on)],
        openX0: openX0,
        closeX0: closeX0,
        openSymmetric: openSymmetric,
        closeKnotsTau: closeKnotsTau,
        closeKnotsTR: closeKnotsTR,
        closeKnotsBR: closeKnotsBR,
        closeRadiusSmooth: closeRadiusSmooth,
        clampToHeight: clampToHeight,
      );

  Radii _clamp(Radii q, Rect r) {
    if (!clampToHeight) return q;
    double c(double v) => math.min(v, r.height);
    return Radii(c(q.tl), c(q.tr), c(q.br), c(q.bl));
  }
  final List<EdgeSpring> open; // L, R, T, B
  final List<EdgeSpring> close;
  final List<double> openX0; // offsets used as x0: L +, T +, R -, B +
  final List<double> closeX0;

  /// Edge springs re-fitted on the fitted silhouettes (fit_edges.py, plain spring variant); only closing changes noticeably.
  static MenuSource proposedEdges(MenuSource base) => MenuSource(
        open: [base.open[0], base.open[1], base.open[2], const EdgeSpring(31.4, 2.181, 0.0218, 0.66, d: 7.19, ts: 215)],
        openX0: [base.openX0[0], base.openX0[1], base.openX0[2], -0.5],
        close: const [
          EdgeSpring(103.9, 0.870, 0.0301, 0.55, d: 12.43, ts: 37), // L
          EdgeSpring(132.7, -0.879, 0.0301, 0.90, d: 1.93, ts: 267), // R
          EdgeSpring(33.1, 1.070, 0.0238, 0.59, d: -5.93, ts: 426), // T
          EdgeSpring(36.3, 0.446, 0.0167, 0.70, d: -7.04, ts: 63), // B
        ],
        // x0 = rest edge + offset (L +, R -, T +, B +): 208.3 - 136.7, 385.7 - 360.1, 89.2 - 62.3, 250.8 - 228.0
        closeX0: const [71.6, 25.6, 26.9, 22.8],
        openSymmetric: true,
      );

  Rect openRect(double tau) => Rect.fromLTRB(
        open[0].at(tau, rest: kCap.left, x0: kCap.left + openX0[0], xf: kMenu.left),
        open[2].at(tau, rest: kCap.top, x0: kCap.top + openX0[2], xf: kMenu.top),
        open[1].at(tau, rest: kCap.right, x0: kCap.right - openX0[1], xf: kMenu.right),
        open[3].at(tau, rest: kCap.bottom, x0: kCap.bottom + openX0[3], xf: kMenu.bottom),
      );

  Rect closeRect(double tau) => Rect.fromLTRB(
        close[0].at(tau, rest: kMenu.left, x0: kMenu.left + closeX0[0], xf: kCap.left),
        close[2].at(tau, rest: kMenu.top, x0: kMenu.top + closeX0[2], xf: kCap.top),
        close[1].at(tau, rest: kMenu.right, x0: kMenu.right - closeX0[1], xf: kCap.right),
        close[3].at(tau, rest: kMenu.bottom, x0: kMenu.bottom + closeX0[3], xf: kCap.bottom),
      );

  /// The radii of glass_menu.dart (`radius`, `trScale`, `brScale`), opening.
  Radii currentOpen(double tau) => currentOpenOn(openRect(tau), tau);

  /// The same formulas for a given rectangle (the radius is min(half, f(tau)) of that rectangle).
  Radii currentOpenOn(Rect r, double tau) {
    final half = math.min(r.width, r.height) / 2;
    final r190 = (() {
      final q = openRect(190);
      return math.min(q.width, q.height) / 2;
    })();
    var radius = tau < 190 ? half : 31.0 + (r190 - 31.0) * math.exp(-(tau - 190) / 56);
    radius = math.min(radius, half);
    if (openSymmetric) return _clamp(Radii(radius, radius, radius, radius), r);
    final lean = smoothStep((tau - 45) / 55) * (1 - smoothStep((tau - 200) / 200));
    return _clamp(Radii(radius, radius * (1 - 0.5 * lean), radius * (1 - 0.15 * lean), radius), r);
  }

  Radii currentClose(double tau) => currentCloseOn(closeRect(tau), tau);

  Radii currentCloseOn(Rect r, double tau) {
    final half = math.min(r.width, r.height) / 2;
    if (closeKnotsTau.isNotEmpty) {
      final radius = math.min(half, 31.0 + 22.0 * smoothStep(tau / 45));
      return _clamp(
        Radii(radius, radius * _knot(closeKnotsTau, closeKnotsTR, tau), radius * _knot(closeKnotsTau, closeKnotsBR, tau), radius),
        r,
      );
    }
    final radius = math.min(half, 31.0 + 0.75 * tau);
    final lean = smoothStep(tau / 60) * (1 - smoothStep((tau - 150) / 110));
    return _clamp(Radii(radius, radius * (1 - 0.5 * lean), radius * (1 - 0.15 * lean), radius), r);
  }
}

double _knot(List<double> xs, List<double> ys, double x) {
  if (x <= xs.first) return ys.first;
  if (x >= xs.last) return ys.last;
  for (var i = 0; i + 1 < xs.length; i++) {
    if (x <= xs[i + 1]) {
      final t = (x - xs[i]) / (xs[i + 1] - xs[i]);
      return ys[i] + (ys[i + 1] - ys[i]) * t;
    }
  }
  return ys.last;
}

/// Proposed (from the fits): radius_corner = rho(tau) * knot_corner(tau).
Radii proposedOpen(Rect r, double tau) {
  final half = math.min(r.width, r.height) / 2;
  final rho = tau < 190 ? half : math.min(half, 30.5 + (82.0 - 30.5) * math.exp(-(tau - 190) / 54.0));
  return Radii(
    rho * _knot(kKnotsOpenTau, kKnotsOpenTL, tau),
    rho * _knot(kKnotsOpenTau, kKnotsOpenTR, tau),
    rho * _knot(kKnotsOpenTau, kKnotsOpenBR, tau),
    rho * _knot(kKnotsOpenTau, kKnotsOpenBL, tau),
  );
}

Radii proposedClose(Rect r, double tau) {
  final half = math.min(r.width, r.height) / 2;
  final rho = math.min(half, 31.0 + 22.0 * smoothStep(tau / 45.0));
  return Radii(
    rho * _knot(kKnotsCloseTau, kKnotsCloseTL, tau),
    rho * _knot(kKnotsCloseTau, kKnotsCloseTR, tau),
    rho * _knot(kKnotsCloseTau, kKnotsCloseBR, tau),
    rho * _knot(kKnotsCloseTau, kKnotsCloseBL, tau),
  );
}

RRect rrect(Rect r, Radii q) => RRect.fromRectAndCorners(
      r,
      topLeft: Radius.circular(math.max(0, q.tl)),
      topRight: Radius.circular(math.max(0, q.tr)),
      bottomRight: Radius.circular(math.max(0, q.br)),
      bottomLeft: Radius.circular(math.max(0, q.bl)),
    );

/// IoU of two rounded rectangles on a 0.5 pt grid (RRect.contains, so Flutter's own radius normalisation applies).
double iou(RRect a, RRect b) {
  final l = math.min(a.left, b.left), t = math.min(a.top, b.top), r = math.max(a.right, b.right), bt = math.max(a.bottom, b.bottom);
  var inter = 0, uni = 0;
  for (var y = t + 0.25; y < bt; y += 0.5) {
    for (var x = l + 0.25; x < r; x += 0.5) {
      final p = Offset(x, y);
      final ia = a.contains(p), ib = b.contains(p);
      if (ia && ib) inter++;
      if (ia || ib) uni++;
    }
  }
  return uni == 0 ? 0 : inter / uni;
}
