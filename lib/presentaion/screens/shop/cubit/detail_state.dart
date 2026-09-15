


import 'package:booking/data/models/product_model.dart';
import 'package:equatable/equatable.dart';

class ProductDetailState extends Equatable {
  final Product? product;
  final bool loading;
  final int activeImage;
  final List<Product> relatedProducts;
  final bool relatedLoading;
  final bool isOpeningChat;
  final bool galleryVisible;
  final int galleryIndex;

  const ProductDetailState({
    this.product,
    this.loading = true,
    this.activeImage = 0,
    this.relatedProducts = const [],
    this.relatedLoading = false,
    this.isOpeningChat = false,
    this.galleryVisible = false,
    this.galleryIndex = 0,
  });

  bool get isOwnListing => false; // resolved against auth in the cubit
  bool get isSoldOut => product?.status == ProductStatus.offline;

  ProductDetailState copyWith({
    Product? product,
    bool? loading,
    int? activeImage,
    List<Product>? relatedProducts,
    bool? relatedLoading,
    bool? isOpeningChat,
    bool? galleryVisible,
    int? galleryIndex,
  }) {
    return ProductDetailState(
      product: product ?? this.product,
      loading: loading ?? this.loading,
      activeImage: activeImage ?? this.activeImage,
      relatedProducts: relatedProducts ?? this.relatedProducts,
      relatedLoading: relatedLoading ?? this.relatedLoading,
      isOpeningChat: isOpeningChat ?? this.isOpeningChat,
      galleryVisible: galleryVisible ?? this.galleryVisible,
      galleryIndex: galleryIndex ?? this.galleryIndex,
    );
  }

  @override
  List<Object?> get props => [
        product,
        loading,
        activeImage,
        relatedProducts,
        relatedLoading,
        isOpeningChat,
        galleryVisible,
        galleryIndex,
      ];
}