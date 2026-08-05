import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DeepLinkHandler {
  static final AppLinks _appLinks = AppLinks();

  // Takes the router instance directly now (rather than pulling a static
  // AppRouter.router field) since AppRouter.create() needs AuthCubit to
  // build the router — there's no longer a router that exists before an
  // AuthCubit instance does. No auth-awareness needed here anymore: every
  // route is now gated centrally by AppRouter's own `redirect`, so this
  // can just navigate and trust the router to bounce to /auth when needed.
  static Future<void> initDeepLinks(GoRouter router) async {
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      debugPrint('Initial deep link: $initialLink');
      _navigateToRoute(router, initialLink);
    }

    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        debugPrint('Stream deep link: $uri');
        _navigateToRoute(router, uri);
      }
    });
  }

  static void _navigateToRoute(GoRouter router, Uri uri) {
    String path;

    if (uri.scheme == 'https' || uri.scheme == 'http') {
      // Universal link: https://timelygh.com/service/ID
      path = uri.path;
    } else {
      // Custom scheme: timely://service/ID
      // uri.host = 'service', uri.pathSegments = ['ID']
      path = '/${uri.host}${uri.path}';
    }

    debugPrint('Navigating to path: $path');

    // Small delay to ensure router is ready (especially on cold start)
    Future.delayed(Duration.zero, () {
      router.go(path);
    });
  }
}