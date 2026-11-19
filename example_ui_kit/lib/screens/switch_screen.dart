import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

import 'tech_page.dart';

/// The same three switches as the native reference (tools/native_glass_ref `switch`).
@RoutePage()
class SwitchScreen extends StatefulWidget {
  const SwitchScreen({super.key});
  @override
  State<SwitchScreen> createState() => _SwitchScreenState();
}

class _SwitchScreenState extends State<SwitchScreen> {
  bool _a = true;
  bool _b = false;
  bool _c = true;
  bool _d = false;
  // tap -> 2 s awaited request (the switch is locked, spinner in the thumb) -> it switches
  Future<void> _toggleSlow(bool v) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _d = v);
  }

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    Widget row(String label, bool v, ValueChanged<bool> on, {Color? color}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            children: [
              Expanded(child: Text(label, style: t.typography.body)),
              GlassSwitch(value: v, onChanged: on, activeColor: color),
            ],
          ),
        );
    return TechPage(
      title: 'Switches',
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                row('Wi-Fi', _a, (v) => setState(() => _a = v)),
                row('Bluetooth', _b, (v) => setState(() => _b = v)),
                row(
                  'Airplane',
                  _c,
                  (v) => setState(() => _c = v),
                  color: const Color(0xFFFF9230),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Loading', style: t.typography.body),
                      ),
                      GlassSwitch(
                        value: _d,
                        onChanged: null,
                        onChangedAsync: _toggleSlow,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pressed (static)',
                          style: t.typography.body,
                        ),
                      ),
                      GlassSwitch(
                        value: false,
                        onChanged: (_) {},
                        debugPressed: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
