import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

@RoutePage()
class HeroSheetFiveScreen extends StatelessWidget {
  const HeroSheetFiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CupertinoNavigationBar(
        middle: const Text('Sheet Five (Scroll)'),
        backgroundColor: CupertinoColors.systemPink.withValues(alpha: 0.9),
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
                        size: 110,
                        color: CupertinoColors.systemPink,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'SwiftSheet #5 (Scrollable)',
                      style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle,
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
