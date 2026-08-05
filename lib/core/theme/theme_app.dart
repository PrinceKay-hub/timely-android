import 'package:booking/core/services/deep_link_handler.dart';
import 'package:booking/core/theme/theme.dart' show AppThemes;
import 'package:booking/presentaion/auth/cubit/auth_cubit.dart';
import 'package:booking/presentaion/theme/cubit/theme_cubit.dart';
import 'package:booking/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ThemeApp extends StatefulWidget {
  const ThemeApp({super.key});

  @override
  State<ThemeApp> createState() => _ThemeAppState();
}

class _ThemeAppState extends State<ThemeApp> {
  // Built once, in initState, and reused for the widget's lifetime.
  // Rebuilding a GoRouter on every build() would reset navigation state
  // (current location, back stack) — it has to be stable.
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // context.read (not watch) — we only need AuthCubit once, to hand its
    // stream to the router's refreshListenable. AuthCubit must already be
    // provided above ThemeApp (e.g. in main.dart's MultiBlocProvider) for
    // this to find it.
    _router = AppRouter.create(context.read<AuthCubit>());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkHandler.initDeepLinks(_router);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        return MaterialApp.router(
          title: 'Timely',
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: _getThemeMode(state.themeMode),
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            return AnimatedTheme(
              data: Theme.of(context),
              child: child!,
            );
          },
        );
      },
    );
  }

  ThemeMode _getThemeMode(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return ThemeMode.light;
      case AppTheme.dark:
        return ThemeMode.dark;
      case AppTheme.system:
        return ThemeMode.system;
    }
  }
}