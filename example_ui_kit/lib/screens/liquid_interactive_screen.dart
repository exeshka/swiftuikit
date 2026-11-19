import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swiftuikit/swiftuikit.dart';

import 'tech_page.dart';

/// Interactive glass (press scale + highlight), same layout as the native
/// reference in tools/native_glass_ref (`inter` mode): gray backdrop, 200x80
/// capsule at (101, 300).
// --dart-define=GRAY=15|50|85 sets the backdrop gray in percent.
const _gray = int.fromEnvironment('GRAY', defaultValue: 50);

// --dart-define=HDR=true: highlight/rim up to 1.25 (needs FLTEnableWideGamut + the EDR flag set natively, see
// docs/hdr-notes.md; the native `ravel/edr` channel exists in example/ios and example/macos).
const _hdr = bool.fromEnvironment('HDR');

@RoutePage()
class LiquidInteractiveScreen extends StatefulWidget {
  const LiquidInteractiveScreen({super.key});

  @override
  State<LiquidInteractiveScreen> createState() =>
      _LiquidInteractiveScreenState();
}

class _LiquidInteractiveScreenState extends State<LiquidInteractiveScreen> {
  @override
  void initState() {
    super.initState();
    if (_hdr) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        try {
          await const MethodChannel('ravel/edr')
              .invokeMethod<String>('set', true);
        } catch (_) {}
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = SwiftUiTheme.of(context);
    return TechPage(
      title: 'Liquid glass interactive',
      child: Theme(
        data: base.isDark
            ? SwiftUiTheme.dark(
                data: base.withGlass(liquidHdr: _hdr ? 1.25 : 1.0),
              )
            : SwiftUiTheme.light(
                data: base.withGlass(liquidHdr: _hdr ? 1.25 : 1.0),
              ),
        child: _body(context),
      ),
    );
  }

  Widget _body(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(
        (_gray * 2.55).round(),
        (_gray * 2.55).round(),
        (_gray * 2.55).round(),
        1,
      ),
      body: Stack(
        children: [
          Positioned(
            left: 101,
            top: 300,
            child: GestureDetector(
              onTap: () {},
              child: const LiquidGlass(
                width: 200,
                height: 80,
                interactive: true,
                child: Center(
                  child: Text(
                    'Glass button',
                    style: TextStyle(color: Colors.white, fontSize: 17),
                  ),
                ),
              ),
            ),
          ),
          // same circles as the native reference (tools/native_glass_ref `inter`): 41/49/57/73 pt
          for (final c in const [
            (56.0, 581.0, 41.0),
            (150.0, 585.0, 49.0),
            (244.0, 589.0, 57.0),
            (342.0, 597.0, 73.0),
          ])
            Positioned(
              left: c.$1 - c.$3 / 2,
              top: c.$2 - c.$3 / 2,
              child: GestureDetector(
                onTap: () {},
                child: LiquidGlass.circle(
                  size: c.$3,
                  interactive: true,
                  child: const Icon(Icons.add, color: Colors.white, size: 22),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
