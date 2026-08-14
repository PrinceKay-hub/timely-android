import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:booking/data/repositories/user_repository_impl.dart';
import 'package:booking/domain/repositories/user_repository.dart';
import 'package:booking/presentaion/auth/cubit/auth_cubit.dart';
import 'package:booking/presentaion/auth/cubit/auth_state.dart';
import 'package:equatable/equatable.dart';

part 'user_state.dart';

class UserCubit extends Cubit<UserState> {
  final UserRepository userRepository;
  StreamSubscription? _subscription;
  final AuthCubit authCubit;

  UserCubit(UserRepositoryImpl read, {required this.userRepository, required this.authCubit})
      : super(UserInitial()) {
    _subscription = authCubit.stream.listen((authState) {
      if (authState is AuthUnauthenticated) {
        emit(UserInitial()); // clear on logout
      } else if (authState is AuthAuthenticated || authState is AuthAuthenticatedGoog) {
        loadUser(forceRefresh: true); // fetch fresh on login
      }
    });
  }

  /// Start listening to real‑time updates of the user's Firestore document
  void startListening(String uid) {
    emit(UserLoading());
    _subscription = userRepository.streamUser(uid).listen(
      (user) {
        emit(UserLoaded(user as Map<String, dynamic>));
      },
      onError: (error) {
        emit(UserError(error.toString()));
      },
    );
  }


  Future<void> loadUser({bool forceRefresh = false}) async {
  // Already have a loaded user and caller didn't ask for a refresh —
  // skip re-fetching and re-emitting entirely.
  if (!forceRefresh && state is UserLoaded) return;
 
  emit(UserLoading());
  try {
    final userData = await userRepository.getUser();
    emit(UserLoaded(userData));
  } catch (e) {
    emit(UserInitial());
  }
}

  Future<void> updateUser(String displayName,  ) async {
    emit(UserLoading());
    try{
      await userRepository.updateUser(displayName);
      await loadUser();
    } catch (e){
      emit(UserError("Error updating profile: $e"));
    }
  }

  Future<void> updateUserContact(String phone,  ) async {
    emit(UserLoading());
    try{
      await userRepository.updateUserContact(phone);
      await loadUser();
    } catch (e){
      emit(UserError("Error updating profile: $e"));
    }
  }

  void reset() {
  emit(UserInitial());
}


  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
