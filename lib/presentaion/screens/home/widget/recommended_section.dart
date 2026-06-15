// lib/presentation/home/widgets/recommended_section.dart
import 'package:booking/presentaion/common/pages/network_error.dart';
import 'package:booking/presentaion/provider/cubit/service_data/service_data_cubit.dart';
import 'package:booking/presentaion/screens/home/cubit/home_cubit.dart';
import 'package:booking/presentaion/screens/home/detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class RecommendedSection extends StatelessWidget {
  final Map<String, dynamic> user;
  const RecommendedSection({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServiceDataCubit, ServiceDataState>(
      builder: (context, state) {
        if (state is ServiceDataLoaded) {
          final services = state.serviceData;
          if (services.isEmpty) {
            return _buildEmptyState(context);
          }
          return Column(
            children: [
              const _ViewTypeSwitcher(),
              const SizedBox(height: 10),
              _ServicesView(services: services, user: user,),
            ],
          );
        } 
        if (state is ServiceDataError) {
          return NetworkError(
            onTap: () {
            context.read<ServiceDataCubit>().fetchServiceData();
          },);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF667eea).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 64,
                color: Color(0xFF667eea),
              ),
            ),
            const SizedBox(height: 24),
             Text(
              'No Content Available',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Check back later for new updates\nand exciting content',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.read<ServiceDataCubit>().fetchServiceData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewTypeSwitcher extends StatelessWidget {
  const _ViewTypeSwitcher();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (previous, current) => previous.viewType != current.viewType,
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSecondary,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Text(
                  'Top services',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.read<HomeCubit>().setViewType(ViewType.tile),
                    icon: Icon(
                      Icons.window,
                      size: 18,
                      color: state.viewType == ViewType.tile
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.read<HomeCubit>().setViewType(ViewType.grid),
                    icon: Icon(
                      Icons.grid_on,
                       size: 18,
                      color: state.viewType == ViewType.grid
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.read<HomeCubit>().setViewType(ViewType.list),
                    icon: Icon(
                      Icons.view_list,
                       size: 18,
                      color: state.viewType == ViewType.list
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ServicesView extends StatelessWidget {
  final List<dynamic> services;
  final Map<String, dynamic> user;
  const _ServicesView({required this.services, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (previous, current) => previous.viewType != current.viewType,
      builder: (context, state) {
        switch (state.viewType) {
          case ViewType.tile:
            return _TileView(services: services, user: user,);
          case ViewType.grid:
            return _GridView(services: services, user: user,);
          case ViewType.list:
            return _ListView(services: services, user: user);
        }
      },
    );
  }
}

class _TileView extends StatelessWidget {
  final List<dynamic> services;
  final Map<String, dynamic> user;
  const _TileView({required this.services, required this.user});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: services.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final item = services[index] as Map<String, dynamic>;
        return _buildTileItem(context, item, user);
      },
    );
  }

  Widget _buildTileItem(BuildContext context, Map<String, dynamic> item,  Map<String, dynamic> user) {
    return GestureDetector(
      onTap: () => _navigateToDetail(context, item, user),
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
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              child: CachedNetworkImage(
                imageUrl: item['images']?[0] ?? '',
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  height: 160,
                  color: Colors.grey[200],
                  child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['name'] ?? '',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (item['isVerified'] == true)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified, color: Color(0xFF10B981), size: 16),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_city, color: Colors.grey[400], size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item['location'] ?? 'Unknown location',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (item['services'] != null && item['services'] is List)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: (item['services'] as List)
                          .take(3)
                          .map((service) => _buildServiceChip(context, service))
                          .toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceChip(BuildContext context, dynamic service) {
    final name = service is Map ? (service['name'] as String? ?? '') : service.toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
  }

  void _navigateToDetail(BuildContext context, Map<String, dynamic> item, Map<String, dynamic> user) {
    
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailScreen(data: item, user: user),
      ),
    );
  }
}

class _GridView extends StatelessWidget {
  final List<dynamic> services;
  final Map<String, dynamic> user;
  const _GridView({required this.services, required this.user});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1 / 1.4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final item = services[index] as Map<String, dynamic>;
        return _buildGridItem(context, item, user);
      },
    );
  }

  Widget _buildGridItem(BuildContext context, Map<String, dynamic> item,  Map<String, dynamic> user) {
    return GestureDetector(
      onTap: () => _navigateToDetail(context, item, user),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
                child: CachedNetworkImage(
                  imageUrl: item['images']?[0] ?? '',
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['location'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.yellow, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            (item['rating'] ?? 0.0).toStringAsFixed(1),
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
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

  void _navigateToDetail(BuildContext context, Map<String, dynamic> item,  Map<String, dynamic> user) {
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailScreen(data: item, user: user),
      ),
    );
  }
}

class _ListView extends StatelessWidget {
  final List<dynamic> services;
  final Map<String, dynamic> user;
  const _ListView({required this.services, required this.user});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final item = services[index] as Map<String, dynamic>;
        return _buildListItem(context, item, user);
      },
    );
  }

  Widget _buildListItem(BuildContext context, Map<String, dynamic> item,  Map<String, dynamic> user) {
    return GestureDetector(
      onTap: () => _navigateToDetail(context, item, user),
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
                imageUrl: item['images']?[0] ?? '',
                height: 120,
                width: 120,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Theme.of(context).colorScheme.surfaceBright,
                  highlightColor: Theme.of(context).colorScheme.surfaceDim,
                  child: Container(width: 120, height: 120, color: Colors.white),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 120,
                  width: 120,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
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
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['location'] ?? 'Unknown location',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                      maxLines: 1,
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

  void _navigateToDetail(BuildContext context, Map<String, dynamic> item, Map<String, dynamic> user) {
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailScreen(data: item, user: user),
      ),
    );
  }
}