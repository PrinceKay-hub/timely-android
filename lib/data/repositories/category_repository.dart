// lib/core/repositories/category_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CategoryRepository {
  static const String _cacheKey = 'categories';
  final Box _box;


  CategoryRepository(this._box);

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    // 1. Try to get from cache with safe casting
    try {
      final cached = _box.get(_cacheKey);
      if (cached != null && cached is List) {
        // Safely cast each element to Map<String, dynamic>
        return cached.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      // If cache is corrupted, delete it and proceed to fetch fresh data
      await _box.delete(_cacheKey);
    }

    // 2. Fetch from Firestore
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

        // Save to cache
        await _box.put(_cacheKey, categories);
        return categories;
      }
      return [];
    } catch (e) {
      // 3. If Firestore fails, try fallback cache again (in case previous attempt was corrupted)
      final fallback = _box.get(_cacheKey);
      if (fallback != null && fallback is List) {
        return fallback.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      // If all fails, rethrow
      rethrow;
    }
  }
}