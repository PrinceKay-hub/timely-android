part of 'search_cubit.dart';

enum SearchSort { newest, priceAsc, priceDesc }

extension SearchSortLabel on SearchSort {
  String get label => switch (this) {
        SearchSort.newest => 'Newest',
        SearchSort.priceAsc => 'Price: Low to High',
        SearchSort.priceDesc => 'Price: High to Low',
      };
}

enum SearchCatalogStatus { loading, success, failure }

class SearchState extends Equatable {
  final SearchCatalogStatus catalogStatus;
  final List<Product> catalog;
  final String searchText;
  final ProductCategory? selectedCategory;
  final SearchSort sortBy;
  final List<String> recentSearches;

  const SearchState({
    this.catalogStatus = SearchCatalogStatus.loading,
    this.catalog = const [],
    this.searchText = '',
    this.selectedCategory,
    this.sortBy = SearchSort.newest,
    this.recentSearches = const [],
  });

  bool get isBrowsing => searchText.trim().isEmpty && selectedCategory == null;

  List<Product> get trending {
    final sorted = [...catalog]..sort((a, b) => b.viewCount.compareTo(a.viewCount));
    return sorted.take(8).toList();
  }

  List<Product> get results {
    final query = searchText.trim().toLowerCase();
    var list = catalog.where((p) {
      final matchesCategory =
          selectedCategory == null || p.category == selectedCategory;
      if (!matchesCategory) return false;
      if (query.isEmpty) return true;
      return p.name.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query) ||
          p.tags.any((t) => t.toLowerCase().contains(query));
    }).toList();

    switch (sortBy) {
      case SearchSort.priceAsc:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SearchSort.priceDesc:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SearchSort.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    return list;
  }

  SearchState copyWith({
    SearchCatalogStatus? catalogStatus,
    List<Product>? catalog,
    String? searchText,
    ProductCategory? selectedCategory,
    bool clearCategory = false,
    SearchSort? sortBy,
    List<String>? recentSearches,
  }) {
    return SearchState(
      catalogStatus: catalogStatus ?? this.catalogStatus,
      catalog: catalog ?? this.catalog,
      searchText: searchText ?? this.searchText,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      sortBy: sortBy ?? this.sortBy,
      recentSearches: recentSearches ?? this.recentSearches,
    );
  }

  @override
  List<Object?> get props => [
        catalogStatus,
        catalog,
        searchText,
        selectedCategory,
        sortBy,
        recentSearches,
      ];
}