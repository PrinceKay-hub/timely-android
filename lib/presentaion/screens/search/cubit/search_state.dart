// lib/cubits/search_state.dart
part of 'search_cubit.dart';

class SearchState extends Equatable {
  final List<Map<String, dynamic>> results;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int page;
  final int totalCount;
  final bool hasMore;
  final Map<String, dynamic>? lastParams; // stores the params used for initial search

  const SearchState({
    this.results = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.page = 1,
    this.totalCount = 0,
    this.hasMore = false,
    this.lastParams,
  });

  SearchState copyWith({
    List<Map<String, dynamic>>? results,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? page,
    int? totalCount,
    bool? hasMore,
    Map<String, dynamic>? lastParams,
    bool clearError = false,
  }) {
    return SearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      lastParams: lastParams ?? this.lastParams,
    );
  }

  @override
  List<Object?> get props => [
        results,
        isLoading,
        isLoadingMore,
        error,
        page,
        totalCount,
        hasMore,
        lastParams,
      ];
}