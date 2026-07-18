import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:example/src/core/router/router.gr.dart';

@RoutePage()
class HeroPageOneScreen extends StatelessWidget {
  const HeroPageOneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CupertinoNavigationBar(
        middle: const Text('Page One'),
        previousPageTitle: 'Home',
        backgroundColor: CupertinoColors.systemBlue.withValues(alpha: 0.1),

        enableBackgroundFilterBlur: false,
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Hero(
                tag: 'hero-icon',
                child: Icon(
                  CupertinoIcons.star_fill,
                  size: 80,
                  color: CupertinoColors.systemRed,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'SwiftPage #1',
                style: CupertinoTheme.of(
                  context,
                ).textTheme.navLargeTitleTextStyle,
              ),
              const SizedBox(height: 8),
              Text(
                'Swipe right to gesture back',
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              const SizedBox(height: 32),
              CupertinoButton.filled(
                onPressed: () => context.router.push(const HeroRouteTwoRoute()),
                child: const Text('Open Page Two'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
