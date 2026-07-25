import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:example/src/core/router/router.gr.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

@RoutePage()
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CupertinoNavigationBar(middle: Text('Profile')),
      body: Center(
        child: IconButton.filled(
          onPressed: () {
            context.router.push(ProfileEditRoute());
          },
          icon: Text('Open edit screen'),
        ),
      ),
    );
  }
}
