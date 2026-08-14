// lib/presentation/screens/search/search_results_screen.dart
import 'package:booking/presentaion/screens/home/detail_screen.dart';
import 'package:booking/presentaion/screens/location/cubit/cubit/set_location_cubit.dart';
import 'package:booking/presentaion/screens/location/region_screen.dart';
import 'package:booking/presentaion/screens/search/cubit/search_cubit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  final String location;
  final Map<String, dynamic> user;

  const SearchResultsScreen({
    super.key,
    required this.query,
    required this.location,
    required this.user,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  // --- Local state for UI controls ---
  String _sortBy = 'distance'; // 'distance' | 'rating' (matches backend)
  String _selectedFilter = 'All'; // 'All' | 'Verified'
  bool _showFilters = false;

  // --- Query, editable in place ---
  late String _currentQuery;
  bool _isEditingQuery = false;
  late final TextEditingController _queryController;
  final FocusNode _queryFocusNode = FocusNode();

  // --- Parsed location parts, kept in sync with SetLocationCubit ---
  String region = '';
  String district = '';
  String _lastFetchedLocation = '';

  // --- Suggestion chips (same source as the search screen) ---
  List<String> _serviceList = [];

  // --- Scroll controller for infinite scroll ---
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentQuery = widget.query;
    _queryController = TextEditingController(text: _currentQuery);
    _parseLocation(widget.location);
    _fetchFirstPage();
    _fetchServices();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _queryController.dispose();
    _queryFocusNode.dispose();
    super.dispose();
  }

  // --- Helpers ---
  void _parseLocation(String location) {
    final parts = location.split(' - ');
    if (parts.length == 2) {
      region = parts[0];
      district = parts[1];
    } else {
      region = location;
      district = '';
    }
    _lastFetchedLocation = location;
  }

  void _fetchFirstPage() {
    final cubit = context.read<SearchCubit>();
    cubit.fetchSearchResults(
      query: _currentQuery,
      region: region,
      district: district.isNotEmpty ? district : null,
      sortBy: _sortBy,
    );
  }

  Future<void> _fetchServices() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('categories')
          .doc('serviceList')
          .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['services'] is List) {
          setState(() {
            _serviceList = (data['services'] as List)
                .map((e) => e.toString())
                .toList();
          });
        }
      }
    } catch (e) {
      // Non-critical: chips just won't show.
      print('Error fetching suggestion categories: $e');
    } 
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SearchCubit>().loadMoreResults();
    }
  }

  // --- Client-side filtering (only on current results) ---
  List<Map<String, dynamic>> _getFilteredResults(
    List<Map<String, dynamic>> allResults,
  ) {
    if (_selectedFilter == 'Verified') {
      return allResults.where((item) => item['isVerified'] == true).toList();
    }
    return allResults;
  }

  List<String> get _suggestionChips => _serviceList
      .where((s) => s.toLowerCase() != _currentQuery.toLowerCase())
      .take(8)
      .toList();

  // --- Query editing ---
  void _beginEditingQuery() {
    setState(() => _isEditingQuery = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _queryFocusNode.requestFocus();
    });
  }

  void _submitQuery(String raw) {
    final trimmed = raw.trim();
    _queryFocusNode.unfocus();
    setState(() => _isEditingQuery = false);
    if (trimmed.isEmpty || trimmed == _currentQuery) {
      _queryController.text = _currentQuery;
      return;
    }
    setState(() => _currentQuery = trimmed);
    _fetchFirstPage();
  }

  void _switchQuery(String term) {
    _queryController.text = term;
    setState(() => _currentQuery = term);
    _fetchFirstPage();
  }

  void _openLocationPicker() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegionsScreen()),
    );
  }

  // --- UI Helpers ---
  String _formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).round()} m';
    } else if (distanceInKm < 10) {
      return '${distanceInKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceInKm.round()} km';
    }
  }

  // --- Build methods ---
  @override
  Widget build(BuildContext context) {
    return BlocListener<SetLocationCubit, SetLocationState>(
      // Picking a new location elsewhere (e.g. the region picker) flows
      // back here automatically — no need to await a Navigator result.
      listenWhen: (previous, current) => current.value != _lastFetchedLocation,
      listener: (context, state) {
        if (state.value.isEmpty || state.value == 'Select Location') return;
        setState(() => _parseLocation(state.value));
        _fetchFirstPage();
      },
      child: Scaffold(
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
            // --- Initial loading (no results yet) ---
            if (state.isLoading && state.results.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }

            // --- Error state ---
            if (state.error != null && state.results.isEmpty) {
              return _buildErrorState(state.error!);
            }

            // --- Loaded state (with or without results) ---
            final allResults = state.results;
            final filteredResults = _getFilteredResults(allResults);

            return Column(
              children: [
                _buildHeader(state.totalCount),
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
      ),
    );
  }

  // --- Header ---
  Widget _buildHeader(int totalCount) {
    final districtLabel = district.isNotEmpty ? '- $district' : '';
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(width: 12),
              Expanded(child: _buildQueryPill()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _openLocationPicker,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'in $region $districtLabel',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.white54,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
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
                  '$totalCount result${totalCount != 1 ? 's' : ''} found',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQueryPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: _isEditingQuery
                ? TextField(
                    controller: _queryController,
                    focusNode: _queryFocusNode,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Search for a service',
                      hintStyle: TextStyle(color: Colors.white70),
                      fillColor: Colors.transparent,
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: _submitQuery,
                    onTapOutside: (_) => _submitQuery(_queryController.text),
                  )
                : GestureDetector(
                    onTap: _beginEditingQuery,
                    child: Text(
                      _currentQuery,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // --- Sort & Filter Bar ---
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

  // --- Filter Chips ---
  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Theme.of(context).colorScheme.secondary,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['All', 'Verified'].map((filter) {
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

  // --- "Browse similar" suggestion chips ---
  Widget _buildSuggestionChips({required bool inEmptyState}) {
    final chips = _suggestionChips;
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(
        left: inEmptyState ? 0 : 20,
        right: inEmptyState ? 0 : 20,
        top: inEmptyState ? 16 : 12,
        bottom: inEmptyState ? 0 : 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            inEmptyState ? 'TRY SEARCHING FOR' : 'BROWSE SIMILAR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: chips.map((term) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _switchQuery(term),
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
                        term,
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
          SizedBox(height: 10),
        ],
      ),
    );
  }

  // --- Results List with infinite scroll ---
  Widget _buildResultsList(
    List<Map<String, dynamic>> items,
    bool isLoadingMore,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      physics: BouncingScrollPhysics(),
      itemCount: items.length + 1 + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildSuggestionChips(inEmptyState: false);
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

  // --- Empty State ---
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
              'No results found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try a different search or location',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            _buildSuggestionChips(inEmptyState: true),
          ],
        ),
      ),
    );
  }

  // --- Individual Result Card ---
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
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              (item['rating'] ?? 0.0).toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.bold),
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

  // --- Sort Options Bottom Sheet ---
  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
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
