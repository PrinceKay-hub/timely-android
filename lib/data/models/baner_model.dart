class BannerModel {
  final String key;
  final String imageUrl;
  final bool isActive;
  final int order;

  const BannerModel({
    required this.key,
    required this.imageUrl,
    required this.isActive,
    required this.order,
  });

  factory BannerModel.fromFirestore(Map<String, dynamic> data) {
    return BannerModel(
      key: data['key'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? false,
      order: data['order'] as int? ?? 0,
    );
  }
}