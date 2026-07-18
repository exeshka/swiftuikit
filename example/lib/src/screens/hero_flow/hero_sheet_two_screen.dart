import 'package:auto_route/auto_route.dart';
import 'package:example/src/core/router/router.gr.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

@RoutePage()
class HeroSheetTwoScreen extends StatelessWidget {
  const HeroSheetTwoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CupertinoNavigationBar(
        middle: const Text('Sheet Two'),
        backgroundColor: CupertinoColors.systemPurple.withValues(alpha: 0.9),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.router.maybePop(),
          child: const Text('Close'),
        ),
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
                  size: 120,
                  color: CupertinoColors.systemPurple,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'SwiftSheet #2',
                style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle,
              ),
              const SizedBox(height: 8),
              Text(
                'Flow continues to scrollable sheets',
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              const SizedBox(height: 32),
              CupertinoButton.filled(
                onPressed: () => context.router.push(const HeroSheetThreeRoute()),
                child: const Text('Open Sheet Three (Scroll)'),
              ),
              const SizedBox(height: 16),
              CupertinoButton(
                color: CupertinoColors.destructiveRed,
                onPressed: () =>
                    context.router.popUntilRouteWithName('HeroRouteOneRoute'),
                child: const Text('Pop to Page One'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
