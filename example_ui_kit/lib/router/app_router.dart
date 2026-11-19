import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../screens/chatgpt_screen.dart';
import '../screens/claude_screen.dart';
import '../screens/coffee_screen.dart';
import '../screens/components_screen.dart';
import '../screens/controls_photo_screen.dart';
import '../screens/controls_screen.dart';
import '../screens/controls_white_screen.dart';
import '../screens/drinkit_screen.dart';
import '../screens/edr_test_screen.dart';
import '../screens/home_screen.dart';
import '../screens/inbox_screen.dart';
import '../screens/input_screen.dart';
import '../screens/liquid_center_screen.dart';
import '../screens/liquid_grid_screen.dart';
import '../screens/liquid_interactive_screen.dart';
import '../screens/liquid_morph_screen.dart';
import '../screens/liquid_playground_screen.dart';
import '../screens/liquid_presence_screen.dart';
import '../screens/liquid_screen.dart';
import '../screens/nav_bars_screen.dart';
import '../screens/page_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/sticky_screen.dart';
import '../screens/switcher_screen.dart';
import '../screens/switch_screen.dart';
import '../screens/telegram_screen.dart';

part 'app_router.gr.dart';

/// Every page of the example. `dart run build_runner build` generates `app_router.gr.dart`.
///
/// Two groups (the same ones the home page lists):
///  * apps: pages that imitate a real application and are built only from the kit;
///  * technical: pages that test one component or one effect.
///
/// The paths are what `--dart-define=SCREEN=<path without the slash>` opens directly.
@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: HomeRoute.page, path: '/', initial: true),

    // ---- apps ---------------------------------------------------------------------------------------------------
    AutoRoute(page: TelegramRoute.page, path: '/telegram'),
    AutoRoute(page: ChatGptRoute.page, path: '/chatgpt'),
    AutoRoute(page: ClaudeRoute.page, path: '/claude'),
    AutoRoute(page: CoffeeRoute.page, path: '/coffee'),
    AutoRoute(page: DrinkitRoute.page, path: '/drinkit'),
    AutoRoute(page: ProfileRoute.page, path: '/profile'),

    // ---- technical: headers, lists, inputs ------------------------------------------------------------------------
    AutoRoute(page: StickyRoute.page, path: '/sticky'),
    AutoRoute(page: StickyReplacingRoute.page, path: '/sticky-replace'),
    AutoRoute(page: NavBarsRoute.page, path: '/nav-bars'),
    AutoRoute(page: PageDemoRoute.page, path: '/page'),
    AutoRoute(page: InputRoute.page, path: '/input'),
    AutoRoute(page: SwitchRoute.page, path: '/switch'),
    AutoRoute(page: ControlsRoute.page, path: '/controls'),
    AutoRoute(page: ControlsPhotoRoute.page, path: '/controls-photo'),
    AutoRoute(page: ControlsWhiteRoute.page, path: '/controls-white'),
    AutoRoute(page: ComponentsRoute.page, path: '/components'),
    AutoRoute(page: SwitcherRoute.page, path: '/switcher'),
    AutoRoute(page: InboxRoute.page, path: '/inbox'),

    // ---- technical: liquid glass --------------------------------------------------------------------------------------
    AutoRoute(page: LiquidPlaygroundRoute.page, path: '/liquid-playground'),
    AutoRoute(page: LiquidRoute.page, path: '/liquid'),
    AutoRoute(page: LiquidMorphRoute.page, path: '/liquid-morph'),
    AutoRoute(page: LiquidPresenceRoute.page, path: '/liquid-presence'),
    AutoRoute(page: LiquidInteractiveRoute.page, path: '/liquid-interactive'),
    AutoRoute(page: LiquidGridRoute.page, path: '/liquid-grid'),
    AutoRoute(page: LiquidCenterRoute.page, path: '/liquid-center'),
    AutoRoute(page: EdrTestRoute.page, path: '/edr-test'),
  ];
}
