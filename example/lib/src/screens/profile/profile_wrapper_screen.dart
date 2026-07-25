import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

@RoutePage()
class ProfileWrapperScreen extends StatelessWidget {
  const ProfileWrapperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SwiftSheetScrollBinding(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: AutoRouter(),
      ),
    );
  }
}
