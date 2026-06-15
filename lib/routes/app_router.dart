
import 'package:booking/presentaion/auth/pages/auth_wrapper.dart';
import 'package:booking/presentaion/booking/booking.dart';
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
import 'package:go_router/go_router.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
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
        ),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => FavoriteScreen(user: state.extra as Map<String, dynamic>),
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
        //builder: (context, state) => DetailScreen(),
        pageBuilder: (context, state) => NoTransitionPage(
          child: DetailScreen(
            data: state.extra as Map<String, dynamic>,
            user: state.extra as Map<String, dynamic>,
          ),
        ),
      ),

      GoRoute(
        path: '/booking',
        builder: (context, state) =>
            BookingScreen(
              data: state.extra as Map<String, dynamic>, 
              user: state.extra as Map<String, dynamic>,),
      ),

    ],
  );
}
