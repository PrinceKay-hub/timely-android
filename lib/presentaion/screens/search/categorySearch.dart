// lib/presentation/screens/search/category_results_screen.dart
import 'package:booking/presentaion/screens/home/detail_screen.dart';
import 'package:booking/presentaion/screens/search/cubit/search_cubit.dart';
import 'package:booking/presentaion/screens/search/search_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

class CategoryResultsScreen extends StatefulWidget {
  final String category;
  final Map<String, dynamic> user;

  const CategoryResultsScreen({
    super.key,
    required this.category,
    required this.user,
  });

  @override
  State<CategoryResultsScreen> createState() => _CategoryResultsScreenState();
}

class _CategoryResultsScreenState extends State<CategoryResultsScreen> {
  // ─── UI state ──────────────────────────────────────────────────────
  String _sortBy = 'distance'; // 'distance' | 'rating'
  String _selectedFilter = 'All'; // 'All' | 'Verified'
  bool _showFilters = false;

  // ─── Category switching ─────────────────────────────────────────────
  late String _currentCategory = widget.category;
  List<Map<String, dynamic>> _serviceList = [];
  bool _loadingServices = true;

  // ─── Scroll controller for infinite scroll ──────────────────────
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchFirstPage();
    _loadCategorySuggestions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Data fetching ─────────────────────────────────────────────────
  void _fetchFirstPage() {
    context.read<SearchCubit>().searchByCategoryAction(
      category: _currentCategory,
      sortBy: _sortBy,
    );
  }

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('categories')
          .doc('main')
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final rawList = data['category'] as List? ?? [];

        final serviceList = rawList.map((item) {
          if (item is Map) {
            return Map<String, dynamic>.from(item);
          } else {
            throw Exception('Invalid category format: expected Map');
          }
        }).toList();

        return serviceList;
      }
      return [];
    } catch (e) {
      rethrow;
    } finally {
      if (mounted) setState(() => _loadingServices = false);
    }
  }

  Future<void> _loadCategorySuggestions() async {
    try {
      final categories = await fetchCategories();
      if (!mounted) return;
      setState(() {
        _serviceList = categories;
      });
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  // Pulls a display/search label out of a category map. Adjust the key
  // priority here if your Firestore documents use a different field name.
  String _categoryLabel(Map<String, dynamic> category) {
    return (category['name'] ?? category['title'] ?? category['category'] ?? '')
        .toString();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SearchCubit>().loadMoreResults();
    }
  }

  // ─── Client‑side filtering (only on current results) ─────────────
  List<Map<String, dynamic>> _getFilteredResults(
    List<Map<String, dynamic>> allResults,
  ) {
    if (_selectedFilter == 'Verified') {
      return allResults.where((item) => item['isVerified'] == true).toList();
    }
    return allResults;
  }

  List<Map<String, dynamic>> get _suggestionChips => _serviceList
      .where((c) => _categoryLabel(c) != _currentCategory)
      .take(8)
      .toList();

  void _switchCategory(String category) {
    if (Navigator.canPop(context) &&
        ModalRoute.of(context)?.isCurrent == false) {
      Navigator.pop(context); // close the category picker sheet, if open
    }
    if (category == _currentCategory) return;
    setState(() => _currentCategory = category);
    _fetchFirstPage();
  }

  void _goToKeywordSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchScreen(user: widget.user)),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────
  String _formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).round()} m';
    } else if (distanceInKm < 10) {
      return '${distanceInKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceInKm.round()} km';
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<SearchCubit, SearchState>(
        listener: (context, state) {
          if (state.loadMoreError != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.loadMoreError!),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'Retry',
                    onPressed: () =>
                        context.read<SearchCubit>().loadMoreResults(),
                  ),
                ),
              );
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.results.isEmpty) {
            return Column(
              children: [
                _buildHeader(0, true),
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ],
            );
          }
          if (state.error != null && state.results.isEmpty) {
            return _buildErrorState(state.error!);
          }

          final allResults = state.results;
          final filteredResults = _getFilteredResults(allResults);

          return Column(
            children: [
              _buildHeader(state.totalCount, state.isLoading),
              _buildSortFilterBar(),
              if (_showFilters) _buildFilterChips(),
              Expanded(
                child: filteredResults.isEmpty
                    ? _buildEmptyState()
                    : _buildResultsList(filteredResults, state.isLoadingMore),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  // ─── Header (category is now tappable, + keyword-search shortcut) ──
  Widget _buildHeader(int totalCount, bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: _showCategoryPicker,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          _currentCategory,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.expand_more,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: _goToKeywordSearch,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$totalCount result${totalCount != 1 ? 's' : ''} found in 10km radius',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Sort & Filter Bar ─────────────────────────────────────────────
  Widget _buildSortFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _showSortOptions,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sort,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _sortBy == 'distance' ? 'Nearest' : 'Highest Rated',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _showFilters
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.tune,
                color: _showFilters
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Filter Chips ──────────────────────────────────────────────────
  Widget _buildFilterChips() {
    const filterOptions = ['All', 'Verified'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Theme.of(context).colorScheme.secondary,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filterOptions.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? null
                        : Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── Suggestion chips: quick category switching ────────────────────
  Widget _buildSuggestionChips({required bool isEmptyState}) {
    final chips = _suggestionChips;
    if (chips.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: isEmptyState ? const EdgeInsets.only(top: 8) : EdgeInsets.zero,
      padding: EdgeInsets.symmetric(
        horizontal: isEmptyState ? 0 : 20,
        vertical: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEmptyState ? 'TRY ANOTHER CATEGORY' : 'BROWSE SIMILAR',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: chips.map((category) {
                final label = _categoryLabel(category);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _switchCategory(label),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Results List (infinite scroll) ───────────────────────────────
  Widget _buildResultsList(
    List<Map<String, dynamic>> items,
    bool isLoadingMore,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: items.length + 1 + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildSuggestionChips(isEmptyState: false);
        }
        final itemIndex = index - 1;
        if (itemIndex == items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final item = items[itemIndex];
        return _buildResultCard(item);
      },
    );
  }

  // ─── Empty State ────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.filter_alt_off,
                size: 60,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No results match your search',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your filters or search criteria',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            _buildSuggestionChips(isEmptyState: true),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedFilter = 'All';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Clear Filters',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Result Card ────────────────────────────────────────────────────
  Widget _buildResultCard(Map<String, dynamic> item) {
    var land = item['landmark'];
    var landmark = land != null ? ', $land' : '';
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetailScreen(id: item['id'])),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
              child: CachedNetworkImage(
                imageUrl:
                    (item['images'] is List &&
                        (item['images'] as List).isNotEmpty)
                    ? item['images'][0] as String
                    : '',
                height: 120,
                width: 120,
                fit: BoxFit.cover,
                memCacheWidth: 240,
                memCacheHeight: 240,
                fadeInDuration: const Duration(milliseconds: 200),
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Theme.of(context).colorScheme.surfaceBright,
                  highlightColor: Theme.of(context).colorScheme.surfaceDim,
                  child: Container(
                    width: 120,
                    height: 120,
                    color: Colors.white,
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 120,
                  width: 120,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                ),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              (item['rating'] ?? 0.0).toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${item['reviews'] ?? 0} reviews)',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),

                        if (item['distance'] == null)
                          const Text('N/A')
                        else
                          Text(
                            _formatDistance(item['distance'].toDouble()),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item['district']}$landmark',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 60,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchFirstPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Category picker bottom sheet ───────────────────────────────────
  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Choose a category',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _goToKeywordSearch();
                      },
                      child: Text(
                        'Search instead',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: _loadingServices
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: _serviceList.map((category) {
                          final label = _categoryLabel(category);
                          final isSelected = label == _currentCategory;
                          return ListTile(
                            leading: Radio<String>(
                              value: label,
                              groupValue: _currentCategory,
                              activeColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              onChanged: (value) => _switchCategory(value!),
                            ),
                            title: Text(
                              label,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.black87,
                              ),
                            ),
                            onTap: () => _switchCategory(label),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // ─── Sort Options Bottom Sheet ─────────────────────────────────────
  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Sort By',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: Radio<String>(
                value: 'distance',
                groupValue: _sortBy,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                  _fetchFirstPage();
                  Navigator.pop(context);
                },
              ),
              title: const Text('Nearest'),
            ),
            ListTile(
              leading: Radio<String>(
                value: 'rating',
                groupValue: _sortBy,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                  _fetchFirstPage();
                  Navigator.pop(context);
                },
              ),
              title: const Text('Highest Rated'),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
