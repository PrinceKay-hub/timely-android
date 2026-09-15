import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductCategory {
  hair,
  nails,
  skincare,
  makeup,
  barbering,
  tools,
  fragrance,
  bundles;

  String get id => name;

  static ProductCategory? fromId(String? id) {
    if (id == null) return null;
    for (final c in ProductCategory.values) {
      if (c.id == id) return c;
    }
    return null;
  }
}

enum ProductStatus {
  active,
  offline,
  pending;

  String get id => name;

  static ProductStatus fromId(String id) {
    return ProductStatus.values.firstWhere(
      (s) => s.id == id,
      orElse: () => ProductStatus.pending,
    );
  }
}

class CategoryMeta {
  final ProductCategory id;
  final String label;
  final String icon; // MaterialCommunityIcons-style name, map to your icon set

  const CategoryMeta({required this.id, required this.label, required this.icon});
}

const List<CategoryMeta> kCategories = [
  CategoryMeta(id: ProductCategory.hair, label: 'Hair', icon: 'hair-dryer'),
  CategoryMeta(id: ProductCategory.nails, label: 'Nails', icon: 'hand-back-right'),
  CategoryMeta(id: ProductCategory.skincare, label: 'Skincare', icon: 'spa'),
  CategoryMeta(id: ProductCategory.makeup, label: 'Makeup', icon: 'palette'),
  CategoryMeta(id: ProductCategory.barbering, label: 'Barbering', icon: 'content-cut'),
  CategoryMeta(id: ProductCategory.tools, label: 'Tools', icon: 'toolbox'),
  CategoryMeta(id: ProductCategory.fragrance, label: 'Fragrance', icon: 'flower'),
  CategoryMeta(id: ProductCategory.bundles, label: 'Bundles', icon: 'gift'),
];

String categoryLabel(ProductCategory category) {
  return kCategories
      .firstWhere((c) => c.id == category, orElse: () => kCategories.first)
      .label;
}

class ProductLocation {
  final String region;
  final String district;
  final String? landmark;

  const ProductLocation({
    required this.region,
    required this.district,
    this.landmark,
  });

  factory ProductLocation.fromMap(Map<String, dynamic> map) {
    return ProductLocation(
      region: map['region'] as String? ?? '',
      district: map['district'] as String? ?? '',
      landmark: map['landmark'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'region': region,
        'district': district,
        'landmark': landmark,
      };
}

class Product {
  final String productId;
  final String sellerId;
  final String sellerName;
  final String sellerType; // "provider" | "client"
  final String name;
  final String description;
  final double price;
  final String currency;
  final ProductCategory category;
  final List<String> tags;
  final List<String> images;
  final String thumbnailUrl;
  final ProductStatus status;
  final String contact;
  final bool isDelivery;
  final ProductLocation? location;
  final int viewCount;
  final int createdAt; // millis since epoch
  final int updatedAt; // millis since epoch

  const Product({
    required this.productId,
    required this.sellerId,
    required this.sellerName,
    required this.sellerType,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.category,
    required this.tags,
    required this.images,
    required this.thumbnailUrl,
    required this.status,
    required this.contact,
    required this.isDelivery,
    required this.location,
    required this.viewCount,
    required this.createdAt,
    required this.updatedAt,
  });

  static int _toMillis(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    return 0;
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    final locMap = map['location'] as Map<String, dynamic>?;
    return Product(
      productId: map['productId'] as String? ?? '',
      sellerId: map['sellerId'] as String? ?? '',
      sellerName: map['sellerName'] as String? ?? '',
      sellerType: map['sellerType'] as String? ?? 'client',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      currency: map['currency'] as String? ?? 'GHS',
      category: ProductCategory.fromId(map['category'] as String?) ??
          ProductCategory.hair,
      tags: (map['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      images: (map['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
      status: ProductStatus.fromId(map['status'] as String? ?? 'pending'),
      contact: map['contact'] as String? ?? '',
      isDelivery: map['isDelivery'] as bool? ?? false,
      location: locMap != null ? ProductLocation.fromMap(locMap) : null,
      viewCount: (map['viewCount'] as num?)?.toInt() ?? 0,
      createdAt: _toMillis(map['createdAt']),
      updatedAt: _toMillis(map['updatedAt']),
    );
  }

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Product.fromMap(doc.data() ?? {});
  }
}