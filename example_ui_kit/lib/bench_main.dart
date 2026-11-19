// Frame-cost benchmark of the progressive blur strategies.
//   cd example && flutter run --profile -d macos -t lib/bench_main.dart
// Prints one line per method and exits.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:swiftuikit/swiftuikit.dart';

enum _Mode { none, uniform, kit }

class _Case {
  const _Case(
    this.name,
    this.mode, {
    this.zone = 150,
    this.layers = 1,
    this.buttons = -1,
    this.variant = 0,
    this.skip = 0,
    this.bar = 0,
    this.prefilter = 0.5,
    this.n = 0,
  });
  final int n; // >0 with bar: N plates scattered over the screen (bar 1 individual, 2 one group, 3 flat)
  final double prefilter; // SwiftUiThemeData.liquidPrefilter
  final int bar; // 1: 6 liquid plates in a bar (individual), 2: same in one LiquidGlassGroup, 3: flat glass
  final int skip; // RenderLiquidGlass.debugSkip
  final int variant;
  final String name;
  final _Mode
  mode; // none / plain uniform BackdropFilter (baseline) / kit ProgressiveBlur
  final double zone;
  final int layers; // zones stacked on each other (stress)
  final int buttons; // >=0: list of gradient cards with N glass buttons each
}

final _cases = [
  _Case('none', _Mode.none),
  _Case('uniform (baseline)', _Mode.uniform),
  _Case('kit blur', _Mode.kit),
  _Case('BAR none', _Mode.none),
  _Case('BAR 6 liquid individual', _Mode.none, bar: 1),
  _Case('BAR 6 liquid grouped', _Mode.none, bar: 2),
  _Case(
    'BAR 6 liquid grouped, shader-only blur',
    _Mode.none,
    bar: 2,
    prefilter: 0,
  ),
  _Case('BAR 6 flat glass', _Mode.none, bar: 3),
  for (final n in [8, 16, 32, 64]) ...[
    _Case('SCATTER $n individual', _Mode.none, bar: 1, n: n),
    _Case('SCATTER $n one group', _Mode.none, bar: 2, n: n),
    _Case('SCATTER $n flat glass', _Mode.none, bar: 3, n: n),
  ],
  _Case('CARDS 4 liquid (36, individual)', _Mode.none, buttons: 4, variant: 5),
  _Case(
    'CARDS 4 liquid, highQuality (engine prefilter)',
    _Mode.none,
    buttons: 4,
    variant: 7,
  ),
  _Case(
    'CARDS 4 liquid, no blur at all',
    _Mode.none,
    buttons: 4,
    variant: 5,
    skip: 4,
  ),
  _Case('CARDS 4 flat glass', _Mode.none, buttons: 4, variant: 6),
];

Widget _button(int v) => v == 7
    ? const LiquidGlass.circle(
        size: 44,
        highQuality: true,
        child: Center(
          child: RavelIcon(RavelIconKind.search, color: Colors.white),
        ),
      )
    : v == 6
    ? const GlassSurface.circle(
        size: 44,
        liquid: false,
        child: Center(
          child: RavelIcon(RavelIconKind.search, color: Colors.white),
        ),
      )
    : v == 5
    ? const LiquidGlass.circle(
        size: 44,
        child: Center(
          child: RavelIcon(RavelIconKind.search, color: Colors.white),
        ),
      )
    : GlassCircleButton(
        icon: RavelIcon(RavelIconKind.search),
        blur: v == 4,
        onPressed: () {},
      );

Widget _bar(int mode, int n) {
  final count = n > 0 ? n : 6;
  final plates = n > 0
      ? Wrap(
          alignment: WrapAlignment.spaceEvenly,
          runAlignment: WrapAlignment.spaceEvenly,
          spacing: 40,
          runSpacing: 40,
          children: [for (var i = 0; i < count; i++) _plate(mode)],
        )
      : Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [for (var i = 0; i < count; i++) _plate(mode)],
        );
  return mode == 2 ? LiquidGlassGroup(child: plates) : plates;
}

Widget _plate(int mode) => mode == 3
    ? const GlassSurface.circle(
        size: 44,
        liquid: false,
        child: Center(
          child: RavelIcon(RavelIconKind.search, color: Colors.white),
        ),
      )
    : const LiquidGlass.circle(
        size: 44,
        child: Center(
          child: RavelIcon(RavelIconKind.search, color: Colors.white),
        ),
      );

Widget _zone(_Case c, BlurEdge edge, String key) {
  switch (c.mode) {
    case _Mode.none:
      return SizedBox(height: c.zone / c.layers);
    case _Mode.uniform:
      return SizedBox(
        height: c.zone / c.layers,
        child: ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: 10,
              sigmaY: 10,
              tileMode: TileMode.clamp,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      );
    case _Mode.kit:
      return ProgressiveBlur(
        key: ValueKey(key),
        height: c.zone / c.layers,
        edge: edge,
        maxSigma: 10,
        tint: Colors.black,
      );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await preloadRavelUiKit();
  runApp(const _BenchApp());
}

class _BenchApp extends StatefulWidget {
  const _BenchApp();
  @override
  State<_BenchApp> createState() => _BenchAppState();
}

class _BenchAppState extends State<_BenchApp>
    with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  late final Ticker _ticker;
  int _case = 0;
  final _frames = <ui.FrameTiming>[];
  bool _recording = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback((t) {
      if (_recording) _frames.addAll(t);
    });
    _ticker = createTicker((d) {
      if (!_scroll.hasClients) return;
      final p = _scroll.position;
      if (!p.hasContentDimensions) return;
      final y = (d.inMicroseconds / 1e6 * 900) % (p.maxScrollExtent - 100);
      _scroll.jumpTo(y);
    })..start();
    unawaited(_run());
  }

  Future<void> _run() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    for (var i = 0; i < _cases.length; i++) {
      RenderLiquidGlass.debugSkip = _cases[i].skip;
      setState(() => _case = i);
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      _frames.clear();
      _recording = true;
      final sw = Stopwatch()..start();
      while (_frames.length < 360 && sw.elapsed < const Duration(seconds: 25)) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
      _recording = false;
      await Future<void>.delayed(const Duration(milliseconds: 300));
      _report(_cases[i]);
    }
    stdout.writeln('BENCH DONE');
    _flush();
    exit(0);
  }

  final _lines = StringBuffer();
  void _flush() {
    try {
      final home = Platform.environment['HOME'];
      if (home != null)
        File('$home/Documents/bench.txt').writeAsStringSync(_lines.toString());
    } catch (_) {}
  }

  double _pct(List<double> s, double p) => s[((s.length - 1) * p).round()];

  void _report(_Case c) {
    if (_frames.length < 5) {
      stdout.writeln('BENCH ${c.name}: no frames');
      return;
    }
    final build =
        _frames.map((f) => f.buildDuration.inMicroseconds / 1000).toList()
          ..sort();
    final raster =
        _frames.map((f) => f.rasterDuration.inMicroseconds / 1000).toList()
          ..sort();
    final total = _frames.map((f) => f.totalSpan.inMicroseconds / 1000).toList()
      ..sort();
    final fin =
        _frames
            .map((f) => f.timestampInMicroseconds(ui.FramePhase.rasterFinish))
            .toList()
          ..sort();
    final ivs = <double>[];
    for (var i = 1; i < fin.length; i++) {
      ivs.add((fin[i] - fin[i - 1]) / 1000);
    }
    ivs.sort();
    final fps =
        _frames.length /
        ((_frames.last.timestampInMicroseconds(ui.FramePhase.rasterFinish) -
                _frames.first.timestampInMicroseconds(
                  ui.FramePhase.vsyncStart,
                )) /
            1e6);
    String f(double v) => v.toStringAsFixed(2);
    final line =
        'BENCH ${c.name.padRight(18)} frames=${_frames.length} fps=${f(fps)} '
        'build p50=${f(_pct(build, .5))} p99=${f(_pct(build, .99))} | '
        'raster p50=${f(_pct(raster, .5))} p99=${f(_pct(raster, .99))} | '
        'total p50=${f(_pct(total, .5))} p99=${f(_pct(total, .99))} | '
        'interval p50=${f(_pct(ivs, .5))} p99=${f(_pct(ivs, .99))} ms';
    stdout.writeln(line);
    _lines.writeln(line);
    _flush();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _cases[_case];
    return SwiftUiApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: SwiftUiThemeData.dark().withGlass(
        liquidPrefilter: c.prefilter,
      ),
      home: Scaffold(
        body: Stack(
          children: [
            if (c.buttons >= 0)
              ListView.builder(
                controller: _scroll,
                itemCount: 400,
                itemExtent: 102,
                itemBuilder: (_, i) => Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      colors: [
                        HSLColor.fromAHSL(
                          1,
                          (i * 37.0) % 360,
                          0.7,
                          0.45,
                        ).toColor(),
                        HSLColor.fromAHSL(
                          1,
                          (i * 37.0 + 50) % 360,
                          0.7,
                          0.35,
                        ).toColor(),
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Wrap(
                    spacing: 12,
                    children: [
                      for (var k = 0; k < c.buttons; k++) _button(c.variant),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                controller: _scroll,
                itemCount: 400,
                itemBuilder: (_, i) => Container(
                  height: 56,
                  color: i.isEven
                      ? const Color(0xFF202030)
                      : const Color(0xFF301820),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Row $i — The quick brown fox jumps over the lazy dog',
                    style: const TextStyle(fontSize: 17),
                  ),
                ),
              ),
            if (c.bar > 0 && c.n > 0)
              Positioned.fill(top: 70, bottom: 70, child: _bar(c.bar, c.n))
            else if (c.bar > 0)
              Positioned(top: 70, left: 0, right: 0, child: _bar(c.bar, 0)),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  for (var i = 0; i < c.layers; i++)
                    _zone(c, BlurEdge.top, 't${c.name}$i'),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  for (var i = 0; i < c.layers; i++)
                    _zone(c, BlurEdge.bottom, 'b${c.name}$i'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
