import 'dart:async';

import 'package:booking/domain/entities/user_entity.dart';
import 'package:booking/domain/repositories/auth_repository.dart';
import 'package:booking/presentaion/auth/cubit/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;
 
  
  AuthCubit(this.authRepository) : super(AuthInitial());


  Future<void> signInWithEmail(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signInWithEmail(email, password);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signUpWithEmail(String email, String password, String displayName,
      {required UserType userType}) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signUpWithEmail(
        email,
        password,
        displayName,
        userType: userType,
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoadingGoog());
    try {
      final user = await authRepository.signInWithGoogle();
      emit(AuthAuthenticatedGoog(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }



  /*Future<void> signInWithApple() async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signInWithApple();
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }*/

  Future<void> signOut() async {
    try {
      await authRepository.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void checkAuthStatus() {
    final user = authRepository.getCurrentUser();
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthUnauthenticated());
    }
  }
}
