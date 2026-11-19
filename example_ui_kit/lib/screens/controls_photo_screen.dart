import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

import 'tech_page.dart';

/// Segmented control and sliders over the photo, the same layout as the native reference (tools/native_glass_ref `controls`).
@RoutePage()
class ControlsPhotoScreen extends StatefulWidget {
  const ControlsPhotoScreen({super.key});
  @override
  State<ControlsPhotoScreen> createState() => _ControlsPhotoScreenState();
}

class _ControlsPhotoScreenState extends State<ControlsPhotoScreen> {
  String _seg = 'a';
  double _v = 0.4;
  double _v2 = 0.7;

  @override
  Widget build(BuildContext context) {
    return TechPage(
      title: 'Photo controls',
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/liquid_bg.png', fit: BoxFit.cover),
            Center(
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
                    const SizedBox(height: 48),
                    GlassSegmentedControl<String>(
                      segments: const [
                        GlassSegment(value: 'a', label: 'All'),
                        GlassSegment(value: 'b', label: 'Unread'),
                        GlassSegment(value: 'c', label: 'Flagged'),
                      ],
                      value: 'b',
                      onChanged: (_) {},
                      debugPressed: true,
                    ),
                    const SizedBox(height: 40),
                    GlassSlider(
                      value: 0.5,
                      onChanged: (_) {},
                      debugPressed: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
