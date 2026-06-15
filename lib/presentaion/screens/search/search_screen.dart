import 'package:booking/presentaion/screens/location/cubit/cubit/set_location_cubit.dart';
import 'package:booking/presentaion/screens/location/region_screen.dart';
import 'package:booking/presentaion/screens/search/results_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Search Screen with Autocomplete
class SearchScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const SearchScreen({super.key, required this.user});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<String> serviceList = [];

  bool _showAutocomplete = false;
  List<String> _suggestions = [];
  Timer? _debounceTimer;
  var location;
  

  final List<String> _recentSearches = [
    'Haircut',
    'Beard Trim',
    'Hair Coloring ',
    'Spa Treatment',
  ];

  @override
  void initState() {
    super.initState();
    fetchServices();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    // Debounce search to avoid too many calls
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (_searchController.text.isEmpty) {
        setState(() {
          _showAutocomplete = false;
          _suggestions = [];
        });
      } else {
        _performSearch(_searchController.text);
      }
    });
  }

  void _onFocusChanged() {
    if (_searchFocusNode.hasFocus && _searchController.text.isNotEmpty) {
      setState(() {
        _showAutocomplete = true;
      });
    }
  }

  void _performSearch(String query) {
    // Simulate API call - Replace with actual API
    final results = serviceList
        .where((service) => service.toLowerCase().contains(query.toLowerCase()))
        .take(5)
        .toList();

    setState(() {
      _suggestions = results;
      _showAutocomplete = results.isNotEmpty;
    });
  }

  void _selectSuggestion(String suggestion) {
    setState(() {
      _searchController.text = suggestion;
      _showAutocomplete = false;
    });
    _searchFocusNode.unfocus();
  }

  void _navigateToLocation() {
   Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegionsScreen()),
    );
  }

  void _performFullSearch() {
    if (_searchController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a search term'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    if (location == 'Select Location') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select location'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Navigate to results page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(
          query: _searchController.text,
          location: location,
          user: widget.user
        ),
      ),
    );
  }

  Future<List<String>> fetchServices() async {
    try {
      
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('categories')
          .doc('serviceList') 
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('services')) {
          // Ensure the value is a List and cast items to String
          List<dynamic> rawList = data['services'];
          // return rawList.map((e) => e.toString()).toList();
          setState(() {
            serviceList = rawList.map((e) => e.toString()).toList();
          });
          return serviceList;
        } else {
          print('Field "services" not found in document');
          return [];
        }
      } else {
        print('Document does not exist');
        return [];
      }
    } catch (e) {
      print('Error fetching services: $e');
      return [];
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _showAutocomplete = false;
      _suggestions = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        body: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: 20,),
                  // Search Bar
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_back,
                              color: Theme.of(
                                context,
                              ).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 10),
                            hintText: 'What service are you looking for?',
                            hintStyle: TextStyle(
                              fontSize: 14
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.grey,
                                    ),
                                    onPressed: _clearSearch,
                                  )
                                : null,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(50),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(50),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                          ),
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 7,
                        color: Color(0xFF8B5CF6),
                      ),
                      GestureDetector(
                        onTap: _performFullSearch,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(0xFF8B5CF6),
                            shape: BoxShape.circle,
                          ),
                          child: FaIcon(
                              FontAwesomeIcons.magnifyingGlass,
                              color: Colors.white,
                              size: 20,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
      
                  // Location Selector
                  GestureDetector(
                    onTap: _navigateToLocation,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: BlocBuilder<SetLocationCubit, SetLocationState>(
                              builder: (context, state) {
                                location = state.value;
                                return Text(
                                  location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      
            // Content Area
            Expanded(
              child: Stack(
                children: [
                  // Main Content (Popular & Recent Searches)
                  if (!_showAutocomplete)
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Recent Searches
                          if (_recentSearches.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Popular Searches',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // Clear recent searches
                                  },
                                  child: Text(
                                    'Clear All',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...List.generate(
                              _recentSearches.length,
                              (index) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEDE9FE),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.history,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(_recentSearches[index]),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      // Remove from recent
                                    },
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _searchController.text =
                                          _recentSearches[index];
                                    });
                                    _performFullSearch();
                                  },
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
      
                  // Autocomplete Suggestions
                  if (_showAutocomplete && _suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _suggestions.length,
                        separatorBuilder: (context, index) =>
                            Divider(height: 1, color: Colors.grey[200]),
                        itemBuilder: (context, index) {
                          final suggestion = _suggestions[index];
                          return ListTile(
                            leading: Icon(
                              Icons.search,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(suggestion),
                            trailing: const Icon(
                              Icons.north_west,
                              color: Colors.grey,
                              size: 16,
                            ),
                            onTap: () => _selectSuggestion(suggestion),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder for Location Selection Screen
class LocationSelectionScreen extends StatelessWidget {
  const LocationSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Location')),
      body: const Center(child: Text('Location Selection Screen')),
    );
  }
}
