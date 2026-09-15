part of 'shop_cubit.dart';

enum ShopStatus { initial, loading, success, failure }

class ShopState extends Equatable {
  final ShopStatus status;
  final List<Product> products;
  final ProductCategory? category; // null = "all"
  final bool refreshing;
  final bool loadingMore;
  final bool hasMore;

  const ShopState({
    this.status = ShopStatus.initial,
    this.products = const [],
    this.category,
    this.refreshing = false,
    this.loadingMore = false,
    this.hasMore = true,
  });

  bool get isLoading => status == ShopStatus.loading;
  bool get isEmpty => status == ShopStatus.success && products.isEmpty;

  ShopState copyWith({
    ShopStatus? status,
    List<Product>? products,
    ProductCategory? category,
    bool clearCategory = false,
    bool? refreshing,
    bool? loadingMore,
    bool? hasMore,
  }) {
    return ShopState(
      status: status ?? this.status,
      products: products ?? this.products,
      category: clearCategory ? null : (category ?? this.category),
      refreshing: refreshing ?? this.refreshing,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props =>
      [status, products, category, refreshing, loadingMore, hasMore];
}