import 'package:auto_route/auto_route.dart';
import 'package:example/src/core/router/router.gr.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

@RoutePage()
class HeroPageTwoScreen extends StatelessWidget {
  const HeroPageTwoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CupertinoNavigationBar(
        automaticBackgroundVisibility: true,
        middle: const Text('Page Two'),
        previousPageTitle: 'Page One',
        backgroundColor: Colors.red,
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
                  size: 96,
                  color: CupertinoColors.systemOrange,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'SwiftPage #2',
                style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle,
              ),
              const SizedBox(height: 8),
              Text(
                'Hero icon grew and changed color',
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              const SizedBox(height: 32),
              CupertinoButton.filled(
                onPressed: () => context.router.push(const HeroSheetOneRoute()),
                child: const Text('Open Sheet One'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
