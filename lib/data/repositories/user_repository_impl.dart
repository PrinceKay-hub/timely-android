
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
  Future<void> updateUserContact(String phone, ) async {
    try {
      final String userId = _firebaseAuth.currentUser!.uid;

      
      await _firestore.collection('users').doc(userId).set(
        {
          'phone': phone,
        }, SetOptions(merge: true)
      );
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  @override
  Future<void> updateProviderProfile({
  required String providerId,
}) async {
  try {
    final updateData = <String, dynamic>{};

    updateData['updatedAt'] = FieldValue.serverTimestamp();
    updateData['isProvider'] = true;
    updateData['userType'] = 'provider';

    await _firestore.collection('users').doc(providerId).update(updateData);
  } catch (e) {
    throw Exception('Failed to update provider profile: $e');
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