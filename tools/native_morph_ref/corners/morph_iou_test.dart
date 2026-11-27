// flutter test tools/native_morph_ref/corners/morph_iou_test.dart
//
// Offline check of the menu morph silhouette against the native one, with no shader: the rectangle springs, x0 offsets, tails, corner
// radii and scale knots are READ FROM lib/src/components/glass_menu.dart, evaluated at the same tau as every native frame and compared
// by IoU of the contours (Flutter RRect, 0.5 pt grid).
//   native        = the rounded rectangle with four radii fitted to the native frame (data/native_fit_*.json, fit_corners.py)
//   code          = glass_menu.dart as it is (its `_EdgeSpring.at` decides whether the tail term is applied)
//   code+tail     = the same with the tail term forced on
//   proposed      = fitted edge springs (with tails) + radii from the fits (morph_model.dart)
//   ceiling       = native rectangle + proposed radii (what the corner shape alone can give)
// Writes out/ours_{open,close}.json (for score_vs_evidence.py, which scores the same shapes against the pixels),
// out/iou_{open,close}.txt and out/windows.txt (mean IoU per window).
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'morph_model.dart';

const _libPath = 'lib/src/components/glass_menu.dart';

List<double> _list(String src, String name) {
  final m = RegExp('const $name = \\[([\\s\\S]*?)\\];').firstMatch(src);
  expect(m, isNotNull, reason: '$name not found in glass_menu.dart');
  return [for (final s in m!.group(1)!.split(',')) if (s.trim().isNotEmpty) double.parse(s.trim())];
}

/// Returns the source as it is (tails as the code applies them) and whether `_EdgeSpring.at` applies the tail at all.
({MenuSource source, bool tailApplied}) readSource() {
  final src = File(_libPath).readAsStringSync();
  EdgeSpring spring(String name) {
    final m = RegExp('const $name = _EdgeSpring\\(([-\\d.]+), ([-\\d.]+), ([-\\d.]+), ([-\\d.]+)(?:, ([-\\d.]+), ([-\\d.]+))?\\);').firstMatch(src);
    expect(m, isNotNull, reason: '$name not found in glass_menu.dart: the test has to be updated');
    double g(int i) => double.parse(m!.group(i)!);
    return EdgeSpring(g(1), g(2), g(3), g(4), d: m!.group(5) == null ? 0 : g(5), ts: m.group(6) == null ? 1 : g(6));
  }

  // offset convention of the model: L +, T +, B + (x0 = edge + value), R - (x0 = edge - value)
  double off(String fn, String name, String edge) {
    final m = RegExp('$fn[\\s\\S]*?$name\\.at\\(\\s*tau,\\s*rest: [a-z]+\\.$edge,\\s*x0: [a-z]+\\.$edge ([+-]) ([\\d.]+)').firstMatch(src);
    expect(m, isNotNull, reason: 'x0 of $name not found');
    final v = double.parse(m!.group(2)!) * (m.group(1) == '-' ? -1 : 1);
    return edge == 'right' ? -v : v;
  }

  final atBody = RegExp(r'double at\([\s\S]*?\n  \}\n\}').firstMatch(src)?.group(0) ?? '';
  final tailApplied = RegExp(r'\btail\b').hasMatch(atBody) && atBody.contains('tailMs');
  final hasKnots = src.contains('_kCloseKnotsTau');
  final source = MenuSource(
    open: [spring('_kOpenL'), spring('_kOpenR'), spring('_kOpenT'), spring('_kOpenB')],
    close: [spring('_kCloseL'), spring('_kCloseR'), spring('_kCloseT'), spring('_kCloseB')],
    openX0: [off('Rect openRect', '_kOpenL', 'left'), off('Rect openRect', '_kOpenR', 'right'), off('Rect openRect', '_kOpenT', 'top'), off('Rect openRect', '_kOpenB', 'bottom')],
    closeX0: [off('Rect closeRect', '_kCloseL', 'left'), off('Rect closeRect', '_kCloseR', 'right'), off('Rect closeRect', '_kCloseT', 'top'), off('Rect closeRect', '_kCloseB', 'bottom')],
    openSymmetric: !src.contains('radius * (1 - 0.5 * lean)') && !src.contains('trScale = 1 - 0.5 * lean'),
    closeKnotsTau: hasKnots ? _list(src, '_kCloseKnotsTau') : const [],
    closeKnotsTR: hasKnots ? _list(src, '_kCloseKnotsTR') : const [],
    closeKnotsBR: hasKnots ? _list(src, '_kCloseKnotsBR') : const [],
  );
  return (source: source.withTails(tailApplied), tailApplied: tailApplied);
}

void main() {
  late MenuSource code, codeTail, proposed;
  late bool tailApplied;
  setUpAll(() {
    final r = readSource();
    code = r.source;
    tailApplied = r.tailApplied;
    // the raw parse again, with the tails forced on
    codeTail = readSource().source; // placeholder, replaced below
    final src = File(_libPath).readAsStringSync();
    codeTail = _raw(src).withTails(true);
    proposed = MenuSource.proposedEdges(code);
  });
  const here = 'tools/native_morph_ref/corners';

  test('the radius formulas in glass_menu.dart are still the ones this test mirrors', () {
    final src = File(_libPath).readAsStringSync();
    for (final s in [
      'const restRadius = 31.0;',
      'restRadius + 22 * _smoothStep(tau / 45)',
      'trScale = _lerpKnots(_kCloseKnotsTau, _kCloseKnotsTR, tau)',
      'brScale = _lerpKnots(_kCloseKnotsTau, _kCloseKnotsBR, tau)',
      'double trScale = 1;',
      'exp(-(tau - 190) / 56)',
    ]) {
      expect(src.contains(s), isTrue, reason: 'changed in glass_menu.dart: $s (update morph_model.dart)');
    }
    // ignore: avoid_print
    print('tail term applied by _EdgeSpring.at: $tailApplied');
  });

  final windows = StringBuffer();
  for (final kind in ['open', 'close']) {
    test('IoU of the $kind silhouette vs the native frames', () {
      final fits = (jsonDecode(File('$here/data/native_fit_$kind.json').readAsStringSync()) as List).cast<Map<String, dynamic>>();
      final rows = <Map<String, dynamic>>[];
      final buf = StringBuffer('tau,ms  native_fit_iou  code  code+tail  proposed  ceiling\n');
      final sum = <double>[0, 0, 0, 0];
      final win = <String, List<List<double>>>{};
      var n = 0;
      for (final f in fits) {
        final tau = (f['tau'] as num).toDouble();
        if (tau < -5 || tau > (kind == 'open' ? 700 : 450)) continue;
        double d(String k) => (f[k] as num).toDouble();
        final natRect = Rect.fromLTRB(d('L'), d('T'), d('R'), d('B'));
        final nat = RRect.fromRectAndCorners(natRect,
            topLeft: Radius.circular(d('tl')), topRight: Radius.circular(d('tr')), bottomRight: Radius.circular(d('br')), bottomLeft: Radius.circular(d('bl')));
        Rect rect(MenuSource s) => kind == 'open' ? s.openRect(tau) : s.closeRect(tau);
        Radii cur(MenuSource s) => kind == 'open' ? s.currentOpen(tau) : s.currentClose(tau);
        final cRect = rect(code), tRect = rect(codeTail), pRect = rect(proposed);
        final cRad = cur(code), tRad = cur(codeTail);
        final pRad = kind == 'open' ? proposedOpen(pRect, tau) : proposedClose(pRect, tau);
        final cRad2 = kind == 'open' ? proposedOpen(natRect, tau) : proposedClose(natRect, tau);
        final v = [iou(nat, rrect(cRect, cRad)), iou(nat, rrect(tRect, tRad)), iou(nat, rrect(pRect, pRad)), iou(nat, rrect(natRect, cRad2))];
        for (var k = 0; k < 4; k++) {
          sum[k] += v[k];
        }
        n++;
        final w = kind == 'open' ? (tau >= 15 && tau <= 40 ? 'open 15-40' : null) : (tau >= 100 && tau <= 230 ? 'close 100-230' : null);
        if (w != null) (win[w] ??= []).add(v);
        rows.add({
          'tau': tau, 'i': f['i'],
          'ours_code': _json(cRect, cRad), 'ours_codetail': _json(tRect, tRad), 'ours_prop_edges': _json(pRect, pRad), 'nat_prop': _json(natRect, cRad2),
          'iou': v,
        });
        buf.writeln('${tau.toStringAsFixed(0).padLeft(5)}  ${d('iou').toStringAsFixed(3)}  ${v.map((e) => e.toStringAsFixed(3)).join('  ')}');
      }
      buf.writeln('mean over $n frames: ${sum.map((e) => (e / n).toStringAsFixed(3)).join('  ')}');
      windows.writeln('$kind all: ${sum.map((e) => (e / n).toStringAsFixed(3)).join('  ')}  (code, code+tail, proposed, ceiling)');
      win.forEach((k, vs) {
        final mean = [for (var j = 0; j < 4; j++) vs.map((e) => e[j]).reduce((a, b) => a + b) / vs.length];
        windows.writeln('$k (${vs.length} frames): ${mean.map((e) => e.toStringAsFixed(3)).join('  ')}');
      });
      Directory('$here/out').createSync(recursive: true);
      File('$here/out/ours_$kind.json').writeAsStringSync(jsonEncode(rows));
      File('$here/out/iou_$kind.txt').writeAsStringSync(buf.toString());
      File('$here/out/windows.txt').writeAsStringSync('tail applied by the code: $tailApplied\n$windows');
      // ignore: avoid_print
      print(buf);
      expect(n, greaterThan(50));
    });
  }
}

/// The springs and offsets exactly as written in the source, tails included whether or not `at()` uses them.
MenuSource _raw(String src) {
  EdgeSpring spring(String name) {
    final m = RegExp('const $name = _EdgeSpring\\(([-\\d.]+), ([-\\d.]+), ([-\\d.]+), ([-\\d.]+)(?:, ([-\\d.]+), ([-\\d.]+))?\\);').firstMatch(src)!;
    double g(int i) => double.parse(m.group(i)!);
    return EdgeSpring(g(1), g(2), g(3), g(4), d: m.group(5) == null ? 0 : g(5), ts: m.group(6) == null ? 1 : g(6));
  }

  double off(String fn, String name, String edge) {
    final m = RegExp('$fn[\\s\\S]*?$name\\.at\\(\\s*tau,\\s*rest: [a-z]+\\.$edge,\\s*x0: [a-z]+\\.$edge ([+-]) ([\\d.]+)').firstMatch(src)!;
    final v = double.parse(m.group(2)!) * (m.group(1) == '-' ? -1 : 1);
    return edge == 'right' ? -v : v;
  }

  final hasKnots = src.contains('_kCloseKnotsTau');
  return MenuSource(
    open: [spring('_kOpenL'), spring('_kOpenR'), spring('_kOpenT'), spring('_kOpenB')],
    close: [spring('_kCloseL'), spring('_kCloseR'), spring('_kCloseT'), spring('_kCloseB')],
    openX0: [off('Rect openRect', '_kOpenL', 'left'), off('Rect openRect', '_kOpenR', 'right'), off('Rect openRect', '_kOpenT', 'top'), off('Rect openRect', '_kOpenB', 'bottom')],
    closeX0: [off('Rect closeRect', '_kCloseL', 'left'), off('Rect closeRect', '_kCloseR', 'right'), off('Rect closeRect', '_kCloseT', 'top'), off('Rect closeRect', '_kCloseB', 'bottom')],
    openSymmetric: !src.contains('trScale = 1 - 0.5 * lean'),
    closeKnotsTau: hasKnots ? _list(src, '_kCloseKnotsTau') : const [],
    closeKnotsTR: hasKnots ? _list(src, '_kCloseKnotsTR') : const [],
    closeKnotsBR: hasKnots ? _list(src, '_kCloseKnotsBR') : const [],
  );
}

Map<String, dynamic> _json(Rect r, Radii q) => {
      'L': r.left, 'T': r.top, 'R': r.right, 'B': r.bottom, 'tl': q.tl, 'tr': q.tr, 'br': q.br, 'bl': q.bl,
    };
