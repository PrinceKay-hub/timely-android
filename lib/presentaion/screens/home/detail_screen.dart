import 'package:booking/core/utils/navigation_utils.dart';
import 'package:booking/data/models/portfolio_model.dart';
import 'package:booking/presentaion/booking/booking.dart';
import 'package:booking/presentaion/common/pages/gallery_widget.dart';
import 'package:booking/presentaion/common/widgets/working_hours_display.dart';
import 'package:booking/presentaion/provider/pages/portfolio/bloc/portfolio_bloc.dart';
import 'package:booking/presentaion/provider/pages/portfolio/bloc/portfolio_state.dart';
import 'package:booking/presentaion/review/cubit/review_cubit.dart';
import 'package:booking/presentaion/screens/favorite/bloc/favorite_bloc.dart';
import 'package:booking/presentaion/screens/favorite/bloc/favorite_state.dart';
import 'package:booking/presentaion/screens/home/detail/widget/portfolio_viewer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final Map<String, dynamic> user;
  const DetailScreen({super.key, required this.data, required this.user});

  @override
  State<DetailScreen> createState() => _DetailScreenState(data, user);
}

class _DetailScreenState extends State<DetailScreen> {
  _DetailScreenState(this.data, this.user);
  final Map<String, dynamic> data;
  final Map<String, dynamic> user;
  late final reviewCubit = context.read<ReviewCubit>();
  late final portCubit = context.read<PortfolioCubit>();
  bool isFavorite = false;
  int currentIndex = 0;
  bool _isLoading = false;

  Future<void> _handleDirections(double lat, double lng) async {
    setState(() => _isLoading = true);
    try {
      await NavigationUtils.openDirectionsWithExplicitStart(lat, lng);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  void shareProviderLink(String serviceId) {
    final deepLink = 'https://timelygh.com/service/$serviceId';
    SharePlus.instance.share(ShareParams(text: 'Check out my services on Timely: $deepLink'));
  }

  @override
  Widget build(BuildContext context) {
    reviewCubit.fetcReviews(data['providerId']);

    portCubit.loadPortfolio(data['id']);

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
      length: 3,
      child: Scaffold(
        body: Stack(
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
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.black),
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
                                  value % data['images'].length as int;
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
                                    builder: (context) => GalleryWidget(
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
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                errorWidget: (context, url, error) =>
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
                          final isFav = state.favoriteIds.contains(data['id']);
                          return Container(
                            margin: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.red : null,
                                size: 24,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (!isFav) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadiusGeometry.circular(10),
                                        ),
                                        showCloseIcon: true,
                                        content: Text('Added to favorite'),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: Colors.red,
                                        showCloseIcon: true,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadiusGeometry.circular(10),
                                        ),
                                        content: const Text(
                                          'Removed from favorite',
                                        ),
                                      ),
                                    );
                                  }
                                });
                                context.read<FavoriteCubit>().toggleFavorite(
                                  data['id'],
                                );
                              },
                            ),
                          );
                        },
                      ),
                     Container(
                      margin: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.share, color: Color(0xFF8B5CF6)),
                        onPressed: () {
                          shareProviderLink(data['id']);
                        },
                      ),
                    ),
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
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      getCategoryIcon(data['category']),
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
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
                                          data['rating'].toStringAsFixed(1),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
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

                                  if (data['providerId'] != user['id'])
                                    ElevatedButton(
                                      onPressed: () {
                                        if (user['isEmailVerified'] == false) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              backgroundColor: Colors.red,
                                              showCloseIcon: true,
                                              behavior:
                                                  SnackBarBehavior.floating,
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
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Book',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
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
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildQuickAction(
                                  Icons.call,
                                  'Call',
                                  () async {
                                    if (data['number'] == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          backgroundColor: Colors.red,
                                          showCloseIcon: true,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadiusGeometry.circular(
                                                  10,
                                                ),
                                          ),
                                          content: const Text(
                                            'Phone number not available',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    ;
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
                                    if (data['number'] == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          backgroundColor: Colors.red,
                                          showCloseIcon: true,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadiusGeometry.circular(
                                                  10,
                                                ),
                                          ),
                                          content: const Text(
                                            'WhatsApp number not available',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    ;
                                    var contact = data['number'];
                                    var text = 'Hello!';
                                    String trimmedNumber = contact.substring(1);

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
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
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
                                          backgroundColor: Colors.red,
                                          showCloseIcon: true,
                                          behavior: SnackBarBehavior.floating,
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
                                          : _handleDirections(
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
                  pinned: true, // This keeps it at the top when scrolling
                  delegate: _StickyTabBarDelegate(
                    TabBar(
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.black,
                      tabs: [
                        Tab(text: 'About'),
                        Tab(text: 'Reviews'),
                        Tab(text: 'Portfolio'),
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
                      _buildPortfolioTab(),
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
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
          ],
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

          if (reviews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.reviews_outlined, color: Colors.grey, size: 30,),
                  SizedBox(height: 10,),
                  Text('No Reviews Yet', 
                  style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold
                  ),
                ),
                SizedBox(height: 5,),
                Text('Engage with service to write review.', 
                  style: TextStyle(
                    color: Colors.grey, 
                    fontSize: 14,
                  ),
                  )
                ],
              ),
            );
          }
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
                /*  Center(
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
                ),*/
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
  Widget _buildPortfolioTab() {
    return BlocBuilder<PortfolioCubit, PortfolioState>(
      builder: (context, state) {
        if (state is PortfolioLoading) {
          return Center(child: CircularProgressIndicator(strokeWidth: 2));
        } else if (state is PortfolioLoaded) {
          final port = state.images;

            if (port.isEmpty) {
              
              return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined, color: Colors.grey, size: 30,),
                  SizedBox(height: 10,),
                  Text('No Portfolio Yet', 
                  style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold
                  ),
                ),
                SizedBox(height: 5,),
                Text("This service hasn't added any portfolio images.", 
                  style: TextStyle(
                    color: Colors.grey, 
                    fontSize: 14,
                  ),
                  )
                ],
              ),
            );
            }

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: port.length,
            itemBuilder: (context, index) {
              final newList = port[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PortfolioViewerScreen(
                        serviceId: data['id'],
                        initialIndex: index,
                      ),
                    ),
                  );
                },
                child: _buildPortfolioItem(newList),
              );
            },
          );
        } else if (state is PortfolioError) {
          return Center(child: Text(state.message));
        }
        return SizedBox.shrink();
      },
    );
  }

  Widget _buildPortfolioItem(PortfolioImage image) {
    final likes = image.likes!.isEmpty ? 0 : image.likes!.length.toString();
    return Container(
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
            CachedNetworkImage(imageUrl: image.imageUrl, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
            /* Positioned(
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
            ),*/
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    image.caption,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.favorite, color: Colors.white, size: 12),
                      SizedBox(width: 4),

                      Text(
                        likes.toString(),
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
    );
  }

  /* void _showPortfolioDetail(int index) {
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
                    'https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/service_images%2F89B8UaIUNCgbK3eqdMAvbRjDJvx2%2F1774627334379.jpg?alt=media&token=c3d87116-0c4b-47d6-8deb-ed16767e7ab2',
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
           /* Padding(
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
            ),*/
          ],
        ),
      ),
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

  String formatDateDifference(DateTime createdDate) {
    // Convert UTC timestamp to local timezone
    final DateTime createdLocal = createdDate.toLocal();
    final DateTime nowLocal = DateTime.now();

    // Extract only the date parts (ignore time)
    final DateTime createdOnly = DateTime(
      createdLocal.year,
      createdLocal.month,
      createdLocal.day,
    );
    final DateTime nowOnly = DateTime(
      nowLocal.year,
      nowLocal.month,
      nowLocal.day,
    );

    // Calendar day difference
    final int dayDiff = nowOnly.difference(createdOnly).inDays;

    // For relative time strings (minutes, hours) we still use the full difference
    final Duration diff = nowLocal.difference(createdLocal);

    if (diff.isNegative) {
      return "In the future";
    } else if (diff.inMinutes < 1) {
      return "Just now";
    } else if (diff.inHours < 1) {
      return "${diff.inMinutes} minutes ago";
    } else if (dayDiff == 0) {
      return "Today";
    } else if (dayDiff == 1) {
      return "Yesterday";
    } else if (dayDiff < 30) {
      return "$dayDiff days ago";
    } else if (dayDiff < 60) {
      return "1 month ago";
    } else if (dayDiff < 365) {
      final int months = (dayDiff / 30).floor();
      return "$months months ago";
    } else if (dayDiff < 730) {
      return "1 year ago";
    } else {
      final int years = (dayDiff / 365).floor();
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
