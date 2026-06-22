import 'package:auto_route/auto_route.dart';
import 'package:example/src/core/router/router.gr.dart';
import 'package:flutter/material.dart';

@RoutePage()
class HeaderBracnkDetailScreen extends StatelessWidget {
  final String url;
  const HeaderBracnkDetailScreen({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: ClampingScrollPhysics(),
        slivers: [
          SliverList.builder(
            itemCount: 15,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  context.router.push(HeaderBracnkDetailRoute(url: ""));
                },

                child: Container(
                  color: Colors.primaries[index & 1],

                  height: 400,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
