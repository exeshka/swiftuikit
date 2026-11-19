import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftuikit/swiftuikit.dart';

/// iPhone-like surface for tests.
void setPhoneSize(WidgetTester tester) {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(402 * 2, 874 * 2);
  addTearDown(tester.view.reset);
}

Widget testApp(Widget home, {Brightness brightness = Brightness.dark}) {
  return SwiftUiApp(
    debugShowCheckedModeBanner: false,
    warmUp: false,
    themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    home: MediaQuery(
      data: const MediaQueryData(
        size: Size(402, 874),
        devicePixelRatio: 2,
        padding: EdgeInsets.only(top: 59, bottom: 34),
        viewPadding: EdgeInsets.only(top: 59, bottom: 34),
      ),
      child: home,
    ),
  );
}

List<Widget> rows(int n, {double height = 49}) => [
  for (var i = 0; i < n; i++)
    SizedBox(
      key: ValueKey('row$i'),
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('Row number $i'),
        ),
      ),
    ),
];
