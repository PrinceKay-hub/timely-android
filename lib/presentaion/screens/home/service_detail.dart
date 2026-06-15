import 'package:booking/core/services/location_service.dart';
import 'package:booking/presentaion/booking/booking.dart';
import 'package:booking/presentaion/common/pages/error_screen.dart';
import 'package:booking/presentaion/common/pages/gallery_widget.dart';
import 'package:booking/presentaion/common/pages/loading_screen.dart';
import 'package:booking/presentaion/common/widgets/working_hours_display.dart';
import 'package:booking/presentaion/provider/cubit/service_detail/service_detail_cubit.dart';
import 'package:booking/presentaion/review/cubit/review_cubit.dart';
import 'package:booking/presentaion/screens/favorite/bloc/favorite_bloc.dart';
import 'package:booking/presentaion/screens/favorite/bloc/favorite_state.dart';
import 'package:booking/presentaion/user/cubit/user_cubit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class ServiceDetail extends StatefulWidget {
  final String id;
  const ServiceDetail({super.key, required this.id});

  @override
  State<ServiceDetail> createState() => _ServiceDetailState();
}

class _ServiceDetailState extends State<ServiceDetail> {
  late final reviewCubit = context.read<ReviewCubit>();
  late final service = context.read<ServiceDetailCubit>();
  late final userCubit = context.read<UserCubit>();
  bool isFavorite = false;
  int currentIndex = 0;
  bool _isLoading = false;

  Future<void> _openDirectionsWithLoading(
    double destLat,
    double destLng,
  ) async {
    setState(() => _isLoading = true);
    try {
      await openDirectionsWithExplicitStart(destLat, destLng);
    } catch (e) {
      // Handle error (show snackbar, etc.)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> openDirectionsWithExplicitStart(
    double destLat,
    double destLng,
  ) async {
    Position? currentPos = await LocationService()
        .getCurrentLocation(); // from geolocator
    if (currentPos == null) {
      // Fallback to Current+Location if location unavailable
      openDirections(destLat, destLng);
      return;
    }

    final url =
        'https://www.google.com/maps/dir/?api=1'
        '&origin=${currentPos.latitude},${currentPos.longitude}'
        '&destination=$destLat,$destLng'
        '&travelmode=driving';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not open Google Maps.';
    }
  }

  Future<void> openDirections(double destLat, double destLng) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&origin=Current+Location&destination=$destLat,$destLng';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not open Google Maps.';
    }
  }

  Future<void> launchWhatsApp({required String phone, String? message}) async {
    // Encode the message if provided
    final text = message != null ? '&text=${Uri.encodeComponent(message)}' : '';
    final url = 'whatsapp://send?phone=$phone$text';

    final Uri whatsappUri = Uri.parse(url);

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri);
    } else {
      // WhatsApp is not installed
      throw 'Could not launch WhatsApp. Make sure it is installed.';
    }
  }

  @override
  void initState() {
    service.getServiceById(widget.id);
    userCubit.loadUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    IconData getCategoryIcon(String category) {
      switch (category.toLowerCase()) {
        case 'barber':
          return Icons.content_cut;
        case 'hair salon':
          return Icons.waves;
        case 'spa':
          return Icons.spa;
        case 'nail salon':
          return Icons.circle_outlined;
        case 'beauty':
          return Icons.face;
        default:
          return Icons.check; // default icon for unknown amenities
      }
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: BlocBuilder<ServiceDetailCubit, ServiceDetailState>(
          builder: (context, state) {
            if (state is ServiceDetailLoading) {
              return LoadingScreen();
            } else if (state is ServiceDetailError) {
              return ErrorScreen(error: state.message);
            } else if (state is ServiceDetailLoaded) {
              final data = state.serviceData;
              reviewCubit.fetcReviews(data['providerId']);
              return BlocBuilder<UserCubit, UserState>(
                builder: (context, state) {
                  if (state is UserLoaded) {
                    final user = state.user;
                    return Stack(
                      children: [
                        CustomScrollView(
                          slivers: [
                            // Collapsing header with image
                            SliverAppBar(
                              expandedHeight: 300.0,
                              pinned: true,
                              floating: false,
                              backgroundColor: Theme.of(context).primaryColor,
                              leading: GestureDetector(
                                onTap: () => context.go('/home-entry'),
                                child: Container(
                                  margin: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              flexibleSpace: FlexibleSpaceBar(
                                background: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    PageView.builder(
                                      onPageChanged: (value) {
                                        setState(() {
                                          currentIndex =
                                              value % data['images'].length
                                                  as int;
                                        });
                                      },
                                      itemCount: data['images'].length,
                                      itemBuilder: (context, index) {
                                        List images = data['images'];
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    GalleryWidget(
                                                      images: images,
                                                      index: index,
                                                    ),
                                              ),
                                            );
                                          },
                                          child: CachedNetworkImage(
                                            imageUrl: data['images'][index],
                                            width: double.infinity,
                                            height: 400,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Shimmer.fromColors(
                                                  baseColor: Theme.of(
                                                    context,
                                                  ).colorScheme.surfaceBright,
                                                  highlightColor: Theme.of(
                                                    context,
                                                  ).colorScheme.surfaceDim,
                                                  child: Container(
                                                    width: double.infinity,
                                                    height: 400,
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: Colors.white,
                                                        ),
                                                  ),
                                                ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(Icons.error),
                                          ),
                                        );
                                      },
                                    ),
                                    Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Padding(
                                        padding: EdgeInsets.all(10),
                                        child: AnimatedSmoothIndicator(
                                          activeIndex: currentIndex,
                                          count: data['images'].length,
                                          effect: WormEffect(
                                            dotHeight: 8,
                                            dotWidth: 16,
                                            dotColor: Colors.grey[200],
                                            type: WormType.thinUnderground,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Action buttons (share, favorite)
                              actions: [
                                if (data['providerId'] != user['id'])
                                  BlocBuilder<FavoriteCubit, FavoriteState>(
                                    builder: (context, state) {
                                      final isFav = state.favoriteIds.contains(
                                        data['id'],
                                      );
                                      return Container(
                                        margin: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            isFav
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: isFav ? Colors.red : null,
                                            size: 24,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              if (!isFav) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    backgroundColor:
                                                        Colors.green,
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadiusGeometry.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    showCloseIcon: true,
                                                    content: Text(
                                                      'Added to favorite',
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    backgroundColor: Colors.red,
                                                    showCloseIcon: true,
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadiusGeometry.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    content: const Text(
                                                      'Removed from favorite',
                                                    ),
                                                  ),
                                                );
                                              }
                                            });
                                            context
                                                .read<FavoriteCubit>()
                                                .toggleFavorite(data['id']);
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                /*Container(
                                            margin: const EdgeInsets.all(8),
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: IconButton(
                                              icon: const Icon(Icons.share, color: Color(0xFF8B5CF6)),
                                              onPressed: () {},
                                            ),
                                          ),*/
                              ],
                            ),

                            SliverToBoxAdapter(
                              child: Container(
                                color: Theme.of(context).colorScheme.secondary,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Basic Info Card
                                    Container(
                                      margin: const EdgeInsets.all(20),
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface,
                                        borderRadius: BorderRadius.circular(20),
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
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Name and Status
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  data['name'],
                                                  style: TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),

                                          // Category
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEDE9FE),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  getCategoryIcon(
                                                    data['category'],
                                                  ),
                                                  color: Color(0xFF8B5CF6),
                                                  size: 16,
                                                ),
                                                SizedBox(width: 6),
                                                Text(
                                                  data['category'],
                                                  style: TextStyle(
                                                    color: Color(0xFF8B5CF6),
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 16),

                                          // Location
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                color: Color(0xFF8B5CF6),
                                                size: 20,
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  data['location'],
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),

                                          // Rating and Price
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.star,
                                                      color: Colors.amber,
                                                      size: 16,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      data['rating']
                                                          .toStringAsFixed(1),
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      '(${data['totalReviews'].toString()} reviews)',
                                                      style: TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Spacer(),

                                              if (data['providerId'] !=
                                                  user['id'])
                                                ElevatedButton(
                                                  onPressed: () {
                                                    if (user['isEmailVerified'] ==
                                                        false) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          backgroundColor:
                                                              Colors.red,
                                                          showCloseIcon: true,
                                                          behavior:
                                                              SnackBarBehavior
                                                                  .floating,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadiusGeometry.circular(
                                                                  10,
                                                                ),
                                                          ),
                                                          content: const Text(
                                                            'Email not verified. Go to Profile Screen',
                                                          ),
                                                        ),
                                                      );
                                                    } else {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              BookingScreen(
                                                                data: data,
                                                                user: user,
                                                              ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Theme.of(
                                                      context,
                                                    ).primaryColor,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 8,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Book',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Quick Actions
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: _buildQuickAction(
                                              Icons.call,
                                              'Call',
                                              () async {
                                                final Uri url = Uri(
                                                  scheme: 'tel',
                                                  path: data['number'],
                                                );
                                                if (await canLaunchUrl(url)) {
                                                  await launchUrl(url);
                                                } else {
                                                  throw 'Could not launch $url';
                                                }
                                                //openCall('tel:${widget.data['number']}');
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildQuickAction(
                                              FontAwesomeIcons.whatsapp,
                                              'WhatsApp',
                                              () async {
                                                var contact = data['number'];
                                                var text = 'Hello!';
                                                String trimmedNumber = contact
                                                    .substring(1);

                                                try {
                                                  await launchWhatsApp(
                                                    phone: trimmedNumber,
                                                    message: text,
                                                  );
                                                } catch (e) {
                                                  // Show a snackbar or dialog
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'WhatsApp not installed',
                                                      ),
                                                      backgroundColor:
                                                          Colors.red,
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadiusGeometry.circular(
                                                              10,
                                                            ),
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildQuickAction(
                                              Icons.directions,
                                              'Direction',
                                              () {
                                                if (data['latitude'] == null &&
                                                    data['longitude'] == null) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      backgroundColor:
                                                          Colors.red,
                                                      showCloseIcon: true,
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadiusGeometry.circular(
                                                              10,
                                                            ),
                                                      ),
                                                      content: const Text(
                                                        'Shop location not available',
                                                      ),
                                                    ),
                                                  );
                                                } else {
                                                  _isLoading
                                                      ? null
                                                      : _openDirectionsWithLoading(
                                                          data['latitude'],
                                                          data['longitude'],
                                                        );
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            ),

                            // Sticky tab bar
                            SliverPersistentHeader(
                              pinned:
                                  true, // This keeps it at the top when scrolling
                              delegate: _StickyTabBarDelegate(
                                TabBar(
                                  labelColor: Colors.black,
                                  unselectedLabelColor: Colors.grey,
                                  indicatorColor: Colors.black,
                                  tabs: [
                                    Tab(text: 'About'),
                                    Tab(text: 'Reviews'),
                                    //Tab(text: 'Portfolio'),
                                    //Tab(text: 'PORTFOLIO'),
                                    //Tab(text: 'GIFT CARDS'),
                                    //Tab(text: 'DETAILS'),
                                  ],
                                ),
                              ),
                            ),

                            // Scrollable content
                            SliverFillRemaining(
                              child: TabBarView(
                                children: [
                                  _buildAboutTab(data),
                                  _buildReviewsTab(data),
                                  // _buildPortfolioTab(),
                                  //_buildServicesTab(),
                                  //Center(child: Text('Reviews')),
                                  // Center(child: Text('Portfolio')),
                                  //Center(child: Text('Gift Cards')),
                                  //Center(child: Text('Details')),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_isLoading)
                          Positioned.fill(
                            child: AbsorbPointer(
                              absorbing: true, // blocks all touch events
                              child: Container(
                                color: Colors.black54,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  }
                  return SizedBox.shrink();
                },
              );
            }
            return SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF8B5CF6), size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // About Tab Content
  Widget _buildAboutTab(Map<String, dynamic> data) {
    IconData getAmenityIcon(String amenity) {
      switch (amenity.toLowerCase()) {
        case 'free wifi':
          return Icons.wifi;
        case 'parking':
          return Icons.local_parking;
        case 'mobile money payment':
          return Icons.credit_card;
        case 'wheelchair access':
          return Icons.accessibility;
        case 'refreshment':
          return Icons.coffee;
        case 'air conditioned':
          return Icons.ac_unit;
        case 'dstv':
          return Icons.tv;
        default:
          return Icons.check; // default icon for unknown amenities
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          const Text(
            'Description',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            data['description'],
            style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 24),

          // Services Offered
          const Text(
            'Services & Pricing',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: data['services']?.length ?? 0,
            itemBuilder: (context, index) {
              final service = data['services'][index];
              return _buildServiceItem(
                service['name'],
                service['price'].toString(),
                service['duration'].toString(),
              );
            },
          ),
          const SizedBox(height: 24),

          // Business Hours
          const Text(
            'Business Hours',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: WorkingHoursDisplay(service: data),
          ),
          const SizedBox(height: 24),

          // Amenities
          const Text(
            'Amenities',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...data['amenities'].map<Widget>((amenity) {
                return _buildAmenityChip(getAmenityIcon(amenity), amenity);
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  // Reviews Tab Content
  Widget _buildReviewsTab(Map<String, dynamic> data) {
    return BlocBuilder<ReviewCubit, ReviewState>(
      builder: (context, state) {
        if (state is ReviewLoading) {
          return Center(child: CircularProgressIndicator(strokeWidth: 2));
        } else if (state is ReviewLoaded) {
          final reviews = state.reviews;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overall Rating Summary
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Text(
                        data['rating'].toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          5,
                          (index) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Based on ${data['totalReviews'].toString()} reviews',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),

                /*const SizedBox(height: 24),
    
              // Filter Chips
              Row(
                children: [
                  const Text(
                    'Sort by:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('Most Recent', true),
                          const SizedBox(width: 8),
                          _buildFilterChip('Highest Rated', false),
                          const SizedBox(width: 8),
                          _buildFilterChip('Lowest Rated', false),
                          const SizedBox(width: 8),
                          _buildFilterChip('With Photos', false),
                        ],
                      ),
                    ),
                  ),
                ],
              ),*/
                const SizedBox(height: 20),

                ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> review = reviews[index];

                    return _buildReviewCard(
                      review['userName'],
                      review['rating'].toStringAsFixed(0),
                      formatDateDifference(review['createdAt'].toDate()),
                      review['comment'],
                      verified: true,
                    );
                  },
                  separatorBuilder: (context, index) {
                    return SizedBox(height: 12);
                  },
                ),

                // Load More Button
                Center(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8B5CF6),
                      side: const BorderSide(color: Color(0xFF8B5CF6)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Load More Reviews',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else if (state is ReviewError) {
          return Center(child: Text(state.message));
        }
        return SizedBox.shrink();
      },
    );
  }

  Widget _buildReviewCard(
    String name,
    String rating,
    String date,
    String review, {
    bool verified = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer Info
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.surface,
                child: Text(
                  name[0],
                  style: const TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (verified) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Color(0xFF8B5CF6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Star Rating
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      rating,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Review Text
          Text(review, style: const TextStyle(fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  // Portfolio Tab Content
  /* Widget _buildPortfolioTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return _buildPortfolioItem(index);
      },
    );
  }*/

  Widget _buildServiceItem(String name, String price, String duration) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.cut, color: Color(0xFF8B5CF6), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$duration mins',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '₵$price',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF8B5CF6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF8B5CF6), size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8B5CF6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /* Widget _buildPortfolioItem(int index) {
    final categories = ['Haircut', 'Beard', 'Color', 'Style'];
    final category = categories[index % categories.length];

    return GestureDetector(
      onTap: () {
        _showPortfolioDetail(index);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                'https://via.placeholder.com/200x240',
                fit: BoxFit.cover,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Modern Style',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: const [
                        Icon(Icons.favorite, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          '124',
                          style: TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }*/

  /*void _showPortfolioDetail(int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: Image.network(
                    'https://via.placeholder.com/400x400',
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Modern Fade Style',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'By Marcus Johnson',
                    style: TextStyle(
                      color: Color(0xFF8B5CF6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'A clean modern fade with textured top. Perfect for professional and casual settings.',
                    style: TextStyle(color: Colors.grey, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Haircut',
                          style: TextStyle(
                            color: Color(0xFF8B5CF6),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.favorite, color: Colors.red, size: 20),
                      const SizedBox(width: 4),
                      const Text(
                        '124',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }*/

  String formatDateDifference(DateTime createdDate) {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(createdDate);

    if (difference.isNegative) {
      return "In the future";
    } else if (difference.inMinutes < 1) {
      return "Just now";
    } else if (difference.inHours < 1) {
      return "${difference.inMinutes} minutes ago";
    } else if (difference.inDays == 0) {
      return "Today";
    } else if (difference.inDays == 1) {
      return "Yesterday";
    } else if (difference.inDays < 30) {
      return "${difference.inDays} days ago";
    } else if (difference.inDays < 60) {
      return "1 month ago";
    } else if (difference.inDays < 365) {
      final int months = (difference.inDays / 30).floor();
      return "$months months ago";
    } else if (difference.inDays < 730) {
      return "1 year ago";
    } else {
      final int years = (difference.inDays / 365).floor();
      return "$years years ago";
    }
  }
}

// Custom delegate for sticky tab bar
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: tabBar);
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}
