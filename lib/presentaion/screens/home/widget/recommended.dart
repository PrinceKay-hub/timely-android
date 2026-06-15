import 'package:booking/presentaion/screens/favorite/bloc/favorite_bloc.dart';
import 'package:booking/presentaion/screens/favorite/bloc/favorite_state.dart';
import 'package:booking/presentaion/screens/home/detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Recommended extends StatelessWidget {
  final List data;
  final Map<String, dynamic> user;
  const Recommended({super.key, required this.data, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
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
        title: Text(
          'Recommended',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          itemCount: data.length,
          shrinkWrap: true,
          physics: BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final Map<String, dynamic> item = data[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailScreen(
                      data: data[index],
                      user: user,
                    ),
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
                          child: CachedNetworkImage(
                            imageUrl: item['images'][0],
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) {
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
                          child: BlocBuilder<FavoriteCubit, FavoriteState>(
                                builder: (context, state) {
                                  final isFav = state.favoriteIds.contains(item['id']);
                                  return Container(
                                    decoration:  BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface,
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon:   Icon(
                                        isFav ? Icons.favorite : Icons.favorite_border,
                                        color: isFav ? Colors.red : null,
                                        size: 24,
                                      ),
                                      onPressed: () {
                                        context.read<FavoriteCubit>().toggleFavorite(item['id']);
                                      },
                                    ),
                                  );
                                },
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
                                    color: const Color(
                                      0xFF10B981,
                                    ).withOpacity(0.1),
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
                              /*const Spacer(),
                              Icon(
                                Icons.location_on,
                                color: Colors.grey[400],
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item['distanceText']?.toString() ?? 'N/A',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),*/
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
                          if (item['services'] != null &&
                              item['services'] is List)
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: (item['services'] as List<dynamic>)
                                  .take(3)
                                  .map((service) {
                                    final name = service is Map
                                        ? (service['name'] as String? ?? '')
                                        : service.toString();
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.secondary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  })
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
    );
  }
}