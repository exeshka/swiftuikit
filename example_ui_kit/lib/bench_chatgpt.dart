// Scroll benchmark of the real ChatGPT screen (profile): flutter run --profile -d <ios> -t lib/bench_chatgpt.dart
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:swiftuikit/swiftuikit.dart';

import 'screens/chatgpt_screen.dart';

final navKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await preloadRavelUiKit();
  runApp(
    SwiftUiApp(
      navigatorKey: navKey,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      home: const ChatGptScreen(),
    ),
  );
  final frames = <ui.FrameTiming>[];
  var rec = false;
  SchedulerBinding.instance.addTimingsCallback((t) {
    if (rec) frames.addAll(t);
  });
  ScrollableState? find() {
    ScrollableState? r;
    void v(Element e) {
      if (r != null) return;
      if (e is StatefulElement && e.state is ScrollableState) {
        r = e.state as ScrollableState;
        return;
      }
      e.visitChildren(v);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(v);
    return r;
  }

  await Future<void>.delayed(const Duration(seconds: 3));
  final nav = navKey;
  final binding = GestureBinding.instance;
  Future<void> measure(String name, Future<void> Function() body) async {
    frames.clear();
    rec = true;
    await body();
    rec = false;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    report(name, frames);
  }

  // A: finger drag with overscroll (down from the top, up, release), repeated
  Future<void> fingerDrag() async {
    for (var k = 0; k < 6; k++) {
      var pos = const Offset(200, 400);
      binding.handlePointerEvent(PointerDownEvent(pointer: 1, position: pos));
      for (var i = 0; i < 40; i++) {
        pos = Offset(
          200,
          400 + 6.0 * (i < 20 ? i : 40 - i),
        ); // pull down and back
        binding.handlePointerEvent(
          PointerMoveEvent(
            pointer: 1,
            position: pos,
            delta: const Offset(0, 6),
          ),
        );
        await SchedulerBinding.instance.endOfFrame;
      }
      binding.handlePointerEvent(PointerUpEvent(pointer: 1, position: pos));
      await Future<void>.delayed(const Duration(milliseconds: 600));
    }
  }

  await measure('finger overscroll', fingerDrag);

  await measure('cupertino push/pop', () async {
    for (var k = 0; k < 4; k++) {
      nav.currentState!.push(
        CupertinoPageRoute<void>(builder: (_) => const ChatGptScreen()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 800));
      nav.currentState!.pop();
      await Future<void>.delayed(const Duration(milliseconds: 800));
    }
  });
  nav.currentState!.push(
    CupertinoPageRoute<void>(builder: (_) => const ChatGptScreen()),
  );
  await Future<void>.delayed(const Duration(seconds: 1));
  await measure('swipe-back drag', () async {
    for (var k = 0; k < 6; k++) {
      var pos = const Offset(4, 400);
      binding.handlePointerEvent(PointerDownEvent(pointer: 2, position: pos));
      for (var i = 0; i < 40; i++) {
        pos = Offset(4 + 5.0 * (i < 20 ? i : 40 - i), 400);
        binding.handlePointerEvent(
          PointerMoveEvent(
            pointer: 2,
            position: pos,
            delta: Offset(i < 20 ? 5 : -5, 0),
          ),
        );
        await SchedulerBinding.instance.endOfFrame;
      }
      binding.handlePointerEvent(PointerUpEvent(pointer: 2, position: pos));
      await Future<void>.delayed(const Duration(milliseconds: 800));
    }
  });
  stdout.writeln('BENCHGPT DONE');
  exit(0);
}

void report(String name, List<ui.FrameTiming> frames) {
  if (frames.length < 5) {
    stdout.writeln('BENCHGPT $name: no frames');
    return;
  }
  double pct(List<double> s, double p) => s[((s.length - 1) * p).round()];
  final raster =
      frames.map((f) => f.rasterDuration.inMicroseconds / 1000).toList()
        ..sort();
  final build =
      frames.map((f) => f.buildDuration.inMicroseconds / 1000).toList()..sort();
  String f(double v) => v.toStringAsFixed(2);
  stdout.writeln(
    'BENCHGPT $name frames=${frames.length} build p50=${f(pct(build, .5))} p99=${f(pct(build, .99))} | raster p50=${f(pct(raster, .5))} p99=${f(pct(raster, .99))} max=${f(raster.last)}',
  );
}
