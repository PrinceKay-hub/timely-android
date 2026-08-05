
import 'package:booking/domain/entities/user_entity.dart';

abstract class UserRepository {
  Future<Map<String, dynamic>> getUser();
  
  Future<void> updateUser(String displayName, );
  Future<void> updateUserContact(String phone, );
  Future<void> updateProviderProfile({
    required String providerId,
  });
  
  Future<UserEntity?> getCurrentUser();
  
  Stream<UserEntity?> get currentUserStream;

  Stream<UserEntity> streamUser(String uid);

}