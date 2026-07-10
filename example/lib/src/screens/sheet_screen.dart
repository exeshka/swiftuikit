import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class SheetScreen extends StatelessWidget {
  const SheetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sheet')),
      body: CustomScrollView(
        slivers: [
          SliverList.builder(
            itemBuilder: (context, index) =>
                Container(height: 100, color: Colors.red),
            itemCount: 30,
          ),
        ],
      ),
    );
  }
}
