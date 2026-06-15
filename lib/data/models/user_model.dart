
import 'package:booking/domain/entities/user_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.displayName,
    super.photoUrl,
    required super.userType,
    super.createdAt,
    super.isEmailVerified,
    super.providerProfile,
    super.hasService,
    super.service
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'],
      photoUrl: json['photoUrl'],
      userType: UserType.values.firstWhere(
        (e) => e.toString().split('.').last == json['userType'],
        orElse: () => UserType.client,
      ),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isEmailVerified: json['isEmailVerified'] ?? false,
      providerProfile: json['providerProfile'],
      hasService: json['hasService'] ?? false,
      service: json['service'] ?? '',
    );
  }

  factory UserModel.fromFirebaseUser({
    required User firebaseUser,
    required Map<String, dynamic> userData,
  }) {
    return UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? userData['email'] ?? '',
      displayName: firebaseUser.displayName ?? userData['displayName'],
      photoUrl: firebaseUser.photoURL ?? userData['photoUrl'],
      userType: UserType.values.firstWhere(
        (e) => e.toString().split('.').last == userData['userType'],
        orElse: () => UserType.client,
      ),
      createdAt: userData['createdAt'] != null
          ? (userData['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isEmailVerified: firebaseUser.emailVerified,
      providerProfile: userData['providerProfile'],
      hasService: false,
      service: userData['service'] ?? '',
    );
  }

  factory UserModel.fromFirebaseUsers(Map<String, dynamic> userData,
    String id,) {
    return UserModel(
      id: id,
      email: userData['email'] ?? '',
      displayName:  userData['displayName'] ?? '',
      photoUrl:  userData['photoUrl'] ?? '',
      userType: UserType.values.firstWhere(
        (e) => e.toString().split('.').last == userData['userType'],
        orElse: () => UserType.client,
      ),
      createdAt: userData['createdAt'] != null
          ? (userData['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isEmailVerified: userData['isEmailVerified'] ?? false,
      providerProfile: userData['providerProfile'],
      hasService: false,
      service: userData['service'] ?? '',
    );
  }



  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      displayName: entity.displayName,
      photoUrl: entity.photoUrl,
      userType: entity.userType,
      createdAt: entity.createdAt,
      isEmailVerified: entity.isEmailVerified,
      providerProfile: entity.providerProfile,
      hasService: entity.hasService,
      service: entity.service
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'userType': userType.toString().split('.').last,
      'createdAt': createdAt ?? DateTime.now(),
      'isEmailVerified': isEmailVerified,
      'providerProfile': providerProfile,
      'hasService': hasService,
      'service': service
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      userType: userType,
      createdAt: createdAt,
      isEmailVerified: isEmailVerified,
      providerProfile: providerProfile,
      hasService: hasService,
      service: service
    );
  }
  
}