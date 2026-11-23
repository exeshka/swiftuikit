import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_keyboard_controller/flutter_keyboard_controller.dart';

import 'src/blur/progressive_blur.dart';
import 'src/components/liquid_glass.dart';

export 'src/widgets/swift_step_sheet.dart';
export 'src/widgets/swift_modal_scaffold.dart';
export 'src/widgets/swift_text.dart';
export 'src/widgets/scroll/swift_sheet_scroll_provider.dart';
export 'src/widgets/scroll/scroll_overlap_listener.dart';
export 'src/widgets/scroll/scroll_value_listener.dart';
export 'src/widgets/scroll/snapping_scroll_physics.dart';

export 'src/routing/page_transitions.dart';
export 'src/routing/sheet_route.dart';
export 'src/routing/scroll_sheet_route.dart';
export 'src/routing/modal_route.dart';
export 'src/routing/page_view_animation.dart';
export 'src/routing/zoom_route.dart';
export 'src/routing_adapters/go_router_adapter.dart';
export 'src/routing_adapters/auto_route_adapter.dart';

export 'src/services/screen_radius_service.dart';

// iOS 26 style UI kit: progressive-blur ChromeScaffold, liquid glass, glass controls, themed through SwiftUiThemeData.
// The ThemeMode of SwiftUiApp is a Flutter type, so an app need not import `material.dart` for it.
export 'package:flutter/material.dart' show ThemeMode;
export 'src/app/swift_ui_app.dart';
export 'src/theme/swift_ui_theme.dart';
export 'src/theme/swift_ui_theme_data.dart';
export 'src/theme/swift_ui_colors.dart';
export 'src/theme/swift_ui_typography.dart';
export 'src/theme/swift_ui_metrics.dart';
export 'src/theme/swift_ui_glass_theme.dart';
export 'src/theme/swift_ui_chrome_theme.dart';
export 'src/theme/swift_ui_encoders.dart';
export 'src/blur/progressive_blur.dart';
export 'src/chrome/chrome_controller.dart';
export 'src/chrome/chrome_scaffold.dart';
export 'src/chrome/chrome_style.dart';
export 'src/adaptive/swift_ui_window_info.dart';
export 'src/scaffold/swift_ui_scaffold.dart';
export 'src/scaffold/swift_ui_page_switcher.dart';
export 'src/scaffold/swift_ui_shell.dart';
export 'src/scaffold/swift_ui_drawer.dart';
export 'src/components/ravel_icon.dart';
export 'src/components/glass_selection_toolbar.dart';
export 'src/components/glass_surface.dart';
export 'src/components/pressable.dart';
export 'src/components/buttons.dart';
export 'src/components/glass_button.dart';
export 'src/components/list_row.dart';
export 'src/components/headers.dart';
export 'src/components/glass_toolbar.dart';
export 'src/components/glass_text_field.dart';
export 'src/components/glass_tab_bar.dart';
export 'src/components/glass_switch.dart';
export 'src/components/glass_menu.dart';
export 'src/components/glass_segmented.dart';
export 'src/components/glass_scroll_segments.dart';
export 'src/components/glass_slider.dart';
export 'src/components/glass_search_bar.dart';
export 'src/components/glass_search_launcher.dart';
export 'src/components/grouped_list.dart';
export 'src/components/stretch_header.dart';
export 'src/components/liquid_glass.dart';
export 'src/util/warm_up.dart';
export 'src/util/route_freeze.dart';
export 'src/util/swift_ui_page_route.dart';

/// Loads every shader of the kit and schedules an iOS keyboard warm-up after
/// the first frame. Call once before `runApp`.
Future<void> preloadRavelUiKit() async {
  await Future.wait([ProgressiveBlur.preload(), LiquidGlass.preload()]);
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      unawaited(KeyboardController.preload().catchError((Object _) {}));
    });
  }
}
