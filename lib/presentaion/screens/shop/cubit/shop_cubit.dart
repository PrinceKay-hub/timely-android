import 'package:booking/data/models/product_model.dart';
import 'package:booking/data/repositories/shop_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


part 'shop_state.dart';

class ShopCubit extends Cubit<ShopState> {
  final ShopRepository _repo;
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;

  ShopCubit({ShopRepository? repository})
      : _repo = repository ?? ShopRepository(),
        super(const ShopState());

  Future<void> load() async {
    emit(state.copyWith(status: ShopStatus.loading));
    _lastDoc = null;
    try {
      final (items, lastDoc) =
          await _repo.fetchProductsPage(category: state.category);
      _lastDoc = lastDoc;
      emit(state.copyWith(
        status: ShopStatus.success,
        products: items,
        hasMore: items.length == kProductsPageSize,
      ));
    } catch (_) {
      emit(state.copyWith(status: ShopStatus.failure));
    }
  }

  Future<void> refresh() async {
    emit(state.copyWith(refreshing: true));
    _lastDoc = null;
    try {
      final (items, lastDoc) =
          await _repo.fetchProductsPage(category: state.category);
      _lastDoc = lastDoc;
      emit(state.copyWith(
        status: ShopStatus.success,
        products: items,
        refreshing: false,
        hasMore: items.length == kProductsPageSize,
      ));
    } catch (_) {
      emit(state.copyWith(refreshing: false, status: ShopStatus.failure));
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore || _lastDoc == null) return;
    emit(state.copyWith(loadingMore: true));
    try {
      final (items, lastDoc) = await _repo.fetchProductsPage(
        category: state.category,
        startAfter: _lastDoc,
      );
      _lastDoc = lastDoc ?? _lastDoc;
      emit(state.copyWith(
        products: [...state.products, ...items],
        loadingMore: false,
        hasMore: items.length == kProductsPageSize,
      ));
    } catch (_) {
      emit(state.copyWith(loadingMore: false));
    }
  }

  Future<void> setCategory(ProductCategory? category) async {
    if (category == state.category) return;
    if (category == null) {
      emit(state.copyWith(clearCategory: true));
    } else {
      emit(state.copyWith(category: category));
    }
    await load();
  }
}