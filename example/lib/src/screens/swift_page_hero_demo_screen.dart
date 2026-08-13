import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

class SwiftPageHeroDemoCard extends StatelessWidget {
  const SwiftPageHeroDemoCard({required this.heroTag, super.key});

  final Object heroTag;

  void _openDemo(BuildContext context) {
    Navigator.of(context).push(
      SwiftPageRoute<void>(
        settings: const RouteSettings(name: '/swift-page-hero-demo'),
        child: SwiftPageHeroDemoScreen(heroTag: heroTag),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open the interactive SwiftPage Hero demo',
      child: GestureDetector(
        key: const ValueKey('swift-page-hero-demo-card'),
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
              colors: [Color(0xff362e75), Color(0xffb43f73)],
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
                      'SWIFTPAGE',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.25,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Interactive Hero',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Open, then slowly swipe back from the center.',
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
                          'Open demo',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 7),
                        Icon(
                          CupertinoIcons.arrow_right,
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
                flightShuttleBuilder: _buildHeroFlight,
                child: const SizedBox.square(
                  dimension: 108,
                  child: _HeroArtwork(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SwiftPageHeroDemoScreen extends StatelessWidget {
  const SwiftPageHeroDemoScreen({required this.heroTag, super.key});

  final Object heroTag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('swift-page-hero-demo-screen'),
      backgroundColor: const Color(0xfff7f1e8),
      body: Stack(
        children: [
          const Positioned(
            top: -120,
            right: -90,
            child: _BackgroundGlow(color: Color(0x55ff4d8d)),
          ),
          const Positioned(
            bottom: -160,
            left: -120,
            child: _BackgroundGlow(color: Color(0x554f46e5)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CupertinoButton(
                    key: const ValueKey('swift-page-hero-back-button'),
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.maybePop(context),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.back, size: 20),
                        SizedBox(width: 4),
                        Text('Back'),
                      ],
                    ),
                  ),
                  const Spacer(flex: 2),
                  Center(
                    child: Hero(
                      tag: heroTag,
                      transitionOnUserGestures: true,
                      flightShuttleBuilder: _buildHeroFlight,
                      child: const SizedBox.square(
                        dimension: 250,
                        child: _HeroArtwork(),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Hero follows your finger',
                    style: TextStyle(
                      color: Color(0xff171525),
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Drag right from any empty area and keep your finger down. '
                    'The page and this artwork should move back together.',
                    style: TextStyle(
                      color: const Color(0xff171525).withValues(alpha: 0.62),
                      fontSize: 17,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.68),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          CupertinoIcons.hand_draw_fill,
                          color: Color(0xff5b4dcb),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Try both a cancelled swipe and a completed swipe.',
                            style: TextStyle(
                              color: Color(0xff28243c),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildHeroFlight(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  return const _HeroArtwork(key: ValueKey('swift-page-hero-flight'));
}

class _HeroArtwork extends StatelessWidget {
  const _HeroArtwork({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xffffce54), Color(0xffff4d8d), Color(0xff6c5ce7)],
          stops: [0, 0.48, 1],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.72),
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x443b256d),
            blurRadius: 36,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: const FractionallySizedBox(
        widthFactor: 0.46,
        heightFactor: 0.46,
        child: FittedBox(
          child: Icon(CupertinoIcons.sparkles, color: Colors.white),
        ),
      ),
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      height: 360,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
