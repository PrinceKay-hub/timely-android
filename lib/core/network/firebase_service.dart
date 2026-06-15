import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
//import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;
  

  // Auth methods
  Future<UserCredential> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      _googleSignIn.initialize(
        serverClientId: dotenv.env['SERVER_CLIENTID'],
      );

      // First, sign out any existing user to avoid reauth issues
      await _googleSignIn.signOut();

      // Trigger the authentication flow
      final googleUser = await _googleSignIn.authenticate();

      // Check if authentication was successful
      if (googleUser == null) {
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Check if we have the required tokens
      if (googleAuth.idToken == null) {
        return null;
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error signing in with Google: $e');
      }
      return null;
    }
  }

  /*Future<UserCredential> signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    
    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );
    
    return await _auth.signInWithCredential(oauthCredential);
  }*/

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Firestore methods
  Future<void> addUserData(Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(data['id'])
        .set(data, SetOptions(merge: true));
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserData(
    String userId,
  ) async {
    return await _firestore.collection('users').doc(userId).get();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  Future<void> createService(Map<String, dynamic> serviceData) async {
    await _firestore.collection('services').add({
      ...serviceData,
      'providerId': _auth.currentUser!.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> bookAppointment(Map<String, dynamic> appointmentData) async {
    await _firestore.collection('appointments').add({
      ...appointmentData,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  // Appointment methods
  Future<void> updateAppointmentStatus(
    String appointmentId,
    String status,
  ) async {
    await _firestore.collection('appointments').doc(appointmentId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Service provider methods
  Future<QuerySnapshot<Map<String, dynamic>>> getServicesByProvider(
    String providerId,
  ) async {
    return await _firestore
        .collection('services')
        .where('providerId', isEqualTo: providerId)
        .get();
  }

  Future<QuerySnapshot<Object?>> searchServices(
    String query,
    String category,
  ) async {
    Query queryRef = _firestore.collection('services');

    if (query.isNotEmpty) {
      queryRef = queryRef.where('name', isGreaterThanOrEqualTo: query);
    }

    if (category.isNotEmpty) {
      queryRef = queryRef.where('category', isEqualTo: category);
    }

    return await queryRef.get();
  }

  // Notification methods
  Future<void> createNotification(Map<String, dynamic> notificationData) async {
    await _firestore.collection('notifications').add({
      ...notificationData,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
  }
}
