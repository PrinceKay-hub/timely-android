import 'dart:async';
import 'package:flutter/foundation.dart';

// Bridges a Bloc/Cubit's Stream into something GoRouter's
// `refreshListenable` can subscribe to. Without this, GoRouter only
// re-evaluates `redirect` when navigation happens — so a user sitting on
// `/auth` who successfully signs in wouldn't automatically get bounced
// onward to their originally-requested page; they'd need to trigger some
// other navigation first. This makes that transition immediate.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}