import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
          onPressed: () => context.pop(),
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
                      onPressed: () => context.go('/hero/page-one'),
                      child: const Text('Pop to Page One'),
                    ),
                  ],
                ),
              );
            }
            return ListTile(
              title: Text('List Item \$index'),
              leading: const Icon(CupertinoIcons.circle_fill, size: 8),
            );
          },
        ),
      ),
    );
  }
}
