import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HeroSheetFourScreen extends StatelessWidget {
  const HeroSheetFourScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CupertinoNavigationBar(
        middle: const Text('Sheet Four (Scroll)'),
        backgroundColor: CupertinoColors.systemTeal.withValues(alpha: 0.9),
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
                        size: 100,
                        color: CupertinoColors.systemTeal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'SwiftSheet #4 (Scrollable)',
                      style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle,
                    ),
                    const SizedBox(height: 16),
                    CupertinoButton.filled(
                      onPressed: () => context.push('/hero/sheet-five'),
                      child: const Text('Open Sheet Five'),
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
