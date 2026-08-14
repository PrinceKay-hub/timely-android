import 'package:booking/data/models/timely_hairstyle.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const int kPageSize = 5;

/// Result of a paginated fetch — mirrors the `{ hairstyles, lastDoc, hasMore }`
/// shape returned by fetchHairstyles() in hairstyleService.ts.
class HairstylePage {
  final List<Hairstyle> hairstyles;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;

  const HairstylePage({
    required this.hairstyles,
    required this.lastDoc,
    required this.hasMore,
  });
}

class HairstyleService {
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('timelyHairstyles');

  /// Paginated fetch for the swipe feed — newest first, PAGE_SIZE at a time.
  Future<HairstylePage> fetchHairstyles({
    DocumentSnapshot<Map<String, dynamic>>? lastDoc,
  }) async {
    Query<Map<String, dynamic>> q = _collection
        .orderBy('createdAt', descending: true)
        .limit(kPageSize);

    if (lastDoc != null) {
      q = q.startAfterDocument(lastDoc);
    }

    try {
      final snapshot = await q.get();
      final hairstyles = snapshot.docs.map(Hairstyle.fromFirestore).toList();
      final newLastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      final hasMore = snapshot.docs.length == kPageSize;

      return HairstylePage(
        hairstyles: hairstyles,
        lastDoc: newLastDoc,
        hasMore: hasMore,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching hairstyles: $e');
      rethrow;
    }
  }

  /// Fetches the full catalog client-side, for the Collections view — it
  /// needs every document to group by category and count each collection.
  ///
  /// Note: if the catalog grows into the thousands, the fix isn't to
  /// paginate this call (that breaks "show every collection with an
  /// accurate count") — it's to maintain a small `categories` collection in
  /// Firestore, written whenever your sync script runs, with
  /// { category, count, coverImage } per category. Collections mode would
  /// then read that tiny collection instead of the whole catalog, and only
  /// fetch a category's full style list once it's opened.
  Future<List<Hairstyle>> fetchAllHairstyles() async {
    final snapshot = await _collection.orderBy('category').get();
    return snapshot.docs.map(Hairstyle.fromFirestore).toList();
  }
}