import 'package:auto_route/auto_route.dart';
import 'package:example/src/core/router/router.gr.dart';
import 'package:flutter/material.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:swiftuikit/swiftuikit.dart';

@RoutePage()
class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwiftScaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Классический аппбар"),
        backgroundColor: Colors.transparent,
      ),
      body: Builder(
        builder: (context) {
          final chromeController = SwiftPinnedHeaderChromeScope.maybeOf(
            context,
          );
          if (chromeController == null) {
            return CustomScrollView(
              slivers: _buildSlivers(context, theme, null),
            );
          }
          return CustomScrollView(
            slivers: _buildSlivers(context, theme, chromeController),
          );
        },
      ),
    );
  }

  List<Widget> _buildSlivers(
    BuildContext context,
    ThemeData theme,
    SwiftPinnedHeaderChromeController? chromeController,
  ) {
    return [
      SwiftHeader(
        pinned: true,
        floating: false,
        right: IconButton(
          onPressed: () {
            context.router.push(const RouteLabRoute());
          },
          icon: Icon(Icons.route_rounded, color: theme.colorScheme.onSurface),
        ),
        middle: Text(
          "Instagram",
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: -1.0,
          ),
        ),
      ),
      ...List.generate(50, (index) {
        return MultiSliver(
          pushPinnedChildren: true,
          children: [
            if (chromeController != null)
              SwiftPinnedHeaderChromeSliver(
                height: 44,
                chromeController: chromeController,
                child: Container(
                  height: 44,
                  color: Colors.grey[900],
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "СЕКЦИЯ $index",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            else
              SliverPinnedHeader(
                child: Container(
                  height: 44,
                  color: Colors.grey[900],
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "СЕКЦИЯ $index",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            SliverList.builder(
              itemCount: 15,
              itemBuilder: (context, index) {
                return Container(
                  height: 100,
                  decoration: BoxDecoration(color: Colors.black),
                );
              },
            ),
          ],
        );
      }),
    ];
  }
}
