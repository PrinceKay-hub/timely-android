import 'package:cloud_firestore/cloud_firestore.dart';

class HairstyleOption {
  final String id;
  final String name;
  final String targetHairstyle;
  final String hairColor;
  final String category;
  final String imageUrl;
  final String gender;
  final String type;
  final int order;

  HairstyleOption({
    required this.id,
    required this.name,
    required this.targetHairstyle,
    required this.hairColor,
    required this.category,
    required this.imageUrl,
    required this.gender,
    required this.type,
    required this.order,
  });

  factory HairstyleOption.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HairstyleOption(
      id: doc.id,
      name: data['name'] ?? '',
      targetHairstyle: data['targetHairstyle'] ?? 'long_hair',
      hairColor: data['hairColor'] ?? 'natural',
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      gender: data['gender'] ?? 'female',
      type: data['type'] ?? 'hairstyle',
      order: data['order'] ?? 0,
    );
  }
}