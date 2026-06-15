import 'package:app_links/app_links.dart';
import 'package:booking/routes/app_router.dart';
import 'package:flutter/material.dart';

class DeepLinkHandler {
  static final AppLinks _appLinks = AppLinks();

  static Future<void> initDeepLinks(BuildContext context) async {
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      print('Initial deep link: $initialLink');
      _navigateToRoute(initialLink);
    }

    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        print('Stream deep link: $uri');
        _navigateToRoute(uri);
      }
    });
  }

  static void _navigateToRoute(Uri uri) {
    final router = AppRouter.router;
    
    String path;

    if (uri.scheme == 'https' || uri.scheme == 'http') {
      // Universal link: https://timelygh.com/service/ID
      path = uri.path;
    } else {
      // Custom scheme: timely://service/ID
      // uri.host = 'service', uri.pathSegments = ['ID']
      path = '/${uri.host}${uri.path}';
    }

    print('Navigating to path: $path');

    // Small delay to ensure router is ready (especially on cold start)
    Future.delayed(Duration.zero, () {
      router.go(path);
    });
  }
}