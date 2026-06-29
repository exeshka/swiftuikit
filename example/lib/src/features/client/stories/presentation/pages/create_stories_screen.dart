import 'package:auto_route/auto_route.dart';
import 'package:example/src/core/router/router.gr.dart';
import 'package:flutter/material.dart';

@RoutePage()
class ClientCreateStoriesScreen extends StatelessWidget {
  const ClientCreateStoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            context.router.push(StoriesModalRoute());
          },
          child: Text("StoriesModalRoute"),
        ),
      ),
    );
  }
}
