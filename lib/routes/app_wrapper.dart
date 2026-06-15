import 'package:booking/presentaion/auth/cubit/auth_cubit.dart';
import 'package:booking/presentaion/auth/cubit/auth_state.dart';
import 'package:booking/presentaion/auth/pages/auth_wrapper.dart';
import 'package:booking/presentaion/screens/home_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        // ----- HANDLE AUTHENTICATED STATES -----
        if (authState is AuthAuthenticated) {
          final user = authState.user;

          return HomeEntry(user: user);
        }

        if (authState is AuthAuthenticatedGoog) {
          return HomeEntry(user: authState.user);
        }

        // ----- UNAUTHENTICATED -----
        if (authState is AuthUnauthenticated) {
          return AuthWrapper();
        }

        // ----- LOADING / INITIAL -----
        return Scaffold(body: Center(child: CircularProgressIndicator(strokeWidth: 2,)));
      },
    );
  }
}
