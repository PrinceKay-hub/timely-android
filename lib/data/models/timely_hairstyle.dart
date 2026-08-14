import 'package:cloud_firestore/cloud_firestore.dart';

class HairstyleImageSet {
  final String thumb;
  final String card;
  final String full;

  const HairstyleImageSet({
    required this.thumb,
    required this.card,
    required this.full,
  });

  factory HairstyleImageSet.fromMap(Map<String, dynamic> map) {
    return HairstyleImageSet(
      thumb: map['thumb'] as String? ?? '',
      card: map['card'] as String? ?? '',
      full: map['full'] as String? ?? '',
    );
  }
}

class Hairstyle {
  final String id;
  final String name;
  final String category;
  final String? styleId;
  final HairstyleImageSet images;
  final DateTime? createdAt;

  const Hairstyle({
    required this.id,
    required this.name,
    required this.category,
    required this.images,
    this.styleId,
    this.createdAt,
  });

  factory Hairstyle.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final imagesRaw = data['images'] as Map<String, dynamic>? ?? const {};
    final createdAtRaw = data['createdAt'];

    return Hairstyle(
      id: doc.id,
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? 'uncategorized',
      styleId: data['styleId'] as String?,
      images: HairstyleImageSet.fromMap(imagesRaw),
      createdAt: createdAtRaw is Timestamp ? createdAtRaw.toDate() : null,
    );
  }
}

/// A category grouping, built client-side from a flat [Hairstyle] list —
/// equivalent to the `groupByCategory` helper in CollectionsExplorer.tsx.
class HairstyleCollection {
  final String category;
  final String displayName;
  final String coverImage;
  final int count;
  final List<Hairstyle> styles;

  const HairstyleCollection({
    required this.category,
    required this.displayName,
    required this.coverImage,
    required this.count,
    required this.styles,
  });
}