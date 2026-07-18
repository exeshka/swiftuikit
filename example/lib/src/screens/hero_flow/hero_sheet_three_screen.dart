import 'package:auto_route/auto_route.dart';
import 'package:example/src/core/router/router.gr.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

@RoutePage()
class HeroSheetThreeScreen extends StatelessWidget {
  const HeroSheetThreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CupertinoNavigationBar(
        middle: const Text('Sheet Three (Scroll)'),
        backgroundColor: CupertinoColors.systemGreen.withValues(alpha: 0.9),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.router.maybePop(),
          child: const Text('Close'),
        ),
      ),
      body: SafeArea(
        child: ListView.builder(
          itemCount: 40,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Hero(
                      tag: 'hero-icon',
                      child: Icon(
                        CupertinoIcons.star_fill,
                        size: 90,
                        color: CupertinoColors.systemGreen,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'SwiftSheet #3 (Scrollable)',
                      style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle,
                    ),
                    const SizedBox(height: 16),
                    CupertinoButton.filled(
                      onPressed: () => context.router.push(const HeroSheetFourRoute()),
                      child: const Text('Open Sheet Four'),
                    ),
                  ],
                ),
              );
            }
            return ListTile(
              title: Text('List Item $index'),
              leading: const Icon(CupertinoIcons.circle_fill, size: 8),
            );
          },
        ),
      ),
    );
  }
}
