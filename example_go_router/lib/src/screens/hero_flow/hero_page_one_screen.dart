import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HeroPageOneScreen extends StatelessWidget {
  const HeroPageOneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CupertinoNavigationBar(
        middle: const Text('Page One'),
        backgroundColor: CupertinoColors.systemBlue.withValues(alpha: 0.1),
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
                style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle,
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
                onPressed: () => context.push('/hero/page-two'),
                child: const Text('Open Page Two'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
