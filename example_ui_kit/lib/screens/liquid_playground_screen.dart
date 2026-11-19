import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

import 'tech_page.dart';

/// Full-screen picture with draggable liquid glass plates on top, and sliders
/// for the liquid glass tokens.
// --dart-define=CLEAN=true hides the controls (for side-by-side with native).
const _clean = bool.fromEnvironment('CLEAN');
// --dart-define=CALIB=true: calibration picture + five 300x90 plates (see tools/native_glass_ref).
const _calib = bool.fromEnvironment('CALIB');
// --dart-define=GROUP=true: all plates share one LiquidGlassGroup pass.
const _group = bool.fromEnvironment('GROUP');
// --dart-define=CLEAR=true: Glass.clear variant.
const _clearGlass = bool.fromEnvironment('CLEAR');

@RoutePage()
class LiquidPlaygroundScreen extends StatefulWidget {
  const LiquidPlaygroundScreen({super.key});

  @override
  State<LiquidPlaygroundScreen> createState() => _LiquidPlaygroundScreenState();
}

class _Plate {
  _Plate(this.pos, this.w, this.h, this.radius, this.label);
  Offset pos;
  final double w;
  final double h;
  final double? radius; // null: fully round
  final String label;
}

class _LiquidPlaygroundScreenState extends State<LiquidPlaygroundScreen> {
  final _plates = _calib
      ? <_Plate>[
          for (final y in [115.0, 255.0, 395.0, 535.0, 675.0])
            _Plate(Offset(51, y), 300, 90, 28, ''),
        ]
      : <_Plate>[
          _Plate(const Offset(40, 220), 96, 96, null, 'circle'),
          _Plate(const Offset(150, 330), 200, 60, null, 'pill'),
          _Plate(const Offset(60, 470), 150, 150, 40, 'squircle'),
          _Plate(const Offset(200, 600), 170, 90, 28, 'card'),
        ];

  double? _refraction;
  double? _bezel;
  double? _blur;
  double? _tintAlpha;

  List<Widget> _wrap(List<Widget> plates) => _group
      ? [
          Positioned.fill(
            child: LiquidGlassGroup(child: Stack(children: plates)),
          ),
        ]
      : plates;

  @override
  Widget build(BuildContext context) {
    final base = SwiftUiTheme.of(context);
    final tokens = base.withGlass(
      liquidRefraction: _refraction ?? base.glass.liquidRefraction,
      liquidBezel: _bezel ?? base.glass.liquidBezel,
      liquidBlur: _blur ?? base.glass.liquidBlur,
      liquidTint: base.glass.liquidTint.withValues(
        alpha: _tintAlpha ?? base.glass.liquidTint.a,
      ),
    );
    final theme = base.isDark
        ? SwiftUiTheme.dark(data: tokens)
        : SwiftUiTheme.light(data: tokens);
    final safe = MediaQuery.paddingOf(context);

    return TechPage(
      title: 'Liquid glass',
      child: Theme(
        data: theme,
        child: Builder(
          builder: (context) {
            final t = SwiftUiTheme.of(context);
            Widget slider(
              String name,
              double value,
              double min,
              double max,
              ValueChanged<double> on,
            ) {
              return Row(
                children: [
                  SizedBox(
                    width: 86,
                    child: Text(
                      name,
                      style: t.typography.caption.copyWith(
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(trackHeight: 2),
                      child: Slider(
                        value: value.clamp(min, max),
                        min: min,
                        max: max,
                        onChanged: on,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 38,
                    child: Text(
                      value.toStringAsFixed(1),
                      style: t.typography.caption.copyWith(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            }

            return Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _calib
                        ? 'assets/liquid_test_bg.png'
                        : 'assets/liquid_bg.png',
                    fit: BoxFit.cover,
                  ),
                  ..._wrap([
                    for (final p in _plates)
                      Positioned(
                        left: p.pos.dx,
                        top: p.pos.dy,
                        child: GestureDetector(
                          onPanUpdate: (d) => setState(() => p.pos += d.delta),
                          child: LiquidGlass(
                            width: p.w,
                            height: p.h,
                            cornerRadius: p.radius,
                            clear: _clearGlass,
                            child: Center(
                              child: Text(
                                p.label,
                                style: t.typography.body.copyWith(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ]),
                  if (!_clean)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: safe.bottom + 6,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                        decoration: BoxDecoration(
                          color: const Color(0x99000000),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            slider(
                              'refraction',
                              t.glass.liquidRefraction,
                              0,
                              40,
                              (v) => setState(() => _refraction = v),
                            ),
                            slider(
                              'bezel',
                              t.glass.liquidBezel,
                              2,
                              40,
                              (v) => setState(() => _bezel = v),
                            ),
                            slider(
                              'blur',
                              t.glass.liquidBlur,
                              0,
                              6,
                              (v) => setState(() => _blur = v),
                            ),
                            slider(
                              'tint',
                              t.glass.liquidTint.a,
                              0,
                              0.6,
                              (v) => setState(() => _tintAlpha = v),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
