import 'package:equatable/equatable.dart';

enum UserType { client, provider, admin }

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final UserType userType;
  final DateTime? createdAt;
  final bool isEmailVerified;
  final Map<String, dynamic>? providerProfile;
  final bool hasService;
  final String? service;

  const UserEntity({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.userType,
    this.createdAt,
    this.isEmailVerified = false,
    this.providerProfile,
    this.hasService = false,
    this.service,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        photoUrl,
        userType,
        createdAt,
        isEmailVerified,
        providerProfile,
        hasService,
        service
      ];
}