import 'package:booking/presentaion/common/widgets/empty_screens.dart';
import 'package:booking/presentaion/screens/location/cubit/cubit/set_location_cubit.dart';
import 'package:booking/presentaion/screens/location/cubit/location_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Location Selection Screen with Search
class RegionsScreen extends StatefulWidget {
  final bool? isService;
  const RegionsScreen({super.key, this.isService});

  @override
  State<RegionsScreen> createState() => _RegionsScreenState();
}

class _RegionsScreenState extends State<RegionsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late final cubit = context.read<LocationCubit>();

  String? _selectedRegion;
  String? _selectedDistrict;
  bool _isPanelOpen = false;

  // Search controllers
  final TextEditingController _regionSearchController = TextEditingController();
  final TextEditingController _districtSearchController =
      TextEditingController();

  // Filtered lists
  List<String> _filteredRegions = [];
  List<String> _filteredDistricts = [];

  // To store the full location data
  Map<String, List<String>> _locationsData = {};

  @override
  void initState() {
    super.initState();
    cubit.fetcLocations();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    // Add search listeners
    _regionSearchController.addListener(_filterRegions);
    _districtSearchController.addListener(_filterDistricts);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _regionSearchController.dispose();
    _districtSearchController.dispose();
    super.dispose();
  }

  void _openPanel(String region) {
    setState(() {
      _selectedRegion = region;
      _isPanelOpen = true;
      _filteredDistricts = _locationsData[region]!;
      _districtSearchController.clear();
    });
    _animationController.forward();
  }

  void _closePanel() {
    _animationController.reverse().then((_) {
      setState(() {
        _isPanelOpen = false;
        _districtSearchController.clear();
      });
    });
  }

  void _filterRegions() {
    final query = _regionSearchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredRegions = _locationsData.keys.toList();
      } else {
        _filteredRegions = _locationsData.keys
            .where((region) => region.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _filterDistricts() {
    if (_selectedRegion == null) return;

    final query = _districtSearchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredDistricts = _locationsData[_selectedRegion]!;
      } else {
        _filteredDistricts = _locationsData[_selectedRegion]!
            .where((district) => district.toLowerCase().contains(query))
            .toList();
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        body: BlocBuilder<LocationCubit, LocationState>(
          builder: (context, state) {
            if (state is LocationLoading) {
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }

            if (state is LocationError) {
              return Center(child: Text(state.message));
            }

            if (state is LocationLoaded) {
              _locationsData = state.location;

              // Initialize filtered lists when data loads
              if (_filteredRegions.isEmpty && _locationsData.isNotEmpty) {
                _filteredRegions = _locationsData.keys.toList();
              }

              if (_locationsData.isEmpty) {
                return EmptyScreen(
                  icon: Icons.search_off,
                  title: 'No Regions found',
                  text: 'Try again later',
                );
              }

              return Stack(
                children: [
                  // Main Content - Regions List
                  Column(
                    children: [
                      // Header
                      Container(
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
                                  onTap: () => Navigator.pop(
                                    context,
                                    '$_selectedRegion - $_selectedDistrict',
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
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
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Text(
                                    'Select Location',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.my_location,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_selectedDistrict == null)
                              const Text(
                                'Choose your region',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$_selectedRegion - $_selectedDistrict',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: TextField(
                          controller: _regionSearchController,
                          decoration: InputDecoration(
                            hintText: 'Search regions...',
                            prefixIcon: Icon(
                              Icons.search,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            suffixIcon: _regionSearchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      _regionSearchController.clear();
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.secondary,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Regions List
                      Expanded(
                        child: _filteredRegions.isEmpty
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
                                          borderRadius: BorderRadius.circular(
                                            60,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.search_off,
                                          size: 60,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      const Text(
                                        'No regions found',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Try a different search term',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                itemCount: _filteredRegions.length,
                                itemBuilder: (context, index) {
                                  final region = _filteredRegions[index];
                                  final districts = _locationsData[region]!;
                                  final isSelected = _selectedRegion == region;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: GestureDetector(
                                      onTap: () => _openPanel(region),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surface,
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          border: isSelected
                                              ? Border.all(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                  width: 2,
                                                )
                                              : null,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.05,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).colorScheme.secondary,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  Icons.location_city,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      region,
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '${districts.length} districts',
                                                      style: const TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Icon(
                                                Icons.chevron_right,
                                                color: isSelected
                                                    ? Theme.of(
                                                        context,
                                                      ).colorScheme.primary
                                                    : Colors.grey,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),

                  // Sliding Districts Panel
                  if (_isPanelOpen)
                    GestureDetector(
                      onTap: _closePanel,
                      child: Container(color: Colors.black.withOpacity(0.3)),
                    ),

                  if (_selectedRegion != null)
                    SlideTransition(
                      position: _slideAnimation,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.85,
                          height: double.infinity,
                          decoration:  BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              bottomLeft: Radius.circular(30),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 20,
                                offset: Offset(-5, 0),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Panel Header
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(30),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: _closePanel,
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.arrow_back,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            _selectedRegion!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _districtSearchController.text.isEmpty
                                          ? '${_locationsData[_selectedRegion]!.length} districts available'
                                          : '${_filteredDistricts.length} of ${_locationsData[_selectedRegion]!.length} districts',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Districts Search
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: TextField(
                                  controller: _districtSearchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search districts...',
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    suffixIcon:
                                        _districtSearchController
                                            .text
                                            .isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(
                                              Icons.clear,
                                              color: Colors.grey,
                                            ),
                                            onPressed: () {
                                              _districtSearchController.clear();
                                            },
                                          )
                                        : null,
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.secondary,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              if (widget.isService == true)
                              SizedBox()
                              else
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    context.read<SetLocationCubit>().saveString(
                                      '$_selectedRegion',
                                    );
                                    // _selectDistrict(district);
                                    Navigator.pop(context, '$_selectedRegion');
                                  },

                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.secondary,
                                      borderRadius: BorderRadius.circular(12),
                                     
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.radio_button_unchecked,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            '${_selectedRegion!} Rgion',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Districts List
                              Expanded(
                                child: _filteredDistricts.isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(40),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  20,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFEDE9FE,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(60),
                                                ),
                                                child: Icon(
                                                  Icons.location_off,
                                                  size: 60,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                ),
                                              ),
                                              const SizedBox(height: 24),
                                              const Text(
                                                'No districts found',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              const Text(
                                                'Try a different search term',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        itemCount: _filteredDistricts.length,
                                        itemBuilder: (context, index) {
                                          final district =
                                              _filteredDistricts[index];
                                          final isSelected =
                                              _selectedDistrict == district;

                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            child: GestureDetector(
                                              onTap: () {
                                                context
                                                    .read<SetLocationCubit>()
                                                    .saveString(
                                                      '$_selectedRegion - $district',
                                                    );
                                                // _selectDistrict(district);
                                                Navigator.pop(
                                                  context,
                                                  '$_selectedRegion - $district',
                                                );
                                              },

                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? const Color(0xFFEDE9FE)
                                                      : Theme.of(context).colorScheme.secondary,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: isSelected
                                                      ? Border.all(
                                                          color: Theme.of(
                                                            context,
                                                          ).colorScheme.primary,
                                                          width: 2,
                                                        )
                                                      : null,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      isSelected
                                                          ? Icons
                                                                .radio_button_checked
                                                          : Icons
                                                                .radio_button_unchecked,
                                                      color: isSelected
                                                          ? Theme.of(context)
                                                                .colorScheme
                                                                .primary
                                                          : Colors.grey,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        district,
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: isSelected
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                    .normal,
                                                          color: isSelected
                                                              ? Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .primary
                                                              : Theme.of(context).colorScheme.onSurface,
                                                        ),
                                                      ),
                                                    ),
                                                    if (isSelected)
                                                      Icon(
                                                        Icons.check,
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.primary,
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),

                              // Confirm Button
                              if (_selectedDistrict != null)
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        // Confirm selection and navigate back
                                        Navigator.pop(context, {
                                          'region': _selectedRegion,
                                          'district': _selectedDistrict,
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        'Confirm Location',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
