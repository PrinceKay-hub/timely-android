
import 'package:booking/domain/entities/user_entity.dart';

abstract class UserRepository {
  Future<Map<String, dynamic>> getUser();
  
  Future<void> updateUser(String displayName, );

  Future<void> updateUserType(String type);
  
  Future<void> updateProviderProfile({
    required String providerId,
    String? serviceId,
    Map<String, dynamic>? additionalInfo,
  });

  Future<List<UserEntity>> getServiceProviders();
  
  Future<UserEntity?> getCurrentUser();
  
  Stream<UserEntity?> get currentUserStream;

  Stream<UserEntity> streamUser(String uid);

}