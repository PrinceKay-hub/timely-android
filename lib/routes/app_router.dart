import 'package:booking/presentaion/auth/cubit/auth_cubit.dart';
import 'package:booking/presentaion/auth/cubit/auth_state.dart';
import 'package:booking/presentaion/auth/pages/auth_wrapper.dart';
import 'package:booking/presentaion/booking/booking.dart';
import 'package:booking/presentaion/chat/chat_screen.dart';
import 'package:booking/presentaion/common/pages/animated_splash.dart';
import 'package:booking/presentaion/common/pages/onboarding_screen.dart';
import 'package:booking/presentaion/provider/pages/registration_screen.dart';
import 'package:booking/presentaion/screens/appointments/appointments_screen.dart';
import 'package:booking/presentaion/screens/favorite/favorite_screen.dart';
import 'package:booking/presentaion/screens/home/detail_screen.dart';
import 'package:booking/presentaion/screens/home/home_screen.dart';
import 'package:booking/presentaion/screens/home/service_detail.dart';
import 'package:booking/presentaion/screens/home_entry.dart';
import 'package:booking/presentaion/screens/profile/profile_screen.dart';
import 'package:booking/routes/app_wrapper.dart';
import 'package:booking/routes/go_router_refresh_stream.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Routes reachable without being signed in. Everything else redirects
  // to /auth first, then continues on to the originally-requested route
  // once sign-in completes (see AuthWrapper's `from` handling below).
  static const Set<String> _publicPaths = {
    '/',
    '/auth',
    '/onboarding',
  };

  static bool _isAuthed(AuthState state) =>
      state is AuthAuthenticated || state is AuthAuthenticatedGoog;

  // Must be created once — after AuthCubit exists — and reused for the
  // app's lifetime (constructing a new GoRouter on every rebuild would
  // reset navigation state). Takes AuthCubit explicitly, rather than
  // reading it off the redirect callback's own BuildContext, specifically
  // so refreshListenable can subscribe to authCubit.stream: that's what
  // makes the router automatically re-run `redirect` and proceed to the
  // originally-requested page the instant sign-in completes, rather than
  // only re-checking on the next manual navigation.
  static GoRouter create(AuthCubit authCubit) {
    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: '/',
      refreshListenable: GoRouterRefreshStream(authCubit.stream),
      redirect: (context, state) {
        final authed = _isAuthed(authCubit.state);
        final target = state.matchedLocation;
        final isPublic = _publicPaths.contains(target);

        if (!authed && !isPublic) {
          // Preserve the originally-requested location — including query
          // params — so AuthWrapper can send the user straight there
          // after they sign in. This is what makes a shared
          // /service/ID link work: land here unauthenticated, get
          // bounced to /auth?from=%2Fservice%2FID, sign in, arrive
          // exactly where the link pointed instead of some generic home.
          final from = Uri.encodeComponent(state.uri.toString());
          return '/auth?from=$from';
        }

        // Already signed in but sitting on /auth or /onboarding — e.g. a
        // stale deep link opened after the user already logged in
        // elsewhere. Bounce into the app instead of re-showing auth.
        //
        // IMPORTANT: this must honor `from` the same way AuthLogin's own
        // post-login context.go(destination) does. GoRouterRefreshStream
        // and AuthLogin's BlocConsumer are both listening to the same
        // authCubit.stream, and refreshListenable subscribed first (at
        // app startup) — so this redirect can fire before, or racing
        // with, AuthLogin's explicit navigation. If the two disagreed on
        // destination, whichever won the race would silently drop `from`
        // depending on timing. Computing the same destination here means
        // that race is harmless either way.
        if (authed && (target == '/auth' || target == '/onboarding')) {
          final from = state.uri.queryParameters['from'];
          return (from != null && from.isNotEmpty) ? from : '/app';
        }

        return null; // no redirect needed
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => AnimatedSplashScreen(),
        ),
        GoRoute(path: '/home-entry', builder: (context, state) => HomeEntry()),
        GoRoute(
          path: '/service/:id',
          builder: (context, state) {
            final serviceId = state.pathParameters['id']!;
            return ServiceDetail(id: serviceId);
          },
        ),
        GoRoute(
          path: '/app',
          builder: (context, state) {
            return AppWrapper();
          },
        ),
        GoRoute(
          path: '/auth',
          builder: (context, state) {
            final from = state.uri.queryParameters['from'];
            return AuthWrapper(from: from);
          },
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => OnboardingScreen(),
        ),
        GoRoute(
          path: '/home-screen',
          builder: (context, state) =>
              HomeScreen(user: state.extra as Map<String, dynamic>),
        ),
        GoRoute(
          path: '/service-registration',
          builder: (context, state) => ServiceRegistrationScreen(
            userId: state.extra as String,
            isProvider: state.extra as bool,
          ),
        ),
        GoRoute(
          path: '/favorites',
          builder: (context, state) =>
              FavoriteScreen(user: state.extra as Map<String, dynamic>),
        ),
        GoRoute(
          path: '/appointments',
          builder: (context, state) =>
              AppointmentsScreen(user: state.extra as Map<String, dynamic>),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) =>
              ProfileScreen(user: state.extra as Map<String, dynamic>),
        ),
        GoRoute(
          path: '/detail-screen',
          name: '/detail-screen',
          pageBuilder: (context, state) => NoTransitionPage(
            child: DetailScreen(
              data: state.extra as Map<String, dynamic>,
              user: state.extra as Map<String, dynamic>,
            ),
          ),
        ),
        GoRoute(
          path: '/booking',
          builder: (context, state) => BookingScreen(
            data: state.extra as Map<String, dynamic>,
            user: state.extra as Map<String, dynamic>,
          ),
        ),
        GoRoute(
          path: '/chat/:id',
          builder: (context, state) {
            final chatId = state.pathParameters['id']!;
            return ChatScreen(chatId: chatId);
          },
        ),
      ],
    );
  }
}