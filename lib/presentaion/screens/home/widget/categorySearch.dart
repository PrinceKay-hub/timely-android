import 'package:booking/presentaion/common/widgets/empty_screens.dart';
import 'package:booking/presentaion/screens/home/detail_screen.dart';
import 'package:booking/presentaion/screens/search/cubit/search_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Categorysearch extends StatefulWidget {
  final String category;
  final Map<String, dynamic> user;
  const Categorysearch({super.key, required this.category, required this.user});

  @override
  State<Categorysearch> createState() => _CategorysearchState();
}

class _CategorysearchState extends State<Categorysearch> {
  late final search = context.read<SearchCubit>();
  String _sortBy = 'Recommended';
  String _selectedFilter = 'All';
  bool _showFilters = false;

  // Store the original data
  List<Map<String, dynamic>> _originalData = [];
  List<Map<String, dynamic>> _filteredData = [];
  String district = '';

  @override
  void initState() {
    fetch();
    super.initState();
  }

  void fetch() {
    search.fetchByCategory(widget.category);
  }

  final List<String> _sortOptions = [
    'Recommended',
    'Highest Rated',
    'Most Reviews',
    'Nearest',
  ];

  final List<String> _filterOptions = [
    'All',
    'Highly Rated (4.5+)',
    'New Listings',
    'Verified',
  ];

  // Apply filters to the data
  void _applyFilters(List<Map<String, dynamic>> data) {
    List<Map<String, dynamic>> filtered = List.from(data);

    // Apply selected filter
    switch (_selectedFilter) {
      case 'Highly Rated (4.5+)':
        filtered = filtered.where((item) {
          final rating = item['rating'] ?? 0.0;
          return rating >= 4.5;
        }).toList();
        break;

      case 'New Listings':
        filtered = filtered.where((item) {
          // Assuming you have a createdAt field
          if (item['createdAt'] != null) {
            final createdAt = item['createdAt'] as DateTime?;
            if (createdAt != null) {
              final daysDifference = DateTime.now()
                  .difference(createdAt)
                  .inDays;
              return daysDifference <= 30; // New = within 30 days
            }
          }
          return false;
        }).toList();
        break;

      case 'Verified':
        filtered = filtered.where((item) {
          final isVerified = item['isVerified'] ?? false;
          return isVerified == true;
        }).toList();
        break;

      case 'All':
      default:
        // No filtering
        break;
    }

    setState(() {
      _filteredData = filtered;
    });

    // Apply sort after filtering
    _applySorting();
  }

  // Apply sorting to the filtered data
  void _applySorting() {
    List<Map<String, dynamic>> sorted = List.from(_filteredData);

    switch (_sortBy) {
      case 'Highest Rated':
        sorted.sort((a, b) {
          final ratingA = a['rating'] ?? 0.0;
          final ratingB = b['rating'] ?? 0.0;
          return ratingB.compareTo(ratingA); // Descending
        });
        break;

      case 'Most Reviews':
        sorted.sort((a, b) {
          final reviewsA = a['reviews'] ?? 0;
          final reviewsB = b['reviews'] ?? 0;
          return reviewsB.compareTo(reviewsA); // Descending
        });
        break;

      case 'Nearest':
        sorted.sort((a, b) {
          final distanceA = a['distance'] ?? double.infinity;
          final distanceB = b['distance'] ?? double.infinity;
          return distanceA.compareTo(distanceB); // Ascending
        });
        break;

      case 'Recommended':
      default:
        // Default sorting - combination of rating and distance
        sorted.sort((a, b) {
          final scoreA = _calculateRecommendationScore(a);
          final scoreB = _calculateRecommendationScore(b);
          return scoreB.compareTo(scoreA); // Descending
        });
        break;
    }

    setState(() {
      _filteredData = sorted;
    });
  }

  // Calculate recommendation score based on rating, reviews, and distance
  double _calculateRecommendationScore(Map<String, dynamic> item) {
    final rating = item['rating'] ?? 0.0;
    final reviews = item['reviews'] ?? 0;
    final distance = item['distance'] ?? 100.0;

    // Weight factors
    const ratingWeight = 0.5;
    const reviewsWeight = 0.3;
    const distanceWeight = 0.2;

    // Normalize reviews (log scale to prevent very high review counts from dominating)
    final normalizedReviews = reviews > 0
        ? (reviews / 100).clamp(0.0, 1.0)
        : 0.0;

    // Normalize distance (inverse - closer is better)
    final normalizedDistance = distance > 0 ? (1 / (1 + distance / 10)) : 1.0;

    // Calculate weighted score
    final score =
        (rating / 5.0) * ratingWeight +
        normalizedReviews * reviewsWeight +
        normalizedDistance * distanceWeight;

    return score;
  }

  String _formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).round()} m';
    } else if (distanceInKm < 10) {
      return '${distanceInKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceInKm.round()} km';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        body: BlocBuilder<SearchCubit, SearchState>(
          builder: (context, state) {
            if (state is SearchLoading) {
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }
      
            if (state is SearchError) {
              return Center(child: Text(state.message));
            }
      
            if (state is SearchLoaded) {
              final receivedData = state.results;
      
              // Initialize data on first load
              if (_originalData.isEmpty && receivedData.isNotEmpty) {
                _originalData = List.from(receivedData);
                _filteredData = List.from(receivedData);
                // Apply initial sorting
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _applySorting();
                });
              }
      
              if (receivedData.isEmpty) {
                return _buildEmptyState();
              }
      
              return Column(
                children: [
                  _buildHeader(_filteredData.length),
                  _buildSortFilterBar(),
                  if (_showFilters) _buildFilterChips(),
                  _buildResultsList(),
                ],
              );
            }
      
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildHeader(int resultCount) {
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
              Text(
                widget.category,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$resultCount result${resultCount != 1 ? 's' : ''} found in 20 km radius',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                        _sortBy,
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
                    ? Theme.of(context).colorScheme.surface
                    : Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filterOptions.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilter = filter;
                  });
                  _applyFilters(_originalData);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? null
                        : Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
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

  Widget _buildResultsList() {
    return Expanded(
      child: _filteredData.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
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
                      'No results match your filters',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Try adjusting your filters or search criteria',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedFilter = 'All';
                          _sortBy = 'Recommended';
                        });
                        _applyFilters(_originalData);
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
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _filteredData.length,
              itemBuilder: (context, index) {
                final Map<String, dynamic> item = _filteredData[index];
                return _buildResultCard(item);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        _buildHeader(0),
        _buildSortFilterBar(),
        if (_showFilters) _buildFilterChips(),
        Expanded(
          child: EmptyScreen(
            icon: Icons.search_off,
            title: 'No data found under',
            text: widget.category,
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailScreen(data: item, user: widget.user),
          ),
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
        child: Column(
          children: [
            // Image & Quick Actions
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                  child: Image.network(
                    item['images'][0],
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 160,
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey[400],
                        ),
                      );
                    },
                  ),
                ),
                // Favorite Button
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.favorite_border,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & Verified Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (item['isVerified'] == true)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified,
                            color: Color(0xFF10B981),
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Rating & Reviews
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        (item['rating'] ?? 0.0).toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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
                      const Spacer(),
                      Icon(
                        Icons.location_on,
                        color: Colors.grey[400],
                        size: 16,
                      ),
                      const SizedBox(width: 4),

                      if (item['distance'] == null)
                        Text('N/A')
                      else
                        Text(
                          _formatDistance(item['distance'].toDouble()),
                          //item['distanceText']?.toString() ?? 'N/A',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Address
                  Row(
                    children: [
                      Icon(
                        Icons.location_city,
                        color: Colors.grey[400],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item['location'] ?? 'Unknown location',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Services Tags
                  if (item['services'] != null && item['services'] is List)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: (item['services'] as List<dynamic>).take(3).map(
                        (service) {
                          final name = service is Map
                              ? (service['name'] as String? ?? '')
                              : service.toString();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              name,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            ...List.generate(
              _sortOptions.length,
              (index) => ListTile(
                leading: Radio<String>(
                  value: _sortOptions[index],
                  groupValue: _sortBy,
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                    });
                    _applySorting();
                    Navigator.pop(context);
                  },
                ),
                title: Text(_sortOptions[index]),
                onTap: () {
                  setState(() {
                    _sortBy = _sortOptions[index];
                  });
                  _applySorting();
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
