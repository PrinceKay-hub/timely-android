import 'package:booking/data/models/product_model.dart';
import 'package:booking/data/repositories/shop_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


part 'search_state.dart';

const int _maxRecentSearches = 6;

class SearchCubit extends Cubit<SearchState> {
  final ShopRepository _repo;

  SearchCubit({ShopRepository? repository})
      : _repo = repository ?? ShopRepository(),
        super(const SearchState());

  Future<void> loadCatalog() async {
    emit(state.copyWith(catalogStatus: SearchCatalogStatus.loading));
    try {
      final catalog = await _repo.fetchSearchCatalog();
      emit(state.copyWith(
        catalogStatus: SearchCatalogStatus.success,
        catalog: catalog,
      ));
    } catch (_) {
      emit(state.copyWith(catalogStatus: SearchCatalogStatus.failure));
    }
  }

  void setSearchText(String text) => emit(state.copyWith(searchText: text));

  void clearSearchText() => emit(state.copyWith(searchText: ''));

  void toggleCategory(ProductCategory category) {
    if (state.selectedCategory == category) {
      emit(state.copyWith(clearCategory: true));
    } else {
      emit(state.copyWith(selectedCategory: category));
    }
  }

  void setSort(SearchSort sort) => emit(state.copyWith(sortBy: sort));

  void commitSearch(String term) {
    final cleaned = term.trim();
    if (cleaned.isEmpty) return;
    final withoutDupe = state.recentSearches
        .where((s) => s.toLowerCase() != cleaned.toLowerCase())
        .toList();
    final next = [cleaned, ...withoutDupe].take(_maxRecentSearches).toList();
    emit(state.copyWith(recentSearches: next));
  }

  void applyRecentSearch(String term) => emit(state.copyWith(searchText: term));

  void removeRecentSearch(String term) {
    emit(state.copyWith(
      recentSearches: state.recentSearches.where((s) => s != term).toList(),
    ));
  }

  void clearRecentSearches() => emit(state.copyWith(recentSearches: []));
}