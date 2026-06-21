import 'package:auto_route/auto_route.dart';
import 'package:example/src/core/router/router.gr.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

@RoutePage()
class HeaderBracnkDetailScreen extends StatelessWidget {
  final String url;
  const HeaderBracnkDetailScreen({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverList.builder(
            itemCount: 15,
            itemBuilder: (context, index) {
              final imageUrl = "https://picsum.photos/500/500?random=$index";

              return GestureDetector(
                onTap: () {
                  context.router.push(HeaderBracnkDetailRoute(url: imageUrl));
                },

                child: SizedBox(height: 400, child: Image.network(imageUrl)),
              );
            },
          ),
        ],
      ),
    );
  }
}
