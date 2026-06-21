import 'package:example/app.dart';
import 'package:flutter/cupertino.dart';
import 'package:swiftuikit/swiftuikit.dart';

void main(List<String> args) async {
  // Ensure the framework bindings are initialized so platform channels can be accessed.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the screen radius service.
  await ScreenRadiusService.instance.initialize();

  // Log the radius obtained before runApp.
  debugPrint(
    "Radius before runApp: ${ScreenRadiusService.instance.radiusValue} (${ScreenRadiusService.instance.radius})",
  );

  runApp(App());
}
