import 'package:cloud_firestore/cloud_firestore.dart';

class PortfolioImage {
  final String id;
  final String imageUrl;
  final DateTime createdAt;
  final List? likes;
  final String caption;
  final String serviceName;

  PortfolioImage({
    required this.id,
    required this.imageUrl,
    required this.createdAt,
    this.likes,
    required this.caption,
    required this.serviceName
  });

  factory PortfolioImage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PortfolioImage(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      likes: data['likes'] ?? [],
      caption: data['caption'] ?? '',
      serviceName: data['serviceName'] ?? ''
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'likes': likes,
        'caption': caption,
        'serviceName': serviceName
      };
}