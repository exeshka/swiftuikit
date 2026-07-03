import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, @PathParam('heroId') required this.heroId});

  final String heroId;

  Color get _color => heroId == 'card-1' ? Colors.blue : Colors.deepPurple;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => context.router.pop(),
        child: Hero(
          tag: heroId,
          child: Container(
            color: _color,
            alignment: Alignment.center,
            child: const Text(
              'Tap to go back',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
        ),
      ),
    );
  }
}
