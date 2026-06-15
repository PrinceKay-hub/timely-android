import 'dart:async';

import 'package:booking/data/repositories/favorite_repositry_impl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'favorite_state.dart';

class FavoriteCubit extends Cubit<FavoriteState> {
  final FavoriteRepositryImpl _favoriteService;
  StreamSubscription? _favoritesSubscription;

  FavoriteCubit({required FavoriteRepositryImpl favoriteService})
      : _favoriteService = favoriteService,
        super(FavoriteState.initial());

  // Load initial favorite IDs
  Future<void> loadFavorites() async {
    emit(state.copyWith(isLoading: true));
    try {
      final ids = await _favoriteService.getFavoriteIds();
      emit(state.copyWith(favoriteIds: ids, isLoading: false));
    } catch (e) {
      // Handle error – for simplicity, emit empty set
      emit(state.copyWith(favoriteIds: {}, isLoading: false));
    }
  }

  // Toggle favorite status for an item
  Future<void> toggleFavorite(String itemId) async {
    // Optimistically update UI
    final newIds = Set<String>.from(state.favoriteIds);
    if (newIds.contains(itemId)) {
      newIds.remove(itemId);
    } else {
      newIds.add(itemId);
    }
    emit(state.copyWith(favoriteIds: newIds));

    // Perform actual toggle in Firestore
    try {
      await _favoriteService.toggleFavorite(itemId);
      // If success, do nothing (already updated)
    } catch (e) {
      // Revert on failure
      final revertIds = Set<String>.from(state.favoriteIds);
      if (revertIds.contains(itemId)) {
        revertIds.remove(itemId);
      } else {
        revertIds.add(itemId);
      }
      emit(state.copyWith(favoriteIds: revertIds));
      // Optionally show error message
    }
  }

  // Load full favorite items (for FavoritesScreen)
  void loadFavoriteItems() {
    emit(state.copyWith(isLoading: true));

    _favoritesSubscription?.cancel();
    _favoritesSubscription = _favoriteService.getUserFavorites().listen(
      (querySnapshot) async {
        // For each favorite document, fetch the corresponding service document
        List<Map<String, dynamic>> items = [];
        for (var doc in querySnapshot.docs) {
          final itemId = doc.id;
          final serviceDoc = await FirebaseFirestore.instance
              .collection('services')
              .doc(itemId)
              .get();
          if (serviceDoc.exists) {
            items.add({
              'id': itemId,
              ...serviceDoc.data() as Map<String, dynamic>,
            });
          }
        }
        emit(state.copyWith(
          favoriteItems: items,
          isLoading: false,
        ));
      },
      onError: (error) {
        emit(state.copyWith(isLoading: false));
        // handle error
      },
    );
  }

  @override
  Future<void> close() {
    _favoritesSubscription?.cancel();
    return super.close();
  }
}