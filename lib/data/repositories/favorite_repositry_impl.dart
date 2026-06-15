import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteRepositryImpl {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helper to get the current user's favorites subcollection reference
  CollectionReference _getFavoritesRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('favorites');
  }

  // Toggle favorite: add if not exists, remove if exists
  Future<void> toggleFavorite(String itemId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final favoritesRef = _getFavoritesRef(user.uid);
    final docRef = favoritesRef.doc(itemId);

    final docSnapshot = await docRef.get();
    if (docSnapshot.exists) {
      await docRef.delete();
    } else {
      await docRef.set({
        'itemId': itemId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }
  

  // Stream for real‑time favorite status of a single item
  Stream<bool> favoriteStatusStream(String itemId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);
    
    final docRef = _getFavoritesRef(user.uid).doc(itemId);
    return docRef.snapshots().map((doc) => doc.exists);
  }

  // Fetch all favorite item IDs once (useful for list views)
  Future<Set<String>> getFavoriteIds() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    final snapshot = await _getFavoritesRef(user.uid).get();
    return snapshot.docs.map((doc) => doc.id).toSet();
  }

  // Stream of all favorite documents (for a "My Favorites" screen)
  Stream<QuerySnapshot> getUserFavorites() {
    final user = _auth.currentUser;
    if (user == null) return Stream.empty();

    return _getFavoritesRef(user.uid).orderBy('timestamp', descending: true).snapshots();
  }
}