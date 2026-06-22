import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

@RoutePage()
class PostDetailScreen extends StatelessWidget {
  const PostDetailScreen({super.key});

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
              right: Icon(
                Icons.send_rounded,
                color: theme.colorScheme.onSurface,
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
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList.separated(
                itemCount: 20,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        "Post Detail Content ${index + 1}",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
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
