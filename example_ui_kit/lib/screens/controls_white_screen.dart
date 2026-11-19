import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

import 'tech_page.dart';

/// Segmented control and sliders on a white background in light theme, the same as the native reference
/// (tools/native_glass_ref, args `controls white`).
@RoutePage()
class ControlsWhiteScreen extends StatefulWidget {
  const ControlsWhiteScreen({super.key});
  @override
  State<ControlsWhiteScreen> createState() => _ControlsWhiteScreenState();
}

class _ControlsWhiteScreenState extends State<ControlsWhiteScreen> {
  String _seg = 'a';
  double _v = 0.4;
  double _v2 = 0.7;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: SwiftUiTheme.light(),
      child: TechPage(
        title: 'White controls',
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GlassSegmentedControl<String>(
                    segments: const [
                      GlassSegment(value: 'a', label: 'All'),
                      GlassSegment(value: 'b', label: 'Unread'),
                      GlassSegment(value: 'c', label: 'Flagged'),
                    ],
                    value: _seg,
                    onChanged: (v) => setState(() => _seg = v),
                  ),
                  const SizedBox(height: 48),
                  GlassSlider(
                    value: _v,
                    onChanged: (v) => setState(() => _v = v),
                  ),
                  const SizedBox(height: 48),
                  GlassSlider(
                    value: _v2,
                    divisions: 10,
                    onChanged: (v) => setState(() => _v2 = v),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
