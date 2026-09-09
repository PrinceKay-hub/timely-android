import 'package:booking/presentaion/banner/cubit/banner_cubit.dart';
import 'package:booking/presentaion/banner/cubit/banner_state.dart';
import 'package:booking/presentaion/provider/pages/registration_screen.dart';
import 'package:booking/presentaion/screens/virtual/collection_explorer_screen.dart';
import 'package:booking/presentaion/screens/virtual/virtual_try_on_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

class BannerItemData {
  final String key;
  final String imageUrl;
  final bool isActive;
  final WidgetBuilder builder;

  const BannerItemData({
    required this.key,
    required this.imageUrl,
    required this.isActive,
    required this.builder,
  });
}

class SpecialOffersCard extends StatelessWidget {
  final Map<String, dynamic> user;
  const SpecialOffersCard({super.key, required this.user});

  
  @override
  Widget build(BuildContext context) {
    bool parseBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      if (value is int) return value != 0;
      return false;
    }

    final isProvider = parseBool(user['isProvider']);
  
  Map<String, WidgetBuilder> _builders() {
    return {
      'registration': (context) =>ServiceRegistrationScreen(
          userId: user['id'] ?? '',
          isProvider: isProvider,
        ),
      'tryon': (context) => const VirtualTryOnScreen(),
      'hairstyles': (context) => const CollectionsExplorerScreen(),
    };
  }


    return BlocProvider(
      create: (_) => BannerCubit()..subscribe(),
      child: BlocBuilder<BannerCubit, BannerState>(
        builder: (context, state) {
          if (state is BannerLoading || state is BannerInitial) {
            return Center(
              child: Shimmer.fromColors(
                baseColor: Theme.of(context).colorScheme.surfaceBright,
                highlightColor: Theme.of(context).colorScheme.surfaceDim,
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ),
            );
          }

          if (state is BannerError) {
            return const SizedBox.shrink(); // or a retry widget
          }

          final banners = (state as BannerLoaded).banners;
          final builders = _builders();

          final items = banners
              .map((b) {
                final builder = builders[b.key];
                if (builder == null) return null; // unknown key, skip
                return BannerItemData(
                  key: b.key,
                  imageUrl: b.imageUrl,
                  isActive: b.isActive,
                  builder: builder,
                );
              })
              .whereType<BannerItemData>()
              .toList();

          if (items.isEmpty) return const SizedBox.shrink();

          return CarouselSlider.builder(
            itemCount: items.length,
            itemBuilder: (context, index, realIndex) {
              final banner = items[index];
              return GestureDetector(
                onTap: () {
                  if (banner.key == 'registration' && user['isEmailVerified'] == false) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.red,
                        content: Text(
                          'Email not verified. Go to Profile Screen',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: banner.builder),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 20,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: banner.imageUrl,
                        fit: BoxFit.cover,
                        memCacheHeight: 350,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Theme.of(
                            context,
                          ).colorScheme.surfaceBright,
                          highlightColor: Theme.of(
                            context,
                          ).colorScheme.surfaceDim,
                          child: Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        errorWidget: (context, error, stackTrace) =>
                            const Icon(Icons.error),
                      ),
                    ),
                  ),
                ),
              );
            },
            options: CarouselOptions(
              height: 160,
              aspectRatio: 16 / 1,
              viewportFraction: 1,
              initialPage: 0,
              enableInfiniteScroll: true,
              reverse: false,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 10),
              autoPlayAnimationDuration: const Duration(milliseconds: 2500),
              autoPlayCurve: Curves.fastOutSlowIn,
              enlargeCenterPage: true,
              enlargeFactor: 0.3,
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.hardEdge,
            ),
          );
        },
      ),
    );
  }
}
