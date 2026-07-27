import 'package:cloud_firestore/cloud_firestore.dart';

class TryOnRecord {
  final String id;
  final String imageUrl;
  final String styleName;
  final String category;
  final Timestamp? savedAt;

  TryOnRecord({
    required this.id,
    required this.imageUrl,
    required this.styleName,
    required this.category,
    this.savedAt,
  });

  factory TryOnRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TryOnRecord(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      styleName: data['styleName'] ?? '',
      category: data['category'] ?? '',
      savedAt: data['savedAt'] as Timestamp?,
    );
  }
}