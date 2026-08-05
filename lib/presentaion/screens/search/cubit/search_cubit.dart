// lib/cubits/search_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:booking/data/repositories/search_repository_impl.dart';
import 'package:equatable/equatable.dart';

part 'search_state.dart';

enum SearchType { search, category }

class SearchCubit extends Cubit<SearchState> {
  final SearchRepositoryImpl _repository;
  int _requestId = 0;

  // Last used parameters for pagination
  Map<String, dynamic>? _lastSearchParams;
  Map<String, dynamic>? _lastCategoryParams;
  SearchType _lastSearchType = SearchType.search;

  SearchCubit({required SearchRepositoryImpl repository})
      : _repository = repository,
        super(const SearchState());

  // ─── Search (query) ────────────────────────────────────────────────────

  Future<void> fetchSearchResults({
    required String query,
    required String region,
    String? district,
    double maxDistanceKm = 10,
    String sortBy = 'distance',
    int pageSize = 20,
  }) async {
    final requestId = ++_requestId;
    _lastSearchType = SearchType.search;
    _lastSearchParams = {
      'query': query,
      'region': region,
      'district': district,
      'maxDistanceKm': maxDistanceKm,
      'sortBy': sortBy,
      'pageSize': pageSize,
    };

    emit(state.copyWith(
      isLoading: true,
      error: null,
      page: 1,
    ));

    try {
      final response = await _repository.searchProviders(
        query: query,
        region: region,
        district: district,
        maxDistanceKm: maxDistanceKm,
        sortBy: sortBy,
        page: 1,
        pageSize: pageSize,
      );

      if (requestId != _requestId) return;

      emit(state.copyWith(
        results: response.providers,
        isLoading: false,
        totalCount: response.totalCount,
        hasMore: response.hasMore,
        clearError: true,
      ));
    } catch (e) {
      if (requestId != _requestId) return;
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // ─── Category ──────────────────────────────────────────────────────────

  Future<void> searchByCategoryAction({
    required String category,
    String sortBy = 'distance',
    double maxDistanceKm = 10,
    int pageSize = 20,
  }) async {
    final requestId = ++_requestId;
    _lastSearchType = SearchType.category;
    _lastCategoryParams = {
      'category': category,
      'sortBy': sortBy,
      'maxDistanceKm': maxDistanceKm,
      'pageSize': pageSize,
    };

    emit(state.copyWith(
      isLoading: true,
      error: null,
      page: 1,
    ));

    try {
      final response = await _repository.searchByCategory(
        category: category,
        maxDistanceKm: maxDistanceKm,
        sortBy: sortBy,
        page: 1,
        pageSize: pageSize,
      );

      if (requestId != _requestId) return;

      emit(state.copyWith(
        results: response.providers,
        isLoading: false,
        totalCount: response.totalCount,
        hasMore: response.hasMore,
        clearError: true,
      ));
    } catch (e) {
      if (requestId != _requestId) return;
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // ─── Load More (works for both search and category) ──────────────────

  Future<void> loadMoreResults() async {
    if (state.isLoadingMore || !state.hasMore) return;

    final requestId = ++_requestId;
    emit(state.copyWith(isLoadingMore: true));

    try {
      final nextPage = state.page + 1;

      if (_lastSearchType == SearchType.search && _lastSearchParams != null) {
        final params = _lastSearchParams!;
        final response = await _repository.searchProviders(
          query: params['query'] as String,
          region: params['region'] as String,
          district: params['district'] as String?,
          maxDistanceKm: (params['maxDistanceKm'] as num?)?.toDouble() ?? 10,
          sortBy: params['sortBy'] as String? ?? 'distance',
          page: nextPage,
          pageSize: (params['pageSize'] as num?)?.toInt() ?? 20,
        );
        if (requestId != _requestId) return;
        emit(state.copyWith(
          results: [...state.results, ...response.providers],
          page: nextPage,
          totalCount: response.totalCount,
          hasMore: response.hasMore,
          isLoadingMore: false,
        ));
      } else if (_lastSearchType == SearchType.category && _lastCategoryParams != null) {
        final params = _lastCategoryParams!;
        final response = await _repository.searchByCategory(
          category: params['category'] as String,
          maxDistanceKm: (params['maxDistanceKm'] as num?)?.toDouble() ?? 10,
          sortBy: params['sortBy'] as String? ?? 'distance',
          page: nextPage,
          pageSize: (params['pageSize'] as num?)?.toInt() ?? 20,
        );
        if (requestId != _requestId) return;
        emit(state.copyWith(
          results: [...state.results, ...response.providers],
          page: nextPage,
          totalCount: response.totalCount,
          hasMore: response.hasMore,
          isLoadingMore: false,
        ));
      } else {
        // Should not happen
        emit(state.copyWith(isLoadingMore: false));
      }
    } catch (e) {
      if (requestId != _requestId) return;
      emit(state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      ));
    }
  }

  void clearResults() {
    emit(const SearchState());
    _lastSearchParams = null;
    _lastCategoryParams = null;
  }
  
}