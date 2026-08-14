// lib/presentaion/screens/search/cubit/search_state.dart
part of 'search_cubit.dart';

class SearchState {
  final bool isLoading;      // first page / full refresh
  final bool isLoadingMore;  // pagination
  final List<Map<String, dynamic>> results;
  final int totalCount;
  final int page;
  final bool hasMore;

  /// Friendly message for a full-page error (no results to show at all).
  final String? error;

  /// Friendly message for a load-more error (results are still shown,
  /// this is surfaced as a one-off SnackBar via the listener).
  final String? loadMoreError;

  const SearchState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.results = const [],
    this.totalCount = 0,
    this.page = 1,
    this.hasMore = false,
    this.error,
    this.loadMoreError,
  });

  SearchState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    List<Map<String, dynamic>>? results,
    int? totalCount,
    int? page,
    bool? hasMore,
    String? error,
    bool clearError = false,
    String? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      results: results ?? this.results,
      totalCount: totalCount ?? this.totalCount,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      loadMoreError:
          clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
    );
  }
}