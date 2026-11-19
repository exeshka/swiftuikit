import 'package:auto_route/auto_route.dart';

import 'dart:async';
import 'dart:ui' show ColorSpace;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tech_page.dart';

/// EDR/HDR experiment: three squares (SDR white 1.0, extended sRGB 1.25 and
/// 2.0) and a timer that toggles `wantsExtendedDynamicRangeContent` on the
/// native layers every 8 s. Needs the native `ravel/edr` channel (macOS only
/// at the moment).
@RoutePage()
class EdrTestScreen extends StatefulWidget {
  const EdrTestScreen({super.key});
  @override
  State<EdrTestScreen> createState() => _EdrTestScreenState();
}

class _EdrTestScreenState extends State<EdrTestScreen> {
  static const _ch = MethodChannel('ravel/edr');
  bool _on = false;
  String _info = '';
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _apply();
    _t = Timer.periodic(const Duration(seconds: 8), (_) {
      _on = !_on;
      _apply();
    });
  }

  Future<void> _apply() async {
    try {
      final r = await _ch.invokeMethod<String>('set', _on);
      debugPrint('EDR flag=$_on\n$r');
      final i = await _ch.invokeMethod<String>('info');
      debugPrint('EDR info: $i');
      if (mounted) setState(() => _info = 'flag=$_on\n$i');
    } catch (e) {
      debugPrint('EDR channel error: $e');
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  Color _g(double v) => Color.from(
    alpha: 1,
    red: v,
    green: v,
    blue: v,
    colorSpace: ColorSpace.extendedSRGB,
  );

  @override
  Widget build(BuildContext context) {
    Widget box(double v) => Container(
      width: 90,
      height: 90,
      color: _g(v),
      alignment: Alignment.center,
      child: Text(v.toString(), style: const TextStyle(color: Colors.black)),
    );
    return TechPage(
      title: 'EDR / HDR test',
      child: Scaffold(
        backgroundColor: const Color(0xFF303030),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  box(1.0),
                  const SizedBox(width: 12),
                  box(1.25),
                  const SizedBox(width: 12),
                  box(2.0),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _info,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
