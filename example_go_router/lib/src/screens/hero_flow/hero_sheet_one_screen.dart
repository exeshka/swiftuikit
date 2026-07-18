import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HeroSheetOneScreen extends StatelessWidget {
  const HeroSheetOneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CupertinoNavigationBar(
        middle: const Text('Sheet One'),
        backgroundColor: CupertinoColors.systemOrange.withValues(alpha: 0.9),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.pop(),
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
                  size: 80,
                  color: CupertinoColors.systemRed,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'SwiftSheet #1',
                style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle,
              ),
              const SizedBox(height: 8),
              Text(
                'Hero continues through sheet transitions',
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              const SizedBox(height: 32),
              CupertinoButton.filled(
                onPressed: () => context.push('/hero/sheet-two'),
                child: const Text('Open Sheet Two'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
