import 'package:booking/domain/entities/user_entity.dart';
import 'package:booking/domain/repositories/auth_repository.dart';
import 'package:booking/data/models/user_model.dart';
import 'package:booking/core/network/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class AuthRepositoryImpl extends AuthRepository {
  final FirebaseService _firebaseService;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
 
  AuthRepositoryImpl({FirebaseService? firebaseService})
    : _firebaseService = firebaseService ?? FirebaseService();

  @override
  Future<UserEntity> signInWithEmail(String email, String password) async {
    try {
      print('Signing in with email: $email');
      final userCredential = await _firebaseService.signInWithEmailPassword(
        email,
        password,
      );

      print('User signed in: ${userCredential.user?.uid}');

      // Get user data from Firestore
      final userDoc = await _firebaseService.getUserData(
        userCredential.user!.uid,
      );

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        return UserModel.fromFirebaseUser(
          firebaseUser: userCredential.user!,
          userData: userData,
        ).toEntity();
      } else {
        // User doesn't exist in Firestore, create a new entry
        final newUser = UserModel(
          id: userCredential.user!.uid,
          email: userCredential.user!.email ?? email,
          displayName: userCredential.user!.displayName,
          photoUrl: userCredential.user!.photoURL,
          userType: UserType.client,
          createdAt: DateTime.now(),
          isEmailVerified: userCredential.user!.emailVerified,
        );

        await _firebaseService.addUserData(newUser.toJson());
        return newUser.toEntity();
      }
    } on FirebaseAuthException catch (e) {
      // Handle the error here
      String errorMessage = _getFriendlyErrorMessage(e);
      throw Exception(errorMessage);
    } catch (e) {
      print('Sign in error: $e');
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  @override
  Future<UserEntity> signUpWithEmail(
    String email,
    String password,
    String displayName, {
    required UserType userType,
  }) async {
    try {
      print('Signing up with email: $email');
      final userCredential = await _firebaseService.signUpWithEmailPassword(
        email,
        password,
      );

      print('User created: ${userCredential.user?.uid}');

      // Create user document in Firestore
      final newUser = UserModel(
        id: userCredential.user!.uid,
        email: email,
        userType: userType,
        createdAt: DateTime.now(),
        isEmailVerified: false,
        displayName: displayName,
        service: '',
      );

      await _firebaseService.addUserData(newUser.toJson());
      print('User data saved to Firestore');

      return newUser.toEntity();
    } on FirebaseAuthException catch (e) {
      // Handle the error here
      String errorMessage = _getFriendlyErrorMessage(e);
      throw Exception(errorMessage);
    } catch (e) {
      print('Sign up error: $e');
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    try {
      print('Starting Google sign in');
      final userCredential = await _firebaseService.signInWithGoogle();

      if (userCredential!.user == null) {
        throw Exception('Google sign in returned null user');
      }

      print('Google sign in successful: ${userCredential.user!.uid}');

      // Check if user exists in Firestore
      final userDoc = await _firebaseService.getUserData(
        userCredential.user!.uid,
      );

      if (!userDoc.exists) {
        // Create new user document
        final newUser = UserModel(
          id: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          displayName: userCredential.user!.displayName,
          photoUrl: userCredential.user!.photoURL,
          userType: UserType.client,
          createdAt: DateTime.now(),
          isEmailVerified: true,
          service: '',
        );


        await _firebaseService.addUserData(newUser.toJson());
        print('New user created from Google sign in');
        return newUser.toEntity();
      } else {
        // User exists, return existing data
        final userData = userDoc.data()!;
        //box.write('current_user', userData);
        return UserModel.fromFirebaseUser(
          firebaseUser: userCredential.user!,
          userData: userData,
        ).toEntity();
      }
    } on PlatformException catch (e) {
      String message = _getGoogleSignInErrorMessage(e);
      throw Exception(message);
    } on FirebaseAuthException catch (e) {
      String message = _getFirebaseAuthErrorMessage(e);
      throw Exception(message);
    } catch (e) {
      print('Google sign in error: $e');
      throw Exception('Google sign in failed: ${e.toString()}');
    }
  }

  /* @override
  Future<UserEntity> signInWithApple() async {
    try {
      print('Starting Apple sign in');
      final userCredential = await _firebaseService.signInWithApple();
      
      if (userCredential.user == null) {
        throw Exception('Apple sign in returned null user');
      }
      
      print('Apple sign in successful: ${userCredential.user!.uid}');
      
      // Check if user exists in Firestore
      final userDoc = await _firebaseService.getUserData(userCredential.user!.uid);
      
      if (!userDoc.exists) {
        // Create new user document
        final newUser = UserModel(
          id: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          displayName: userCredential.user!.displayName,
          userType: UserType.client,
          createdAt: DateTime.now(),
          isEmailVerified: userCredential.user!.emailVerified,
        );
        
        await _firebaseService.addUserData(newUser.toJson());
        print('New user created from Apple sign in');
        return newUser.toEntity();
      } else {
        // User exists, return existing data
        final userData = userDoc.data()!;
        return UserModel.fromFirebaseUser(
          firebaseUser: userCredential.user!,
          userData: userData,
        ).toEntity();
      }
    } catch (e) {
      print('Apple sign in error: $e');
      throw Exception('Apple sign in failed: ${e.toString()}');
    }
  }*/

  @override
  Future<void> signOut() async {
    try {
      await _firebaseService.signOut();
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  @override
  UserEntity? getCurrentUser() {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        print('No current user found');
        return null;
      }

      print('Current user found: ${user.uid}');
      return UserModel(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoUrl: user.photoURL,
        userType: UserType.client, // Default, should fetch from Firestore
        isEmailVerified: user.emailVerified,
      ).toEntity();
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  @override
  Stream<UserEntity?> get userChanges {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) {
        print('Auth state changed: User signed out');
        return null;
      }

      print('Auth state changed: User signed in - ${user.uid}');

      try {
        final userDoc = await _firebaseService.getUserData(user.uid);

        if (!userDoc.exists) {
          print('User document not found in Firestore');
          return UserModel(
            id: user.uid,
            email: user.email ?? '',
            displayName: user.displayName,
            photoUrl: user.photoURL,
            userType: UserType.client,
            isEmailVerified: user.emailVerified,
          ).toEntity();
        }

        final userData = userDoc.data()!;
        return UserModel.fromFirebaseUser(
          firebaseUser: user,
          userData: userData,
        ).toEntity();
      } catch (e) {
        print('Error fetching user data: $e');
        return null;
      }
    });
  }
}

String _getFriendlyErrorMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return 'The email address is badly formatted.';
    case 'user-not-found':
      return 'No user found with this email. Please sign up.';
    case 'wrong-password':
      return 'Incorrect password. Please try again.';
    case 'email-already-in-use':
      return 'This email is already registered. Please log in.';
    case 'weak-password':
      return 'The password is too weak. Please use a stronger password.';
    case 'too-many-requests':
      return 'Too many failed login attempts. Please try again later.';
    case 'network-request-failed':
      return 'Network error. Please check your internet connection.';
    case 'invalid-credential':
      return 'Invalid email or password. Please try again.';
    // Add more cases as needed
    default:
      return 'An unexpected error occurred: ${e.message}';
  }
}

String _getGoogleSignInErrorMessage(dynamic error) {
  if (error is PlatformException) {
    switch (error.code) {
      case 'sign_in_failed':
        // Try to extract underlying error
        if (error.message?.contains('10') == true) {
          return 'App configuration error (SHA1 mismatch). Please contact support.';
        }
        return 'Google Sign-In failed. Please try again.';
      case 'network_error':
        return 'Network error. Check your internet connection.';
      case 'popup_closed_by_user':
        return 'Sign-in cancelled.';
      default:
        return 'Google Sign-In error: ${error.message}';
    }
  } else if (error is Exception) {
    // Handle generic exceptions
    return 'An error occurred during Google Sign-In.';
  }
  return 'Unknown error.';
}

String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'account-exists-with-different-credential':
      return 'An account already exists with the same email using a different sign-in method. Sign in with your email and password, then link your Google account.';
    case 'invalid-credential':
      return 'Invalid Google credentials. Please try again.';
    case 'operation-not-allowed':
      return 'Google Sign-In is not enabled. Please contact support.';
    case 'user-disabled':
      return 'This account has been disabled.';
    case 'network-request-failed':
      return 'Network error. Please check your connection.';
    default:
      return 'Firebase authentication error: ${e.message}';
  }
}
