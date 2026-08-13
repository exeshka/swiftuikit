import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

class SwiftSheetHeroDemoCard extends StatelessWidget {
  const SwiftSheetHeroDemoCard({required this.heroTag, super.key});

  final Object heroTag;

  void _openDemo(BuildContext context) {
    Navigator.of(context).push(
      SwiftSheetRoute<void>(
        settings: const RouteSettings(name: '/swift-sheet-hero-demo'),
        showDragHandle: true,
        sheetRadius: 34,
        scrollableBuilder: (context, controller) => SwiftSheetHeroDemoContent(
          heroTag: heroTag,
          scrollController: controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open the interactive SwiftSheet Hero demo',
      child: GestureDetector(
        key: const ValueKey('swift-sheet-hero-demo-card'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _openDemo(context),
        child: Container(
          height: 220,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xff064e3b), Color(0xff0f766e)],
            ),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SWIFTSHEET',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.25,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Hero + live background',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Dismiss fast, then immediately scroll this page.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    const Row(
                      children: [
                        Text(
                          'Open sheet',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 7),
                        Icon(
                          CupertinoIcons.arrow_up_right,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Hero(
                tag: heroTag,
                transitionOnUserGestures: true,
                flightShuttleBuilder: buildSwiftSheetHeroFlight,
                child: const SizedBox.square(
                  dimension: 104,
                  child: SwiftSheetHeroArtwork(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SwiftSheetHeroDemoContent extends StatelessWidget {
  const SwiftSheetHeroDemoContent({
    required this.heroTag,
    required this.scrollController,
    super.key,
  });

  final Object heroTag;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('swift-sheet-hero-demo-content'),
      color: const Color(0xffecfdf5),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(24, 46, 24, 48),
        children: [
          Center(
            child: Hero(
              tag: heroTag,
              transitionOnUserGestures: true,
              flightShuttleBuilder: buildSwiftSheetHeroFlight,
              child: const SizedBox.square(
                dimension: 230,
                child: SwiftSheetHeroArtwork(),
              ),
            ),
          ),
          const SizedBox(height: 34),
          const Text(
            'SwiftSheet Hero',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xff062f2a),
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'The Hero follows both a slow interactive drag and a fast dismiss.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xff062f2a).withValues(alpha: 0.62),
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          const _GestureHint(
            icon: CupertinoIcons.hand_draw_fill,
            title: 'Slow gesture',
            body:
                'Drag down slowly, pause, then cancel or complete the dismiss.',
          ),
          const SizedBox(height: 12),
          const _GestureHint(
            icon: CupertinoIcons.bolt_fill,
            title: 'Fast gesture',
            body:
                'Flick down and immediately scroll the revealed Discover page.',
          ),
          const SizedBox(height: 140),
        ],
      ),
    );
  }
}

Widget buildSwiftSheetHeroFlight(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  return const SwiftSheetHeroArtwork(key: ValueKey('swift-sheet-hero-flight'));
}

class SwiftSheetHeroArtwork extends StatelessWidget {
  const SwiftSheetHeroArtwork({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(38),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff5eead4), Color(0xff14b8a6), Color(0xff0f766e)],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.78),
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x440f766e),
            blurRadius: 34,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: const FractionallySizedBox(
        widthFactor: 0.48,
        heightFactor: 0.48,
        child: FittedBox(
          child: Icon(CupertinoIcons.layers_alt_fill, color: Colors.white),
        ),
      ),
    );
  }
}

class _GestureHint extends StatelessWidget {
  const _GestureHint({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x18062f2a)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xffccfbf1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xff0f766e)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xff062f2a),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: TextStyle(
                    color: const Color(0xff062f2a).withValues(alpha: 0.62),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
