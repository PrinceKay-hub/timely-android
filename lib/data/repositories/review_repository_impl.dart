import 'package:booking/data/models/review_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewRepositoryImpl {
  Future<void> submitReview({
    required String providerId,
    required String userId,
    required String userName,
    required double rating,
    required String comment,
    required String serviceId,
  }) async {
    final review = Review(
      id: '', // Firestore will auto-generate
      providerId: providerId,
      userId: userId,
      userName: userName,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );

    // Add to Firestore
    await FirebaseFirestore.instance.collection('reviews').add(review.toMap());

    // Optionally update provider's average rating (see below)
    await _updateProviderRating(providerId, serviceId);
  }

  Future<void> _updateProviderRating(String providerId, String serviceId) async {
    final reviewsSnapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .where('providerId', isEqualTo: providerId)
        .get();

    if (reviewsSnapshot.docs.isEmpty) return;

    double total = 0;
    for (var doc in reviewsSnapshot.docs) {
      total += doc['rating'];
    }
    double average = total / reviewsSnapshot.docs.length;

    await FirebaseFirestore.instance
        .collection('services') // adjust your providers collection name
        .doc(serviceId)
        .update({
          'rating': average,
          'totalReviews': reviewsSnapshot.docs.length,
        });
  }


  Future<List> getReviews(String providerId) async {
    List<Map<dynamic, dynamic>> bookingList = [];
    List item = [];
    try {
      await FirebaseFirestore.instance
          .collection('reviews')
          .where('providerId', isEqualTo: providerId)
          .orderBy('createdAt', descending: true)
          .get()
          .then(
        (value) {
          bookingList = value.docs
              .map((e) => e.data(), ).toList();
          //postList = value.docs.toList();
          if (bookingList.isNotEmpty) {
            for (var l in bookingList) {
              item.add(l);
              //print(l);
            }
          }
        });
      return item;
    } catch (e) {
      throw Exception('Failed to get reviews: $e');
    }
  }
}
