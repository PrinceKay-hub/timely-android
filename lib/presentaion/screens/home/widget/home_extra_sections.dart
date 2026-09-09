import 'package:booking/presentaion/screens/home/cubit_home/near_you_cubit.dart';
import 'package:booking/presentaion/screens/home/cubit_home/top_rated_cubit.dart';
import 'package:booking/presentaion/screens/home/cubit_home/new_on_timely_cubit.dart';
import 'package:booking/presentaion/screens/home/detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

class _CompactServiceCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _CompactServiceCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(id: item['id'])),
      ),
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              child: CachedNetworkImage(
                imageUrl:
                    (item['images'] is List &&
                        (item['images'] as List).isNotEmpty)
                    ? item['images'][0] as String
                    : '',
                height: 110,
                width: 150,
                fit: BoxFit.cover,
                memCacheWidth: 300,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Theme.of(context).colorScheme.surfaceBright,
                  highlightColor: Theme.of(context).colorScheme.surfaceDim,
                  child: Container(
                    height: 110,
                    width: 150,
                    color: Colors.white,
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 110,
                  width: 150,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        (item['rating'] ?? 0.0).toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (item['distanceKm'] != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _formatDistance(
                            (item['distanceKm'] as num).toDouble(),
                          ),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HorizontalSectionShell extends StatelessWidget {
  final String title;
  final Widget child;
  const _HorizontalSectionShell({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(height: title == 'Near You' ? 190 : 170, child: child),
        const SizedBox(height: 24),
      ],
    );
  }
}

Widget _horizontalCardList(List<Map<String, dynamic>> items) {
  return ListView.builder(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    itemCount: items.length,
    itemBuilder: (context, i) => _CompactServiceCard(item: items[i]),
  );
}

String _formatDistance(double km) {
  if (km < 1) {
    return '${(km * 1000).round()} m away';
  }
  return '${km.toStringAsFixed(1)} km away';
}

class NearYouSection extends StatelessWidget {
  const NearYouSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NearYouCubit, NearYouState>(
      builder: (context, state) {
        if (state is NearYouLoading || state is NearYouInitial) {
          return _HorizontalSectionShell(
            title: 'Near You',
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 5,
              itemBuilder: (context, i) => Shimmer.fromColors(
                  baseColor: Theme.of(context).colorScheme.surfaceBright,
                  highlightColor: Theme.of(context).colorScheme.surfaceDim,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      height: 110,
                      width: 150,
                      
                    ),
                  ),
                ),
            ),
          );
        }
        if (state is NearYouLoaded) {
          if (state.services.isEmpty) return const SizedBox.shrink();
          return _HorizontalSectionShell(
            title: 'Near You',
            child: _horizontalCardList(state.services),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class TopRatedSection extends StatelessWidget {
  const TopRatedSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TopRatedCubit, TopRatedState>(
      builder: (context, state) {
        if (state is TopRatedLoading || state is TopRatedInitial) {
          return _HorizontalSectionShell(
            title: 'Top Rated',
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 5,
              itemBuilder: (context, i) => Shimmer.fromColors(
                  baseColor: Theme.of(context).colorScheme.surfaceBright,
                  highlightColor: Theme.of(context).colorScheme.surfaceDim,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      height: 110,
                      width: 150,
                      
                    ),
                  ),
                ),
            ),
          );
        }
        if (state is TopRatedLoaded) {
          if (state.services.isEmpty) return const SizedBox.shrink();
          return _HorizontalSectionShell(
            title: 'Top Rated',
            child: _horizontalCardList(state.services),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class NewOnTimelySection extends StatelessWidget {
  const NewOnTimelySection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NewOnTimelyCubit, NewOnTimelyState>(
      builder: (context, state) {
        if (state is NewOnTimelyLoading || state is NewOnTimelyInitial) {
          return _HorizontalSectionShell(
            title: 'New on Timely',
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 5,
              itemBuilder: (context, i) => Shimmer.fromColors(
                  baseColor: Theme.of(context).colorScheme.surfaceBright,
                  highlightColor: Theme.of(context).colorScheme.surfaceDim,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      height: 110,
                      width: 150,
                      
                    ),
                  ),
                ),
            ),
          );
        }
        if (state is NewOnTimelyLoaded) {
          if (state.services.isEmpty) return const SizedBox.shrink();
          return _HorizontalSectionShell(
            title: 'New on Timely',
            child: _horizontalCardList(state.services),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
