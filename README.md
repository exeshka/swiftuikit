<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

TODO: Put a short description of the package here that helps potential users
know whether this package might be useful for them.

## Features

TODO: List what your package can do. Maybe include images, gifs, or videos.

## Getting started

TODO: List prerequisites and provide or point to information on how to
start using the package.

## Usage

Use `SwiftPage` from a `go_router` `pageBuilder` to apply the same iOS-style
page transition used by the package routes:

```dart
GoRoute(
  path: '/post/:id',
  pageBuilder: (context, state) {
    return SwiftPage<void>(
      key: state.pageKey,
      name: state.name,
      child: PostDetailScreen(id: state.pathParameters['id']!),
    );
  },
);
```

Sheets are available through the same Navigator 2.0 page API:

```dart
GoRoute(
  path: '/compose',
  pageBuilder: (context, state) {
    return SwiftSheetPage<void>(
      key: state.pageKey,
      child: ComposeScreen(),
    );
  },
);
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
