import 'dart:async';
import 'dart:io';

import 'package:booking/data/models/portfolio_model.dart';
import 'package:booking/presentaion/provider/pages/portfolio/bloc/portfolio_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PortfolioCubit extends Cubit<PortfolioState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  StreamSubscription<QuerySnapshot>? _portfolioSubscription;
  
  PortfolioCubit() : super(PortfolioLoading());

  // Helper to get portfolio collection reference
  CollectionReference _getPortfolioRef(String serviceId) {
    return _firestore
        .collection('services')
        .doc(serviceId)
        .collection('portfolio');
  }

  void loadPortfolio(String serviceId) {
    // Cancel previous subscription if any
    _portfolioSubscription?.cancel();

    emit(PortfolioLoading());

    // Listen to the query with orderBy
    final query = _getPortfolioRef(serviceId)
        .orderBy('createdAt', descending: true)
        .snapshots();

    _portfolioSubscription = query.listen(
      (snapshot) {
        final images = snapshot.docs
            .map((doc) => PortfolioImage.fromFirestore(doc))
            .toList();
        emit(PortfolioLoaded(images));
      },
      onError: (error) {
        emit(PortfolioError('Failed to load portfolio: $error'));
      },
    );
  }

  Future<void> addPortfolioImage(File imageFile, String serviceId, String serviceName, {String? caption}) async {
    final currentState = state;
    if (currentState is! PortfolioLoaded) return;

    // Optimistic update (optional – but we'll show loading)
    emit(PortfolioLoading());
    try {
      final userId = _auth.currentUser!.uid;
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef = _storage.ref().child('providers/$userId/portfolio/$fileName.jpg');

      // Upload
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();


      // Save to Firestore
     final _portfolioRef =  _firestore.collection('services').doc(serviceId).collection('portfolio').doc();
      final newDoc = _portfolioRef;
      await newDoc.set({
        'id': _portfolioRef.id,
        'imageUrl': downloadUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'caption': caption ?? '',
        'likes': [],
        'serviceName': serviceName
      });

    } catch (e) {
      emit(PortfolioError('Failed to add image: $e'));
    }
  }

  Future<void> deletePortfolioImage(String imageId, String imageUrl, serviceId) async {
    final currentState = state;
    if (currentState is! PortfolioLoaded) return;

    emit(PortfolioLoading());
    try {
      // Delete from Storage
      final storageRef = _storage.refFromURL(imageUrl);
      await storageRef.delete();

      // Delete Firestore document
      await _firestore.collection('services').doc(serviceId).collection('portfolio').doc(imageId).delete();

    } catch (e) {
      emit(PortfolioError('Failed to delete image: $e'));
    }
  }

// Inside your PortfolioCubit (or similar class)
Future<void> toggleLike(String serviceId, String imageId) async {
  final currentState = state;
  if (currentState is! PortfolioLoaded) return;

  final userId = _auth.currentUser?.uid;
  if (userId == null) return; // No user logged in

  final docRef = _firestore
      .collection('services')
      .doc(serviceId)
      .collection('portfolio')
      .doc(imageId);

  try {
    // --- Optimistic UI update ---
    final updatedImages = currentState.images.map((image) {
      if (image.id == imageId) {
        final currentLikes = image.likes ?? [];
        final bool isLiked = currentLikes.contains(userId);
        final List newLikes = isLiked
            ? currentLikes.where((id) => id != userId).toList()
            : [...currentLikes, userId];
        return PortfolioImage(
          id: image.id,
          imageUrl: image.imageUrl,
          createdAt: image.createdAt,
          likes: newLikes,
          caption: image.caption,
          serviceName: image.serviceName,
        );
      }
      return image;
    }).toList();

    emit(PortfolioLoaded(updatedImages));

    // --- Firestore transaction to ensure consistency ---
    await _firestore.runTransaction((transaction) async {
      final docSnapshot = await transaction.get(docRef);
      if (!docSnapshot.exists) return;

      final currentLikes = (docSnapshot.data()?['likes'] as List?) ?? [];
      final bool isLiked = currentLikes.contains(userId);

      if (isLiked) {
        transaction.update(docRef, {
          'likes': FieldValue.arrayRemove([userId]),
        });
      } else {
        transaction.update(docRef, {
          'likes': FieldValue.arrayUnion([userId]),
        });
      }
    });
  } catch (e) {
    emit(PortfolioError('Failed to toggle like: $e'));
  }
}


@override
  Future<void> close() {
    _portfolioSubscription?.cancel();
    return super.close();
  }

   // Update caption (optional)
 /* Future<void> updateCaption(int index, String newCaption) async {
    final currentState = state;
    if (currentState is! PortfolioLoaded) return;
    if (index >= currentState.images.length) return;

    emit(PortfolioLoading());
    try {
      final image = currentState.images[index];
      final updatedImage = PortfolioImage(
         id: '', 
        caption: newCaption,
        createdAt: image.createdAt, 
        imageUrl: image.imageUrl,
      );

      // Get current portfolio list
      /*final doc = await _firestore.collection('services').doc(serviceId).collection('portfolio').get();
      final List<dynamic> currentPortfolio = doc.data()?['portfolio'] ?? [];
      final newPortfolio = currentPortfolio.map((item) {
        if (item['url'] == image.imageUrl) {
          return updatedImage.toMap();
        }
        return item;
      }).toList();

      await _providerRef.update({'portfolio': newPortfolio});
      await loadPortfolio();*/
    } catch (e) {
      emit(PortfolioError('Failed to update caption: $e'));
      //await loadPortfolio();
    }
  }*/
}