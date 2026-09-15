// ─────────────────────────────────────────────────────────────────────────
// product_detail_cubit.dart
// ─────────────────────────────────────────────────────────────────────────
import 'package:booking/presentaion/screens/shop/cubit/detail_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:booking/data/models/product_model.dart';
import 'package:booking/data/repositories/shop_api_services.dart';
import 'package:booking/data/repositories/shop_repository.dart';

class ProductDetailCubit extends Cubit<ProductDetailState> {
  final String productId;
  final ShopRepository _repo;
  final ShopApiService _api;
  final FirebaseAuth _auth;

  ProductDetailCubit({
    required this.productId,
    ShopRepository? repository,
    ShopApiService? api,
    FirebaseAuth? auth,
  })  : _repo = repository ?? ShopRepository(),
        _api = api ?? ShopApiService(),
        _auth = auth ?? FirebaseAuth.instance,
        super(const ProductDetailState());

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    try {
      final product = await _repo.fetchProduct(productId);
      if (product == null) {
        emit(state.copyWith(loading: false));
        return;
      }
      emit(state.copyWith(product: product, loading: false));

      final isOwn = _auth.currentUser?.uid == product.sellerId;
      if (!isOwn) {
        // fire-and-forget
        _repo.incrementViewCount(productId).catchError((_) {});
      }

      _loadRelated(product);
    } catch (_) {
      emit(state.copyWith(loading: false));
    }
  }

  Future<void> _loadRelated(Product product) async {
    emit(state.copyWith(relatedLoading: true));
    try {
      final items = await _repo.fetchRelatedProducts(
        category: product.category,
        excludeProductId: product.productId,
      );
      emit(state.copyWith(
        relatedProducts: items.take(10).toList(),
        relatedLoading: false,
      ));
    } catch (_) {
      emit(state.copyWith(relatedLoading: false));
    }
  }

  void setActiveImage(int index) => emit(state.copyWith(activeImage: index));

  void openGallery(int index) => emit(state.copyWith(
        galleryVisible: true,
        galleryIndex: index,
      ));

  void closeGallery() => emit(state.copyWith(galleryVisible: false));

  void setOpeningChat(bool v) => emit(state.copyWith(isOpeningChat: v));
}