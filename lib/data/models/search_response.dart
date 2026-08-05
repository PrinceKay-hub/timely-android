// lib/models/search_response.dart
class SearchResponse {
  final List<Map<String, dynamic>> providers;
  final int totalCount;
  final int page;
  final int pageSize;
  final bool hasMore;

  SearchResponse({
    required this.providers,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  factory SearchResponse.fromMap(Map<String, dynamic> map) {
    return SearchResponse(
      providers: List<Map<String, dynamic>>.from(
        (map['providers'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? [],
      ),
      totalCount: (map['totalCount'] as num?)?.toInt() ?? 0,
      page: (map['page'] as num?)?.toInt() ?? 1,
      pageSize: (map['pageSize'] as num?)?.toInt() ?? 20,
      hasMore: map['hasMore'] as bool? ?? false,
    );
  }
}