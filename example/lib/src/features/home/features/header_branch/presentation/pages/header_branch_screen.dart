import 'package:auto_route/auto_route.dart';
import 'package:example/src/core/router/router.gr.dart';
import 'package:flutter/material.dart';

@RoutePage()
class HeaderBranchScreen extends StatelessWidget {
  const HeaderBranchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ElevatedButton(
              onPressed: () {
                context.router.push(HeaderBranch2Route());
              },
              child: Text('gregerger'),
            ),
          ),

          SliverList.builder(
            itemCount: 15,
            itemBuilder: (context, index) {
              final imageUrl = "https://picsum.photos/500/500?random=$index";

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  print('Tapped item $index on main screen');
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
