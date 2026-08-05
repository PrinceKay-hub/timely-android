import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:booking/domain/repositories/user_repository.dart';
import 'package:equatable/equatable.dart';

part 'user_state.dart';

class UserCubit extends Cubit<UserState> {
  final UserRepository userRepository;
  StreamSubscription? _subscription;

  UserCubit(this.userRepository) : super(UserInitial());

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


  Future<void> loadUser() async {
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


  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
