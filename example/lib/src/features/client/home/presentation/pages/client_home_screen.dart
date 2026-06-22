import 'package:auto_route/auto_route.dart';
import 'package:example/src/core/router/router.gr.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

@RoutePage()
class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black, // Dark sleek look
      body: SwiftPinnedHeaderChrome(
        child: CustomScrollView(
          slivers: [
            // First header - pins at the top
            SwiftHeader(
              pinned: true,

              floating: false,
              right: Icon(
                Icons.send_rounded,
                color: theme.colorScheme.onSurface,
              ),
              middle: Text(
                "Post",
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1.0,
                ),
              ),
            ),

            SliverList.separated(
              itemCount: 20,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    context.router.push(PostDetailRoute());
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple,
                            child: Text(
                              "${index + 1}",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            "User ${index + 1}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: const Text(
                            "St. Petersburg, Russia",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        AspectRatio(
                          aspectRatio: 1.0,
                          child: Image.network(
                            "https://loremflickr.com/600/600?lock=$index",
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[850],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            "Enjoying the beautiful progressive blur effect under the pinned headers! #iOS26 #Flutter #Design",
                            style: TextStyle(color: Colors.grey[300]),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SwiftProgressiveBlurSliver(
              fadeLength: 60.0,
              maxBlurSigma: 24.0,
            ),
          ],
        ),
      ),
    );
  }
}
