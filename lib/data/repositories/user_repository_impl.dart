
import 'package:booking/core/services/storage_service.dart';
import 'package:booking/domain/entities/user_entity.dart';
import 'package:booking/domain/repositories/user_repository.dart';
import 'package:booking/data/models/user_model.dart';
import 'package:booking/core/network/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserRepositoryImpl extends UserRepository {
  final FirebaseService firebaseService;
  final StorageService storageServices;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserRepositoryImpl({FirebaseService? firebaseService, required this.storageServices})
      : firebaseService = firebaseService ?? FirebaseService();

  @override
  Future<Map<String, dynamic>> getUser() async {
    try {
      final String userId = _firebaseAuth.currentUser!.uid;
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) {
        throw Exception('User not found');
      }
      
      final userData = doc.data()!;
      userData['id'] = doc.id;
      return userData;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  @override
  Future<void> updateUser(String displayName, ) async {
    try {
      final String userId = _firebaseAuth.currentUser!.uid;

      
      await _firestore.collection('users').doc(userId).update(
        {
          'displayName': displayName,
        }
      );
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  @override
  Future<void> updateProviderProfile({
  required String providerId,
  String? serviceId,
  Map<String, dynamic>? additionalInfo,
}) async {
  try {
    final updateData = <String, dynamic>{};
    print(serviceId);

    if (serviceId != null) {
      print('This is serviceId: $serviceId');
      print('This is providerId: $providerId');
      updateData['service'] = serviceId;
      
    }

    if (additionalInfo != null) {
      updateData.addAll(additionalInfo);
    }

    updateData['updatedAt'] = FieldValue.serverTimestamp();
    updateData['isProvider'] = true;

    await _firestore.collection('users').doc(providerId).update(updateData);
  } catch (e) {
    throw Exception('Failed to update provider profile: $e');
  }
}

  @override
  Future<List<UserEntity>> getServiceProviders() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('userType', whereIn: ['provider', 'admin'])
          .where('isProvider', isEqualTo: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return UserModel.fromJson(data).toEntity();
      }).toList();
    } catch (e) {
      throw Exception('Failed to get service providers: $e');
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;
      
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!doc.exists) return null;
      
      final userData = doc.data()!;
      userData['id'] = doc.id;

      print('User Data in Home Screen: $userData');
      
      return UserModel.fromJson(userData).toEntity();
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<UserEntity?> get currentUserStream {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!doc.exists) return null;
      
      final userData = doc.data()!;
      userData['id'] = doc.id;
      
      return UserModel.fromJson(userData).toEntity();
    });
  }

  @override
  Future<void> updateUserType(String type)async {
    try {
      final String userId = _firebaseAuth.currentUser!.uid;

      
      await _firestore.collection('users').doc(userId).update(
        {
          'userType': type,
          'hasService': true
        }
      );
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }


    /// Real‑time stream of the user's Firestore document
  @override
  Stream<UserEntity> streamUser(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            // Convert to your existing UserModel, then to UserEntity
            final userModel = UserModel.fromFirebaseUsers(snapshot.data()!, snapshot.id);
            return userModel.toEntity();
          } else {
            // Document doesn't exist – you could create a default one here
            throw Exception('User document not found');
          }
        });
  }

}