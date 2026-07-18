import 'package:example_go_router/app.dart';
import 'package:flutter/cupertino.dart';
import 'package:swiftuikit/swiftuikit.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await ScreenRadiusService.instance.initialize();
  debugPrint(
    "Radius before runApp: \${ScreenRadiusService.instance.radiusValue} (\${ScreenRadiusService.instance.radius})",
  );
  runApp(App());
}
