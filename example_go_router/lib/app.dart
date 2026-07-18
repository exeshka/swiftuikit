import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swiftuikit/swiftuikit.dart';

import 'src/screens/splash_screen.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/detail_screen.dart';
import 'src/screens/detail_no_swipe_screen.dart';
import 'src/screens/sheet_screen.dart';
import 'src/screens/hero_flow/hero_page_one_screen.dart';
import 'src/screens/hero_flow/hero_page_two_screen.dart';
import 'src/screens/hero_flow/hero_sheet_one_screen.dart';
import 'src/screens/hero_flow/hero_sheet_two_screen.dart';
import 'src/screens/hero_flow/hero_sheet_three_screen.dart';
import 'src/screens/hero_flow/hero_sheet_four_screen.dart';
import 'src/screens/hero_flow/hero_sheet_five_screen.dart';

class App extends StatelessWidget {
  App({super.key});

  final _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) =>
            SwiftPage(child: const SplashScreen()),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) =>
            SwiftPage(child: const HomeScreen()),
      ),
      GoRoute(
        path: '/detail',
        pageBuilder: (context, state) =>
            SwiftPage(child: const DetailScreen()),
      ),
      GoRoute(
        path: '/detail-no-swipe',
        pageBuilder: (context, state) => SwiftPage(
          canSwipe: false,
          canOnlySwipeFromEdge: true,
          child: const DetailNoSwipeScreen(),
        ),
      ),
      GoRoute(
        path: '/sheet',
        pageBuilder: (context, state) =>
            SwiftSheetPage(child: const SheetScreen()),
      ),
      GoRoute(
        path: '/sheet-no-bg',
        pageBuilder: (context, state) => SwiftSheetPage(
          animateBackground: false,
          child: const SheetNoBgScreen(),
        ),
      ),
      GoRoute(
        path: '/sheet-no-swipe',
        pageBuilder: (context, state) => SwiftSheetPage(
          enableDrag: false,
          child: const SheetNoSwipeScreen(),
        ),
      ),
      GoRoute(
        path: '/sheet-custom-radius',
        pageBuilder: (context, state) => SwiftSheetPage(
          sheetRadius: 16,
          child: const SheetCustomRadiusScreen(),
        ),
      ),
      GoRoute(
        path: '/hero/page-one',
        pageBuilder: (context, state) =>
            SwiftPage(child: const HeroPageOneScreen()),
      ),
      GoRoute(
        path: '/hero/page-two',
        pageBuilder: (context, state) =>
            SwiftPage(child: const HeroPageTwoScreen()),
      ),
      GoRoute(
        path: '/hero/sheet-one',
        pageBuilder: (context, state) =>
            SwiftSheetPage(child: const HeroSheetOneScreen()),
      ),
      GoRoute(
        path: '/hero/sheet-two',
        pageBuilder: (context, state) =>
            SwiftSheetPage(child: const HeroSheetTwoScreen()),
      ),
      GoRoute(
        path: '/hero/sheet-three',
        pageBuilder: (context, state) =>
            SwiftSheetPage(child: const HeroSheetThreeScreen()),
      ),
      GoRoute(
        path: '/hero/sheet-four',
        pageBuilder: (context, state) =>
            SwiftSheetPage(child: const HeroSheetFourScreen()),
      ),
      GoRoute(
        path: '/hero/sheet-five',
        pageBuilder: (context, state) =>
            SwiftSheetPage(child: const HeroSheetFiveScreen()),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
    );
  }
}
