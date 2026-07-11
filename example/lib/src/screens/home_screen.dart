import 'package:auto_route/auto_route.dart';
import 'package:example/src/screens/detail_screen.dart';
import 'package:example/src/screens/modal_screen.dart';
import 'package:flutter/material.dart' hide ModalRoute;

import 'package:example/src/core/router/router.gr.dart';
import 'package:swiftuikit/swiftuikit.dart';

@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      appBar: AppBar(title: const Text('Home')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: () {
              context.router.push(DetailRoute(heroId: 'card-1'));
            },
            child: Hero(
              tag: 'card-1',
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Tap me — Hero card',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              // context.router.push(DetailRoute(heroId: 'card-2'));

              Navigator.of(context).push(
                SwiftSheetRoute(
                  showDragHandle: true,
                  // topGap: 0.08,
                  enableDrag: true,
                  sheetRadius: 38,
                  scrollableBuilder: (context, scrollController) =>
                      PrimaryScrollController(
                        controller: scrollController,
                        child: DetailScreen(heroId: ""),
                      ),
                ),
              );
            },
            child: Hero(
              tag: 'card-2',
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Tap me — Hero card',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            tileColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text(
              'Open Sheet',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () => context.router.push(const SheetRoute()),
          ),
          const SizedBox(height: 8),
          ListTile(
            tileColor: Colors.orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text(
              'Open Modal',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () => context.router.push(const ModalRoute()),
          ),

          ListTile(
            tileColor: Colors.orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text(
              'Open Modal',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.of(context).push(
                SwiftScrollSheetRoute(
                  detents: [.fraction(0.3), .medium, .large],
                  // topGap: 0.08,
                  settings: RouteSettings(),

                  child: ModalScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
