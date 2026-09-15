
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:booking/data/models/product_model.dart';
import 'package:booking/data/repositories/shop_api_services.dart';
import 'package:booking/data/repositories/shop_repository.dart';

part 'my_listings_state.dart';

class MyListingsCubit extends Cubit<MyListingsState> {
  final ShopRepository _repo;
  final ShopApiService _api;
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  MyListingsCubit({
    ShopRepository? repository,
    ShopApiService? api,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _repo = repository ?? ShopRepository(),
        _api = api ?? ShopApiService(),
        _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance,
        super(const MyListingsState());

  String? get uid => _auth.currentUser?.uid;

  Future<void> load({bool isRefresh = false}) async {
    final id = uid;
    if (id == null) {
      emit(state.copyWith(status: MyListingsStatus.success, listings: []));
      return;
    }

    if (isRefresh) {
      emit(state.copyWith(refreshing: true));
    } else {
      emit(state.copyWith(status: MyListingsStatus.loading));
    }

    try {
      final listings = await _repo.fetchMyListings(id);
      emit(state.copyWith(
        status: MyListingsStatus.success,
        listings: listings,
        refreshing: false,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: MyListingsStatus.failure,
        refreshing: false,
      ));
    }
  }

  Future<void> refresh() => load(isRefresh: true);

  /// Toggles a listing between [active] and [offline].
  Future<bool> toggleStatus(Product product) async {
    final next = product.status == ProductStatus.offline
        ? ProductStatus.active
        : ProductStatus.offline;

    emit(state.copyWith(mutatingId: product.productId));
    try {
      await _db
          .collection('products')
          .doc(product.productId)
          .update({'status': next.id});
      await load(isRefresh: true);
      return true;
    } catch (_) {
      emit(state.copyWith(clearMutatingId: true));
      return false;
    } finally {
      // If we got here because of the refresh path, clear the mutating flag.
      if (state.mutatingId != null) {
        emit(state.copyWith(clearMutatingId: true));
      }
    }
  }

  Future<bool> deleteListing(Product product) async {
    emit(state.copyWith(mutatingId: product.productId));
    try {
      await _api.deleteProduct(product.productId);
      emit(state.copyWith(
        listings: state.listings
            .where((p) => p.productId != product.productId)
            .toList(),
        clearMutatingId: true,
      ));
      return true;
    } catch (_) {
      emit(state.copyWith(clearMutatingId: true));
      return false;
    }
  }
}