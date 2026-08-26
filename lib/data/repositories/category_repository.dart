// lib/core/repositories/category_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryRepository {

  Future<List<Map<String, dynamic>>> fetchCategories() async {
   
    try {
      final doc = await FirebaseFirestore.instance
          .collection('categories')
          .doc('main')
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final rawList = data['category'] as List? ?? [];

        // Convert each item safely
        final categories = rawList.map((item) {
          if (item is Map) {
            return Map<String, dynamic>.from(item);
          } else {
            throw Exception('Invalid category format: expected Map');
          }
        }).toList();

        return categories;
      }
      return [];
    } catch (e) {
      // If all fails, rethrow
      rethrow;
    }
  }
}