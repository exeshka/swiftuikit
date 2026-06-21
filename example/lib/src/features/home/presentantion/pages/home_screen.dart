import 'package:auto_route/auto_route.dart';
import 'package:example/src/core/router/router.gr.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

@RoutePage()
class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final List<Color> mockPage = [Colors.red, Colors.green, Colors.amber, Colors.pink];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: AutoTabsRouter.builder(
        routes: const [HeaderBranchRoute(), HeaderBranch2Route()],
        builder: (context, children, tabsRouter) {
          return SwiftPageViewAnimation.pageView(
            itemCount: children.length,
            onPageChanged: tabsRouter.setActiveIndex,
            itemBuilder: (context, index) {
              return children[index];
            },
          );
        },
      ),
      // body: SwiftPageViewAnimation.pageView(
      //   parallaxIndexes: [0],
      //   itemCount: mockPage.length,
      //   onPageChanged: (value) {},
      //   itemBuilder: (context, index) {
      //     return Container(color: mockPage[index]);
      //   },
      // ),
    );
  }
}
