

import 'package:booking/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> signInWithEmail(String email, String password);
  
  Future<UserEntity> signUpWithEmail(String email, String password, String displayName,
      {required UserType userType});
  
  Future<UserEntity> signInWithGoogle();
  
  //Future<UserEntity> signInWithApple();
  
  Future<void> signOut();
  
  UserEntity? getCurrentUser();
  
  Stream<UserEntity?> get userChanges;
}