import 'package:auto_route/auto_route.dart';
import 'package:example/src/core/router/router.gr.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

@RoutePage()
class HeaderBranch2Screen extends StatelessWidget {
  const HeaderBranch2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverList.builder(
            itemCount: 15,
            itemBuilder: (context, index) {
              final imageUrl =
                  "https://picsum.photos/500/500?random=${index + 100}";

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  print('Tapped item $index on main screen 2');
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
