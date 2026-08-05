
import 'package:booking/presentaion/auth/cubit/auth_cubit.dart';
import 'package:booking/presentaion/auth/cubit/auth_state.dart';
import 'package:booking/presentaion/auth/pages/auth_wrapper.dart';
import 'package:booking/presentaion/chat/cubit_chat/chat_cubit.dart';
import 'package:booking/presentaion/chat/cubit_presence/presence_cubit.dart';
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

          context.read<PresenceCubit>().startOwnPresence(user.id);
          context.read<ChatCubit>().subscribeToChats(user.id);
          
          return HomeEntry(user: user);
        }

        if (authState is AuthAuthenticatedGoog) {
          final user = authState.user;

          context.read<PresenceCubit>().startOwnPresence(user.id);
          context.read<ChatCubit>().subscribeToChats(user.id);
          return HomeEntry(user: authState.user);
        }

        // ----- UNAUTHENTICATED -----
        if (authState is AuthUnauthenticated) {
          context.read<PresenceCubit>().stopOwnPresence();
          context.read<PresenceCubit>().disposeAll();
          context.read<ChatCubit>().disposeAll();
          
          return AuthWrapper();
        }

        // ----- LOADING / INITIAL -----
        return Scaffold(body: Center(child: CircularProgressIndicator(strokeWidth: 2,)));
      },
    );
  }
}
